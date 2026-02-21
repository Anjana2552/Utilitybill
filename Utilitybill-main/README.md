# Utilitybill Project Configuration

This README covers environment setup and configuration for both backend (Django) and frontend (Flutter).

## Prerequisites
- Python 3.10+ (recommended 3.11)
- Git
- Flutter SDK (verified working with Flutter 3.38.x, Dart 3.10.x)
- Optional: MySQL server (if not using default SQLite)

## Backend (Django)

### 1) Create and activate a virtual environment (Windows PowerShell)
```powershell
Push-Location "C:\Users\samee\OneDrive\Desktop\MES\Utilitybill\Utilitybill-main\utilitybill_backend"
py -m venv venv
.\venv\Scripts\Activate.ps1
```
If activation is blocked, run (temporary for the current shell):
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### 2) Install dependencies
```powershell
pip install -r requirements.txt
```
Packages (from requirements): Django 5.1.7, DRF 3.16.0, cors-headers 4.9.0, Pillow 11.2.1, mysqlclient 2.2.7.

### 3) Environment variables
Copy the example env and adjust values:
```powershell
Copy-Item .env.example .env
```
Edit `.env`:
- `SECRET_KEY`: set a strong random string
- `DEBUG`: `True` for development
- `ALLOWED_HOSTS`: e.g., `localhost,127.0.0.1`
- For PostgreSQL (optional): uncomment `DB_*` entries in `.env.example`
- For MySQL (optional): see MySQL section below

### 4) Database
By default, the project uses SQLite (no extra config required).

For MySQL setup, see: `utilitybill_backend/MYSQL_SETUP.md` and `utilitybill_backend/setup_mysql.sql`.
Notes for Windows:
- Ensure MySQL server is running and credentials match your settings.
- `mysqlclient` may require Microsoft C++ Build Tools.

### 5) Migrate and run
```powershell
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser   # optional, for admin panel
python manage.py runserver         # starts at http://127.0.0.1:8000/
```
API base path: `http://127.0.0.1:8000/api`

## Frontend (Flutter)

### 1) Install dependencies
```powershell
Push-Location "C:\Users\samee\OneDrive\Desktop\MES\Utilitybill\Utilitybill-main\utilitybill_frontend"
flutter pub get
```

### 2) Configure API base URL
Update `lib/config/api_config.dart` if running on device/emulator:
```dart
class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
}
```
- For Android emulator use: `http://10.0.2.2:8000/api`
- For iOS simulator use: `http://127.0.0.1:8000/api`
- For physical devices: use your machine's LAN IP, e.g., `http://192.168.x.x:8000/api`

### 3) Run the app
```powershell
flutter run
```
Choose a device target (web, windows, android, etc.) as needed.

## Connecting Frontend & Backend
See detailed guidance in `FRONTEND_BACKEND_CONNECTION.md`.
Key notes:
- Ensure CORS allows your frontend origin. In development, `CORS_ALLOW_ALL_ORIGINS=True` is set via `.env.example`.
- Confirm the API base URL in the frontend matches the backend host.

## Troubleshooting
- Virtual env activation blocked: use the `Set-ExecutionPolicy` command shown above.
- MySQL connection errors: verify server is running, credentials, and driver (`mysqlclient`) installed.
- CORS errors: enable appropriate origins or keep `CORS_ALLOW_ALL_ORIGINS=True` for development.
- Flutter cannot reach backend: update `ApiConfig.baseUrl` according to your runtime target.

## Useful Links
- Backend requirements: `utilitybill_backend/requirements.txt`
- Backend README: `utilitybill_backend/README.md`
- MySQL setup: `utilitybill_backend/MYSQL_SETUP.md`
- Frontend pubspec: `utilitybill_frontend/pubspec.yaml`
- Frontend/backend connection notes: `FRONTEND_BACKEND_CONNECTION.md`
