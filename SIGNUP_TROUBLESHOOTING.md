# Signup Issue - Root Cause Analysis & Solutions

## 🔴 PRIMARY ISSUE: PostgreSQL Database Connection

### The Problem
Your Django backend cannot connect to PostgreSQL because the password is empty:

**File:** `backend/core/settings.py` (Line 79)
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'POS_DB',
        'USER': 'macbook',
        'PASSWORD': '',  # ← THIS IS EMPTY!
        'HOST': '127.0.0.1',
        'PORT': '5432',
    }
}
```

### Why This Breaks Signup
1. When user clicks "Create Account" in Flutter app
2. Frontend sends POST request to `http://127.0.0.1:8000/api/v1/auth/register/`
3. Django's `register_user` view tries to save the user to the database
4. The database connection fails because PASSWORD is empty
5. The request times out or returns a 500 error
6. User sees "An unexpected error occurred" message

### The Fix
Set the correct PostgreSQL password in your database configuration.

---

## 🔧 QUICK FIX (5 minutes)

### Option 1: Using Environment Variables (RECOMMENDED)

**Step 1:** Create a `.env` file in the `backend/` directory:
```bash
cd backend
cat > .env << EOF
DB_NAME=POS_DB
DB_USER=macbook
DB_PASSWORD=your_postgresql_password_here
DB_HOST=127.0.0.1
DB_PORT=5432
EOF
```

**Step 2:** Install python-decouple (already in requirements.txt):
```bash
pip install python-decouple
```

**Step 3:** Update `backend/core/settings.py`:
```python
from decouple import config

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME', 'POS_DB'),
        'USER': config('DB_USER', 'macbook'),
        'PASSWORD': config('DB_PASSWORD', ''),
        'HOST': config('DB_HOST', '127.0.0.1'),
        'PORT': config('DB_PORT', '5432'),
    }
}
```

**Step 4:** Restart Django server
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

---

### Option 2: Direct Fix (Simpler but less secure)

Edit `backend/core/settings.py` and replace:
```python
'PASSWORD': '',
```

With:
```python
'PASSWORD': 'your_actual_postgresql_password',
```

---

## 🔍 STEP-BY-STEP VERIFICATION

### Step 1: Verify PostgreSQL is Running
```bash
# Check if PostgreSQL is running
brew services list | grep postgres

# If not running:
brew services start postgresql

# Test connection
psql -U macbook -h 127.0.0.1
```

You should see the `postgres=#` prompt. Type `\q` to exit.

### Step 2: Verify Database Exists
```bash
# List all databases
psql -U macbook -h 127.0.0.1 -l

# Look for POS_DB in the list
# If not found, create it:
createdb -U macbook POS_DB
```

### Step 3: Test Django Connection
```bash
cd backend

# Run migrations to test connection
python manage.py migrate

# If successful, you'll see:
# Applying sessions.0001_initial... OK
# Applying admin.0001_initial... OK
# ... etc
```

### Step 4: Start Django Server
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

Expected output:
```
Watching for file changes with StatReloader
Performing system checks...

System check identified no issues (0 silenced).
January 13, 2025 - 12:00:00
Django version 4.2, using settings 'core.settings'
Starting development server at http://0.0.0.0:8000/
Quit the server with CONTROL-C.
```

### Step 5: Test Signup Endpoint
```bash
# In a new terminal, test the API
curl -X POST http://127.0.0.1:8000/api/v1/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Test User",
    "email": "test@example.com",
    "password": "TestPassword123",
    "password_confirm": "TestPassword123",
    "agreed_to_terms": true
  }'
```

Expected successful response:
```json
{
  "success": true,
  "message": "User registered successfully.",
  "data": {
    "user": {
      "id": 1,
      "full_name": "Test User",
      "email": "test@example.com",
      "date_joined": "2025-01-13T12:00:00Z",
      "last_login": null
    },
    "token": "abc123def456..."
  }
}
```

### Step 6: Test Flutter App
1. Make sure Django is running
2. Launch Flutter app
3. Navigate to signup screen
4. Fill in the form and click "Create Account"
5. Should successfully register and redirect to dashboard

---

## 📋 PASSWORD REQUIREMENTS

When creating a test account, password must:
- ✅ Be at least 8 characters long
- ✅ Contain at least one uppercase letter (A-Z)
- ✅ Contain at least one lowercase letter (a-z)
- ✅ Contain at least one digit (0-9)

**Valid example:** `TestPassword123`
**Invalid examples:**
- `password` - lowercase only
- `PASSWORD` - uppercase only
- `Abcdefgh` - no digit
- `Test12` - too short

