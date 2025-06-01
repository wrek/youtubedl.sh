# YouTube Downloader - All-in-One Script
# Handles installation, WSL setup, and downloading with fallbacks

param(
    [string]$Url,
    [string]$Channel,
    [string]$Playlist,
    [switch]$Setup,
    [switch]$Test,
    [switch]$Help,
    [switch]$Native
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

function Write-ColorOutput($Text, $Color = "White") {
    Write-Host $Text -ForegroundColor $Color
}

function Test-System {
    Write-ColorOutput "`n=== YouTube Downloader System Check ===" "Cyan"
    
    $allGood = $true
    
    # Check WSL
    try {
        $distros = wsl --list --quiet 2>$null | Where-Object { $_ -and $_.Trim() }
        if ($distros -and $distros.Count -gt 0) {
            Write-ColorOutput "✅ WSL with Linux distributions available" "Green"
            $script:HasWSL = $true
        } else {
            Write-ColorOutput "⚠️  WSL available but no Linux distributions" "Yellow"
            $script:HasWSL = $false
            $allGood = $false
        }
    } catch {
        Write-ColorOutput "❌ WSL not available" "Red"
        $script:HasWSL = $false
        $allGood = $false
    }
    
    # Check youtube-dl/yt-dlp (native)
    $ytdlp = Get-Command yt-dlp -ErrorAction SilentlyContinue
    $ytdl = Get-Command youtube-dl -ErrorAction SilentlyContinue
    
    if ($ytdlp) {
        Write-ColorOutput "✅ yt-dlp found (native)" "Green"
        $script:NativeDownloader = "yt-dlp"
    } elseif ($ytdl) {
        Write-ColorOutput "✅ youtube-dl found (native)" "Green"
        $script:NativeDownloader = "youtube-dl"
    } else {
        Write-ColorOutput "⚠️  No native downloader found" "Yellow"
        $script:NativeDownloader = $null
    }
    
    # Check config
    if (Test-Path $ConfigFile) {
        try {
            $script:Config = Get-Content $ConfigFile | ConvertFrom-Json
            Write-ColorOutput "✅ Configuration loaded" "Green"
        } catch {
            Write-ColorOutput "⚠️  Invalid config, using defaults" "Yellow"
            $script:Config = $DefaultConfig
        }
    } else {
        Write-ColorOutput "⚠️  No config found, creating default" "Yellow"
        $script:Config = $DefaultConfig
        Save-Config
    }
    
    if ($allGood -and ($script:HasWSL -or $script:NativeDownloader)) {
        Write-ColorOutput "`n🎉 System ready for downloads!" "Green"
    } else {
        Write-ColorOutput "`n⚠️  System needs setup. Use -Setup to fix issues." "Yellow"
    }
    
    return $allGood
}

function Install-WSLUbuntu {
    Write-ColorOutput "`n=== Installing WSL + Ubuntu ===" "Cyan"
    
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-ColorOutput "❌ Administrator privileges required for WSL installation" "Red"
        Write-ColorOutput "Please run PowerShell as Administrator and try again" "Yellow"
        return $false
    }
    
    try {
        Write-ColorOutput "Installing Ubuntu..." "Yellow"
        wsl --install Ubuntu
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Ubuntu installation started!" "Green"
            Write-ColorOutput "`nNext steps:" "Yellow"
            Write-ColorOutput "1. Restart your computer" "Gray"
            Write-ColorOutput "2. Ubuntu will open automatically - complete setup" "Gray"
            Write-ColorOutput "3. Run this script again" "Gray"
            return $true
        } else {
            throw "Installation failed"
        }
    } catch {
        Write-ColorOutput "❌ Automatic installation failed" "Red"
        Write-ColorOutput "`nManual installation:" "Yellow"
        Write-ColorOutput "1. Open Microsoft Store" "Gray"
        Write-ColorOutput "2. Search and install 'Ubuntu'" "Gray"
        Write-ColorOutput "3. Launch Ubuntu and complete setup" "Gray"
        return $false
    }
}

function Install-NativeDownloader {
    Write-ColorOutput "`n=== Installing Native Downloader ===" "Cyan"
    
    # Try to install yt-dlp via pip
    try {
        $python = Get-Command python -ErrorAction SilentlyContinue
        if ($python) {
            Write-ColorOutput "Installing yt-dlp via pip..." "Yellow"
            python -m pip install yt-dlp
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✅ yt-dlp installed successfully" "Green"
                return $true
            }
        }
    } catch { }
    
    # Try chocolatey
    try {
        $choco = Get-Command choco -ErrorAction SilentlyContinue
        if ($choco) {
            Write-ColorOutput "Installing yt-dlp via Chocolatey..." "Yellow"
            choco install yt-dlp -y
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✅ yt-dlp installed via Chocolatey" "Green"
                return $true
            }
        }
    } catch { }
    
    Write-ColorOutput "❌ Could not install native downloader automatically" "Red"
    Write-ColorOutput "`nManual installation options:" "Yellow"
    Write-ColorOutput "1. Install Python and run: pip install yt-dlp" "Gray"
    Write-ColorOutput "2. Install Chocolatey and run: choco install yt-dlp" "Gray"
    Write-ColorOutput "3. Download yt-dlp.exe from GitHub releases" "Gray"
    
    return $false
}

function Save-Config {
    $script:Config | ConvertTo-Json -Depth 3 | Set-Content $ConfigFile
}

