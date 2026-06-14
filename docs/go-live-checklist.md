# Go-Live Checklist — Security ERP Platform

## Infrastructure ✅
- [x] Docker Compose налаштовано та протестовано
- [x] Cloudflare Tunnel підключено (порти назовні закриті)
- [x] TLS 1.3 для всіх публічних ендпоінтів
- [x] MariaDB healthy, PostgreSQL healthy, Redis healthy
- [x] MinIO healthy, NATS healthy
- [x] Monitoring: Prometheus + Grafana + Loki + Promtail

## Security ✅
- [x] JWT автентифікація (15 min access, 7d refresh)
- [x] RBAC налаштовано (9 ролей, 18 permissions)
- [x] Account lockout after 5 failed attempts
- [x] API proxy — прямий доступ до сервісів заборонений
- [x] Circuit Breaker для backend сервісів

## ERPNext ✅
- [x] security_erp додаток встановлено (v1.0.0)
- [x] 10 кастомних DocTypes
- [x] 41 кастомне поле
- [x] Security CRM Workspace
- [x] Ukrainian language configured

## Microservices ✅
- [x] Security API Gateway (:8000) — JWT, RBAC, Proxy
- [x] FSM Service (:8001) — Tickets, Visits, SLA Engine
- [x] CMDB Service (:8002) — Objects, Equipment, Topology
- [x] Telegram Service — polling, /mytickets, /newticket, photo, materials
- [x] n8n (:5678) — 9 workflows, webhooks active

## Business Process ✅
- [x] Lead → Customer flow (CRM)
- [x] Estimate → Quotation → Sales Order (Sales)
- [x] Ticket → Assign → Visit → Photo → Materials → Close (FSM)
- [x] Object → Equipment registration (CMDB)
- [x] Material Reservation for projects (Inventory)
- [x] Installation Act with serial numbers (Projects)
- [x] SLA monitoring with breach notifications

## Data Migration ✅
- [x] Wave 1: migrate_customers.py
- [x] Wave 2: migrate_objects.py
- [x] Wave 3: migrate_equipment.py
- [x] Wave 4: migrate_tickets.py
- [x] Sample CSV templates provided

## Backup ✅
- [x] backup.sh — MariaDB + PostgreSQL + n8n + config
- [x] Auto-cleanup old backups (>7 days)
- [x] Backup verified (26MB)

## Performance ✅
- [x] k6 load tests baseline: P95=7ms (budget: <200ms)
- [x] 100% checks passed, 0% errors

## Service URLs
| Service | URL | Credentials |
|---------|-----|-------------|
| ERPNext | https://erp.riad.fun | Administrator / jokerLA23 |
| Security API | https://api.riad.fun | joker / jokerLA23 |
| n8n | https://n8n.riad.fun | joker / jokerLA23 |
| Grafana | https://grafana.riad.fun | joker / jokerLA23 |
| Telegram Bot | @RiadSecurityBot | — |

## Known Issues (non-blocking)
- [ ] n8n wf-02 (Прострочена КП) not created yet
- [ ] ERPNext login page may show English (language setting issue)
- [ ] 70GB disk is tight — need periodic docker system prune
