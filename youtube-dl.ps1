# YouTube Downloader - All-in-One Script
# Handles installation and downloading with fallbacks

param(
    [Parameter(HelpMessage="Single YouTube video URL, ID, or handle")] [string]$Url,
    [Parameter(HelpMessage="Download from channel URL, ID, or handle")] [string]$Channel,
    [Parameter(HelpMessage="Download from playlist URL or ID")] [string]$Playlist,
    [Parameter(HelpMessage="Search for channels, videos, and playlists by keywords")] [string]$Search,
    [Parameter(HelpMessage="Run setup and install tools")] [switch]$Setup,
    [Parameter(HelpMessage="Run system test")] [switch]$Test,
    [Parameter(HelpMessage="Show help and usage")] [switch]$Help,
    [Parameter(HelpMessage="Force native mode (legacy, ignored)")] [switch]$Native,
    [Parameter(HelpMessage="Disable logging to youtube-dl.log")] [switch]$NoLog
)

# Configuration
$ConfigFile = "config.json"
$DefaultConfig = @{
    settings = @{
        outputDir = "~/Downloads/YouTube"
        quality = "best"
        format = "mp4"
    }
    channels = @()
}

$LogFile = "youtube-dl.log"

function Write-ChannelLog($Message, $ChannelName = $null) {
    if ($NoLog) { return }
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "$timestamp $Message"
        
        # Write to main log
        $logMessage | Out-File -FilePath $LogFile -Append -Encoding utf8
        
        # Also write to channel-specific log if channel name provided
        if ($ChannelName) {
            $channelLogFile = "downloads\channels\$ChannelName\$ChannelName-download.log"
            $channelLogDir = Split-Path $channelLogFile -Parent
            if (-not (Test-Path $channelLogDir)) {
                New-Item -ItemType Directory -Path $channelLogDir -Force | Out-Null
            }
            $logMessage | Out-File -FilePath $channelLogFile -Append -Encoding utf8
        }
    } catch {
        # Silently continue if logging fails
    }
}

function Write-ColorOutput($Text, $Color = "White") {
    Write-Host $Text -ForegroundColor $Color
    Write-ChannelLog $Text
}

function Clear-LogFile {
    if (-not $NoLog) {
        try {
            if (Test-Path $LogFile) {
                Remove-Item $LogFile -Force
            }
        } catch {
            # Silently continue if log clearing fails
        }
    }
}

function Test-System {
    Write-ColorOutput "`n=== YouTube Downloader System Check ===" "Cyan"
    $allGood = $true
    
    # Check yt-dlp/youtube-dl (native)
    $ytdlp = Get-Command yt-dlp -ErrorAction SilentlyContinue
    $ytdl = Get-Command youtube-dl -ErrorAction SilentlyContinue
    
    if ($ytdlp) {
        Write-ColorOutput "[OK] yt-dlp found (native)" "Green"
        $script:NativeDownloader = "yt-dlp"
    } elseif ($ytdl) {
        Write-ColorOutput "[OK] youtube-dl found (native)" "Green"
        $script:NativeDownloader = "youtube-dl"
    } else {
        Write-ColorOutput "[WARN] No native downloader found" "Yellow"
        $script:NativeDownloader = $null
        $allGood = $false
    }
    
    # Check config
    if (Test-Path $ConfigFile) {
        try {
            $script:Config = Get-Content $ConfigFile | ConvertFrom-Json
            Write-ColorOutput "[OK] Configuration loaded" "Green"
        } catch {
            Write-ColorOutput "[WARN] Invalid config, using defaults" "Yellow"
            $script:Config = $DefaultConfig
        }
    } else {
        Write-ColorOutput "[WARN] No config found, creating default" "Yellow"
        $script:Config = $DefaultConfig
        Save-Config
    }
    
    if ($allGood -and $script:NativeDownloader) {
        Write-ColorOutput "`n[SUCCESS] System ready for downloads!" "Green"
    } else {
        Write-ColorOutput "`n[WARN] System needs setup. Use -Setup to fix issues." "Yellow"
    }
    
    return $allGood
}

function Install-NativeDownloader {    Write-ColorOutput "`n=== Installing Native Downloader ===" "Cyan"
    Write-ChannelLog "Starting native downloader installation."
    
    # Try to install yt-dlp via pip
    try {
        $python = Get-Command python -ErrorAction SilentlyContinue        if ($python) {
            Write-ColorOutput "Installing yt-dlp via pip..." "Yellow"
            Write-ChannelLog "Running: python -m pip install yt-dlp"
            $process = Start-Process -FilePath "python" -ArgumentList "-m", "pip", "install", "yt-dlp" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Write-ColorOutput "[OK] yt-dlp installed successfully" "Green"
                Write-ChannelLog "yt-dlp installed successfully via pip."
                return $true
            } else {
                Write-ChannelLog "yt-dlp pip install failed with exit code $($process.ExitCode)."
            }
        } else {
            Write-ChannelLog "Python not found for pip install."
        }
    } catch {
        Write-ChannelLog "Exception during pip install: $_"
    }
    
    # Try chocolatey
    try {
        $choco = Get-Command choco -ErrorAction SilentlyContinue        if ($choco) {
            Write-ColorOutput "Installing yt-dlp via Chocolatey..." "Yellow"
            Write-ChannelLog "Running: choco install yt-dlp -y"
            $process = Start-Process -FilePath "choco" -ArgumentList "install", "yt-dlp", "-y" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Write-ColorOutput "[OK] yt-dlp installed via Chocolatey" "Green"
                Write-ChannelLog "yt-dlp installed successfully via Chocolatey."
                return $true
            } else {
                Write-ChannelLog "yt-dlp Chocolatey install failed with exit code $($process.ExitCode)."
            }
        } else {
            Write-ChannelLog "Chocolatey not found for install."
        }
    } catch {
        Write-ChannelLog "Exception during Chocolatey install: $_"
    }
      Write-ColorOutput "[ERROR] Could not install native downloader automatically" "Red"
    Write-ChannelLog "Automatic native downloader installation failed."
    Write-ColorOutput "`nManual installation options:" "Yellow"
    Write-ColorOutput "1. Install Python and run: pip install yt-dlp" "Gray"
    Write-ColorOutput "2. Install Chocolatey and run: choco install yt-dlp" "Gray"
    Write-ColorOutput "3. Download yt-dlp.exe from GitHub releases" "Gray"
    return $false
}

