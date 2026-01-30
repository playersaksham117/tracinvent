@echo off
echo ========================================
echo BillEase Suite - Main Website
echo ========================================
echo.

REM Check if node_modules exists
if not exist "node_modules" (
    echo [INFO] Installing dependencies...
    call npm install
    echo.
)

REM Check if .env.local exists
if not exist ".env.local" (
    echo [WARNING] .env.local not found!
    echo [INFO] Creating from .env.example...
    copy .env.example .env.local
    echo.
    echo [IMPORTANT] Please edit .env.local with your credentials:
    echo   - Supabase URL and keys from https://supabase.com
    echo   - Stripe keys from https://stripe.com
    echo   - Generate JWT secret: openssl rand -base64 32
    echo.
    pause
)

echo [INFO] Starting development server...
echo [INFO] Server will be available at http://localhost:3000
echo.
echo Press Ctrl+C to stop the server
echo.

npm run dev
