$LogFile = "simple_log.csv"
"Time,CPUSpeed,CPU_Usage,MemoryUsage" | Out-File $LogFile

Write-Host "Monitoring for 10 minutes..."
for ($i = 0; $i -lt 120; $i++) {
    $time = Get-Date -Format "HH:mm:ss"
    $cpuInstance = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
    $cpuSpeed = $cpuInstance.CurrentClockSpeed
    $cpuUsage = $cpuInstance.LoadPercentage
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $memUsage = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize * 100, 1)
    
    "$time,$cpuSpeed,$cpuUsage,$memUsage" | Out-File $LogFile -Append
    Write-Host "Sample $i - CPU: $cpuSpeed MHz - Usage: $cpuUsage% - Memory: $memUsage%"
    
    Start-Sleep -Seconds 5
}

Write-Host "Done! File: $LogFile"