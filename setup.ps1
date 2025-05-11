param([switch]$Elevated)

if (-not $Elevated) {
    Write-Host "Restarting script with Administrator privileges..."
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Elevated"
    exit
}

Write-Host "Administrator access confirmed. Proceeding..."
Write-Host "path: $PSScriptRoot"

Set-Location -Path $PSScriptRoot
Write-Host "path: $PSScriptRoot"


$architecture = (Get-CimInstance Win32_OperatingSystem).OSArchitecture

$expectedVersion = "8.4.7"

$phpZip = "php.zip"
$phpDir = "php"
$shareDir = "share"



if ($architecture -eq "64-bit") {
    $phpUrl = "https://windows.php.net/downloads/releases/php-$expectedVersion-Win32-vs17-x64.zip"
} elseif ($architecture -eq "32-bit") {
    $phpUrl = "https://windows.php.net/downloads/releases/php-$expectedVersion-Win32-vs17-x86.zip"
} else {
    Write-Host "Could not determine the operating system architecture. Detected value: $architecture"
    exit
}

# Functions
function CreateShareDirectory {
    param([string]$shareDir)
    
    Write-Host "Creating 'share' directory..."
    New-Item -Path $shareDir -ItemType Directory
}

function DownloadPHP {
    param([string]$phpUrl , [string]$phpZip)

    Write-Host "Downloading PHP..."
    Invoke-WebRequest -Uri $phpUrl -OutFile $phpZip
    
}
function ExtractPHPZip {
    param([string]$phpZip , [string]$phpDir)
    
    Write-Host "Extracting PHP..."
    Expand-Archive -Path $phpZip -DestinationPath $phpDir -Force

}

function DeletePHPZip {
    param([string]$phpZip)
    
    Write-Host "Deleting php.zip after successful extraction..."
    Remove-Item $phpZip -Force

}

function RemovePHPFolder {    
    Remove-Item -Path .\php -Recurse -Force
}


function InstallApp {
    param([string]$phpUrl, [string]$phpZip, [string]$phpDir)
    
     DownloadPHP $phpUrl $phpZip
     ExtractPHPZip $phpZip $phpDir

     if (Test-Path $phpDir) {
        DeletePHPZip $phpZip
    }

}




if (-Not (Test-Path $shareDir)) {
    CreateShareDirectory $shareDir
}

if (-Not (Test-Path $phpZip) -and -Not (Test-Path $phpDir)) {
 
    InstallApp $phpUrl $phpZip $phpDir

}
elseif ((Test-Path $phpZip) -and (-Not (Test-Path $phpDir))) {

    ExtractPHPZip $phpZip $phpDir

    if (Test-Path $phpDir) {

         DeletePHPZip $phpZip
    }
}
else {
    Write-Host "PHP already downloaded and extracted. Skipping..."

    if (Test-Path $phpZip) {

         DeletePHPZip $phpZip
    }
}




$phpExecutable = ".\php\php.exe"
$currentVersion = $null

$phpOutput = & $phpExecutable -v 2>&1 | Out-String


if ($phpOutput -match "PHP\s+([0-9\.]+)") {
    $currentVersion = $Matches[1]
}

if ($currentVersion -eq $expectedVersion) {
    Write-Host "PHP version $expectedVersion is installed and up to date."

} else {
    if ($currentVersion) {
        Write-Host "PHP update required. Current version: $currentVersion, Required version: $expectedVersion."

         RemovePHPFolder
         InstallApp $phpUrl $phpZip $phpDir

    } else {
        Write-Host "PHP installation or update to version $expectedVersion is required."
    }
}

$localIP = Get-WmiObject Win32_NetworkAdapterConfiguration |
    Where-Object { $_.IPEnabled -eq $true -and $_.IPAddress -ne $null } |
    ForEach-Object { $_.IPAddress } |
    ForEach-Object { $_ | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' -and $_ -notlike '127.*' -and $_ -ne '0.0.0.0' } } |
    Select-Object -First 1

if (-not $localIP) {
    Write-Host "Could not determine local IP address." -ForegroundColor Red
    exit 1
}


$phpIniPath = Join-Path -Path $phpDir -ChildPath "php.ini"

if (-Not (Test-Path $phpIniPath)) {
    if (Test-Path "$phpDir\php.ini-development") {
        Copy-Item "$phpDir\php.ini-development" $phpIniPath
    } elseif (Test-Path "$phpDir\php.ini-production") {
        Copy-Item "$phpDir\php.ini-production" $phpIniPath
    } else {
        Write-Host "No default php.ini file found!" -ForegroundColor Red
        exit 1
    }
}


(Get-Content $phpIniPath) |
    ForEach-Object {
        $_ -replace '^\s*post_max_size\s*=.*$', 'post_max_size = 2G'
    } |
    ForEach-Object {
        $_ -replace '^\s*upload_max_filesize\s*=.*$', 'upload_max_filesize = 2G'
    } |
    Set-Content $phpIniPath

Write-Host "php.ini updated with increased limits: post_max_size=2G, upload_max_filesize=2G"


try {
    Write-Host "Adding firewall rule for port 8007..." -ForegroundColor Cyan
    New-NetFirewallRule -DisplayName "Open Port 8007" -Direction Inbound -Protocol TCP -LocalPort 8007 -Action Allow -Profile Any -ErrorAction Stop
    Write-Host "Firewall rule added successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to add firewall rule: $_" -ForegroundColor Red
}


Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "`"Write-Host 'Starting the project at ' -ForegroundColor White; Write-Host 'http://$($localIP):8007' -ForegroundColor Green;
     Write-Host ' (available on local network)';
     Write-Host '';
      .\php\php.exe -S 0.0.0.0:8007 -t public`""
)
