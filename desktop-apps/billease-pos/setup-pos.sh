#!/bin/bash

# BillEase POS Setup Script
# This script helps initialize the POS system

echo "🏪 BillEase POS System Setup"
echo "================================"
echo ""

# Check if we're in the right directory
if [ ! -d "main-website" ]; then
    echo "❌ Error: Please run this script from the BillEase Suite root directory"
    exit 1
fi

echo "📦 Step 1: Installing Web App Dependencies..."
cd main-website
npm install

echo ""
echo "✅ Dependencies installed!"
echo ""

echo "📝 Step 2: Environment Setup"
echo "Please configure your .env.local file with:"
echo "  - NEXT_PUBLIC_SUPABASE_URL"
echo "  - NEXT_PUBLIC_SUPABASE_ANON_KEY"
echo "  - JWT_SECRET"
echo ""

read -p "Have you configured .env.local? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "⚠️  Please configure .env.local before continuing"
    exit 1
fi

echo ""
echo "🗄️  Step 3: Database Setup"
echo "Please run the following migrations in your Supabase dashboard:"
echo "  1. migrations/pos/001_initial_schema.sql"
echo "  2. migrations/pos/002_customers_and_enhancements.sql"
echo ""

read -p "Have you run the migrations? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "⚠️  Please run migrations before continuing"
    exit 1
fi

echo ""
echo "🚀 Step 4: Starting Development Server..."
echo "The web app will start at http://localhost:3000"
echo ""

read -p "Start the dev server now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    npm run dev
else
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "To start the web app: cd main-website && npm run dev"
    echo "To start desktop app: cd desktop-app/python_backend && python pos_app.py"
    echo ""
    echo "📖 Read POS_SYSTEM_GUIDE.md for complete documentation"
    echo ""
fi
