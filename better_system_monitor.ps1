# Optimized Advanced System Monitor
# Run as Administrator for accurate metrics

[CmdletBinding()]
Param()

# Function to get unique filename (simplified)
function Get-UniqueFilename {
    param([string]$BaseName)
    
    $basePath = if ($BaseName -like "*.csv") { $BaseName -replace '\.csv$', '' } else { $BaseName }
    $counter = 1
    $filePath = "$basePath.csv"
    
    while (Test-Path $filePath) {
        $filePath = "$basePath`_$counter.csv"
        $counter++
    }
    return $filePath
}

# Configuration
$durationSeconds = 600  # 10 minutes
$intervalSeconds = 5
$iterations = $durationSeconds / $intervalSeconds
$baseLogName = "system_performance_log"
$logFile = Get-UniqueFilename -BaseName $baseLogName

# Initialize log
"Time,CPUSpeed(MHz),CPUUsage(%),MemoryUsage(%)" | Out-File -FilePath $logFile -Encoding utf8

Write-Host "System Performance Monitoring started..." -ForegroundColor Green
Write-Host "Monitoring for 10 minutes (5-second intervals)..." -ForegroundColor Yellow
Write-Host "Log file: $logFile" -ForegroundColor Green
Write-Host "!!YOU CAN STOP ANYTIME BY PRESSING-AND-HOLDING DOWN CTRL+C!!" -ForegroundColor Yellow

# Get nominal frequency (base clock from WMI/CIM, used for scaling)
$nominalFreq = "N/A"
try {
    $nominalFreq = (Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1).MaxClockSpeed
} catch {
    Write-Warning "Could not retrieve nominal CPU frequency: $_"
}

# Data collection array for batch write
$dataLines = New-Object System.Collections.ArrayList

# Stopwatch for precise timing
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    for ($i = 1; $i -le $iterations; $i++) {
        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # CPU Frequency (MHz) - Dynamic via % Processor Performance (handles turbo)
        $cpuFreq = "N/A"
        if ($nominalFreq -ne "N/A") {
            try {
                $perfSamples = Get-Counter '\Processor Information(_Total)\% Processor Performance' -ErrorAction Stop
                $perf = if ($perfSamples.CounterSamples) { $perfSamples.CounterSamples.CookedValue } else { $null }
                $cpuFreq = if ($perf -ne $null) { [math]::Round($nominalFreq * ($perf / 100), 0) } else { "N/A" }
            } catch {
                Write-Warning "Could not retrieve CPU performance: $_"
            }
        }
        
        # CPU Usage (%)
        $cpuUsage = "N/A"
        try {
            $usageSamples = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
            $cpuUsage = if ($usageSamples.CounterSamples) {
                [math]::Round($usageSamples.CounterSamples.CookedValue, 2)
            } else { "N/A" }
        } catch {
            Write-Warning "Could not retrieve CPU usage: $_"
        }
        
        # Memory Usage (%)
        $memUsage = "N/A"
        try {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
            if ($os.TotalVisibleMemorySize -gt 0) {
                $memUsage = [math]::Round(100 * (1 - ($os.FreePhysicalMemory / $os.TotalVisibleMemorySize)), 2)
            }
        } catch {
            Write-Warning "Could not retrieve memory usage: $_"
        }
        
        $line = "$time,$cpuFreq,$cpuUsage,$memUsage"
        [void]$dataLines.Add($line)
        
        # Display progress with padded sample number
        $sampleNumber = $i.ToString("D3")
        Write-Host "Sample $sampleNumber - Time: $time - CPU: $cpuFreq MHz - Usage: $cpuUsage% - Memory: $memUsage%"
        
        # Batch write every 10 samples
        if ($i % 10 -eq 0 -or $i -eq $iterations) {
            $dataLines | Out-File -FilePath $logFile -Append -Encoding utf8
            $dataLines.Clear()
        }
        
        # Precise sleep
        $elapsed = $stopwatch.Elapsed.TotalSeconds
        $nextWake = $i * $intervalSeconds
        if ($elapsed -lt $nextWake) {
            Start-Sleep -Milliseconds (($nextWake - $elapsed) * 1000)
        }
    }
} catch {
    Write-Error "Monitoring interrupted: $_"
} finally {
    $stopwatch.Stop()
}

