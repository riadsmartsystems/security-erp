# BUILD_LOG

---

### E8 — Push (FCM) + Auth Integration ✅ DONE

**Дата:** 2026-06-26
**Статус:** DoD виконано

#### Завершені компоненти
1. ✅ Backend: Push service + routes + triggers (P1 T1-T4)
2. ✅ Backend: Push unit tests 38/38 (P1 T3)
3. ✅ Flutter: push_service.dart + Firebase init + Gradle plugin (P1 T2)
4. ✅ Flutter: AuthService + AuthApiClient + LoginScreen (F1-F3)
5. ✅ Flutter: Push integration in auth flow (F4)
6. ✅ CI: push test gates (P1 T3)

#### DoD перевірка
1. ✅ PushService.initialize() викликається після login
2. ✅ PushService.revoke() викликається при logout
3. ✅ Токени зберігаються в flutter_secure_storage
4. ✅ Навігація: login → home → logout → login
5. ✅ Flutter тести зелені
6. ✅ BUILD_LOG оновлено

---

### E9 — Security Hardening + DR 🔄 IN PROGRESS

**Дата:** 2026-06-26
**Статус:** Частково виконано

#### Завершені компоненти
1. ✅ Key-escrow процедура (задокументовано)
2. ✅ Vault restore drill (тести + скрипт)
3. ✅ PITR drill (тести)
4. ✅ CI coverage (додано відсутні тести)

#### Залишок (потребує ручних дій)
1. 🔴 Firebase Console — T1 (ручна задача)
2. 🟠 Offsite GPG ключ — копіювання configs/backup_secret.gpg
3. 🟠 Rate-limit tuning — staging під реальним трафіком
4. 🟡 CB тюнінг — staging
5. 🟡 Whisper тюнінг — staging
6. 🟡 Offline Vault cache (H4) — рішення бізнесу
