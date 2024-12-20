# Daily Usage Scripts 🛠️

A collection of useful Python and Bash scripts for everyday tasks, system maintenance, and security monitoring and more. These scripts are designed to automate common tasks and improve workflow efficiency.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Scripts Overview](#scripts-overview)
- [Usage](#usage)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

## Features

- 🎥 YouTube video/audio downloader with format selection
- 🔄 System update automation for multiple package managers
- 🔒 Security breach monitoring and notification system
- 🧹 System cleanup and maintenance utilities
  -✨ Upcoming soon

## Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/daily-usage-scripts.git
cd daily-usage-scripts
```

2. Install required dependencies:

```bash
pip install -r requirements.txt
```

## Scripts Overview

### 1. YouTube Downloader (`yt_downloader.sh`)

Downloads videos and audio from YouTube with custom quality settings.

**Key Features:**

- Support for both video and audio downloads
- Quality selection (4K, 1080p, 720p, etc.)
- Playlist support
- Custom output directory
- Progress bar and download status

### 2. System Update Script (`system_update.sh`)

Automates system updates across different package managers.

**Key Features:**

- Support for apt, yum, pacman, and brew
- Automatic cache cleanup
- Update logging
- Error handling and reporting
- Optional automatic reboot

### 3. Security Breach Monitor (`security_monitor.py`)

Monitors system and network for potential security breaches.

**Key Features:**

- Real-time log monitoring
- Failed login attempt detection
- Port scanning detection
- Email notifications for suspicious activities
- Daily security reports
- Integration with common security tools

### 4. System Cleanup (`system_cleanup.py`)

Maintains system health by cleaning unwanted files and optimizing storage.

**Key Features:**

- Temporary file cleanup
- Package cache cleanup
- Old log removal
- Duplicate file detection
- Disk space analysis
- Configurable cleanup rules

## Usage

### YouTube Downloader

```bash
bash yt_downloader.sh
```

### System Update

```bash
bash system_update.sh
```

### Security Monitor

```bash
python security_monitor.py --email your@email.com --sensitivity high
```

### System Cleanup

```bash
python system_cleanup.py --deep-clean --preserve-days 30
```

## Requirements

- bash
- Python 3.8 or higher
- Operating System: Linux, macOS, or Windows

## Project Structure

```
everyday-scripts/
├── scripts/
│   ├── yt_downloader.py
│   ├── system_update.py
│   ├── security_monitor.py
│   └── system_cleanup.py
├── config/
│   └── config.yaml
├── logs/
│   └── script_logs.log
├── tests/
│   └── test_scripts.py
├── requirements.txt
└── README.md
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

- Sheikh Vazid
- GitHub: [@sudovazid](https://github.com/sudovazid)
- LinkedIn: [Vazid](https://linkedin.com/in/vazid)

## Acknowledgments

- [pytube](https://github.com/pytube/pytube) for YouTube download functionality
- Various system administration tools and utilities
- Open source security monitoring tools

---

⭐ Found this project useful? Please star it on GitHub! ⭐
