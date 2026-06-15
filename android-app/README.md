# Security ERP - Android App

Flutter додаток для польових інженерів.

## Встановлення

```bash
# Встановити Flutter
https://docs.flutter.dev/get-started/install

# Встановити залежності
cd android-app
flutter pub get

# Запустити на емуляторі
flutter run
```

## API конфігурація

Файл: `lib/services/api_service.dart`

```dart
static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
// Для реального пристрою:
// static const String baseUrl = 'http://YOUR_IP:8000';
// Або через Cloudflare:
// static const String baseUrl = 'https://api.riad.fun';
```

## Екрани

1. **Login** — JWT автентифікація
2. **Dashboard** — KPI: заявки, об'єкти, обладнання, виїзди

## План розвитку

- [x] Login screen
- [x] Dashboard
- [ ] Tickets list
- [ ] Ticket detail
- [ ] Visit flow (start/finish with GPS)
- [ ] Photo upload
- [ ] Materials entry
- [ ] Objects list
- [ ] Equipment list
- [ ] Offline support
