# Key-Escrow Procedure — RIAD Security ERP

**Останнє оновлення:** 2026-06-26
**Відповідальний:** joker@riad.fun

---

## Мета

Забезпечити відновлення Vault після повної втрати сервера.

---

## Що зберігається в escrow

1. `vault_master_key` — 32-байтний AES-256 ключ (hex, 64 символи)
2. `backup_secret.gpg` — GPG приватний ключ для дешифрування бекапів

---

## Процедура зберігання (при зміні ключа)

### Крок 1: Згенерувати новий ключ

```bash
openssl rand -hex 32 > /tmp/vault_master_key_new
```

### Крок 2: Зашифрувати для escrow

```bash
gpg --recipient backup@riad.local --encrypt /tmp/vault_master_key_new
```

### Крок 3: Зберегти в escrow (два канали)

- **Канал 1:** USB-ключ (шифрований), зберігається у сейфі
- **Канал 2:** Зашифрований файл на окремому сервері/хмарному сховищі

### Крок 4: Замінити ключ на сервері

```bash
cp /tmp/vault_master_key_new configs/vault_master_key
chmod 0400 configs/vault_master_key
docker compose restart erpnext-backend erpnext-worker-default erpnext-worker-short
```

### Крок 5: Верифікувати

```bash
docker compose exec erpnext-backend bench --site erp.localhost console
```

```python
from security_erp.vault._key import get_master_key
key = get_master_key()
print(f"Key loaded: {len(key)} bytes")
```

### Крок 6: Видалити тимчасовий файл

```bash
shred -u /tmp/vault_master_key_new
shred -u /tmp/vault_master_key_new.gpg
```

---

## Ротація ключа

- Рекомендовано: кожні 12 місяців
- Або при підозрі компрометації

---

## Аварійне відновлення (втрата сервера)

### Крок 1: Отримати vault_master_key з escrow

### Крок 2: Отримати backup_secret.gpg з escrow

### Крок 3: Відновити MariaDB з бекапу

```bash
ls -la backups/automated/mariadb_daily_*.sql.gz.gpg
gpg --decrypt backups/automated/mariadb_daily_XXXXXX.sql.gz.gpg | gunzip | mysql -u root -p _73c82ec6d255ebe3
```

### Крок 4: Встановити vault_master_key

```bash
echo "ESCROW_KEY_HERE" > configs/vault_master_key
chmod 0400 configs/vault_master_key
```

### Крок 5: Запустити стек

```bash
docker compose up -d
```

### Крок 6: Верифікувати Vault

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

---

## Відповідальні

| Роль | Дані |
|------|------|
| Ключі зберігаються | [ІМ'Я ОПЕРАТОРА] |
| USB-ключ | [МІСЦЕ ЗБЕРІГАННЯ] |
| Другий канал | [ХМАРА/СЕРВЕР] |
| Ротація | [ДАТА ОСТАННЬОЇ РОТАЦІЇ] |
