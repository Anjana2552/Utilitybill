# Frontend-Backend Connection Guide

## ✅ Completed Setup

### Backend (Django)
- ✓ Django REST API configured
- ✓ User registration and login endpoints
- ✓ CORS enabled for frontend communication
- ✓ MySQL database configuration ready

### Frontend (Flutter)
- ✓ API service created with REST endpoints
- ✓ User authentication service with local storage
- ✓ Login page connected to API
- ✓ Register page connected to API
- ✓ Home page displays user data
- ✓ Session management with SharedPreferences

## 🚀 Running the Application

### 1. Start Django Backend

```bash
cd E:\MES\utilitybill_backend
python manage.py runserver
```

Backend will run on: `http://127.0.0.1:8000`

**Important**: Make sure MySQL is running and database is created!

### 2. Start Flutter Frontend

Open a new terminal:

```bash
cd E:\MES\utilitybill_frontend
flutter run
```

## 📱 Testing Different Devices

### For Android Emulator:
Update `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

### For Physical Device:
1. Find your computer's IP address:
   ```bash
   ipconfig  # On Windows
   ```
2. Update `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:8000/api';
   // Example: 'http://192.168.1.100:8000/api'
   ```
3. Update Django settings.py:
   ```python
   ALLOWED_HOSTS = ['YOUR_IP', 'localhost', '127.0.0.1']
   ```

## 🔌 API Endpoints Connected

| Endpoint | Method | Purpose | Frontend Page |
|----------|--------|---------|---------------|
| `/api/auth/register/` | POST | Register new user | RegisterPage |
| `/api/auth/login/` | POST | Login user | LoginPage |
| `/api/auth/logout/` | POST | Logout user | HomePage |
| `/api/auth/current-user/` | GET | Get user details | HomePage |
| `/api/profiles/` | GET | Get user profile | HomePage |

## 📦 Data Flow

### Registration Flow:
1. User fills form in `RegisterPage`
2. Frontend sends POST to `/api/auth/register/`
3. Backend creates user with role='user'
4. Returns user data and profile
5. Frontend navigates to login page

### Login Flow:
1. User enters credentials in `LoginPage`
2. Frontend sends POST to `/api/auth/login/`
3. Backend authenticates and returns user + profile
4. Frontend saves data to SharedPreferences
5. Navigates to `HomePage`

### Home Page:
1. Loads user data from SharedPreferences
2. Displays user information and role
3. Shows user profile details
4. Provides logout functionality

## 🔒 Authentication

- User credentials stored in SharedPreferences
- Session persists across app restarts
- Logout clears all stored data

## 🎨 Features Implemented

### Frontend:
- ✅ Beautiful UI with curved designs
- ✅ Form validation
- ✅ Loading states during API calls
- ✅ Error handling with snackbars
- ✅ Persistent login sessions
- ✅ User profile display
- ✅ Logout functionality

### Backend:
- ✅ User registration with default 'user' role
- ✅ Login authentication
- ✅ Profile creation on registration
- ✅ Role-based system (user/utility/admin)
- ✅ CORS configured for Flutter

## 🧪 Testing the Connection

1. **Start Backend**:
   ```bash
   cd utilitybill_backend
   python manage.py runserver
   ```

2. **Start Frontend**:
   ```bash
   cd utilitybill_frontend
   flutter run
   ```

3. **Test Registration**:
   - Click "Get started" → "Create Account"
   - Fill in username, email, password
   - Submit form
   - Should see success message

4. **Test Login**:
   - Enter registered credentials
   - Click "Log in"
   - Should navigate to Home page

5. **Verify Data**:
   - Home page should display:
     - Username
     - Email
     - Role (User)
     - Profile information

## ⚠️ Troubleshooting

### Connection Refused Error:
- Make sure Django backend is running
- Check the baseUrl in `api_service.dart`
- Verify CORS settings in Django

### Registration Fails:
- Check username doesn't already exist
- Ensure email is valid format
- Password must match confirmation

### Login Fails:
- Verify credentials are correct
- Check backend console for errors
- Ensure database is accessible

### Data Not Showing:
- Check browser/app developer tools
- Verify API responses in backend logs
- Clear app data and try again

## 📝 Next Steps

- Add more features to home page
- Implement bills management
- Add profile editing
- Create admin dashboard
- Add password reset functionality