function Save-Config {
    try {
        $script:Config | ConvertTo-Json -Depth 3 | Set-Content $ConfigFile
        Write-ChannelLog "Configuration saved to $ConfigFile."
    } catch {
        Write-ColorOutput "[ERROR] Failed to save configuration: $_" "Red"        
        Write-ChannelLog "Failed to save configuration: $_"
    }
}

function Resolve-YouTubeUrl {
    param(
        [string]$InputUrl,
        [ValidateSet('video','playlist','channel')][string]$Type = 'video'
    )
    
    if ([string]::IsNullOrWhiteSpace($InputUrl)) {
        return $InputUrl
    }
    
    # More aggressive trimming of trailing characters including parentheses
    $inputTrimmed = $InputUrl.Trim().TrimEnd(')', ']', '}', '.', ',', ';', ':', '!', '?', '(', '[', '{')
    
    # If it's already a full YouTube URL, clean and return
    if ($inputTrimmed -match '^https?://(www\.)?youtube\.com|youtu\.be') {
        # Convert deprecated /c/ URLs to @handle format when possible
        if ($inputTrimmed -match 'youtube\.com/c/([^/?#]+)') {
            $channelName = $Matches[1]
            Write-ColorOutput "[WARN] Converting deprecated /c/ URL to @handle format" "Yellow"
            return "https://www.youtube.com/@$channelName"
        }
        return $inputTrimmed
    }
    
    # If it's a channel handle (e.g. @PrimitiveTechnology)
    if ($Type -eq 'channel' -and $inputTrimmed -match '^@([A-Za-z0-9_\-]+)$') {
        return "https://www.youtube.com/$inputTrimmed"
    }
    
    # If it's a channel ID (UC...)
    if ($Type -eq 'channel' -and $inputTrimmed -match '^(UC[A-Za-z0-9_-]{21,})$') {
        return "https://www.youtube.com/channel/$inputTrimmed"
    }
    
    # If it's a custom channel name, try @handle format first
    if ($Type -eq 'channel' -and $inputTrimmed -match '^[A-Za-z0-9_\-]+$') {
        return "https://www.youtube.com/@$inputTrimmed"
    }
    
    # If it's a playlist ID (PL..., UU..., RD..., FL...)
    if ($Type -eq 'playlist' -and $inputTrimmed -match '^(PL|UU|RD|FL)[A-Za-z0-9_-]+$') {
        return "https://www.youtube.com/playlist?list=$inputTrimmed"
    }
    
    # If it's a video ID (11 chars, typical YouTube video ID)
    if ($Type -eq 'video' -and $inputTrimmed -match '^[A-Za-z0-9_-]{11}$') {
        return "https://youtu.be/$inputTrimmed"
    }
    
    # Handle partial URLs that start with youtube.com but missing protocol
    if ($inputTrimmed -match '^youtube\.com' -and $inputTrimmed -notmatch '^https?://') {
        return "https://$inputTrimmed"
    }
    
    # Handle partial URLs that start with www.youtube.com but missing protocol
    if ($inputTrimmed -match '^www\.youtube\.com' -and $inputTrimmed -notmatch '^https?://') {
        return "https://$inputTrimmed"
    }
      # Fallback: return as-is
    return $inputTrimmed
}

function Resolve-Input {
    param([string]$InputValue)
    
    if ([string]::IsNullOrWhiteSpace($InputValue)) {
        return @{ Type = "unknown"; Value = $InputValue }
    }
    
    $cleanInput = $InputValue.Trim()
    
    # Check if it's a URL
    if ($cleanInput -match '^https?://' -or $cleanInput -match '^youtube\.com' -or $cleanInput -match '^youtu\.be') {
        $urlType = Get-YouTubeUrlType $cleanInput
        return @{ Type = $urlType; Value = $cleanInput }
    }
    
    # Check if it's a handle (@username)
    if ($cleanInput -match '^@[A-Za-z0-9_\-]+$') {
        return @{ Type = "channel"; Value = $cleanInput }
    }
    
    # Check if it's a video ID (11 chars)
    if ($cleanInput -match '^[A-Za-z0-9_-]{11}$') {
        return @{ Type = "video"; Value = $cleanInput }
    }
    
    # Check if it's a channel ID (UC...)
    if ($cleanInput -match '^UC[A-Za-z0-9_-]{21,}$') {
        return @{ Type = "channel"; Value = $cleanInput }
    }
    
    # Check if it's a playlist ID (PL..., UU..., RD..., FL...)
    if ($cleanInput -match '^(PL|UU|RD|FL)[A-Za-z0-9_-]+$') {
        return @{ Type = "playlist"; Value = $cleanInput }
    }
    
    # Check if it's a simple channel name (likely for @handle conversion)
    if ($cleanInput -match '^[A-Za-z0-9_\-]+$' -and $cleanInput.Length -le 50) {
        return @{ Type = "channel"; Value = $cleanInput }
    }
    
    # Otherwise, treat as search query
    return @{ Type = "search"; Value = $cleanInput }
}

