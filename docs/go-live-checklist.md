# Go-Live Checklist — Security ERP Platform
_Оновлено: 2026-06-15_

## Infrastructure ✅
- [x] Docker Compose налаштовано (19 контейнерів)
- [x] Cloudflare Tunnel підключено (riad.fun)
- [x] TLS 1.3 для всіх публічних ендпоінтів
- [x] MariaDB healthy, Redis healthy, MinIO healthy, NATS healthy
- [x] PostgreSQL (лише для n8n)
- [x] Monitoring: Prometheus + Grafana + Loki + Promtail
- [x] Traefik reverse proxy

## Security ✅
- [x] JWT автентифікація (15 min access, 7d refresh)
- [x] RBAC налаштовано (9 ролей)
- [x] Frappe API key authentication
- [x] Cloudflare Access OTP для зовнішнього доступу
- [ ] Rate limiting на Security API (НЕ реалізовано)
- [ ] CORS налаштування (зараз allow_origins=*)

## Single Database Architecture ✅
- [x] Всі дані в MariaDB через ERPNext DocTypes
- [x] 25 DocTypes в модулі Security ERP
- [x] PostgreSQL лише для n8n (integration schema)
- [x] Security API → Frappe API proxy
- [x] FSM/CMDB/AI мікросервіси ВИДАЛЕНІ

## ERPNext ✅
- [x] security_erp додаток встановлено (v1.0.0)
- [x] 25 DocTypes з правами доступу
- [x] Ukrainian language configured
- [x] CSS/JS assets partially loaded
- [ ] ERPNext UI кастомізація (НЕ зроблено)

## API Gateway ✅
- [x] Security API Gateway (:8000) — JWT, RBAC, Proxy → Frappe
- [x] 28+ endpoints (auth, tickets, objects, equipment, visits, etc.)
- [x] Frappe API proxy для всіх DocType операцій

## Telegram Bot ✅
- [x] @riad_ss_bot працює
- [x] /start, /mytickets, /newticket, /visit_start, /visit_finish
- [x] /object, /sla, /kpi, /help, /photo, /materials
- [x] Inline buttons для дій
- [x] 5-кроковий /newticket діалог

## n8n Workflows ✅
- [x] 10 workflows створено
- [x] 6 webhooks: new-lead, new-ticket, sla-breach, emergency-ticket, low-stock, payment-received
- [x] 4 schedulers: KP reminder, maintenance, warranty, KPI
- [x] Telegram notification через HTTP Request nodes
- [ ] n8n webhooks потребують ручної активації після restart

## Data Migration ⏳
- [ ] migrate_customers.py — CSV → ERPNext
- [ ] migrate_objects.py — CSV → Security Object
- [ ] migrate_equipment.py — CSV → Equipment
- [ ] migrate_tickets.py — CSV → Service Ticket

## Backup ✅
- [x] backup-mariadb.sh — daily 2AM, weekly Sun 3AM
- [x] Auto-cleanup old backups (>30 days)
- [x] Cron jobs налаштовані

## Performance ❌
- [x] k6 load tests baseline: P95=2.94s (budget: <500ms) — FAILED
- [x] Error rate: 27.86% (budget: <10%) — FAILED
- [ ] Rate limiting (НЕ реалізовано)
- [ ] Connection pooling для Frappe API
- [ ] JWT token caching

## Service URLs
| Service | URL | Credentials |
|---------|-----|-------------|
| ERPNext | https://erp.riad.fun | Administrator / jokerLA23 |
| Security API | https://api.riad.fun | joker@riad.fun / jokerLA23 |
| n8n | https://n8n.riad.fun | jokerla23@gmail.com / jokerLA23 |
| Grafana | https://grafana.riad.fun | joker / jokerLA23 |
| Telegram Bot | @riad_ss_bot | — |
| MinIO | http://localhost:9001 | minioadmin / minio_secret |

## Known Issues
- [ ] Rate limiting не реалізовано (P95 latency 2.94s)
- [ ] n8n webhooks потребують ручної активації
- [ ] ERPNext CSS/JS не завантажується через Cloudflare (assets issue)
- [ ] Cloudflare Access OTP вимкнено для тестування
- [ ] Load test P95 2.94s (target <500ms)
- [ ] Load test error rate 27.86% (target <10%)
- [ ] 70GB disk — потрібен periodic docker system prune
