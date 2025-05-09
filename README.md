## LocalDrop

### Built With

* [![PHP][php.net]][PHP-url]
* [![PowerShell][PowerShell.com]][PowerShell-url]

## Introduction

This is a local network file-sharing application developed in PHP.

### Installation

1. Clone the repository using Git, or alternatively, download the ZIP archive and extract it manually :
    ```bash
    git clone https://github.com/your-username/your-project-name.git
    ```

2. Run the setup script :
    ```bash
    setup.bat
    ```
    
The `setup.bat` script will automatically configure the environment, install dependencies, and prepare the application for use.

It allows users within the same network to access a shared folder, where they can upload and download files easily through a web interface. Once the application is launched, a local access URL is displayed (running on port `8007` by default), which users can open in their browsers.
All files are stored on the host machine (the computer running the application).

> ⚠️ Currently, this application is only supported on Windows operating systems.

[php.net]: https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white
[php-url]: https://php.net

[PowerShell.com]: https://img.shields.io/badge/powershell-5391FE?style=for-the-badge&logo=powershell&logoColor=white
[PowerShell-url]: https://github.com/PowerShell/PowerShell


