@echo off
REM BillEase POS Setup Script for Windows
REM This script helps initialize the POS system

echo.
echo 🏪 BillEase POS System Setup
echo ================================
echo.

REM Check if we're in the right directory
if not exist "main-website" (
    echo ❌ Error: Please run this script from the BillEase Suite root directory
    exit /b 1
)

echo 📦 Step 1: Installing Web App Dependencies...
cd main-website
call npm install

echo.
echo ✅ Dependencies installed!
echo.

echo 📝 Step 2: Environment Setup
echo Please configure your .env.local file with:
echo   - NEXT_PUBLIC_SUPABASE_URL
echo   - NEXT_PUBLIC_SUPABASE_ANON_KEY
echo   - JWT_SECRET
echo.

set /p configured="Have you configured .env.local? (y/n): "
if /i not "%configured%"=="y" (
    echo ⚠️  Please configure .env.local before continuing
    exit /b 1
)

echo.
echo 🗄️  Step 3: Database Setup
echo Please run the following migrations in your Supabase dashboard:
echo   1. migrations/pos/001_initial_schema.sql
echo   2. migrations/pos/002_customers_and_enhancements.sql
echo.

set /p migrations="Have you run the migrations? (y/n): "
if /i not "%migrations%"=="y" (
    echo ⚠️  Please run migrations before continuing
    exit /b 1
)

echo.
echo 🚀 Step 4: Starting Development Server...
echo The web app will start at http://localhost:3000
echo.

set /p startserver="Start the dev server now? (y/n): "
if /i "%startserver%"=="y" (
    npm run dev
) else (
    echo.
    echo ✅ Setup complete!
    echo.
    echo To start the web app: cd main-website ^&^& npm run dev
    echo To start desktop app: cd desktop-app\python_backend ^&^& python pos_app.py
    echo.
    echo 📖 Read POS_SYSTEM_GUIDE.md for complete documentation
    echo.
)

cd ..
