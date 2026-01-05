# API Quick Reference

## Base URL
```
http://127.0.0.1:8000/api
```

## Authentication Endpoints

### Register User
```http
POST /auth/register/
Content-Type: application/json

{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "securepass123",
  "password2": "securepass123",
  "first_name": "John",      // optional
  "last_name": "Doe"          // optional
}

Response (201 Created):
{
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe"
  },
  "profile": {
    "id": 1,
    "user": { ... },
    "role": "user",
    "role_display": "User",
    "phone": "",
    "address": "",
    "created_at": "2026-01-05T...",
    "updated_at": "2026-01-05T..."
  },
  "message": "User registered successfully with role: user"
}
```

### Login
```http
POST /auth/login/
Content-Type: application/json

{
  "username": "johndoe",
  "password": "securepass123"
}

Response (200 OK):
{
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe"
  },
  "profile": {
    "id": 1,
    "user": { ... },
    "role": "user",
    "role_display": "User",
    "phone": "",
    "address": "",
    "created_at": "2026-01-05T...",
    "updated_at": "2026-01-05T..."
  },
  "message": "Login successful"
}
```

### Logout
```http
POST /auth/logout/
Content-Type: application/json

Response (200 OK):
{
  "message": "Logout successful"
}
```

### Get Current User
```http
GET /auth/current-user/
Content-Type: application/json

Response (200 OK):
{
  "id": 1,
  "username": "johndoe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe"
}
```

## User Profile Endpoints

### Get User Profiles
```http
GET /profiles/
Content-Type: application/json

Response (200 OK):
[
  {
    "id": 1,
    "user": { ... },
    "role": "user",
    "role_display": "User",
    "phone": "",
    "address": "",
    "created_at": "2026-01-05T...",
    "updated_at": "2026-01-05T..."
  }
]
```

## Error Responses

### Validation Error (400 Bad Request)
```json
{
  "username": ["This field is required."],
  "email": ["Enter a valid email address."],
  "password": ["Password fields didn't match."]
}
```

### Authentication Error (401 Unauthorized)
```json
{
  "error": "Invalid credentials"
}
```

### Server Error (500 Internal Server Error)
```json
{
  "error": "Internal server error"
}
```

## User Roles

| Role | Value | Description |
|------|-------|-------------|
| User | `user` | Default role for registered users |
| Utility | `utility` | For utility providers |
| Admin | `admin` | For administrators |

## Testing with cURL

### Register
```bash
curl -X POST http://127.0.0.1:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "testpass123",
    "password2": "testpass123"
  }'
```

### Login
```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpass123"
  }'
```

## Flutter API Service Usage

### Register
```dart
final result = await ApiService.register(
  username: 'johndoe',
  email: 'john@example.com',
  password: 'securepass123',
  password2: 'securepass123',
);

if (result['success']) {
  // Registration successful
  print(result['data']);
} else {
  // Show error
  print(result['message']);
}
```

### Login
```dart
final result = await ApiService.login(
  username: 'johndoe',
  password: 'securepass123',
);

if (result['success']) {
  final user = result['user'] as User;
  final profile = result['profile'] as UserProfile;
  // Save and navigate
} else {
  // Show error
  print(result['message']);
}
```
