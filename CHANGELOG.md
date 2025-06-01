# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive YouTube search functionality for channels, videos, and playlists
- Interactive menu system with 7 options
- Channel-specific logging system
- Enhanced command-line argument processing
- Support for @handle format URLs
- Automatic downloader installation via pip and Chocolatey
- Better error handling and user feedback
- Format optimization for MP4 with proper audio

### Changed
- Updated search functionality to find all content types (channels, videos, playlists)
- Improved URL resolution and validation
- Enhanced logging with both main and channel-specific log files
- Better directory structure organization
- Modernized channel URL handling (deprecated /c/ format warnings)

### Fixed
- Channel download failures for various URL formats
- @TheHacksmith channel download issues
- Format issues for MP4 downloads with sound
- Various syntax errors and unused variable warnings
- Menu navigation and user input validation

### Removed
- Dependency on external web scraping (now uses native yt-dlp/youtube-dl search)

## [1.0.0] - Initial Release

### Added
- Basic YouTube video, channel, and playlist downloading
- Native yt-dlp/youtube-dl integration
- Configuration management
- Logging system
- Cross-platform PowerShell support
