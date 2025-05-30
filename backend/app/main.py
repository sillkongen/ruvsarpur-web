import os
import sys
import json
import logging
import asyncio
import subprocess
from pathlib import Path
from typing import Optional, Dict, List
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Add the ruvsarpur directory to Python path and find the script
RUVSARPUR_PATH = os.environ.get('RUVSARPUR_PATH', os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "ruv-container", "ruvsarpur", "src"))
RUVSARPUR_SCRIPT = os.path.join(RUVSARPUR_PATH, "ruvsarpur.py")

# Path to the schedule JSON file
SCHEDULE_FILE = os.environ.get('SCHEDULE_FILE', os.path.expanduser("~/.ruvsarpur/tvschedule.json"))
SCHEDULE_FILE_FALLBACK = os.environ.get('SCHEDULE_FILE_FALLBACK', "/app/.ruvsarpur/tvschedule.json")

# Verify the script exists
if not os.path.exists(RUVSARPUR_SCRIPT):
    raise FileNotFoundError(f"Could not find ruvsarpur.py script at: {RUVSARPUR_SCRIPT}")

# Global variable to hold the schedule data in memory
schedule_data: Dict = {}

def load_schedule():
    """Load the TV schedule from JSON file into memory"""
    global schedule_data
    
    # Try multiple locations for the schedule file
    possible_locations = [
        SCHEDULE_FILE,
        SCHEDULE_FILE_FALLBACK,
        "/root/.ruvsarpur/tvschedule.json",
        "/app/.ruvsarpur/tvschedule.json"
    ]
    
    schedule_file = None
    for location in possible_locations:
        if os.path.exists(location):
            schedule_file = location
            break
    
    if not schedule_file:
        logger.error(f"No schedule file found in any of these locations: {possible_locations}")
        schedule_data = {}
        return
    
    try:
        logger.info(f"Loading schedule from {schedule_file}")
        with open(schedule_file, 'r', encoding='utf-8') as f:
            schedule_data = json.load(f)
        logger.info(f"Loaded {len(schedule_data)} items from schedule")
    except Exception as e:
        logger.error(f"Error loading schedule from {schedule_file}: {str(e)}")
        schedule_data = {}

app = FastAPI(title="RÚV Downloader API")

# Load schedule on startup
load_schedule()

# Global dictionary to track download status
download_status: Dict[str, Dict] = {}

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class DownloadRequest(BaseModel):
    pid: str
    quality: str = "HD1080"
    output_dir: str = "/app/downloads"  # Always use absolute path in container

    @field_validator('pid')
    @classmethod
    def strip_pid_whitespace(cls, value: str) -> str:
        if isinstance(value, str):
            return value.strip()
        return value
    
    @field_validator('output_dir')
    @classmethod
    def ensure_absolute_path(cls, value: str) -> str:
        # Ensure we always have an absolute path
        return os.path.abspath(value)

@app.get("/api/search/{query}")
async def search_shows(query: str):
    """Search for shows in the loaded schedule data"""
    try:
        logger.info(f"Searching for: {query}")
        
        if not schedule_data:
            # Try to reload if empty
            load_schedule()
            if not schedule_data:
                raise HTTPException(status_code=503, detail="Schedule data not available")
        
        results = []
        query_lower = query.lower()
        
        # Search through all items in the schedule
        for pid, item in schedule_data.items():
            try:
                if pid == 'date' or not isinstance(item, dict):
                    continue
                
                # Search in multiple fields
                searchable_texts = [
                    item.get('title', ''),
                    item.get('series_title', ''),
                    item.get('episode_title', ''),
                    item.get('desc', ''),
                    item.get('series_desc', ''),
                    item.get('series_sdesc', ''),
                    item.get('original-title', '') or ''
                ]
                
                # Check if query matches any of the searchable fields
                found = any(query_lower in text.lower() for text in searchable_texts if text)
                
                if found:
                    # Create rich result object
                    result = {
                        'pid': pid,
                        'title': item.get('title', ''),
                        'description': item.get('desc', ''),
                        'duration': item.get('duration_friendly', ''),
                        'image': item.get('series_image') or item.get('episode_image') or '',
                        'has_subtitles': item.get('has_subtitles', False),
                        'is_movie': item.get('is_movie', False),
                        'is_sport': item.get('is_sport', False),
                        'is_docu': item.get('is_docu', False),
                        'showtime': item.get('showtime', ''),
                        'series_title': item.get('series_title', ''),
                        'episode_title': item.get('episode_title', ''),
                        'series_desc': item.get('series_sdesc', ''),
                    }
                    
                    # Add episode info if available
                    if item.get('ep_num') and item.get('ep_total'):
                        result['episode_info'] = f"Episode {item['ep_num']} of {item['ep_total']}"
                        result['episode_number'] = item['ep_num']
                        result['total_episodes'] = item['ep_total']
                    
                    # Add original title if available
                    if item.get('original-title'):
                        result['original_title'] = item['original-title']
                    
                    # Add series ID for grouping
                    if item.get('sid'):
                        result['series_id'] = item['sid']
                    
                    results.append(result)
                    
            except Exception as item_error:
                logger.error(f"Error processing item {pid}: {str(item_error)}")
                continue
        
        # Sort results by series and episode number
        results.sort(key=lambda x: (
            x.get('series_title', ''),
            int(x.get('episode_number', 0)) if x.get('episode_number') else 0
        ))
        
        logger.info(f"Found {len(results)} results")
        return results
        
    except Exception as e:
        logger.error(f"Search error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/refresh")