function Invoke-ContentDownload {
    param(
        [string]$Url, 
        [string]$Type = "video"
    )
    
    if ([string]::IsNullOrWhiteSpace($Url)) {
        $Url = Read-Host "Enter YouTube URL, ID, or handle"
        if ([string]::IsNullOrWhiteSpace($Url)) {
            Write-ColorOutput "[ERROR] No URL provided" "Red"
            return
        }
    }
    
    $Url = Resolve-YouTubeUrl -InputUrl $Url -Type $Type
    
    # Get the script's directory properly
    if ($MyInvocation.MyCommand.Definition) {
        $baseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    } else {
        $baseDir = Get-Location
    }
    
    # Ensure baseDir is not null or empty
    if ([string]::IsNullOrWhiteSpace($baseDir)) {
        $baseDir = $PWD.Path
    }    # Create downloads subfolder structure
    $downloadsDir = Join-Path $baseDir "downloads"
    $quality = $script:Config.settings.quality
    $channelName = $null
    
    if ($Type -eq "channel") {
        # Try to extract channel name from URL
        if ($Url -match "/channel/([^/?#]+)") {
            $channelName = $Matches[1]
        } elseif ($Url -match "/@([^/?#]+)") {
            $channelName = $Matches[1].TrimStart('@')
        } elseif ($Url -match "/c/([^/?#]+)") {
            $channelName = $Matches[1]
            Write-ColorOutput "[WARN] /c/ URLs are deprecated. Script will try @handle format." "Yellow"
        } elseif ($Url -match "/user/([^/?#]+)") {
            $channelName = $Matches[1]
            Write-ColorOutput "[WARN] /user/ URLs may not always work. Prefer /channel/ or /@ URLs for best results." "Yellow"
        } elseif ($Url -match "youtube.com/([^/?#]+)") {
            $channelName = $Matches[1]
        } else {
            Write-ColorOutput "[WARN] Unrecognized channel URL format. Using fallback directory." "Yellow"
        }
        
        if ($channelName) {
            # Sanitize channel name for filesystem
            $channelName = $channelName -replace '[<>:"/\\|?*]', '_'
            $outputDir = Join-Path $downloadsDir "channels\$channelName"
        } else {
            $outputDir = Join-Path $downloadsDir "channels\UnknownChannel"
        }
    } elseif ($Type -eq "playlist") {
        # Create playlists subdirectory
        $outputDir = Join-Path $downloadsDir "playlists"
    } else {
        # Create videos subdirectory for single videos
        $outputDir = Join-Path $downloadsDir "videos"
    }
    
    # Validate output directory path
    if ([string]::IsNullOrWhiteSpace($outputDir)) {
        Write-ColorOutput "[ERROR] Failed to determine output directory" "Red"
        Write-ChannelLog "Failed to determine output directory. BaseDir: $baseDir, Type: $Type"
        return
    }
      # Create output directory if it doesn't exist (only log once)
    if (-not (Test-Path $outputDir)) {
        try {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            Write-ColorOutput "Created output directory: $outputDir" "Green"
            Write-ChannelLog "Created output directory: $outputDir"
        } catch {
            Write-ColorOutput "[ERROR] Failed to create output directory: $_" "Red"
            Write-ChannelLog "Failed to create output directory: $_"
            return
        }
    } else {
        Write-ColorOutput "Using existing directory: $outputDir" "Gray"
        Write-ChannelLog "Using existing directory: $outputDir"
    }
      # Use native downloader only
    if ($script:NativeDownloader) {
        Invoke-DownloadNative $Url $Type $outputDir $quality
    } else {
        Write-ColorOutput "[ERROR] No downloader available. Run with -Setup to install." "Red"
        Write-ChannelLog "No downloader available. User prompted to run setup."
        return
    }
}

