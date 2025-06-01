# YouTube Downloader

A comprehensive, all-in-one YouTube downloader PowerShell script with interactive menu, comprehensive search, and automatic dependency management.

## ✨ Features

- **🔍 Comprehensive Search** - Find channels, videos, and playlists by keywords
- **📱 Interactive Menu** - User-friendly 7-option menu system
- **📺 Multiple Content Types** - Download videos, channels, playlists
- **🎯 Smart URL Handling** - Supports all YouTube URL formats and @handles
- **📊 Channel-Specific Logging** - Organized logs per channel
- **🔧 Auto-Installation** - Automatically installs yt-dlp via pip or Chocolatey
- **🎬 Quality Optimization** - Downloads MP4 with best audio/video quality
- **📁 Organized Structure** - Clean directory organization for downloads

## 🚀 Quick Start

1. **Run the script**: `.\youtube-dl.ps1`
2. **First time**: The script will test your system and offer to install dependencies
3. **Download**: Use the interactive menu or command line options

## 📖 Usage

### Interactive Menu (Recommended)
```powershell
.\youtube-dl.ps1
```

The menu offers these options:
1. **Download Single Video** - Enter any YouTube video URL or ID
2. **Download Channel** - Enter channel URL, @handle, or search for channels
3. **Download Playlist** - Enter playlist URL or ID
4. **Search YouTube** - Comprehensive search for channels, videos, and playlists
5. **System Test** - Check if downloaders are properly installed
6. **Setup/Install** - Install or update yt-dlp downloader
7. **Help** - Show detailed help and usage examples

### Command Line Usage
```powershell
# Download single video
.\youtube-dl.ps1 -Url "https://youtube.com/watch?v=..."
.\youtube-dl.ps1 -Url "dQw4w9WgXcQ"  # Video ID also works

# Download entire channel
.\youtube-dl.ps1 -Channel "https://youtube.com/@channelname"
.\youtube-dl.ps1 -Channel "@PrimitiveTechnology"  # @handle format
.\youtube-dl.ps1 -Channel "UC..."  # Channel ID

# Download playlist
.\youtube-dl.ps1 -Playlist "https://youtube.com/playlist?list=..."
.\youtube-dl.ps1 -Playlist "PL..."  # Playlist ID

# Search for content
.\youtube-dl.ps1 -Search "primitive technology"
.\youtube-dl.ps1 -Search "electronics tutorial"

# System management
.\youtube-dl.ps1 -Test    # Check system status
.\youtube-dl.ps1 -Setup   # Install dependencies
.\youtube-dl.ps1 -Help    # Show detailed help
```

## 🔧 How It Works

The script automatically:
- Uses yt-dlp (preferred) or youtube-dl for downloading
- Installs dependencies via pip or Chocolatey if needed
- Creates organized directory structure in `downloads/`
- Manages configuration in `config.json`
- Provides comprehensive search across all YouTube content types
- Logs activities to both main and channel-specific log files

## 📁 Directory Structure

```
downloads/
├── channels/
│   ├── ChannelName/
│   │   ├── ChannelName-download.log
│   │   └── [downloaded videos]
├── videos/
│   └── [individual videos]
└── playlists/
    └── [playlist downloads]
```

## ⚙️ Setup

The script handles setup automatically, but you can also manually install:

### Option 1: Python + pip (Recommended)
```powershell
pip install yt-dlp
```

### Option 2: Chocolatey
```powershell
choco install yt-dlp
```

### Option 3: Let the script handle it
```powershell
.\youtube-dl.ps1 -Setup
```

## 📋 Requirements

- **Windows** with PowerShell 5.1 or later
- **Internet connection**
- **Optional**: Python 3.6+ (for pip installation method)

## 📄 Files and Documentation

### Core Files
- `youtube-dl.ps1` - Main script (this is all you need!)
- `config.json` - Settings (auto-created)
- `.gitignore` - Git ignore rules
- `downloads/` - Downloaded content (auto-created)

### Documentation
- `README.md` - This file
- `CONTRIBUTING.md` - How to contribute
- `CHANGELOG.md` - Version history and changes
- `SECURITY.md` - Security policy and reporting
- `LICENSE` - MIT License
- `ExampleYoutubeChannels.md` - Example channels for testing

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 🔒 Security

Found a security issue? Please read our [Security Policy](SECURITY.md) for responsible disclosure.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Troubleshooting

### Common Issues
- **"No downloader found"**: Run `.\youtube-dl.ps1 -Setup` to install yt-dlp
- **Channel not found**: Try using the search function or verify the @handle
- **Downloads fail**: Check internet connection and try different quality settings

### Getting Help
1. Run `.\youtube-dl.ps1 -Help` for detailed usage information
2. Check the log files in the downloads directory
3. Create an issue on GitHub with error details

## 👨‍💻 Author

**Chad Kovac** ([@wrek](https://github.com/wrek))
- Email: generalchad@gmail.com
- GitHub: [github.com/wrek](https://github.com/wrek)

---

⭐ If this script helped you, please consider giving it a star on GitHub!
