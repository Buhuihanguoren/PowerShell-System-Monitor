# Optimized Basic System Monitor
# Run as Administrator for accurate metrics

[CmdletBinding()]
Param()

# Configuration
$durationSeconds = 600  # 10 minutes
$intervalSeconds = 5
$iterations = $durationSeconds / $intervalSeconds
$baseLogPath = "simple_log"
$logExtension = ".csv"

# Find next available log file
$logNumber = 1
while (Test-Path "$baseLogPath`_$logNumber$logExtension") { $logNumber++ }
$logFile = "$baseLogPath`_$logNumber$logExtension"

# Initialize log
"Time,CPUSpeed(MHz),CPUUsage(%),MemoryUsage(%)" | Out-File -FilePath $logFile -Encoding utf8

Write-Host "Monitoring started for 10 minutes (5-second intervals). Log: $logFile"

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
        
        Write-Host "Sample $i - Time: $time - CPU: $cpuFreq MHz - Usage: $cpuUsage% - Memory: $memUsage%"
        
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

# Summary Statistics (excluding N/A)
if (Test-Path $logFile) {
    $data = Import-Csv $logFile | Where-Object { $_.'CPUSpeed(MHz)' -ne "N/A" -and $_.'CPUUsage(%)' -ne "N/A" -and $_.'MemoryUsage(%)' -ne "N/A" }
    
    if ($data.Count -gt 0) {
        $cpuFreqStats = $data | Measure-Object -Property 'CPUSpeed(MHz)' -Average -Minimum -Maximum
        $cpuUsageStats = $data | Measure-Object -Property 'CPUUsage(%)' -Average -Minimum -Maximum
        $memUsageStats = $data | Measure-Object -Property 'MemoryUsage(%)' -Average -Minimum -Maximum
        
        Write-Host "`nSummary Statistics:"
        Write-Host "CPU Frequency (MHz): Avg $([math]::Round($cpuFreqStats.Average, 2)), Min $([math]::Round($cpuFreqStats.Minimum, 2)), Max $([math]::Round($cpuFreqStats.Maximum, 2))"
        Write-Host "CPU Usage (%): Avg $([math]::Round($cpuUsageStats.Average, 2)), Min $([math]::Round($cpuUsageStats.Minimum, 2)), Max $([math]::Round($cpuUsageStats.Maximum, 2))"
        Write-Host "Memory Usage (%): Avg $([math]::Round($memUsageStats.Average, 2)), Min $([math]::Round($memUsageStats.Minimum, 2)), Max $([math]::Round($memUsageStats.Maximum, 2))"
        Write-Host "Valid samples: $($data.Count)/$iterations"
    } else {
        Write-Host "`nNo valid data collected for statistics."
    }
}

Write-Host "Monitoring complete. Log saved to: $logFile"