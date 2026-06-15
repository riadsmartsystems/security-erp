# Security ERP - Android App

Flutter додаток для польових інженерів Security ERP.

## Встановлення

```bash
# Встановити Flutter SDK
https://docs.flutter.dev/get-started/install

# Залежності
cd android-app
flutter pub get

# Запуск
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

| # | Екран | Опис |
|---|-------|------|
| 1 | **Login** | JWT автентифікація, secure storage |
| 2 | **Dashboard** | KPI: заявки, об'єкти, обладнання, виїзди |
| 3 | **Tickets List** | Кольори пріоритету, pull-to-refresh |
| 4 | **Ticket Detail** | Інформація + виїзди + створення |
| 5 | **Visit Flow** | GPS чекін/чекаут, статуси виїздів |
| 6 | **Photo Upload** | Типи фото (до/після/проблема/обладнання) |
| 7 | **Materials** | Внесення матеріалів з цінами |
| 8 | **Objects List** | Об'єкти з іконками |
| 9 | **Equipment List** | Обладнання зі статусами |

## Навігація

- **BottomNavigationBar** — Головна, Заявки, Об'єкти, Обладнання
- **Drawer** — швидкий доступ + вихід
- **Ticket → Visit → Photo/Materials** — глибока навігація

## Залежності

- `http` — HTTP клієнт
- `flutter_secure_storage` — JWT token storage
- `geolocator` — GPS координати
- `image_picker` — камера/галерея
- `permission_handler` — дозволи пристрою
- `intl` — форматування дат

## Структура

```
lib/
├── main.dart
├── services/
│   └── api_service.dart        # JWT API клієнт
└── screens/
    ├── login_screen.dart        # Авторизація
    ├── home_screen.dart         # Shell (Drawer + BottomNav)
    ├── dashboard_screen.dart    # KPI дашборд
    ├── tickets_screen.dart      # Список заявок
    ├── ticket_detail_screen.dart # Деталі заявки
    ├── visit_flow_screen.dart   # GPS виїзд
    ├── photo_upload_screen.dart # Фотозвіт
    ├── materials_screen.dart    # Матеріали
    ├── objects_screen.dart      # Об'єкти
    └── equipment_screen.dart    # Обладнання
```
