# RÚV Sarpurinn Web Downloader

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/sillkongen/ruvsarpur-web/workflows/CI/badge.svg)](https://github.com/sillkongen/ruvsarpur-web/actions)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)

A modern web interface for downloading shows from RÚV Sarpurinn with instant search, download tracking, and enhanced reliability.

**Built on top of [ruvsarpur](https://github.com/sverrirs/ruvsarpur) by [@sverrirs](https://github.com/sverrirs) - the excellent Python script for downloading content from the Icelandic RÚV website.**

## 🌟 Features

- 🔍 **Instant Search**: Lightning-fast search through 7000+ show entries loaded in memory
- 📥 **Reliable Downloads**: Enhanced timeout protection and automatic EPG data handling  
- 🔄 **Smart EPG Management**: Automatic EPG data persistence and download recovery
- 🌙 **Dark Mode**: Beautiful dark/light theme toggle with persistent preference
- 🎯 **Modern UI**: Clean, responsive Bootstrap-based interface with real-time status updates
- ⚡ **Robust Architecture**: FastAPI + Flask with comprehensive error handling
- 🐳 **Production Ready**: Dockerized deployment with proper user permissions
- 🛡️ **Timeout Protection**: 30-minute download timeouts prevent infinite hanging
- 📊 **Enhanced Status Tracking**: Real-time download progress with visual indicators

## 🚀 Recent Improvements (v2.0)

### ✅ **EPG Data Persistence Fixed**
- Automatic EPG data mounting and persistence between container restarts
- Smart fallback locations with proper ownership handling
- Initial EPG download detection with user-friendly messages

### ✅ **Download Reliability Enhanced** 
- 30-minute timeout protection prevents infinite hanging
- Proper environment variable handling for EPG data access
- Fixed infinite status polling after download completion
- Enhanced error logging and debugging information

### ✅ **User Experience Improvements**
- EPG status indicator shows data availability 
- Clean success/error messaging
- Improved download button states and status updates
- Fixed permission issues - downloads now owned by your user

## 📸 Demo

![RÚV Web Interface](https://via.placeholder.com/800x400?text=RÚV+Web+Interface+Demo)

*Modern web interface with instant search, EPG status monitoring, and dark mode support*

## 🚀 Quick Start

### Prerequisites

This web interface includes ruvsarpur source code, so you only need:

1. **EPG data**: Run ruvsarpur at least once to generate `~/.ruvsarpur/tvschedule.json`  
   (Or use any existing ruvsarpur installation)

### Docker Deployment (Recommended)

1. **Clone this repository:**
   ```bash
   git clone https://github.com/sillkongen/ruvsarpur-web.git
   cd ruvsarpur-web
   ```

2. **Quick Start (handles permissions automatically):**
   ```bash
   ./start.sh
   ```
   This script will:
   - Set correct user/group IDs to avoid permission issues
   - Create necessary directories
   - Setup EPG data if available
   - Start the containers

3. **Manual setup (alternative):**
   ```bash
   mkdir -p downloads data
   ./setup-epg.sh  # If you have EPG data
   export USER_ID=$(id -u) GROUP_ID=$(id -g)
   docker-compose up --build
   ```

4. **Access the application:**
   - Web interface: http://localhost:5000
   - API backend: http://localhost:8001

**Note**: Downloaded files will now have proper ownership matching your user! 🎉

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
├── start.sh               # Easy startup script (handles permissions)
├── app.py                  # Flask frontend application
├── backend/                # FastAPI backend
│   └── app/
│       └── main.py        # API endpoints and download logic
├── ruvsarpur/             # Included ruvsarpur source code
│   ├── ruvsarpur.py       # Main download script by @sverrirs
│   ├── utilities.py       # Utility functions
│   └── LICENSE-ruvsarpur  # Original MIT license
├── templates/             # HTML templates
├── static/               # CSS, JS, and assets
├── database.py           # SQLite database operations
├── downloads/            # Downloaded videos (mounted volume)
├── data/                # Application data and EPG cache
├── docker-compose.yml   # Docker deployment configuration
├── Dockerfile           # Container build instructions
├── .dockerignore        # Excludes large files from Docker build
└── setup-epg.sh        # EPG data setup script
```

## 📄 Configuration

### Docker Build Optimization

The `.dockerignore` file excludes unnecessary content from the Docker build:
- 🎬 Video files (*.mp4, *.mkv, etc.) - prevents large files in image
- 📁 Downloads/data directories - these are mounted as volumes
- 🛠️ Development files - keeps image lean

This ensures fast builds and small image sizes while maintaining full functionality.

### EPG Data Handling

The application now features **robust EPG data management** with multiple fallback locations:

**Primary Location (Recommended):**
- `${HOME}/.ruvsarpur/tvschedule.json` (mounted from host - persists between container restarts)

**Fallback Locations:**
- `./data/.ruvsarpur/tvschedule.json` (local copy)
- `/root/.ruvsarpur/tvschedule.json` (container fallback)
- `/app/.ruvsarpur/tvschedule.json` (legacy location)

**EPG Data Features:**
- ✅ **Automatic Detection**: Web interface shows EPG availability status
- ✅ **Smart Mounting**: EPG data persists between container restarts
- ✅ **First-Run Handling**: If no EPG data exists, first download will fetch it (5-8 minutes)
- ✅ **Proper Permissions**: EPG data owned by your user, not root

**Setup EPG Data:**
```bash
# Option 1: Use existing ruvsarpur installation
cp ~/.ruvsarpur/tvschedule.json ./data/.ruvsarpur/

# Option 2: Let the application download EPG on first run
# (Web interface will show progress and estimated time)

# Option 3: Use the setup script
./setup-epg.sh
```

The EPG data is automatically excluded from version control to respect RÚV's copyright.

## 🔧 Troubleshooting

### EPG Data Issues
- **"EPG data not found"**: Web interface will show download progress on first run
- **Downloads hanging**: Fixed with 30-minute timeout protection
- **Permission errors**: Rebuild container to ensure proper user permissions

### Common Solutions
```bash
# Rebuild with proper permissions
sudo docker-compose down --remove-orphans
sudo docker-compose up --build

# Check EPG data status
sudo docker-compose exec ruvsarpur-web ls -la /home/appuser/.ruvsarpur/

# View container logs
sudo docker-compose logs --tail=50
```

### Download Debugging
- Downloads include comprehensive logging in container output
- 30-minute timeout prevents infinite hanging
- Status polling automatically stops when downloads complete
- All download errors are logged with detailed information

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

### Volume Mounts

- `./downloads` → `/app/downloads` (Downloaded video files - **accessible outside container**)
- `./data` → `/app/data` (Application data)
- `~/.ruvsarpur` → `/home/appuser/.ruvsarpur` (EPG/Schedule cache - **persists between restarts**)

**Note**: ruvsarpur source code is now included in the repository - no external mounting required!

### Environment Variables

- `RUVSARPUR_PATH`: Path to ruvsarpur script (default: `/app/ruvsarpur`)
- `SCHEDULE_FILE`: Path to TV schedule JSON (default: `/home/appuser/.ruvsarpur/tvschedule.json`)
- `FLASK_ENV`: Flask environment (default: `production`)

## 🏗️ Architecture

- **Frontend**: Flask app serving the web interface
- **Backend**: FastAPI handling search and downloads with enhanced error handling
- **Script**: ruvsarpur.py for actual video downloading
- **Database**: SQLite for download tracking
- **Cache**: In-memory schedule data for fast search (7000+ entries)

### Download Process

When you download a show, the backend calls ruvsarpur with proper environment variables:
```bash
HOME=/home/appuser python ruvsarpur.py --pid <program_id> --output /app/downloads --quality HD1080
```

The `/app/downloads` path is mounted to `./downloads` on your host, ensuring files are accessible outside the container.

## 🎯 Usage

1. Type in the search box (minimum 2 characters)
2. Browse instant search results from 7000+ shows
3. Click "Download" on any show
4. Watch real-time status updates with timeout protection
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

Built with ❤️ for easy RÚV content downloading with enhanced reliability and user experience.