---

## 🐛 COMMON ERRORS & SOLUTIONS

### Error: "could not connect to server: Connection refused"
```
psycopg2.OperationalError: could not connect to server: Connection refused
```
**Solution:**
- PostgreSQL is not running
- Run: `brew services start postgresql`

### Error: "database 'POS_DB' does not exist"
```
psycopg2.OperationalError: database "POS_DB" does not exist
```
**Solution:**
```bash
# Create the database
createdb -U macbook POS_DB

# Then run migrations
cd backend
python manage.py migrate
```

### Error: "password authentication failed"
```
psycopg2.OperationalError: FATAL: password authentication failed for user "macbook"
```
**Solution:**
- Update PASSWORD in settings.py to your actual PostgreSQL password
- Or reset PostgreSQL password:
  ```bash
  psql -U postgres
  ALTER USER macbook PASSWORD 'new_password';
  ```

### Error: "Unexpected error occurred" in Flutter
- Django server is not running
- API endpoint is wrong in Flutter config
- Database connection is failing (see above)

**To debug:**
1. Check Django server is running: `curl http://127.0.0.1:8000/api/v1/auth/login/`
2. Check logs in terminal running Django server
3. Check network tab in browser DevTools (if using web)

---

## 🚀 TESTING CHECKLIST

After applying the fix, verify each step:

- [ ] PostgreSQL is running (`brew services list`)
- [ ] Database POS_DB exists
- [ ] User macbook can connect with password
- [ ] Django migrations passed (`python manage.py migrate`)
- [ ] Django server is running (`python manage.py runserver`)
- [ ] Signup endpoint responds to curl request
- [ ] Frontend can connect to backend
- [ ] Signup form validates input correctly
- [ ] User is created in database
- [ ] Auth token is returned
- [ ] User is redirected to dashboard
- [ ] Token is stored in device storage
- [ ] Subsequent requests include token in header

---

## 📱 FRONTEND CONFIGURATION CHECK

If using a custom IP address instead of 127.0.0.1:

**File:** `frontend/lib/src/config/api_config.dart` (Line 5)
```dart
// For localhost (if Django and Flutter on same machine):
static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

// For custom IP (if accessing from different machine):
static const String baseUrl = 'http://192.168.x.x:8000/api/v1';
```

To find your machine's IP:
```bash
# macOS
ifconfig | grep "inet " | grep -v 127.0.0.1
```

---

## 🆘 IF YOU STILL HAVE ISSUES

1. **Check Django logs** - Look at the terminal where you ran `python manage.py runserver`
2. **Check Flutter logs** - Run Flutter in verbose mode: `flutter run -v`
3. **Test API directly** - Use curl or Postman to test endpoints
4. **Check database** - Connect directly with psql to verify tables exist
5. **Clear Flutter cache** - `flutter clean && flutter pub get`

---

## 📚 USEFUL COMMANDS

```bash
# PostgreSQL
brew services start postgresql     # Start PostgreSQL
brew services stop postgresql      # Stop PostgreSQL
psql -U macbook                    # Connect to PostgreSQL
\l                                 # List databases
\du                                # List users
\c POS_DB                          # Connect to specific database
SELECT * FROM user;                # Check users table
\q                                 # Quit psql

# Django
cd backend
python manage.py migrate           # Run migrations
python manage.py createsuperuser   # Create admin user
python manage.py shell             # Django shell
python manage.py runserver         # Start dev server
python manage.py test              # Run tests

# Flutter
flutter clean                      # Clean build
flutter pub get                    # Get dependencies
flutter run                        # Run app
flutter run -v                     # Run with verbose logging
```

---

## ✅ SUCCESS INDICATORS

After fixing, you should see:

1. **In Django Terminal:**
   ```
   [13/Jan/2025 12:00:00] "POST /api/v1/auth/register/ HTTP/1.1" 201 Created
   ```

2. **In Flutter Console:**
   ```
   [Info] Registration successful! Token: abc123...
   ```

3. **In Database:**
   ```
   postgres=# SELECT * FROM user;
    id | email | full_name
   ----+-------+-----------
     1 | test@example.com | Test User
   ```

---

## 🎯 NEXT STEPS

Once signup is working:
1. Test login functionality
2. Verify token is stored and used in subsequent requests
3. Test protected endpoints (dashboard, sales, etc.)
4. Set up proper CORS if accessing from different domain
5. Configure media/file upload paths
6. Set up proper logging for production

