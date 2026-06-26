# DR Runbook — Security ERP Platform

**Останнє оновлення:** 2026-06-26
**Відповідальний:** joker@riad.fun

---

## 1. Огляд системи

| Компонент | Опис |
|-----------|------|
| ERPNext | Frappe ERP (backend + frontend + workers + scheduler) |
| MariaDB | Основна БД (source of truth) |
| Redis | Кеш, черги, rate limiting |
| Security API | FastAPI gateway (JWT auth + RBAC) |
| Cloudflared | Тунель до riad.fun |

---

## 2. Стратегія бекапів

### 2.1 Що бекапиться

| Даний | Метод | Частота | Зберігання |
|-------|-------|---------|------------|
| MariaDB | `scripts/backup-mariadb.sh` | Щодня о 02:00 (cron) | 30 днів |
| Повний стек | `scripts/backup.sh` | Щотижня | 7 днів |

### 2.2 Де зберігаються бекапи

```
/home/joker/RIAD CRM/backups/automated/
├── mariadb_daily_YYYYMMDD_HHMMSS.sql.gz      # GPG-зашифровані
├── mariadb_daily_YYYYMMDD_HHMMSS.sql.gz.gpg  # зашифровані копії
└── ...
```

### 2.3 GPG-шифрування

- **Публічний ключ:** `configs/backup_public.gpg` (для шифрування)
- **Приватний ключ:** `configs/backup_secret.gpg` (для дешифрування)
- **Fingerprint:** `72569A554E8EE37BC74EDCBFE1CE1076F4941C61`
- **ВАЖЛИВО:** Приватний ключ ОБОВ'ЯЗКОВО зберігати в офлайн-сховищі (password manager / USB)

---

## 3. Перевірка системи (Quick Health Check)

```bash
# 1. Статус контейнерів
docker compose ps

# 2. Логи MariaDB (останні 50 рядків)
docker compose logs --tail=50 mariadb

# 3. Логи ERPNext backend
docker compose logs --tail=50 erpnext-backend

# 4. Перевірка з'єднання з БД
docker compose exec mariadb mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1"

# 5. Останній бекап
ls -lt /home/joker/RIAD\ CRM/backups/automated/ | head -5
```

---

## 4. Відновлення з бекапу (Restore)

### 4.1 Підготовка

```bash
# Зупинити ERPNext (НЕ зупиняємо MariaDB та Redis)
cd "/home/joker/RIAD CRM"
docker compose stop erpnext-backend erpnext-frontend erpnext-worker-default erpnext-worker-short erpnext-scheduler
```

### 4.2 Відновлення MariaDB

**Варіант A: Автоматичний (рекомендовано)**

```bash
# Використовуємо скрипт відновлення
# Він автоматично знайде найновіший бекап
./scripts/restore.sh
```

**Варіант B: Ручний (конкретний файл)**

```bash
# Знайти бекап
ls -lt backups/automated/mariadb_daily_*.sql.gz*

# Якщо .sql.gz.gpg (зашифрований):
GPG_FILE="backups/automated/mariadb_daily_YYYYMMDD_HHMMSS.sql.gz.gpg"
GPG_DIR=$(mktemp -d)
gpg --batch --yes --homedir "$GPG_DIR" --import configs/backup_secret.gpg
gpg --batch --yes --homedir "$GPG_DIR" --decrypt "$GPG_FILE" | gunzip | \
  docker compose exec -T mariadb mysql -u root -p"${MYSQL_ROOT_PASSWORD}"
rm -rf "$GPG_DIR"

# Якщо .sql.gz (не зашифрований):
GZ_FILE="backups/automated/mariadb_daily_YYYYMMDD_HHMMSS.sql.gz"
gunzip -c "$GZ_FILE" | docker compose exec -T mariadb mysql -u root -p"${MYSQL_ROOT_PASSWORD}"
```

### 4.3 Після відновлення

```bash
# Запустити ERPNext
docker compose up -d

# Перевірити статус
docker compose ps

# Перевірити логи
docker compose logs -f erpnext-backend --tail=100
```

---

## 5. Відновлення на новому сервері

### 5.1 Кроки

1. **Встановити Docker та Docker Compose** на новому сервері
2. **Клонувати репозиторій:**
   ```bash
   git clone <repo-url> "/home/joker/RIAD CRM"
   cd "/home/joker/RIAD CRM"
   ```
3. **Відновити .env файл:**
   ```bash
   # Скопіювати з офлайн-сховища або створити заново
   cp /path/to/backup/.env "/home/joker/RIAD CRM/.env"
   ```