function Invoke-DownloadNative {
    param(
        [string]$Url, 
        [string]$Type, 
        [string]$OutputDir, 
        [string]$Quality
    )
    
    Write-ColorOutput "Downloading via native $($script:NativeDownloader)..." "Cyan"
    
    # Extract channel name for logging if this is a channel download
    $channelName = $null
    if ($Type -eq "channel") {
        if ($Url -match "/@([^/?#]+)") {
            $channelName = $Matches[1].TrimStart('@')
        } elseif ($Url -match "/channel/([^/?#]+)") {
            $channelName = $Matches[1]
        } elseif ($Url -match "/c/([^/?#]+)") {
            $channelName = $Matches[1]
        } elseif ($Url -match "/user/([^/?#]+)") {
            $channelName = $Matches[1]
        }
    }
      Write-Log "Starting download: $Url as $Type to $OutputDir with quality $Quality using $($script:NativeDownloader)" $channelName
    
    # Validate parameters
    if ([string]::IsNullOrWhiteSpace($OutputDir)) {
        Write-ColorOutput "[ERROR] Output directory is null or empty" "Red"
        Write-Log "Output directory is null or empty" $channelName
        return
    }
    
    if (-not (Test-Path $OutputDir)) {
        Write-ColorOutput "[ERROR] Output directory does not exist: $OutputDir" "Red"
        Write-Log "Output directory does not exist: $OutputDir" $channelName
        return
    }
    
    $originalLocation = Get-Location
    try {
        Set-Location $OutputDir
          # Use mp4 format with best quality audio and video
        $dlArgs = @("--progress", "--newline", "--no-warnings")
        
        # Force mp4 format with best quality audio/video combination
        $dlArgs += @("-f", "best[ext=mp4]/bestvideo[ext=mp4]+bestaudio[ext=m4a]/best")
        
        switch ($Type) {
            "playlist" { 
                $dlArgs += "--yes-playlist" 
                Write-ColorOutput "Note: This may take a while for large playlists..." "Yellow"
            }
            "channel" { 
                # Add channel-specific options
                $dlArgs += "--write-info-json"
                Write-ColorOutput "Note: Channel downloads can take a very long time. Press Ctrl+C to cancel." "Yellow"
                if ($Url -notmatch '/channel/|/@|/c/|/user/') {
                    Write-ColorOutput "[WARN] URL might not be a channel. Treating as regular download." "Yellow"
                    Write-Log "URL might not be a channel: $Url"
                }
            }
        }
        $dlArgs += $Url
        
        Write-ColorOutput "Executing: $($script:NativeDownloader) $($dlArgs -join ' ')" "Gray"
        Write-Log "Executing: $($script:NativeDownloader) $($dlArgs -join ' ')"
        Write-Log "Working directory set to: $OutputDir"
        
        # Create temp files with unique names to avoid conflicts
        $tempOutput = "temp_output_$(Get-Random).txt"
        $tempError = "temp_error_$(Get-Random).txt"
          try {
            # Use direct process execution with timeout monitoring
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $script:NativeDownloader
            $psi.Arguments = $dlArgs -join ' '
            $psi.UseShellExecute = $false
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.CreateNoWindow = $true
            $psi.WorkingDirectory = $OutputDir
            
            Write-Log "Working directory set to: $OutputDir" $channelName
            
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $psi
            
            # Event handlers for real-time output
            $outputReceived = {
                param($obj, $data)
                if ($data.Data) {
                    Write-Host $data.Data -ForegroundColor Gray
                    Write-Log "yt-dlp: $($data.Data)" $channelName
                }
            }
            
            $errorReceived = {
                param($obj, $data)
                if ($data.Data) {
                    Write-Host $data.Data -ForegroundColor Yellow
                    Write-Log "yt-dlp error: $($data.Data)" $channelName
                }
            }
            
            Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action $outputReceived | Out-Null
            Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action $errorReceived | Out-Null
            
            Write-ColorOutput "Starting download process..." "Cyan"
            $process.Start() | Out-Null
            $process.BeginOutputReadLine()
            $process.BeginErrorReadLine()
            
            # Wait for process with periodic status updates
            $timeout = 3600000  # 1 hour timeout
            $checkInterval = 30000  # Check every 30 seconds
            $elapsed = 0
            
            while (-not $process.HasExited -and $elapsed -lt $timeout) {
                Start-Sleep -Milliseconds $checkInterval
                $elapsed += $checkInterval
                
                if ($elapsed % 120000 -eq 0) {  # Every 2 minutes
                    Write-ColorOutput "[INFO] Download still in progress... (Press Ctrl+C to cancel)" "Cyan"
                }            }
            
            if (-not $process.HasExited) {
                Write-ColorOutput "[WARN] Download timed out after 1 hour. Terminating process." "Yellow"
                $process.Kill()
                $process.WaitForExit(5000)
                Write-Log "Download process terminated due to timeout." $channelName
            } else {
                $process.WaitForExit()
            }
              # Clean up event handlers
            Get-EventSubscriber | Where-Object {$_.SourceObject -eq $process} | Unregister-Event
            
            if ($process.ExitCode -eq 0) {
                Write-ColorOutput "[SUCCESS] Download completed!" "Green"
                Write-ColorOutput "Files saved to: $OutputDir" "Gray"
                Write-Log "Download completed successfully." $channelName
            } else {
                Write-ColorOutput "[ERROR] Download failed with exit code $($process.ExitCode)" "Red"
                Write-Log "Download failed with exit code $($process.ExitCode)." $channelName
                
                # Check for specific errors and provide suggestions
                if ($Url -match "/c/") {
                    Write-ColorOutput "`n[TIP] The /c/ URL format is deprecated. Try these alternatives:" "Cyan"
                    $channelName = ($Url -split "/c/")[1] -split "[/?#]" | Select-Object -First 1
                    Write-ColorOutput "   @$channelName" "Gray"
                    Write-ColorOutput "   Or search for the channel's current @handle on YouTube" "Gray"
                } elseif ($Type -eq "channel" -and $process.ExitCode -eq 1) {
                    Write-ColorOutput "`n[TIP] Channel not found. This could be due to:" "Cyan"
                    Write-ColorOutput "   • Incorrect channel handle (case sensitive)" "Gray"
                    Write-ColorOutput "   • Channel has been renamed or deleted" "Gray"
                    Write-ColorOutput "   • Channel is private or restricted" "Gray"
                    Write-ColorOutput "   • Try searching for the channel instead:" "Gray"
                    if ($Url -match "/@([^/?#]+)") {
                        $searchTerm = $Matches[1]
                        Write-ColorOutput "     .\youtube-dl.ps1 -Search '$searchTerm'" "Gray"
                    }
                }
            }
            
        } finally {
            # Cleanup
            if ($process) {
                if (-not $process.HasExited) {
                    try { $process.Kill() } catch { }
                }
                $process.Dispose()
            }
        }
        
    } catch {
        Write-ColorOutput "[ERROR] Exception during download: $_" "Red"
        Write-Log "Exception during download: $_"
    } finally {        # Clean up temp files
        if (Test-Path $tempOutput) { Remove-Item $tempOutput -ErrorAction SilentlyContinue }
        if (Test-Path $tempError) { Remove-Item $tempError -ErrorAction SilentlyContinue }
        Set-Location $originalLocation
    }
}

