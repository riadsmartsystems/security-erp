# DR Runbook — RIAD Security ERP

> Оновлено: 2026-06-26 (v2)
> Контакт: joker@riad.fun

## Крок 0: Якщо сервер втрачено повністю (апаратна помилка)

Якщо це не просто втрата даних, а втрата ВСЬОГО хоста — спочатку підготуйте
нове середовище, ПЕРШ ніж переходити до розділу "Повне відновлення":

1. Піднімте новий сервер, встановіть Docker + Docker Compose.
2. `git clone <repo> "/home/joker/RIAD CRM"` та `git checkout master`.
3. Відновіть .env із захищеного сховища секретів (password manager / vault).
   Файл .env НЕ зберігається в git і не відновлюється автоматично.
4. Якщо backup'и зашифровані GPG — відновіть configs/backup_secret.gpg з
   ОФЛАЙН-резервної копії (поза цим сервером). Без цього файлу зашифровані
   backup'и НЕВІДНОВЛЮВАНІ.
   chmod 0600 "/home/joker/RIAD CRM/configs/backup_secret.gpg"
5. `docker compose up -d` (піднімає mariadb, redis і т.д., поки що без даних).
6. Тільки після цього переходьте до розділу "Повне відновлення" нижче.

⚠️ Приватний GPG-ключ backup@riad.local (configs/backup_secret.gpg) ОБОВ'ЯЗКОВО
має офлайн-копію поза цим сервером (password manager / зашифрований USB / vault).
Якщо копії немає — це треба виправити негайно: інакше шифрування backup'ів не
має сенсу саме для сценарію втрати хоста.

## Швидка перевірка стану системи

```bash
# Чи працює ERPNext?
curl -sf https://erp.riad.fun/api/method/ping && echo "ERPNext: OK" || echo "ERPNext: DOWN"

# Останній backup (> 1MB = норма)?
ls -lt /home/joker/RIAD\ CRM/backups/automated/ | head -3
LATEST=$(ls -t /home/joker/RIAD\ CRM/backups/automated/mariadb_daily_*.sql.gz* 2>/dev/null | head -1)
[ -n "$LATEST" ] && [ $(stat -c%s "$LATEST") -gt 1000000 ] && echo "BACKUP: OK" || echo "BACKUP: FAIL"

# Binlog (PITR)?
MARIADB=$(docker ps --format '{{.Names}}' | grep -m1 mariadb)
PASS=$(grep '^MYSQL_ROOT_PASSWORD=' /home/joker/RIAD\ CRM/.env | cut -d= -f2-)
docker exec "$MARIADB" mysql -u root -p"$PASS" -e "SHOW VARIABLES LIKE 'log_bin';"
# Очікується: log_bin = ON

# Redis AOF?
docker exec $(docker ps --format '{{.Names}}' | grep -m1 redis) redis-cli CONFIG GET appendonly
# Очікується: appendonly = yes

# Всі контейнери healthy?
docker compose ps | grep -c healthy
# Очікується: ≥ 9
```

## Повне відновлення (Restore)

### Крок 1: Знайти backup

```bash
ls -lt /home/joker/RIAD\ CRM/backups/automated/mariadb_daily_*.sql.gz* | head -3
# Обери файл з найновішою датою (.sql.gz.gpg = зашифрований, .sql.gz = звичайний)
```

### Крок 2: Зупинити ERPNext (НЕ MariaDB!)

```bash
cd "/home/joker/RIAD CRM"
docker compose stop erpnext-backend erpnext-worker-default erpnext-worker-short erpnext-scheduler
# Перевір: docker compose ps — ці 4 контейнери мають бути Exited
```

### Крок 3: Відновити базу

**Якщо backup = .sql.gz (plain):**
```bash
BACKUP="/home/joker/RIAD CRM/backups/automated/mariadb_daily_XXXXXXXX_XXXXXX.sql.gz"
MARIADB=$(docker ps --format '{{.Names}}' | grep -m1 mariadb)
PASS=$(grep '^MYSQL_ROOT_PASSWORD=' /home/joker/RIAD\ CRM/.env | cut -d= -f2-)
gunzip -c "$BACKUP" | docker exec -i "$MARIADB" mysql -u root -p"$PASS"
echo "RESTORE_EXIT=$?"
```

