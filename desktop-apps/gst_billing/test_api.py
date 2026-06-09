#!/usr/bin/env python3
import requests
import json

try:
    # Test company endpoint
    response = requests.get('http://localhost:8000/api/company')
    print(f"Company API Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Company endpoint working - got '{data.get('company_name', 'N/A')}'")
    else:
        print(f"✗ Company endpoint error: {response.text}")
    
    # Test health endpoint
    response = requests.get('http://localhost:8000/health')
    print(f"\nHealth API Status: {response.status_code}")
    if response.status_code == 200:
        print(f"✓ Health endpoint working")
    else:
        print(f"✗ Health endpoint error: {response.text}")
        
except Exception as e:
    print(f"✗ Error connecting to backend: {e}")
