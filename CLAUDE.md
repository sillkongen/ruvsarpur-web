# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RÚV Sarpurinn Web Downloader — a web UI wrapping the [ruvsarpur](https://github.com/sverrirs/ruvsarpur) CLI tool for downloading shows from Iceland's national broadcaster (RÚV). No build step is required; all code is interpreted Python.

## Running the Application

**Docker (recommended):**
```bash
./pre-start.sh          # Sets HOST_UID/HOST_GID env vars, creates host dirs
docker-compose up --build -d
# Frontend: http://localhost:5000  |  Backend API: http://localhost:8001
docker-compose down --remove-orphans
```

**Local development:**
```bash
# Terminal 1 — FastAPI backend
pip install -r requirements.txt
cd backend && uvicorn app.main:app --reload --port 8001

# Terminal 2 — Flask frontend
python app.py            # http://localhost:5000
```

## Architecture

Two-process Python app — both processes run in the same Docker container but are separate services:

- **Flask frontend** (`app.py`) — serves the HTML/JS UI and proxies API calls to FastAPI. Routes: `/`, `/search`, `/download`, `/check_status/<pid>`, `/downloads`, `/download/<filename>`.
- **FastAPI backend** (`backend/app/main.py`) — owns all business logic: schedule search, subprocess-based download management (timeout: 30 min), and EPG auto-refresh (every 2 hours).
- **SQLite** (`database.py`) — persists download history. Single `downloads` table; schema auto-migrates (adds columns if missing).
- **ruvsarpur** (`ruvsarpur/ruvsarpur.py`) — third-party downloader invoked as a subprocess by the FastAPI backend. Not modified directly.

### Data flow

1. **Search**: Browser → Flask → FastAPI → in-memory `tvschedule.json` → fuzzy search results
2. **Download**: Browser → Flask → FastAPI → async subprocess (`ruvsarpur.py`) → status stored in-memory dict
3. **Status polling**: Browser polls Flask every 3–5 s → Flask queries FastAPI `/api/status/<pid>`

### EPG data locations (checked in order)

1. `~/.ruvsarpur/tvschedule.json` (primary, mapped to Docker volume `./data/epg`)
2. `./data/.ruvsarpur/tvschedule.json` (fallback)

## Key Configuration

| Setting | Value |
|---|---|
| Download directory | `/app/downloads` (Docker) |
| EPG refresh interval | 2 hours (background task in FastAPI) |
| Download timeout | 30 minutes |
| Search debounce | 300 ms |

## Useful API Endpoints (FastAPI)

```
GET  /api/epg-status        # Check whether EPG data is loaded
POST /api/download-epg      # Manually trigger EPG refresh
GET  /api/test-ruvsarpur    # Validate the ruvsarpur script is accessible
GET  /api/search/{query}    # Search for shows
POST /api/download          # Start a download
GET  /api/status/{pid}      # Check download status
```

## Docker Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `./data/epg` | `/home/appuser/.ruvsarpur` | EPG/schedule JSON |
| `./downloads` | `/app/downloads` | Downloaded video files |
| `./data` | `/app/data` | Fallback data directory |

## Environment Variables (set in docker-compose.yml / entrypoint.sh)

- `PYTHONPATH=/app:/app/ruvsarpur:/app/backend`
- `RUVSARPUR_PATH=/app/ruvsarpur`
- `FLASK_ENV=production`
- `HOST_UID` / `HOST_GID` — set by `pre-start.sh` for correct file ownership inside the container