function Search-YouTubeChannels {
    param([string]$SearchQuery)
    
    if ([string]::IsNullOrWhiteSpace($SearchQuery)) {
        $SearchQuery = Read-Host "Enter search terms for YouTube channels"
        if ([string]::IsNullOrWhiteSpace($SearchQuery)) {
            Write-ColorOutput "[ERROR] No search query provided" "Red"
            return
        }
    }
    
    Write-ColorOutput "`n=== Searching YouTube for: '$SearchQuery' ===" "Cyan"
    Write-Log "Starting YouTube search for: $SearchQuery"
    
    if (-not $script:NativeDownloader) {
        Write-ColorOutput "[ERROR] No downloader available. Run with -Setup to install." "Red"
        Write-Log "No downloader available for search."
        return
    }
    
    try {
        # Use yt-dlp to search for channels
        $searchArgs = @(
            "--quiet", 
            "--no-warnings",
            "--dump-json",
            "--playlist-end", "10",  # Limit to 10 results
            "ytsearch10:$SearchQuery channel"
        )
        
        Write-ColorOutput "Searching..." "Yellow"
        Write-Log "Executing: $($script:NativeDownloader) $($searchArgs -join ' ')"
        
        $searchResults = & $script:NativeDownloader $searchArgs 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $searchResults) {
            $channels = @()
            $searchResults | ForEach-Object {
                try {
                    $result = $_ | ConvertFrom-Json
                    if ($result.channel_url -and $result.channel) {
                        $channels += [PSCustomObject]@{
                            Name = $result.channel
                            URL = $result.channel_url
                            Description = if ($result.description) { $result.description.Substring(0, [Math]::Min(100, $result.description.Length)) + "..." } else { "No description" }
                            VideoTitle = $result.title
                        }
                    }
                } catch {
                    # Skip invalid JSON entries
                }
            }
            
            # Remove duplicates based on channel URL
            $uniqueChannels = $channels | Group-Object URL | ForEach-Object { $_.Group[0] }
            
            if ($uniqueChannels.Count -gt 0) {
                Write-ColorOutput "`nFound $($uniqueChannels.Count) channels:" "Green"
                Write-ColorOutput "==============================" "Cyan"
                
                for ($i = 0; $i -lt $uniqueChannels.Count; $i++) {
                    $channel = $uniqueChannels[$i]
                    Write-ColorOutput "$($i + 1). $($channel.Name)" "White"
                    Write-ColorOutput "   URL: $($channel.URL)" "Gray"
                    Write-ColorOutput "   Sample: $($channel.VideoTitle)" "Gray"
                    Write-ColorOutput "   Description: $($channel.Description)" "Gray"
                    Write-ColorOutput "" "White"
                }
                  Write-ColorOutput "Options:" "Cyan"
                Write-ColorOutput "- Enter number (1-$($uniqueChannels.Count)) to download that channel" "Gray"
                Write-ColorOutput "- Enter 'a' to download ALL channels" "Gray"
                Write-ColorOutput "- Enter 'q' to quit" "Gray"                while ($true) {
                    $choice = Read-Host "`nYour choice"
                    Write-Log "User entered choice: '$choice'"
                    
                    if ($choice -eq 'q' -or $choice -eq 'Q') {
                        Write-Log "User chose to quit"
                        return
                    } elseif ($choice -eq 'a' -or $choice -eq 'A') {
                        Write-ColorOutput "`nDownloading ALL channels..." "Yellow"
                        Write-Log "User chose to download all channels"
                        foreach ($channel in $uniqueChannels) {
                            Write-ColorOutput "`nDownloading: $($channel.Name)" "Cyan"
                            Invoke-ContentDownload $channel.URL "channel"
                        }
                        break
                    } else {
                        try {
                            $num = [int]$choice
                            Write-Log "Parsed choice as number: $num (valid range: 1-$($uniqueChannels.Count))"
                            if ($num -ge 1 -and $num -le $uniqueChannels.Count) {
                                $selectedChannel = $uniqueChannels[$num - 1]
                                Write-ColorOutput "`nDownloading: $($selectedChannel.Name)" "Cyan"
                                Write-Log "User selected channel: $($selectedChannel.Name)"
                                Invoke-ContentDownload $selectedChannel.URL "channel"
                                break
                            } else {
                                Write-ColorOutput "Invalid choice. Please enter 1-$($uniqueChannels.Count), 'a', or 'q'." "Red"
                                Write-Log "Choice $num is out of range (1-$($uniqueChannels.Count))"
                            }
                        } catch {
                            Write-ColorOutput "Invalid choice. Please enter 1-$($uniqueChannels.Count), 'a', or 'q'." "Red"
                            Write-Log "Failed to parse choice '$choice' as number: $_"
                        }
                    }
                }
                
            } else {
                Write-ColorOutput "`nNo channels found for '$SearchQuery'" "Yellow"
                Write-ColorOutput "Try different search terms or check spelling." "Gray"
            }
        } else {
            Write-ColorOutput "`nSearch failed or no results found for '$SearchQuery'" "Yellow"
            Write-ColorOutput "Try different search terms." "Gray"
            Write-Log "Search failed with exit code: $LASTEXITCODE"
        }
        
    } catch {
        Write-ColorOutput "[ERROR] Search failed: $_" "Red"
        Write-Log "Search exception: $_"
    }
}

