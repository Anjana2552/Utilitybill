# MySQL Setup Instructions

## Prerequisites
1. Install MySQL Server (MySQL 8.0 or higher recommended)
2. Download from: https://dev.mysql.com/downloads/mysql/

## Setup Steps

### 1. Start MySQL Server
Make sure MySQL service is running:
- **Windows**: Open Services (services.msc) and start "MySQL" service
- Or use MySQL Workbench to start the server

### 2. Create Database
You have two options:

#### Option A: Using MySQL Workbench
1. Open MySQL Workbench
2. Connect to your local MySQL server
3. Open the `setup_mysql.sql` file
4. Execute the script

#### Option B: Using MySQL Command Line
```bash
mysql -u root -p < setup_mysql.sql
```

#### Option C: Using MySQL Workbench Query Tab
```sql
CREATE DATABASE IF NOT EXISTS utility_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. Update Django Settings
The `settings.py` file has been configured with:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'utility_db',
        'USER': 'root',
        'PASSWORD': '',  # Add your MySQL password here
        'HOST': 'localhost',
        'PORT': '3306',
    }
}
```

**Important**: Update the `PASSWORD` field in `settings.py` with your MySQL root password!

### 4. Run Django Migrations
After creating the database, run:
```bash
python manage.py migrate
```

This will create all the necessary tables including the `bills_userprofile` table.

### 5. Verify Setup
Check if the table was created:
```sql
USE utility_db;
SHOW TABLES;
DESCRIBE bills_userprofile;
```

## Troubleshooting

### Error: Can't connect to MySQL server
- Make sure MySQL service is running
- Check if the port 3306 is not blocked
- Verify your MySQL credentials

### Error: Access denied for user 'root'
- Update the PASSWORD field in settings.py with your MySQL password
- Verify your MySQL username

### Error: mysqlclient installation issues
- Already installed: mysqlclient 2.2.7
- If you encounter issues, try: `pip install pymysql` as an alternative
