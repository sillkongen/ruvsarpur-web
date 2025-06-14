document.addEventListener('DOMContentLoaded', () => {
    const searchForm = document.getElementById('searchForm');
    const searchInput = document.getElementById('searchInput');
    const resultsDiv = document.getElementById('results');
    const loadingDiv = document.getElementById('loading');
    const themeToggle = document.getElementById('themeToggle');
    const themeIcon = document.getElementById('themeIcon');
    const epgStatusDiv = document.getElementById('epgStatus');
    const epgStatusText = document.getElementById('epgStatusText');
    const downloadEpgBtn = document.getElementById('downloadEpgBtn');
    let debounceTimer;
    
    // Make activeDownloads globally accessible
    if (!window.activeDownloads) {
        window.activeDownloads = new Set();
    }

    // EPG Status functionality
    async function checkEpgStatus() {
        try {
            const response = await fetch('/api/epg-status');
            const data = await response.json();
            
            if (data.epg_available) {
                epgStatusDiv.className = 'alert alert-success mb-4';
                epgStatusText.innerHTML = `
                    ✅ EPG data available (${data.epg_size_mb} MB, ${data.schedule_items} shows)
                    <br><small class="text-muted">Location: ${data.epg_location}</small>
                `;
                downloadEpgBtn.classList.add('d-none');
            } else {
                epgStatusDiv.className = 'alert alert-warning mb-4';
                epgStatusText.innerHTML = `
                    ⚠️ EPG data not found. Downloads may take 5-8 minutes for initial EPG download.
                    <br><small class="text-muted">Click the button to download EPG data manually.</small>
                `;
                downloadEpgBtn.classList.remove('d-none');
            }
        } catch (error) {
            console.error('Error checking EPG status:', error);
            epgStatusDiv.className = 'alert alert-danger mb-4';
            epgStatusText.textContent = 'Error checking EPG status';
            downloadEpgBtn.classList.add('d-none');
        }
    }

    async function downloadEpg() {
        downloadEpgBtn.disabled = true;
        downloadEpgBtn.textContent = 'Downloading EPG...';
        epgStatusDiv.className = 'alert alert-info mb-4';
        epgStatusText.innerHTML = `
            ⏳ Downloading EPG data, please wait (this may take 5-8 minutes)...
            <br><small class="text-muted">Do not close this page during download.</small>
        `;
        
        try {
            const response = await fetch('/api/download-epg', { method: 'POST' });
            const data = await response.json();
            
            if (data.status === 'success') {
                epgStatusDiv.className = 'alert alert-success mb-4';
                epgStatusText.innerHTML = `
                    ✅ EPG data downloaded successfully! (${data.schedule_items} shows available)
                    <br><small class="text-muted">You can now search and download shows.</small>
                `;
                downloadEpgBtn.classList.add('d-none');
            } else {
                epgStatusDiv.className = 'alert alert-danger mb-4';
                epgStatusText.innerHTML = `
                    ❌ EPG download failed: ${data.message}
                    <br><small class="text-muted">${data.stderr || ''}</small>
                `;
                downloadEpgBtn.disabled = false;
                downloadEpgBtn.textContent = 'Retry Download';
            }
        } catch (error) {
            console.error('Error downloading EPG:', error);
            epgStatusDiv.className = 'alert alert-danger mb-4';
            epgStatusText.innerHTML = `
                ❌ Error downloading EPG data: ${error.message}
                <br><small class="text-muted">Please try again or check the logs.</small>
            `;
            downloadEpgBtn.disabled = false;
            downloadEpgBtn.textContent = 'Retry Download';
        }
    }

    // Initialize EPG status check
    // checkEpgStatus();  // Temporarily disabled to avoid 404 errors
    
    // Add EPG download button event listener
    downloadEpgBtn.addEventListener('click', downloadEpg);

    // Dark mode functionality
    function initTheme() {
        const savedTheme = localStorage.getItem('theme') || 'light';
        document.documentElement.setAttribute('data-theme', savedTheme);
        updateThemeIcon(savedTheme);
    }

    function toggleTheme() {
        const currentTheme = document.documentElement.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        
        document.documentElement.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
        updateThemeIcon(newTheme);
    }

    function updateThemeIcon(theme) {
        themeIcon.textContent = theme === 'dark' ? '☀️' : '🌙';
    }

    // Initialize theme on page load
    initTheme();

    // Add theme toggle event listener
    themeToggle.addEventListener('click', toggleTheme);

    // Remove the form submit event listener since we'll search on input
    searchForm.addEventListener('submit', (e) => e.preventDefault());

    // Add input event listener for instant search
    searchInput.addEventListener('input', () => {
        const query = searchInput.value.trim();
        
        // Clear any pending searches
        clearTimeout(debounceTimer);
        
        // Don't search if less than 2 characters
        if (query.length < 2) {
            resultsDiv.innerHTML = `
                <div class="text-center text-muted my-4">
                    Type at least 2 characters to search...
                </div>
            `;
            loadingDiv.classList.add('d-none');
            return;
        }

        // Show loading spinner
        loadingDiv.classList.remove('d-none');

        // Debounce the search to avoid too many API calls
        debounceTimer = setTimeout(async () => {
            try {
                const response = await fetch(`/search?q=${encodeURIComponent(query)}`);
                const data = await response.json();
                console.log('Search response:', data);

                if (response.ok) {
                    displayResults(data);
                } else {
                    throw new Error(data.error || 'Search failed');
                }
            } catch (error) {
                console.error('Search error:', error);
                showError(error.message);
            } finally {
                loadingDiv.classList.add('d-none');
            }
        }, 300);
    });

    function displayResults(results) {
        resultsDiv.innerHTML = '';
        console.log('Displaying results:', results); // Debug log
        
        if (!Array.isArray(results) || results.length === 0) {
            resultsDiv.innerHTML = `
                <div class="text-center text-muted my-4">
                    No results found. Try a different search term.
                </div>
            `;
            return;
        }

        results.forEach(result => {
            // Handle the specific format from ruvsarpur API
            const title = result.title || result.name || 'Untitled';
            const description = result.description || result.desc || '';
            const id = result.pid || result.id || '';
            const episodeInfo = result.episode_number ? 
                `Episode ${result.episode_number}${result.series_title ? ` - ${result.series_title}` : ''}` : '';

            const item = document.createElement('div');
            item.className = 'list-group-item d-flex justify-content-between align-items-center';
            item.innerHTML = `
                <div class="flex-grow-1">
                    <h6 class="mb-1">${title}</h6>
                    ${episodeInfo ? `<small class="text-primary fw-semibold">${episodeInfo}</small><br>` : ''}
                    <p class="mb-1 text-muted">${description}</p>
                    ${result.duration ? `<small class="text-muted">Duration: ${result.duration}</small>` : ''}
                </div>
                <div class="ms-3">
                    <button class="btn btn-primary btn-download" 
                            onclick="downloadShow('${id}', '${title.replace(/'/g, "\\'")}', this)"
                            data-pid="${id}">
                        Download
                    </button>
                </div>
            `;
            resultsDiv.appendChild(item);
        });
    }

    // Make downloadShow globally accessible
    window.downloadShow = async function(pid, title, buttonElement) {
        if (window.activeDownloads.has(pid)) {
            console.log(`Download already in progress for ${pid}`);
            return;
        }

        try {
            window.activeDownloads.add(pid);
            
            // Update button to show "Starting..."
            buttonElement.innerHTML = '<span class="download-status status-started">⏳ Starting...</span>';
            buttonElement.disabled = true;

            const response = await fetch('/download', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    pid: pid,
                    title: title,
                    quality: 'HD1080',
                    output_dir: 'downloads'
                })
            });

            const result = await response.json();
            console.log('Download response:', result);

            if (response.ok) {
                console.log(`Download started for ${pid}`);
                buttonElement.innerHTML = '<span class="download-status status-started">📥 Downloading...</span>';
                
                // Start polling for status
                checkDownloadStatus(pid, buttonElement);
            } else {
                throw new Error(result.error || 'Download failed');
            }
        } catch (error) {
            console.error('Download error:', error);
            buttonElement.innerHTML = '<span class="download-status status-failed">❌ Failed</span>';
            buttonElement.disabled = false;
            window.activeDownloads.delete(pid);
            showError(`Download failed: ${error.message}`);
        }
    };

    async function checkDownloadStatus(pid, buttonElement) {
        console.log(`Checking status for download ${pid}...`);
        
        try {
            const response = await fetch(`/check_status/${pid}`);
            const result = await response.json();
            
            console.log(`Status update for ${pid}:`, result);
            
            if (response.ok) {
                const status = result.status;
                
                if (status === 'completed') {
                    buttonElement.innerHTML = '<span class="download-status status-completed"><span class="checkmark">✓</span> Downloaded</span>';
                    window.activeDownloads.delete(pid);
                    return; // Stop polling when completed
                } else if (status === 'failed') {
                    buttonElement.innerHTML = '<span class="download-status status-failed">❌ Failed</span>';
                    buttonElement.disabled = false;
                    window.activeDownloads.delete(pid);
                    return; // Stop polling when failed
                } else {
                    // Still in progress, continue polling
                    setTimeout(() => checkDownloadStatus(pid, buttonElement), 3000);
                }
            } else {
                console.error(`Status check failed for ${pid}:`, result.error);
                // If 404, the download might not exist anymore, stop polling
                if (response.status === 404) {
                    buttonElement.innerHTML = '<span class="download-status status-failed">❌ Not found</span>';
                    buttonElement.disabled = false;
                    window.activeDownloads.delete(pid);
                    return; // Stop polling when not found
                } else {
                    // Other errors, continue polling but less frequently
                    setTimeout(() => checkDownloadStatus(pid, buttonElement), 5000);
                }
            }
        } catch (error) {
            console.error(`Error checking status for ${pid}:`, error);
            // Continue polling on network errors
            setTimeout(() => checkDownloadStatus(pid, buttonElement), 5000);
        }
    }

    function showError(message) {
        resultsDiv.innerHTML = `
            <div class="alert alert-danger" role="alert">
                Error: ${message}
            </div>
        `;
    }
}); 