function Write-Log($Message, $ChannelName = $null) {
    Write-ChannelLog $Message $ChannelName
}

function Search-YouTubeContent {
    param([string]$SearchQuery)
    
    if ([string]::IsNullOrWhiteSpace($SearchQuery)) {
        $SearchQuery = Read-Host "Enter search terms for YouTube content"
        if ([string]::IsNullOrWhiteSpace($SearchQuery)) {
            Write-ColorOutput "[ERROR] No search query provided" "Red"
            return
        }
    }
    
    Write-ColorOutput "`n=== Comprehensive YouTube Search for: '$SearchQuery' ===" "Cyan"
    Write-Log "Starting comprehensive YouTube search for: $SearchQuery"
    
    if (-not $script:NativeDownloader) {
        Write-ColorOutput "[ERROR] No downloader available. Run with -Setup to install." "Red"
        Write-Log "No downloader available for search."
        return
    }
    
    try {
        Write-ColorOutput "Searching for channels, videos, and playlists..." "Yellow"
        
        # Search for mixed content (channels, videos, playlists)
        $searchArgs = @(
            "--quiet", 
            "--no-warnings",
            "--dump-json",
            "--playlist-end", "15",  # Get more results
            "ytsearch15:$SearchQuery"
        )
        
        Write-Log "Executing: $($script:NativeDownloader) $($searchArgs -join ' ')"
        Write-ColorOutput "Please wait, this may take a moment..." "Gray"
        
        $searchResults = & $script:NativeDownloader $searchArgs 2>$null
        Write-Log "Search completed with exit code: $LASTEXITCODE"
          if ($LASTEXITCODE -eq 0 -and $searchResults) {
            $channels = @()
            $videos = @()
            
            Write-Log "Processing search results..."
            $resultCount = 0
            
            $searchResults | ForEach-Object {
                try {
                    $result = $_ | ConvertFrom-Json
                    $resultCount++
                    Write-Log "Processing result $resultCount`: $($result.title)"
                    
                    # Categorize results
                    if ($result.channel_url -and $result.channel) {
                        # This is channel information
                        $existingChannel = $channels | Where-Object { $_.URL -eq $result.channel_url }
                        if (-not $existingChannel) {
                            $channels += [PSCustomObject]@{
                                Name = $result.channel
                                URL = $result.channel_url
                                Description = if ($result.description) { $result.description.Substring(0, [Math]::Min(100, $result.description.Length)) + "..." } else { "No description" }
                                SampleVideo = $result.title
                                Type = "Channel"
                            }
                        }
                    }
                    
                    # Also add individual videos
                    if ($result.title -and $result.webpage_url) {
                        $videos += [PSCustomObject]@{
                            Title = $result.title
                            URL = $result.webpage_url
                            Channel = $result.channel
                            Duration = if ($result.duration) { [TimeSpan]::FromSeconds($result.duration).ToString("mm\:ss") } else { "Unknown" }
                            Description = if ($result.description) { $result.description.Substring(0, [Math]::Min(100, $result.description.Length)) + "..." } else { "No description" }
                            Type = "Video"
                        }
                    }
                    
                    # Check for playlists (this would need additional search)
                } catch {
                    Write-Log "Failed to process search result: $_"
                }
            }
            
            Write-Log "Found $($channels.Count) unique channels, $($videos.Count) videos"
            
            # Display results
            $allResults = @()
            $allResults += $channels
            $allResults += $videos | Select-Object -First 10  # Limit videos to prevent overwhelming
            
            if ($allResults.Count -gt 0) {
                Write-ColorOutput "`nFound $($allResults.Count) results:" "Green"
                Write-ColorOutput "==================================" "Cyan"
                
                for ($i = 0; $i -lt $allResults.Count; $i++) {
                    $item = $allResults[$i]
                    $typeColor = if ($item.Type -eq "Channel") { "Yellow" } else { "White" }
                    
                    Write-ColorOutput "$($i + 1). [$($item.Type)] " -NoNewline
                    Write-ColorOutput "$(if ($item.Type -eq 'Channel') { $item.Name } else { $item.Title })" $typeColor
                    
                    if ($item.Type -eq "Channel") {
                        Write-ColorOutput "   URL: $($item.URL)" "Gray"
                        Write-ColorOutput "   Sample Video: $($item.SampleVideo)" "Gray"
                    } else {
                        Write-ColorOutput "   Channel: $($item.Channel)" "Gray"
                        Write-ColorOutput "   Duration: $($item.Duration)" "Gray"
                        Write-ColorOutput "   URL: $($item.URL)" "Gray"
                    }
                    Write-ColorOutput "   Description: $($item.Description)" "Gray"
                    Write-ColorOutput "" "White"
                }
                
                Write-ColorOutput "Options:" "Cyan"
                Write-ColorOutput "- Enter number (1-$($allResults.Count)) to download that item" "Gray"
                Write-ColorOutput "- Enter 'c' to download ALL channels only" "Gray"
                Write-ColorOutput "- Enter 'v' to download ALL videos only" "Gray"
                Write-ColorOutput "- Enter 'a' to download EVERYTHING" "Gray"
                Write-ColorOutput "- Enter 'q' to quit" "Gray"                while ($true) {
                    $choice = Read-Host "`nYour choice"
                    Write-Log "User entered choice: '$choice'" 
                    
                    if ($choice -eq 'q' -or $choice -eq 'Q') {
                        Write-Log "User chose to quit search"
                        return
                    } elseif ($choice -eq 'c' -or $choice -eq 'C') {
                        Write-ColorOutput "`nDownloading ALL channels..." "Yellow"
                        Write-Log "User chose to download all channels ($($channels.Count) channels)"
                        foreach ($channel in $channels) {
                            Write-ColorOutput "`nDownloading Channel: $($channel.Name)" "Cyan"
                            Invoke-ContentDownload $channel.URL "channel"
                        }
                        break
                    } elseif ($choice -eq 'v' -or $choice -eq 'V') {
                        Write-ColorOutput "`nDownloading ALL videos..." "Yellow"
                        Write-Log "User chose to download all videos ($($videos.Count) videos)"
                        foreach ($video in $videos) {
                            Write-ColorOutput "`nDownloading Video: $($video.Title)" "Cyan"
                            Invoke-ContentDownload $video.URL "video"
                        }
                        break
                    } elseif ($choice -eq 'a' -or $choice -eq 'A') {
                        Write-ColorOutput "`nDownloading EVERYTHING..." "Yellow"
                        Write-Log "User chose to download everything"
                        foreach ($channel in $channels) {
                            Write-ColorOutput "`nDownloading Channel: $($channel.Name)" "Cyan"
                            Invoke-ContentDownload $channel.URL "channel"
                        }
                        foreach ($video in $videos) {
                            Write-ColorOutput "`nDownloading Video: $($video.Title)" "Cyan"
                            Invoke-ContentDownload $video.URL "video"
                        }
                        break
                    } elseif ($choice -ge 1 -and $choice -le $allResults.Count) {
                        $selectedItem = $allResults[$choice - 1]
                        $downloadType = if ($selectedItem.Type -eq "Channel") { "channel" } else { "video" }
                        $itemName = if ($selectedItem.Type -eq "Channel") { $selectedItem.Name } else { $selectedItem.Title }
                        
                        Write-ColorOutput "`nDownloading $($selectedItem.Type): $itemName" "Cyan"
                        Write-Log "User selected $($selectedItem.Type): $itemName"
                        Invoke-ContentDownload $selectedItem.URL $downloadType
                        break
                    } else {
                        Write-ColorOutput "Invalid choice. Please enter 1-$($allResults.Count), 'c', 'v', 'a', or 'q'." "Red"
                        Write-Log "Choice $choice is out of range (1-$($allResults.Count))"
                    }
                }
                
            } else {
                Write-ColorOutput "`nNo results found for '$SearchQuery'" "Yellow"
                Write-ColorOutput "Try different search terms or check spelling." "Gray"
                Write-Log "No results found for search query: $SearchQuery"
            }
        } else {
            Write-ColorOutput "`nSearch failed or no results found for '$SearchQuery'" "Yellow"
            Write-ColorOutput "Try different search terms." "Gray"
            Write-Log "Search failed with exit code: $LASTEXITCODE"
        }
        
    } catch {
        Write-ColorOutput "[ERROR] Search failed: $_" "Red"
        Write-Log "Search exception: $_"
    }
}

