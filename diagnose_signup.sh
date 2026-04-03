#!/bin/bash

# Signup Issue Diagnostic Script
# This script helps diagnose signup problems

echo "=== POS System Signup Diagnostic Tool ==="
echo ""

# Check 1: PostgreSQL Status
echo "1. Checking PostgreSQL Status..."
if command -v psql &> /dev/null; then
    echo "   ✓ PostgreSQL client installed"
    
    # Try to connect
    if psql -U macbook -h 127.0.0.1 -d POS_DB -c "SELECT 1" &> /dev/null; then
        echo "   ✓ PostgreSQL connection successful"
    else
        echo "   ✗ PostgreSQL connection failed"
        echo "     → Check that PostgreSQL is running"
        echo "     → Verify database 'POS_DB' exists"
        echo "     → Verify user 'macbook' exists"
    fi
else
    echo "   ✗ PostgreSQL client not installed"
fi

echo ""

# Check 2: Django Status
echo "2. Checking Django Setup..."
if [ -f "backend/manage.py" ]; then
    echo "   ✓ Django project found"
    
    # Check if requirements are installed
    if python3 -c "import django" 2>/dev/null; then
        echo "   ✓ Django installed"
    else
        echo "   ✗ Django not installed"
        echo "     → Run: pip install -r backend/requirements.txt"
    fi
else
    echo "   ✗ Django project not found"
fi

echo ""

# Check 3: Django Server Status
echo "3. Checking Django Server..."
if curl -s http://127.0.0.1:8000/api/v1/auth/login/ > /dev/null 2>&1; then
    echo "   ✓ Django server is running"
else
    echo "   ✗ Django server is not running"
    echo "     → Run: cd backend && python manage.py runserver 0.0.0.0:8000"
fi

echo ""

# Check 4: Frontend Flutter Setup
echo "4. Checking Flutter Setup..."
if command -v flutter &> /dev/null; then
    echo "   ✓ Flutter installed"
    
    # Check if pubspec.yaml exists
    if [ -f "frontend/pubspec.yaml" ]; then
        echo "   ✓ Flutter project found"
    else
        echo "   ✗ Flutter project not found"
    fi
else
    echo "   ✗ Flutter not installed"
fi

echo ""

# Check 5: Configuration Check
echo "5. Checking Configuration..."

# Check if using correct API baseURL
if grep -q "127.0.0.1:8000" frontend/lib/src/config/api_config.dart; then
    echo "   ✓ Frontend API baseUrl configured correctly (127.0.0.1:8000)"
elif grep -q "192.168" frontend/lib/src/config/api_config.dart; then
    echo "   ⚠ Frontend API baseUrl uses custom IP address"
else
    echo "   ✗ Frontend API baseUrl might be incorrect"
fi

echo ""

# Check 6: Test API Endpoint
echo "6. Testing Signup Endpoint..."

# Test with curl
TEST_RESULT=$(curl -s -X POST http://127.0.0.1:8000/api/v1/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Test User",
    "email": "test'$(date +%s)'@example.com",
    "password": "TestPassword123",
    "password_confirm": "TestPassword123",
    "agreed_to_terms": true
  }' 2>/dev/null)

if echo "$TEST_RESULT" | grep -q "success"; then
    echo "   ✓ Signup endpoint is working!"
    echo "     Response: $(echo $TEST_RESULT | head -c 100)..."
else
    echo "   ✗ Signup endpoint returned an error"
    echo "     Response: $TEST_RESULT"
fi

echo ""
echo "=== Diagnostic Complete ==="
