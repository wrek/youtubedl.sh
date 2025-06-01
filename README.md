# YouTube Downloader

A simple, all-in-one YouTube downloader that works on Windows with automatic WSL detection and fallbacks.

## Quick Start

1. **Run the script**: `.\youtube-dl.ps1`
2. **First time**: Choose "System Test" then "Setup/Install" if needed
3. **Download**: Use the menu or command line options

## Usage

```powershell
# Interactive menu (recommended)
.\youtube-dl.ps1

# Command line usage
.\youtube-dl.ps1 -Url "https://youtube.com/watch?v=..."
.\youtube-dl.ps1 -Playlist "https://youtube.com/playlist?list=..."
.\youtube-dl.ps1 -Channel "https://youtube.com/@channelname"

# System management
.\youtube-dl.ps1 -Test    # Check system status
.\youtube-dl.ps1 -Setup   # Install dependencies
.\youtube-dl.ps1 -Help    # Show help
```

## How It Works

The script automatically:

- Detects WSL + Linux distributions (preferred)
- Falls back to native Windows downloaders (yt-dlp/youtube-dl)
- Installs dependencies as needed
- Manages configuration in `config.json`

## Setup

The script handles setup automatically, but you can also:

- Install WSL + Ubuntu manually from Microsoft Store
- Install Python + `pip install yt-dlp`
- Install Chocolatey + `choco install yt-dlp`

## Files

- `youtube-dl.ps1` - Main script (this is all you need!)
- `config.json` - Settings (auto-created)

That's it! No complex setup, no multiple files, just one script that does everything.