function Show-Menu {
    Write-ColorOutput "`n=== YouTube Downloader ===" "Cyan"
    Write-ColorOutput "================================" "Cyan"
    Write-ColorOutput "1. Download Single Video" "White"
    Write-ColorOutput "2. Download Channel" "White"
    Write-ColorOutput "3. Download Playlist" "White"
    Write-ColorOutput "4. Comprehensive Search" "White"
    Write-ColorOutput "5. System Test" "White"
    Write-ColorOutput "6. Setup/Install Tools" "White"
    Write-ColorOutput "7. Exit" "White"
    Write-ColorOutput "================================" "Cyan"
    
    do {
        $choice = Read-Host "`nSelect option (1-7)"
        Write-ChannelLog "User menu choice: $choice"
        
        switch ($choice) {
            "1" {
                $url = Read-Host "Enter video URL or ID"
                if (![string]::IsNullOrWhiteSpace($url)) {
                    Invoke-ContentDownload $url "video"
                }
                return
            }            "2" {
                $channel = Read-Host "Enter channel URL, handle (@username), or search term"
                if (![string]::IsNullOrWhiteSpace($channel)) {
                    $inputAnalysis = Resolve-Input $channel
                    if ($inputAnalysis.Type -eq "search") {
                        Write-ColorOutput "Input detected as search query. Using comprehensive search..." "Cyan"
                        Search-YouTubeContent $channel
                    } else {
                        Invoke-ContentDownload $channel "channel"
                    }
                }
                return
            }
            "3" {
                $playlist = Read-Host "Enter playlist URL or ID"
                if (![string]::IsNullOrWhiteSpace($playlist)) {
                    Invoke-ContentDownload $playlist "playlist"
                }
                return
            }
            "4" {
                $searchTerm = Read-Host "Enter search terms for comprehensive search"
                if (![string]::IsNullOrWhiteSpace($searchTerm)) {
                    Search-YouTubeContent $searchTerm
                }
                return
            }
            "5" {
                Test-System
                Read-Host "`nPress Enter to continue"
                Show-Menu
                return
            }
            "6" {
                Test-System
                Initialize-System
                Read-Host "`nPress Enter to continue"
                Show-Menu
                return
            }
            "7" {
                Write-ColorOutput "Goodbye!" "Green"
                Write-ChannelLog "User chose to exit"
                return
            }
            default {
                Write-ColorOutput "Invalid choice. Please select 1-7." "Red"
            }
        }
    } while ($true)
}

