# RÚV Sarpurinn Web Downloader

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)

A modern web interface for downloading shows from RÚV Sarpurinn with instant search, download tracking, and enhanced reliability.

**Built on top of [ruvsarpur](https://github.com/sverrirs/ruvsarpur) by [@sverrirs](https://github.com/sverrirs).**

## Features

- **Instant Search**: Lightning-fast search through 7000+ show entries
- **Reliable Downloads**: Enhanced timeout protection and automatic EPG data handling  
- **Smart EPG Management**: Automatic EPG data persistence and download recovery
- **Dark Mode**: Dark/light theme toggle with persistent preference
- **Modern UI**: Clean, responsive Bootstrap-based interface
- **Robust Architecture**: FastAPI + Flask with comprehensive error handling
- **Production Ready**: Dockerized deployment with proper user permissions

## Quick Start

### Prerequisites

1. **EPG data**: Run ruvsarpur at least once to generate `~/.ruvsarpur/tvschedule.json`  
   (Or use any existing ruvsarpur installation)

### Docker Commands

1. **Clone this repository:**
   ```bash
   git clone https://github.com/sillkongen/ruvsarpur-web.git
   cd ruvsarpur-web && sudo ./pre-start.sh
   ```

2. **Start the application:**
   ```bash
   docker-compose up --build -d
   ```

3. **Stop the application:**
   ```bash
   docker-compose down --remove-orphans
   ```

4. **Access the application:**
   - Web interface: http://localhost:5000
   - API backend: http://localhost:8001

## Screenshots

### Light Mode
![Light Mode Interface](screenshots/Screenshot.png)

### Dark Mode
![Dark Mode Interface](screenshots/Screenshot_dark_mode.png)

## Project Structure

```
ruvsarpur-web/
├── start.sh               # Easy startup script
├── app.py                 # Flask frontend application
├── backend/               # FastAPI backend
├── ruvsarpur/            # Included ruvsarpur source code
├── templates/            # HTML templates
├── static/               # CSS, JS, and assets
├── database.py           # SQLite database operations
├── downloads/            # Downloaded videos
├── data/                 # Application data and EPG cache
└── docker-compose.yml    # Docker deployment configuration
```

## Configuration

### EPG Data Handling

The application looks for EPG data in the following locations:

1. `${HOME}/.ruvsarpur/tvschedule.json` (primary)
2. `./data/.ruvsarpur/tvschedule.json` (local copy)
3. `/root/.ruvsarpur/tvschedule.json` (container fallback)

If no EPG data exists, the first download will fetch it (5-8 minutes).

### Download Location

Downloaded files will be saved to `./downloads` in your current directory.
ctually an important file that should typically be included in version control, not ignored. It contains the instructions for building your application's Docker container and is a crucial part of your ap

## Todo

1. File management, delete from Download section
2. Proper non root user setup within container


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **[ruvsarpur](https://github.com/sverrirs/ruvsarpur)** by [@sverrirs](https://github.com/sverrirs)
- **RÚV (Ríkisútvarpið)** - Iceland's national public-service broadcasting organization

## Legal Notice

This tool is for educational and personal use only. Please respect RÚV's terms of service and copyright.
