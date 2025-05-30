from flask import Flask, render_template, request, jsonify
import requests
from database import init_db, add_download, update_download_status, get_downloads
import os
import sqlite3

app = Flask(__name__)

BACKEND_URL = "http://localhost:8001"  # FastAPI backend URL

# Default download directory (absolute path for container)
DEFAULT_DOWNLOAD_DIR = "/app/downloads"

@app.route('/')
def index():
    # Get recent downloads for display
    downloads = get_downloads(limit=10)
    return render_template('index.html', downloads=downloads)

@app.route('/search')
def search():
    query = request.args.get('q', '')
    try:
        response = requests.get(f"{BACKEND_URL}/api/search/{query}")
        data = response.json()
        
        # Log the response for debugging
        print("Backend response:", data)
        
        if not response.ok:
            return jsonify({'error': data.get('detail', 'Search failed')}), response.status_code
            
        # Ensure we return a list
        if isinstance(data, list):
            results = data
        elif isinstance(data, dict):
            results = data.get('results', []) or data.get('items', [])
        else:
            results = []
            
        return jsonify(results)
    except requests.RequestException as e:
        print("Search error:", str(e))
        return jsonify({'error': str(e)}), 500

@app.route('/download', methods=['POST'])
def download():
    data = request.json
    print(f"Flask received download request: {data}")  # Debug log
    try:
        # Add download to tracking database
        pid = data.get('pid')
        title = data.get('title', 'Unknown Title')
        print(f"Adding download to database: PID={pid}, Title={title}")  # Debug log
        add_download(pid, title)
        
        # Prepare request data for FastAPI
        fastapi_data = {
            'pid': pid,
            'quality': data.get('quality', 'HD1080'),
            'output_dir': data.get('output_dir', DEFAULT_DOWNLOAD_DIR)
        }
        print(f"Sending to FastAPI: {fastapi_data}")  # Debug log
        print(f"FastAPI URL: {BACKEND_URL}/api/download")  # Debug log
        
        # Forward request to backend
        response = requests.post(f"{BACKEND_URL}/api/download", json=fastapi_data, timeout=10)
        print(f"FastAPI response status: {response.status_code}")  # Debug log
        print(f"FastAPI response content: {response.text}")  # Debug log
        
        result = response.json()
        
        # Log the response for debugging
        print("Download response:", result)
        
        if not response.ok:
            update_download_status(pid, 'failed')
            return jsonify({'error': result.get('detail', 'Download failed')}), response.status_code
        
        # The backend returns 'started' status initially
        return jsonify({
            'status': 'started',
            'pid': pid,
            'message': 'Download started successfully'
        })
    except requests.RequestException as e:
        print("Download error:", str(e))
        if data.get('pid'):
            update_download_status(data['pid'], 'failed')
        return jsonify({'error': str(e)}), 500
    except Exception as e:
        print(f"Unexpected error in Flask download route: {str(e)}")
        if data.get('pid'):
            update_download_status(data['pid'], 'failed')
        return jsonify({'error': str(e)}), 500

@app.route('/check_status/<pid>')
def check_status(pid):
    try:
        # Check status from backend
        response = requests.get(f"{BACKEND_URL}/api/status/{pid}")
        result = response.json()
        
        print(f"Status check for {pid}:", result)
        
        if not response.ok:
            return jsonify({'error': result.get('detail', 'Status check failed')}), response.status_code
        
        # Update our local status based on backend response
        status = result.get('status', 'unknown')
        file_path = result.get('file_path') or result.get('path')
        
        if status == 'completed' and file_path:
            update_download_status(pid, 'completed', file_path)
        elif status == 'failed':
            update_download_status(pid, 'failed')
        elif status == 'downloading':
            update_download_status(pid, 'started')
            
        return jsonify(result)
    except requests.RequestException as e:
        print("Status check error:", str(e))
        return jsonify({'error': str(e)}), 500

@app.route('/downloads')
def get_download_history():
    downloads = get_downloads()
    return jsonify([dict(d) for d in downloads])

if __name__ == '__main__':
    init_db()  # Initialize the database on startup
    app.run(debug=False, host='0.0.0.0', port=5000) 