function Initialize-System {
    Write-ColorOutput "`n=== System Initialization ===" "Cyan"
    
    if (-not $script:NativeDownloader) {
        Write-ColorOutput "Installing native downloader..." "Yellow"
        if (Install-NativeDownloader) {
            Write-ColorOutput "Installation successful!" "Green"
        } else {
            Write-ColorOutput "Installation failed. Please install manually." "Red"
            return $false
        }
    }
    
    # Create directory structure
    $dirs = @("downloads", "downloads\channels", "downloads\videos", "downloads\playlists")
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-ColorOutput "Created directory: $dir" "Green"
        }
    }
    
    Save-Config
    Write-ColorOutput "System initialization complete!" "Green"
    return $true
}

function Show-Help {
    Write-ColorOutput "`n=== YouTube Downloader Help ===" "Cyan"
    Write-ColorOutput "================================" "Cyan"
    Write-ColorOutput ""
    Write-ColorOutput "USAGE:" "Yellow"
    Write-ColorOutput "  .\youtube-dl.ps1                    # Interactive menu (recommended)" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Url <url>         # Download single video" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Channel <channel> # Download entire channel" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Playlist <list>   # Download playlist" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Search <terms>    # Comprehensive search" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Test              # System check" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Setup             # Install/setup tools" "White"
    Write-ColorOutput ""
    Write-ColorOutput "EXAMPLES:" "Yellow"
    Write-ColorOutput "  .\youtube-dl.ps1 -Url 'https://youtu.be/dQw4w9WgXcQ'" "Gray"
    Write-ColorOutput "  .\youtube-dl.ps1 -Channel '@PrimitiveTechnology'" "Gray"
    Write-ColorOutput "  .\youtube-dl.ps1 -Search 'primitive technology'" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "FEATURES:" "Yellow"
    Write-ColorOutput "  - Automatic format detection (MP4 with best quality)" "White"
    Write-ColorOutput "  - Channel-specific logging" "White"
    Write-ColorOutput "  - Comprehensive search (channels, videos, playlists)" "White"
    Write-ColorOutput "  - Smart input detection" "White"
    Write-ColorOutput "  - Organized directory structure" "White"
    Write-ColorOutput ""
    Write-ColorOutput "FILES:" "Yellow"
    Write-ColorOutput "  downloads/channels/   # Channel downloads" "Gray"
    Write-ColorOutput "  downloads/videos/     # Individual videos" "Gray"
    Write-ColorOutput "  downloads/playlists/  # Playlist downloads" "Gray"
    Write-ColorOutput "  youtube-dl.log        # Main log file" "Gray"
    Write-ColorOutput "  config.json           # Configuration settings" "Gray"
}

# Initialize variables
$script:NativeDownloader = $null
$script:Config = $DefaultConfig

# Clear log file on startup
Clear-LogFile

# Main execution
if ($Help) {
    Show-Help
    exit
}

if ($Test) {
    Test-System
    exit
}

if ($Setup) {
    Test-System
    Initialize-System
    exit
}

# Test system on startup
Test-System | Out-Null

# Handle command line arguments - Smart detection for any input type
if ($Url) {
    $inputAnalysis = Resolve-Input $Url
    switch ($inputAnalysis.Type) {
        "search" {
            Write-ColorOutput "Input detected as search query. Using comprehensive search..." "Cyan"
            Search-YouTubeContent $Url
        }
        default {
            Invoke-ContentDownload $Url $inputAnalysis.Type
        }
    }
} elseif ($Playlist) {
    Invoke-ContentDownload $Playlist "playlist"
} elseif ($Channel) {
    $inputAnalysis = Resolve-Input $Channel
    if ($inputAnalysis.Type -eq "search") {
        Write-ColorOutput "Channel input detected as search query. Using comprehensive search..." "Cyan"
        Search-YouTubeContent $Channel
    } else {
        Invoke-ContentDownload $Channel "channel"    }
} elseif ($Search) {
    Search-YouTubeContent $Search
} else {
    # Show interactive menu
    Show-Menu
}
