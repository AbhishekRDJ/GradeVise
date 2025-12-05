import requests
import json

API_KEY = 'AIzaSyDeXAFQO1eLRUe9dCewgmVnq5gpZRChomc'
MODEL = 'gemini-2.0-flash-exp'
URL = f'https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={API_KEY}'

headers = {'Content-Type': 'application/json'}
data = {
    'contents': [
        {
            'parts': [
                {'text': 'Hello, are you working?'}
            ]
        }
    ]
}

try:
    response = requests.post(URL, headers=headers, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {response.text}")
except Exception as e:
    print(f"Error: {e}")