4. **Відновити GPG ключі:**
   ```bash
   # Отримати з офлайн-сховища
   cp /path/to/backup/backup_secret.gpg configs/
   cp /path/to/backup/backup_public.gpg configs/
   chmod 600 configs/backup_secret.gpg
   ```
5. **Запустити стек:**
   ```bash
   docker compose up -d
   ```
6. **Відновити дані** (див. розділ 4)

### 5.2 Необхідні файли з офлайн-сховища

| Файл | Опис |
|------|------|
| `.env` | Конфігурація середовища (паролі, ключі) |
| `configs/backup_secret.gpg` | Приватний GPG ключ |
| `configs/backup_public.gpg` | Публічний GPG ключ |

---

## 6. Перевірка цілісності бекапу

```bash
# Перевірка розміру (має бути > 1MB для повного бекапу)
ls -lh backups/automated/mariadb_daily_*.sql.gz* | tail -5

# Перевірка GPG-зашифрованого файлу
GPG_FILE="backups/automated/mariadb_daily_YYYYMMDD_HHMMSS.sql.gz.gpg"
GPG_DIR=$(mktemp -d)
gpg --batch --yes --homedir "$GPG_DIR" --import configs/backup_secret.gpg
gpg --batch --yes --homedir "$GPG_DIR" --decrypt "$GPG_FILE" | gunzip | head -20
rm -rf "$GPG_DIR"
# Очікуваний вивід: SQL dump header (CREATE TABLE, INSERT тощо)
```

---

## 7. Troubleshooting

### 7.1 MariaDB не стартує

```bash
# Перевірити логи
docker compose logs mariadb

# Перевірити диск
df -h

# Перезапустити
docker compose restart mariadb
```

### 7.2 ERPNext не підключається до БД

```bash
# Перевірити MariaDB
docker compose exec mariadb mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW DATABASES"

# Перевірити site_config
docker compose exec erpnext-backend cat sites/erp.localhost/site_config.json
```

### 7.3 Бекап не створюється (cron)

```bash
# Перевірити cron
crontab -l | grep backup

# Перевірити логи backup
cat /var/log/syslog | grep backup-mariadb

# Запустити вручну для діагностики
./scripts/backup-mariadb.sh
```

### 7.4 GPG-шифрування не працює

```bash
# Перевірити наявність ключів
ls -la configs/backup_*.gpg

# Перевірити GPG
gpg --list-keys backup@riad.local

# Тестове шифрування
echo "test" | gpg --encrypt --recipient backup@riad.local | gpg --decrypt
```

---

## 8. Контакти

| Роль | Контакт |
|------|---------|
| Адміністратор | joker@riad.fun |
| Сервер | riad.fun |
| Репозиторій | GitHub (див. .git/config) |

---

## 9. Чек-лист відновлення

- [ ] Зупинити ERPNext контейнери
- [ ] Знайти останній бекап
- [ ] Дешифрувати (якщо .gpg)
- [ ] Відновити MariaDB
- [ ] Запустити ERPNext
- [ ] Перевірити логи
- [ ] Перевірити доступність через https://riad.fun
- [ ] Повідомити користувачів про відновлення

---

## 10. Відновлення Vault після втрати сервера

### Передумова

- vault_master_key отримано з escrow (див. `docs/key_escrow_procedure.md`)
- MariaDB відновлено (кроки вище)

### Верифікація

```bash
docker compose exec erpnext-backend bench --site erp.localhost console
```

```python
from security_erp.vault._key import get_master_key
key = get_master_key()
print(f"Master key loaded: {len(key)} bytes")

from security_erp.vault.audit import verify_chain
broken = verify_chain()
if not broken:
    print("Audit chain: OK")
else:
    print(f"Audit chain: {len(broken)} broken links")
    for b in broken:
        print(f"  {b}")
```

### Якщо verify показує broken

1. Перевірити що vault_master_key правильний (32 байти = 64 hex символи)
2. Перевірити що MariaDB не пошкоджена
3. Якщо key неправильний — отримати з escrow ще раз

---

## 11. Необхідні файли з офлайн-сховища (оновлено)

| Файл | Опис |
|------|------|
| `.env` | Конфігурація середовища (паролі, ключі) |
| `configs/backup_secret.gpg` | Приватний GPG ключ |
| `configs/backup_public.gpg` | Публічний GPG ключ |
| `configs/vault_master_key` | AES-256 ключ шифрування Vault |
