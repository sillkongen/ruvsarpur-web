# RÚV Sarpurinn Web Downloader

A modern web interface for downloading shows from RÚV Sarpurinn with instant search and download tracking.

## Features

- 🔍 **Instant Search**: Lightning-fast search through 30MB+ schedule data loaded in memory
- 📥 **Download Tracking**: Real-time download status with visual indicators  
- 🌙 **Dark Mode**: Beautiful dark/light theme toggle with persistent preference
- 🎯 **Modern UI**: Clean, responsive Bootstrap-based interface
- ⚡ **Fast Backend**: FastAPI + Flask architecture for optimal performance

## Prerequisites

This web interface requires the `ruvsarpur` source code to be available. Make sure you have:

1. **ruvsarpur source**: Located at `../ruv-container/ruvsarpur/src` relative to this directory
2. **EPG data**: Run ruvsarpur at least once to generate `~/.ruvsarpur/tvschedule.json`

## Docker Deployment

### Quick Start

1. **Clone and setup:**
   ```bash
   cd ruvsarpur-web
   mkdir -p downloads data
   ```

2. **Setup EPG data:**
   ```bash
   ./setup-epg.sh
   ```
   This copies your EPG data locally to avoid volume mount issues.

3. **Verify ruvsarpur source location:**
   ```bash
   ls ../ruv-container/ruvsarpur/src/ruvsarpur.py
   ```
   If this file doesn't exist, adjust the volume mount in `docker-compose.yml`

4. **Build and run:**
   ```bash
   docker-compose up --build
   ```

5. **Access the application:**
   - Web interface: http://localhost:5000
   - API backend: http://localhost:8001

### EPG Data Handling

The application looks for EPG data in multiple locations:
- `${HOME}/.ruvsarpur/tvschedule.json` (mounted from host)
- `./data/.ruvsarpur/tvschedule.json` (local copy)
- `/root/.ruvsarpur/tvschedule.json` (inside container)
- `/app/.ruvsarpur/tvschedule.json` (fallback location)

Use `./setup-epg.sh` to copy your EPG data locally if volume mounting doesn't work.

### Volume Mounts

- `./downloads` → `/app/downloads` (Downloaded video files - **accessible outside container**)
- `./data` → `/app/data` (Application data)
- `~/.ruvsarpur` → `/root/.ruvsarpur` (EPG/Schedule cache)
- `../ruv-container/ruvsarpur/src` → `/app/ruvsarpur` (ruvsarpur source code)

### Download Location

Downloaded files will be saved to `./downloads` in your current directory, making them easily accessible outside the container. The directory structure will be:

```
ruvsarpur-web/
├── downloads/          ← Your downloaded videos appear here
│   ├── show1.mp4
│   └── show2.mp4
├── data/               ← Application database
└── docker-compose.yml
```

**Path Mapping:**
- Container: `/app/downloads` → Host: `./downloads`
- All downloads are automatically accessible outside the container
- No need to copy files - they're directly saved to your host filesystem

**Testing Download Path:**
```bash
# Check downloads directory (should be empty initially)
ls -la downloads/

# After downloading, files will appear here
ls -la downloads/*.mp4
```

### Environment Variables

- `RUVSARPUR_PATH`: Path to ruvsarpur script (default: `/app/ruvsarpur`)
- `SCHEDULE_FILE`: Path to TV schedule JSON (default: `~/.ruvsarpur/tvschedule.json`)
- `FLASK_ENV`: Flask environment (default: `production`)

## Manual Development

If you prefer to run without Docker:

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Start backend:**
   ```bash
   cd backend
   uvicorn app.main:app --reload --workers 1 --port 8001
   ```

3. **Start frontend:**
   ```bash
   python app.py
   ```

## Architecture

- **Frontend**: Flask app serving the web interface
- **Backend**: FastAPI handling search and downloads  
- **Script**: ruvsarpur.py for actual video downloading
- **Database**: SQLite for download tracking
- **Cache**: In-memory schedule data for fast search

### Download Process

When you download a show, the backend calls ruvsarpur with:
```bash
python ruvsarpur.py --pid <program_id> --output /app/downloads --quality HD1080
```

The `/app/downloads` path is mounted to `./downloads` on your host, ensuring files are accessible outside the container.

## Usage

1. Type in the search box (minimum 2 characters)
2. Browse instant search results  
3. Click "Download" on any show
4. Watch real-time status updates
5. Toggle dark mode with the moon/sun button
6. **Find your downloads**: Check the `./downloads` folder in your current directory

Built with ❤️ for easy RÚV content downloading. 