**Якщо backup = .sql.gz.gpg (зашифрований):**
```bash
BACKUP="/home/joker/RIAD CRM/backups/automated/mariadb_daily_XXXXXXXX_XXXXXX.sql.gz.gpg"
MARIADB=$(docker ps --format '{{.Names}}' | grep -m1 mariadb)
PASS=$(grep '^MYSQL_ROOT_PASSWORD=' /home/joker/RIAD\ CRM/.env | cut -d= -f2-)
GPG_DIR=$(mktemp -d)
gpg --batch --yes --homedir "$GPG_DIR" --import "/home/joker/RIAD CRM/configs/backup_secret.gpg" 2>/dev/null
gpg --batch --yes --homedir "$GPG_DIR" --decrypt "$BACKUP" 2>/dev/null | gunzip | docker exec -i "$MARIADB" mysql -u root -p"$PASS"
echo "RESTORE_EXIT=$?"
rm -rf "$GPG_DIR"
```

> Альтернатива: `scripts/restore.sh "<BACKUP_DIR>"` робить це автоматично і
> сам визначає формат (GPG / plain gz / plain sql) — підходить як для
> timestamped cron-backup'ів (mariadb_daily_*), так і для legacy
> full-backup'ів (mariadb_full.*).

### Крок 4: Запустити ERPNext

```bash
cd "/home/joker/RIAD CRM"
docker compose up -d erpnext-backend erpnext-worker-default erpnext-worker-short erpnext-scheduler
# Чекати ~2 хвилини
docker compose ps
# Всі 4 контейнери мають бути Up (healthy)
```

### Крок 5: Верифікація після restore

```bash
# Таблиці на місці?
MARIADB=$(docker ps --format '{{.Names}}' | grep -m1 mariadb)
PASS=$(grep '^MYSQL_ROOT_PASSWORD=' /home/joker/RIAD\ CRM/.env | cut -d= -f2-)
DB=$(grep '^MARIADB_DATABASE=' /home/joker/RIAD\ CRM/.env | cut -d= -f2-)
TABLES=$(docker exec "$MARIADB" mysql -u root -p"$PASS" -e "USE \`$DB\`; SHOW TABLES;" | wc -l)
echo "TABLES=$TABLES"
# Очікується: > 700

# ERPNext відповідає?
curl -sf https://erp.riad.fun/api/method/ping && echo "ERPNext: OK" || echo "ERPNext: DOWN"

# Користувачі на місці?
docker exec "$MARIADB" mysql -u root -p"$PASS" -e "SELECT name, enabled FROM \`$DB\`.tabUser WHERE enabled=1;"
```

## PITR (Point-in-Time Recovery)

Використовуй коли потрібно відновити стан БД на конкретний момент часу
(наприклад, до помилкового видалення даних о 14:30).

