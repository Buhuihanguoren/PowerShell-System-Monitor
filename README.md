# System Performance Monitor

Two PowerShell scripts that log CPU speed, CPU usage and memory usage to a CSV file every 5 seconds for 10 minutes, then print summary statistics.

| Script | What it adds |
|---|---|
| `system_monitor.ps1` | The basic version: sampling, CSV logging, summary |
| `better_system_monitor.ps1` | Checks every sample, handles missing values ("N/A") in the statistics, reports data quality, and formats the output more clearly |

Basic version:

<img width="639" height="259" alt="Basic monitor output" src="https://github.com/user-attachments/assets/96bd0cec-1c47-4ef1-8529-842eb9bde8bc" />

Better version:

<img width="621" height="310" alt="Better monitor output" src="https://github.com/user-attachments/assets/c7b7c277-eba4-46a6-b1c4-cae21adc313f" />

## What it records

- CPU speed (MHz), CPU usage (%) and memory usage (%), one sample every 5 seconds
- 120 samples (10 minutes) per run, numbered 001 to 120 in the better version
- A new CSV file for each run (the file name number goes up, nothing is overwritten)
- Summary statistics at the end; stop early with Ctrl+C

## Run it

```powershell
cd path\to\PowerShell-System-Monitor
.\system_monitor.ps1           # basic version
.\better_system_monitor.ps1    # better version
```

If PowerShell refuses to run scripts:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Needs Windows PowerShell 5.1 or newer with WMI. Running as Administrator is recommended. Close other heavy programs first, or they will show up in the numbers.
