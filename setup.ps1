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

$phpUrl = "https://windows.php.net/downloads/releases/php-8.2.28-Win32-vs16-x64.zip"
$phpZip = "php.zip"
$phpDir = "php"
$shareDir = "share"

if (-Not (Test-Path $shareDir)) {
    Write-Host "Creating 'share' directory..."
    New-Item -Path $shareDir -ItemType Directory
}

if (-Not (Test-Path $phpZip) -and -Not (Test-Path $phpDir)) {
    Write-Host "Downloading PHP..."
    Invoke-WebRequest -Uri $phpUrl -OutFile $phpZip

    Write-Host "Extracting PHP..."
    Expand-Archive -Path $phpZip -DestinationPath $phpDir -Force

    if (Test-Path $phpDir) {
        Write-Host "Deleting php.zip after successful extraction..."
        Remove-Item $phpZip -Force
    }
}
elseif ((Test-Path $phpZip) -and (-Not (Test-Path $phpDir))) {
    Write-Host "Extracting existing PHP archive..."
    Expand-Archive -Path $phpZip -DestinationPath $phpDir -Force

    if (Test-Path $phpDir) {
        Write-Host "Deleting php.zip after extraction..."
        Remove-Item $phpZip -Force
    }
}
else {
    Write-Host "PHP already downloaded and extracted. Skipping..."

    if (Test-Path $phpZip) {
        Write-Host "PHP folder already exists. Deleting leftover php.zip..."
        Remove-Item $phpZip -Force
    }
}


# $phpUrl = "https://windows.php.net/downloads/releases/php-8.2.28-Win32-vs16-x64.zip"
# $phpZip = "php.zip"
# $phpDir = "php"

# if (-Not (Test-Path $phpZip)) {
#     Write-Host "Downloading PHP..."
#     Invoke-WebRequest -Uri $phpUrl -OutFile $phpZip

#     Write-Host "Extracting PHP..."
#     Expand-Archive -Path $phpZip -DestinationPath $phpDir -Force
# }
# elseif ((Test-Path $phpZip) -and (-Not (Test-Path $phpDir))) {
#     Write-Host "Extracting existing PHP archive..."
#     Expand-Archive -Path $phpZip -DestinationPath $phpDir -Force
# }
# else {
#     Write-Host "PHP already downloaded and extracted. Skipping..."
# }

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
