#!/bin/bash
# Security ERP — Startup Script
set -e

echo "=== Security ERP Platform ==="

# Перевірка Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker не встановлено"
    exit 1
fi

# Перевірка .env
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo "Копіюю .env.example → .env ..."
        cp .env.example .env
        echo ""
        echo "⚠ Відредагуйте .env та змініть паролі (changeme_*)."
        echo "  Потім запустіть скрипт знову."
        exit 0
    else
        echo "ERROR: .env не знайдено. Створіть його з .env.example."
        exit 1
    fi
fi

# Збірка backend-образу
echo "Збираю erpnext-backend..."
docker compose build erpnext-backend

# Запуск інфраструктури
echo "Запускаю MariaDB та Redis..."
docker compose up -d mariadb redis

echo "Чекаю на готовність бази даних (~30 сек)..."
sleep 30

# Запуск backend
echo "Запускаю erpnext-backend..."
docker compose up -d erpnext-backend

echo ""
echo "=== Перший запуск? ==="
echo "Якщо сайт ще не ініціалізовано — виконайте в окремому терміналі:"
echo ""
echo "  docker compose exec erpnext-backend bash"
echo "  cd /home/frappe/frappe-bench"
echo "  /home/frappe/frappe-bench/env/bin/pip install -e apps/security_erp"
echo "  bench new-site erp.localhost \\"
echo "    --db-root-password \$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2) \\"
echo "    --admin-password \$(grep ADMIN_PASSWORD .env | cut -d= -f2) \\"
echo "    --no-mariadb-socket"
echo "  bench --site erp.localhost install-app erpnext"
echo "  bench --site erp.localhost install-app security_erp"
echo "  exit"
echo ""
echo "Після ініціалізації запустіть решту сервісів:"
echo "  docker compose up -d"
echo ""

# Запуск всіх сервісів
echo "Запускаю всі сервіси..."
docker compose up -d

echo ""
echo "=== Статус контейнерів ==="
docker compose ps

echo ""
echo "=== Доступ ==="
echo "ERPNext UI:  http://localhost:8080"
echo "Логін:       Administrator"
echo "Пароль:      значення ADMIN_PASSWORD з файлу .env"
echo ""
echo "=== Перевірка backend ==="
sleep 5
status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/method/ping 2>/dev/null || echo "000")
echo "erpnext-backend /api/method/ping: HTTP $status"