async def refresh_schedule():
    """Manually refresh the schedule data"""
    try:
        load_schedule()
        return {"status": "success", "items": len(schedule_data)}
    except Exception as e:
        logger.error(f"Refresh error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

async def download_show_task(pid: str, quality: str, output_dir: str):
    """Background task to handle show download using ruvsarpur script"""
    try:
        logger.info(f"Starting download for PID: {pid}")
        download_status[pid] = {"status": "downloading", "file_path": None}
        
        # Ensure we have the absolute path
        abs_output_dir = os.path.abspath(output_dir)
        logger.info(f"Using absolute output directory: {abs_output_dir}")
        
        # Create output directory
        os.makedirs(abs_output_dir, exist_ok=True)
        
        # Use the correct Python interpreter from the current virtual environment
        python_executable = os.path.join(os.path.dirname(sys.executable), "python3")
        if not os.path.exists(python_executable):
            python_executable = sys.executable
        
        # Use the ruvsarpur script to download with absolute path
        cmd = [python_executable, RUVSARPUR_SCRIPT, "--pid", pid, "--output", abs_output_dir]
        
        # Add quality if specified and not default
        if quality and quality != "HD1080":
            cmd.extend(["--quality", quality])
        
        logger.info(f"Running download command: {' '.join(cmd)}")
        
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=RUVSARPUR_PATH
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode == 0:
            logger.info(f"Download completed successfully for PID: {pid}")
            download_status[pid] = {
                "status": "completed",
                "file_path": abs_output_dir,
                "message": "Download completed successfully"
            }
        else:
            error_msg = stderr.decode('utf-8') if stderr else "Unknown error"
            logger.error(f"Download failed for PID {pid}: {error_msg}")
            download_status[pid] = {
                "status": "failed",
                "error": error_msg
            }
            
    except Exception as e:
        logger.error(f"Download error for {pid}: {str(e)}")
        download_status[pid] = {"status": "failed", "error": str(e)}

@app.post("/api/download")
async def download_show(request: DownloadRequest, background_tasks: BackgroundTasks):
    """Download a show by its program ID"""
    try:
        logger.info(f"Received download request for PID: '{request.pid}' (type: {type(request.pid)}), Quality: {request.quality}, Output: {request.output_dir}")
        
        # Create output directory if it doesn't exist
        os.makedirs(request.output_dir, exist_ok=True)
        
        # Initialize status before starting download
        download_status[request.pid] = {"status": "starting"}
        logger.info(f"PID '{request.pid}' set to 'starting'. Current download_status keys: {list(download_status.keys())}")
        
        # Start download in background
        background_tasks.add_task(
            download_show_task,
            request.pid,
            request.quality,
            request.output_dir
        )
        
        return {
            "status": "started",
            "pid": request.pid,
            "message": "Download started successfully"
        }
    except Exception as e:
        logger.error(f"Error in /api/download for PID '{request.pid if request and hasattr(request, 'pid') else 'unknown'}': {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/status/{pid}")
async def get_status(pid: str):
    """Get the status of a download"""
    stripped_pid = pid.strip()
    logger.debug(f"Status check for PID: '{stripped_pid}' (original: '{pid}', type: {type(stripped_pid)}).")
    logger.debug(f"Current download_status keys: {list(download_status.keys())}")

    if stripped_pid not in download_status:
        logger.warning(f"PID '{stripped_pid}' not found in download_status for /api/status. Available PIDs: {list(download_status.keys())}. Raising 404.")
        raise HTTPException(status_code=404, detail="Download not found")
    
    logger.debug(f"PID '{stripped_pid}' found. Status: {download_status[stripped_pid]}")
    return download_status[stripped_pid] 