function Download-Content($Url, $Type = "video") {
    if (-not $Url) {
        $Url = Read-Host "Enter YouTube URL"
    }
    
    $outputDir = $script:Config.settings.outputDir
    $quality = $script:Config.settings.quality
    
    # Expand path variables
    $outputDir = $outputDir -replace '^~', $env:USERPROFILE
    $outputDir = [System.Environment]::ExpandEnvironmentVariables($outputDir)
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $outputDir)) { 
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        Write-ColorOutput "Created output directory: $outputDir" "Green"
    }
    
    # Determine downloader and method
    if ($script:HasWSL -and -not $Native) {
        Download-ViaWSL $Url $Type $outputDir $quality
    } elseif ($script:NativeDownloader) {
        Download-ViaNative $Url $Type $outputDir $quality
    } else {
        Write-ColorOutput "❌ No downloader available. Run with -Setup to install." "Red"
        return
    }
}

function Download-ViaWSL($Url, $Type, $OutputDir, $Quality) {
    Write-ColorOutput "Downloading via WSL..." "Cyan"
    
    # Convert Windows path to WSL path
    $wslPath = $OutputDir
    if ($OutputDir -match '^[A-Z]:') {
        $drive = $OutputDir.Substring(0,1).ToLower()
        $path = $OutputDir.Substring(2) -replace '\\', '/'
        $wslPath = "/mnt/$drive$path"
    }
    
    # Build yt-dlp command based on type
    $command = "mkdir -p '$wslPath' && cd '$wslPath' && "
    
    switch ($Type) {
        "playlist" { $command += "yt-dlp -f '$Quality' --yes-playlist '$Url'" }
        "channel" { $command += "yt-dlp -f '$Quality' '$Url'" }
        default { $command += "yt-dlp -f '$Quality' '$Url'" }
    }
    
    Write-ColorOutput "Executing: $command" "Gray"
    wsl bash -c $command
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Download completed!" "Green"
        Write-ColorOutput "Files saved to: $OutputDir" "Gray"
    } else {
        Write-ColorOutput "❌ Download failed" "Red"
    }
}

function Download-ViaNative($Url, $Type, $OutputDir, $Quality) {
    Write-ColorOutput "Downloading via native $($script:NativeDownloader)..." "Cyan"
    
    Push-Location $OutputDir
    try {
        # Build command based on type  
        $args = @("-f", $Quality)
        
        switch ($Type) {
            "playlist" { $args += "--yes-playlist" }
            "channel" { 
                # For channels, might need special handling
                if ($Url -notmatch '/channel/|/@|/c/') {
                    Write-ColorOutput "⚠️  URL might not be a channel. Treating as regular download." "Yellow"
                }
            }
        }
        
        $args += $Url
        
        Write-ColorOutput "Executing: $($script:NativeDownloader) $($args -join ' ')" "Gray"
        & $script:NativeDownloader @args
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Download completed!" "Green"
            Write-ColorOutput "Files saved to: $OutputDir" "Gray"
        } else {
            Write-ColorOutput "❌ Download failed" "Red"
        }
    } finally {
        Pop-Location
    }
}

function Show-Menu {
    while ($true) {
        Clear-Host
        Write-ColorOutput "===== YouTube Downloader =====" "Cyan"
        Write-ColorOutput "1. Download Video" "White"
        Write-ColorOutput "2. Download Playlist" "White"
        Write-ColorOutput "3. Download Channel" "White"
        Write-ColorOutput "4. System Test" "White"
        Write-ColorOutput "5. Setup/Install" "White"
        Write-ColorOutput "6. Exit" "White"
        Write-ColorOutput "===============================" "Cyan"
        
        $choice = Read-Host "Enter choice (1-6)"
        
        switch ($choice) {
            "1" { Download-Content }
            "2" { 
                $url = Read-Host "Enter playlist URL"
                Download-Content $url "playlist"
            }
            "3" { 
                $url = Read-Host "Enter channel URL"
                Download-Content $url "channel"
            }
            "4" { Test-System; Read-Host "Press Enter to continue" }
            "5" { 
                Setup-System
                Read-Host "Press Enter to continue"
            }
            "6" { exit }
            default { Write-ColorOutput "Invalid choice" "Red" }
        }
    }
}

function Setup-System {
    Write-ColorOutput "`n=== System Setup ===" "Cyan"
    
    if (-not $script:HasWSL) {
        $install = Read-Host "Install WSL + Ubuntu? (y/N)"
        if ($install -eq 'y' -or $install -eq 'Y') {
            Install-WSLUbuntu
        }
    }
    
    if (-not $script:NativeDownloader) {
        $install = Read-Host "Install native downloader? (y/N)"
        if ($install -eq 'y' -or $install -eq 'Y') {
            Install-NativeDownloader
        }
    }
}

function Show-Help {
    Write-ColorOutput "`nYouTube Downloader - All-in-One Script" "Cyan"
    Write-ColorOutput "`nUsage:" "Yellow"
    Write-ColorOutput "  .\youtube-dl.ps1                    # Interactive menu" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Url <url>         # Download single video" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Playlist <url>    # Download playlist" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Channel <url>     # Download channel" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Test              # System test" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Setup             # Install/setup system" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Native            # Force native mode" "White"
    Write-ColorOutput "  .\youtube-dl.ps1 -Help              # Show this help" "White"
    Write-ColorOutput "`nThis script automatically detects and uses WSL or native downloaders." "Gray"
}

# Initialize variables
$script:HasWSL = $false
$script:NativeDownloader = $null
$script:Config = $DefaultConfig

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
    Setup-System
    exit
}

# Test system on startup
Test-System | Out-Null

# Handle command line arguments
if ($Url) {
    Download-Content $Url
} elseif ($Playlist) {
    Download-Content $Playlist "playlist"
} elseif ($Channel) {
    Download-Content $Channel "channel"
} else {
    # Show interactive menu
    Show-Menu
}
