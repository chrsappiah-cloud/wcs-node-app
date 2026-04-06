#!/bin/bash

# World Class Scholars - API Key Setup Script
# Run this script to update your OpenAI API key

echo "🚀 World Class Scholars API Key Setup"
echo "====================================="
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found!"
    echo "Please run this script from the WorldClassScholarsSite directory"
    exit 1
fi

echo "📝 Current OpenAI API key status:"
grep "OPENAI_API_KEY" .env
echo ""

echo "🔑 To get your OpenAI API key:"
echo "   1. Visit: https://platform.openai.com/api-keys"
echo "   2. Sign in to your OpenAI account"
echo "   3. Click 'Create new secret key'"
echo "   4. Copy the key (format: sk_live_... or sk_test_...)"
echo ""

read -p "Enter your OpenAI API key: " api_key

if [ -z "$api_key" ]; then
    echo "❌ No API key provided. Exiting."
    exit 1
fi

# Validate key format
if [[ ! $api_key =~ ^sk_ ]]; then
    echo "⚠️  Warning: API key should start with 'sk_'. Are you sure this is correct?"
    read -p "Continue anyway? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
fi

# Update .env file
sed -i.bak "s/OPENAI_API_KEY=.*/OPENAI_API_KEY=$api_key/" .env

echo ""
echo "✅ API key updated successfully!"
echo ""
echo "🔄 Restarting backend server..."
echo ""

# Kill existing server if running
pkill -f "nodemon backend/server.js" 2>/dev/null || true

# Start server
npm run dev &
sleep 3

# Test the API
echo ""
echo "🧪 Testing API with new key..."
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/token | jq -r .token 2>/dev/null)
if [ $? -eq 0 ] && [ "$TOKEN" != "null" ]; then
    echo "✅ Authentication working"
    echo "🎨 Testing image generation..."
    RESULT=$(curl -s -X POST http://localhost:3000/api/images/generate \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"prompt":"A colorful dinosaur","style":"artistic","quantity":1}' | jq -r .success 2>/dev/null)

    if [ "$RESULT" = "true" ]; then
        echo "✅ Image generation working! 🎉"
        echo ""
        echo "🌐 Open API tester: http://localhost:8000/api-tester.html"
        echo "📱 Main website: http://localhost:8000"
    else
        echo "⚠️  Image generation test failed. Check your API key."
        echo "   Visit: http://localhost:8000/api-tester.html to test manually"
    fi
else
    echo "❌ Server not responding. Check if it started correctly."
fi

echo ""
echo "📚 Documentation:"
echo "   - Setup Guide: BACKEND_SETUP.md"
echo "   - Security: BACKEND_SECURITY.md"
echo "   - Status: DEPLOYMENT_STATUS.md"