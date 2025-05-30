# RÚV Sarpurinn Web Downloader

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/sillkongen/ruvsarpur-web/workflows/CI/badge.svg)](https://github.com/sillkongen/ruvsarpur-web/actions)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)

A modern web interface for downloading shows from RÚV Sarpurinn with instant search and download tracking.

**Built on top of [ruvsarpur](https://github.com/sverrirs/ruvsarpur) by [@sverrirs](https://github.com/sverrirs) - the excellent Python script for downloading content from the Icelandic RÚV website.**

## 🌟 Features

- 🔍 **Instant Search**: Lightning-fast search through 30MB+ schedule data loaded in memory
- 📥 **Download Tracking**: Real-time download status with visual indicators  
- 🌙 **Dark Mode**: Beautiful dark/light theme toggle with persistent preference
- 🎯 **Modern UI**: Clean, responsive Bootstrap-based interface
- ⚡ **Fast Backend**: FastAPI + Flask architecture for optimal performance
- 🐳 **Docker Ready**: One-command deployment with Docker Compose

## 📸 Demo

![RÚV Web Interface](https://via.placeholder.com/800x400?text=RÚV+Web+Interface+Demo)

*Modern web interface with instant search and dark mode support*

## 🚀 Quick Start

### Prerequisites

This web interface requires the `ruvsarpur` source code to be available. Make sure you have:

1. **ruvsarpur source**: Clone from [https://github.com/sverrirs/ruvsarpur](https://github.com/sverrirs/ruvsarpur)
2. **EPG data**: Run ruvsarpur at least once to generate `~/.ruvsarpur/tvschedule.json`

### Docker Deployment (Recommended)

1. **Clone this repository:**
   ```bash
   git clone https://github.com/sillkongen/ruvsarpur-web.git
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

### Manual Development

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

## 📁 Project Structure

```
ruvsarpur-web/
├── app.py                  # Flask frontend application
├── backend/                # FastAPI backend
│   └── app/
│       └── main.py        # API endpoints and download logic
├── templates/             # HTML templates
├── static/               # CSS, JS, and assets
├── database.py           # SQLite database operations
├── downloads/            # Downloaded videos (mounted volume)
├── data/                # Application data and EPG cache
├── docker-compose.yml   # Docker deployment configuration
├── Dockerfile           # Container build instructions
└── setup-epg.sh        # EPG data setup script
```

## 🔧 Configuration

### EPG Data Handling

⚠️ **IMPORTANT**: EPG schedule data is copyrighted by RÚV and is **NOT included** in this repository.

The application looks for EPG data in multiple locations:
- `${HOME}/.ruvsarpur/tvschedule.json` (mounted from host)
- `./data/.ruvsarpur/tvschedule.json` (local copy - **excluded from Git**)
- `/root/.ruvsarpur/tvschedule.json` (inside container)
- `/app/.ruvsarpur/tvschedule.json` (fallback location)

Use `./setup-epg.sh` to copy your EPG data locally. This data is automatically excluded from version control to respect RÚV's copyright.

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

### Volume Mounts

- `./downloads` → `/app/downloads` (Downloaded video files - **accessible outside container**)
- `./data` → `/app/data` (Application data)
- `~/.ruvsarpur` → `/root/.ruvsarpur` (EPG/Schedule cache)
- `../ruv-container/ruvsarpur/src` → `/app/ruvsarpur` (ruvsarpur source code)

### Environment Variables

- `RUVSARPUR_PATH`: Path to ruvsarpur script (default: `/app/ruvsarpur`)
- `SCHEDULE_FILE`: Path to TV schedule JSON (default: `~/.ruvsarpur/tvschedule.json`)
- `FLASK_ENV`: Flask environment (default: `production`)

## 🏗️ Architecture

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

## 🎯 Usage

1. Type in the search box (minimum 2 characters)
2. Browse instant search results  
3. Click "Download" on any show
4. Watch real-time status updates
5. Toggle dark mode with the moon/sun button
6. **Find your downloads**: Check the `./downloads` folder in your current directory

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[ruvsarpur](https://github.com/sverrirs/ruvsarpur)** by [@sverrirs](https://github.com/sverrirs) - The core Python script that makes this web interface possible
- **RÚV (Ríkisútvarpið)** - Iceland's national public-service broadcasting organization
- All contributors who helped improve this project

## ⚖️ Legal Notice

This tool is for educational and personal use only. Please respect RÚV's terms of service and copyright. The authors are not responsible for any misuse of this software.

---

Built with ❤️ for easy RÚV content downloading. 