Write-Host "`nMonitoring completed!" -ForegroundColor Green
Write-Host "Data saved to: $logFile" -ForegroundColor Yellow
Write-Host "Total samples collected: $($i - 1)" -ForegroundColor Green  # Adjust for loop exit

# Summary Statistics (excluding N/A per metric)
if (Test-Path $logFile) {
    $data = Import-Csv $logFile
    
    $validCpuFreq = $data | Where-Object { $_.'CPUSpeed(MHz)' -ne "N/A" } | ForEach-Object { [double]$_.'CPUSpeed(MHz)' }
    $validCpuUsage = $data | Where-Object { $_.'CPUUsage(%)' -ne "N/A" } | ForEach-Object { [double]$_.'CPUUsage(%)' }
    $validMemUsage = $data | Where-Object { $_.'MemoryUsage(%)' -ne "N/A" } | ForEach-Object { [double]$_.'MemoryUsage(%)' }
    
    Write-Host "`nSummary Statistics:" -ForegroundColor Magenta
    
    if ($validCpuFreq.Count -gt 0) {
        $cpuFreqStats = $validCpuFreq | Measure-Object -Average -Minimum -Maximum
        Write-Host "CPU Frequency (MHz): Avg $([math]::Round($cpuFreqStats.Average, 2)), Min $([math]::Round($cpuFreqStats.Minimum, 2)), Max $([math]::Round($cpuFreqStats.Maximum, 2))"
    } else {
        Write-Host "CPU Frequency: No valid data" -ForegroundColor Yellow
    }
    
    if ($validCpuUsage.Count -gt 0) {
        $cpuUsageStats = $validCpuUsage | Measure-Object -Average -Minimum -Maximum
        Write-Host "CPU Usage (%): Avg $([math]::Round($cpuUsageStats.Average, 2)), Min $([math]::Round($cpuUsageStats.Minimum, 2)), Max $([math]::Round($cpuUsageStats.Maximum, 2))"
    } else {
        Write-Host "CPU Usage: No valid data" -ForegroundColor Yellow
    }
    
    if ($validMemUsage.Count -gt 0) {
        $memUsageStats = $validMemUsage | Measure-Object -Average -Minimum -Maximum
        Write-Host "Memory Usage (%): Avg $([math]::Round($memUsageStats.Average, 2)), Min $([math]::Round($memUsageStats.Minimum, 2)), Max $([math]::Round($memUsageStats.Maximum, 2))"
    } else {
        Write-Host "Memory Usage: No valid data" -ForegroundColor Yellow
    }
    
    Write-Host "Valid CPU Freq samples: $($validCpuFreq.Count)/$($data.Count)" -ForegroundColor Gray
    Write-Host "Valid CPU Usage samples: $($validCpuUsage.Count)/$($data.Count)" -ForegroundColor Gray
    Write-Host "Valid Memory samples: $($validMemUsage.Count)/$($data.Count)" -ForegroundColor Gray
    Write-Host "Monitoring duration: 10 minutes" -ForegroundColor White
} else {
    Write-Host "`nNo log file found for statistics." -ForegroundColor Red
}

# Show nearby log files
Write-Host "`nOther log files in this directory:" -ForegroundColor Gray
Get-ChildItem -Path "." -Filter "$baseLogName*.csv" | ForEach-Object {
    if ($_.Name -eq (Split-Path $logFile -Leaf)) {
        Write-Host "  > $($_.Name) (current)" -ForegroundColor Green
    } else {
        Write-Host "    $($_.Name)" -ForegroundColor DarkGray
    }
}