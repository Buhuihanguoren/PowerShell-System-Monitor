# System Performance Monitor

A PowerShell script for monitoring system performance metrics including CPU speed, CPU usage, and memory usage.

## 1. Overall

### 1.1 System Monitor (`system_monitor.ps1`)
- **Basic version** with essential functionality
- Monitors CPU speed, CPU usage, and memory usage
- Logs data to CSV files with automatic filename incrementation
- Simple output format
- 10-minute monitoring duration (5-second intervals)

### 1.2 Better System Monitor (`better_system_monitor.ps1`)
- **Advanced version** with enhanced features
- Improved error handling for data validation
- Better formatting with 3-digit sample numbers
- Handles "N/A" values in statistics calculation
- Shows data quality metrics
- Same 10-minute monitoring duration
- A lot more GUI

## 2 Features

### 2.1 Common Features (Both Scripts)
- ✅ Real-time system performance monitoring
- ✅ CSV logging with automatic file management
- ✅ CPU Speed (MHz) monitoring
- ✅ CPU Usage (%) monitoring  
- ✅ Memory Usage (%) monitoring
- ✅ 5-second sampling intervals
- ✅ 10-minute total monitoring duration
- ✅ Summary statistics at completion
- ✅ Safe interruption with Ctrl+C

### 2.2 Advanced Features (Better System Monitor Only)
- ✅ Improved data validation
- ✅ "N/A" value handling in statistics
- ✅ Data quality reporting
- ✅ Better output formatting
- ✅ Sample number padding (001, 002, ..., 120)

## ️ 3 Installation & Usage

### 3.1 Prerequisites
- Windows PowerShell 5.1 or newer
- Administrator privileges (recommended)
- Windows Management Instrumentation (WMI) enabled

### 3.2 Running the Scripts

1. **Download the scripts** to your preferred directory (Or create a file with the same name and extension "ps1" and just copy paste the code)
2. **Open PowerShell as Administrator**
3. **Navigate to the scripts folder**:
   ```powershell
   cd path\to\SystemPerformanceMonitor\scripts .\(Write File_Name here)
   
# Run basic version
.\system_monitor.ps1

# Run advanced version  
.\better_system_monitor.ps1

If you encounter execution policy errors, run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
!!! For accurate results, ensure no other resource-intensive applications are running during monitoring. !!!