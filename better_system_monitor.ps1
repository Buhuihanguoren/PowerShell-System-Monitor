<#
System Performance Monitor - Logs CPU and Memory usage to CSV
=====================================================================================
This script monitors system performance metrics (CPU speed, CPU usage, Memory Usage)
and logs them to a CSV file with basic formatting and error handling. Automatically
creates new files with incrementing number if the target file already exists.

#>

# Function to get unique filename
function Get-UniqueFilename {
    param([string]$BaseName)
    
    $counter = 1
    $basePath = $BaseName
    
    # Check if base filename exists
    if (Test-Path "$basePath.csv") {
        # Extract base name
        if ($BaseName -like "*.csv") {
            $basePath = $BaseName -replace '\.csv$', ''
        }
        
        # Find the next filename number
        while (Test-Path "${basePath}_$counter.csv") {
            $counter++
        }
        return "${basePath}_$counter.csv"
    } else {
        # If base doesn't exist
        if ($BaseName -like "*.csv") {
            return $BaseName
        } else {
            return "$BaseName.csv"
        }
    }
}

# Get !unique! log filename
$BaseLogName = "system_performance_log"
$LogFile = Get-UniqueFilename -BaseName $BaseLogName

# Write CSV header
"Time,CPUSpeed(MHz),CPUUsage(%),MemoryUsage(%)" | Out-File $LogFile -Encoding UTF8

Write-Host "System Performance Monitoring started..." -ForegroundColor Green
Write-Host "Monitoring for 10 minutes (5-second intervals)..." -ForegroundColor Yellow
Write-Host "Log file: $LogFile" -ForegroundColor Green
Write-Host "!!YOU CAN STOP ANYTIME BY PRESSING-AND-HOLDING DOWN CTR+C!!" -ForegroundColor Yellow

try {
    for ($i = 0; $i -lt 120; $i++) {
        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Get CPU Speed
        $cpuSpeed = "N/A"
        try {
            $cpuSpeedRaw = (Get-WmiObject -Class Win32_Processor | Select-Object -First 1).CurrentClockSpeed
            if ($cpuSpeedRaw -and $cpuSpeedRaw -gt 0) {
                $cpuSpeed = $cpuSpeedRaw
            }
        } catch {
            Write-Warning "Could not retrieve CPU speed: $($_.Exception.Message)"
        }
        
        # Get CPU Usage
        $cpuUsage = "N/A"
        try {
            $cpuUsageRaw = (Get-WmiObject Win32_Processor).LoadPercentage
            if ($cpuUsageRaw -ge 0 -and $cpuUsageRaw -le 100) {
                $cpuUsage = $cpuUsageRaw
            }
        } catch {
            Write-Warning "Could not retrieve CPU usage: $($_.Exception.Message)"
        }
        
        # Get Memory Usage
        $memUsage = "N/A"
        try {
            $memory = Get-WmiObject Win32_OperatingSystem
            if ($memory.TotalVisibleMemorySize -gt 0) {
                $usedMemory = $memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory
                $memUsage = [math]::Round(($usedMemory / $memory.TotalVisibleMemorySize) * 100, 2)
            }
        } catch {
            Write-Warning "Could not retrieve memory usage: $($_.Exception.Message)"
        }
        
        # Create CSV row
        $csvRow = "$time,$cpuSpeed,$cpuUsage,$memUsage"
        
        # Write on CSV
        $csvRow | Out-File $LogFile -Append -Encoding UTF8
        
        # Display progress with proper formatting (3-digit sample number)
        $sampleNumber = ($i + 1).ToString().PadLeft(3, '0')
        Write-Host "Sample $sampleNumber - Time: $time - CPU: $cpuSpeed MHz - Usage: $cpuUsage% - Memory: $memUsage%"
        
        # Wait 5 seconds
        Start-Sleep -Seconds 5
    }
} catch {
    Write-Error "Monitoring interrupted: $($_.Exception.Message)"
}

Write-Host "`nMonitoring completed!" -ForegroundColor Green
Write-Host "Data saved to: $LogFile" -ForegroundColor Yellow
Write-Host "Total samples collected: $i" -ForegroundColor Green

# Display summary
if (Test-Path $LogFile) {
    $data = Import-Csv $LogFile
    
    # Filter out rows with N/A values and convert to numbers
    $validCPUData = $data | Where-Object { $_.'CPUUsage(%)' -ne "N/A" } | ForEach-Object { 
        [PSCustomObject]@{
            CPUUsage = [double]$_.'CPUUsage(%)'
            MemoryUsage = [double]$_.'MemoryUsage(%)'
        }
    }
    
    $validMemoryData = $data | Where-Object { $_.'MemoryUsage(%)' -ne "N/A" } | ForEach-Object { 
        [double]$_.'MemoryUsage(%)'
    }
    
    if ($validCPUData.Count -gt 0 -or $validMemoryData.Count -gt 0) {
        Write-Host "`nSummary Statistics:" -ForegroundColor Magenta
        
        if ($validCPUData.Count -gt 0) {
            $avgCPU = ($validCPUData | Measure-Object -Property CPUUsage -Average).Average
            Write-Host "Average CPU Usage: $([math]::Round($avgCPU, 2))%" -ForegroundColor White
        } else {
            Write-Host "Average CPU Usage: No valid data" -ForegroundColor Yellow
        }
        
        if ($validMemoryData.Count -gt 0) {
            $avgMemory = ($validMemoryData | Measure-Object -Average).Average
            Write-Host "Average Memory Usage: $([math]::Round($avgMemory, 2))%" -ForegroundColor White
        } else {
            Write-Host "Average Memory Usage: No valid data" -ForegroundColor Yellow
        }
        
        Write-Host "Valid CPU samples: $($validCPUData.Count)/$($data.Count)" -ForegroundColor Gray
        Write-Host "Valid Memory samples: $($validMemoryData.Count)/$($data.Count)" -ForegroundColor Gray
        Write-Host "Monitoring duration: 10 minutes" -ForegroundColor White
    } else {
        Write-Host "`nNo valid data collected for statistics." -ForegroundColor Red
    }
}

# Show nearby log files
Write-Host "`nOther log files in this directory:" -ForegroundColor Gray
Get-ChildItem -Path "." -Filter "${BaseLogName}*.csv" | ForEach-Object {
    if ($_.Name -eq $LogFile) {
        Write-Host "  > $($_.Name) (current)" -ForegroundColor Green
    } else {
        Write-Host "    $($_.Name)" -ForegroundColor DarkGray
    }
}