⚠️ Обмеження: binlog зберігається лише 7 днів (configs/mariadb.cnf,
expire_logs_days=7). PITR можливий ТІЛЬКИ в межах останніх 7 днів. Для
давніших інцидентів — лише відновлення з найближчого daily/weekly backup'у
(точність — до дати backup'у, не до секунди).

### Крок 1: Перевірити binlog

```bash
MARIADB=$(docker ps --format '{{.Names}}' | grep -m1 mariadb)
PASS=$(grep '^MYSQL_ROOT_PASSWORD=' /home/joker/RIAD\ CRM/.env | cut -d= -f2-)
docker exec "$MARIADB" mysql -u root -p"$PASS" -e "SHOW VARIABLES LIKE 'log_bin';"
# log_bin = ON
```

### Крок 2: Знайти потрібний файл логів

```bash
docker exec "$MARIADB" mysql -u root -p"$PASS" -e "SHOW BINARY LOGS;"
# Покаже список файлів логів з розмірами. Ротація відбувається автоматично,
# тож "потрібний" файл — НЕ завжди mariadb-bin.000001. Якщо backup створено
# з --master-data (див. опціональний Task 1b), точна позиція початку
# записана в заголовку самого дампу (CHANGE MASTER TO / MASTER_LOG_FILE).
# Якщо ні — орієнтуйся на час модифікації файлів логів.
```

### Крок 3: Витягнути зміни у файл і ПЕРЕВІРИТИ перед застосуванням

```bash
docker exec "$MARIADB" mysqlbinlog \
    --stop-datetime="2026-06-26 14:30:00" \
    /var/lib/mysql/mariadb-bin.000001 > /tmp/pitr_recovery.sql
# Якщо потрібний проміжок охоплює кілька файлів — повтори для кожного
# (000001, 000002, ...) у хронологічному порядку й об'єднай результати.

less /tmp/pitr_recovery.sql
# ОБОВ'ЯЗКОВО перегляньте файл перед застосуванням — переконайтесь, що
# в ньому немає операції, яку ви намагаєтесь скасувати. НЕ пайпте
# mysqlbinlog напряму в prod mysql без перегляду.
```

### Крок 4: Застосувати

```bash
docker exec -i "$MARIADB" mysql -u root -p"$PASS" < /tmp/pitr_recovery.sql
# Заміни --stop-datetime на момент ДО помилкової операції.
# Для точнішого відновлення (секундна гранулярність часто занадто груба) —
# знайди точну --stop-position замість --stop-datetime, переглянувши вивід
# mysqlbinlog без фільтра і знайшовши потрібну транзакцію.
```

## Emergency Contacts

- Сервер: riad.fun
- SSH: joker@riad.fun
- Docker статус: `docker compose ps`
- Backend логи: `docker compose logs -f erpnext-backend --tail=100`
- MariaDB логи: `docker compose logs -f mariadb --tail=100`
- Redis логи: `docker compose logs -f redis --tail=100`
- Backup логи: `cat /home/joker/RIAD\ CRM/backups/automated/cron.log | tail -20`

## Щотижневі перевірки (кожного понеділка)

```bash
cd "/home/joker/RIAD CRM"

echo "=== Щотижнева перевірка ==="

# 1. Backup > 1MB?
LATEST=$(ls -t backups/automated/mariadb_daily_*.sql.gz* 2>/dev/null | head -1)
[ -n "$LATEST" ] && [ $(stat -c%s "$LATEST") -gt 1000000 ] && echo "1. BACKUP: OK ($(basename "$LATEST"))" || echo "1. BACKUP: FAIL"

# 2. Binlog?
MARIADB=$(docker ps --format '{{.Names}}' | grep -m1 mariadb)
PASS=$(grep '^MYSQL_ROOT_PASSWORD=' .env | cut -d= -f2-)
docker exec "$MARIADB" mysql -u root -p"$PASS" -e "SHOW VARIABLES LIKE 'log_bin';" | grep -q ON && echo "2. BINLOG: OK" || echo "2. BINLOG: FAIL"

# 3. Redis AOF?
docker exec $(docker ps --format '{{.Names}}' | grep -m1 redis) redis-cli CONFIG GET appendonly | grep -q yes && echo "3. AOF: OK" || echo "3. AOF: FAIL"

# 4. Cron?
crontab -l | grep -q backup && echo "4. CRON: OK" || echo "4. CRON: FAIL"

# 5. Контейнери healthy?
HEALTHY=$(docker compose ps | grep -c "healthy")
echo "5. CONTAINERS: $HEALTHY healthy"

# 6. Disk?
df -h / | tail -1 | awk '{print "6. DISK: "$5" used"}'

# 7. Офлайн-копія GPG-ключа підтверджена? (ручна перевірка, раз на квартал)
echo "7. GPG OFFSITE KEY: перевір вручну, чи копія в password manager / vault досі актуальна"
```
