<#
Author: Lightspeed Sharing (YT) | Project: Cotton059/Light-Help
Developer: Lightspeed Sharing (YT) | Project : Light-Help (GitHub)
#>

# ==========================================
# UI & Environment Initialization (UTF-8 Enforced)
# ==========================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "CryoRAM | Smart RAM Optimizer V4 (God Mode)"

$MenuColor = "Cyan"
$Level1Color = "Cyan"
$Level2Color = "DarkCyan"
$Level3Color = "Magenta"
$Level4Color = "Red"
$Level5Color = "Green"

# Request Administrator Privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "[!] Administrator rights are required for V4 God Mode. Restarting script..."
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# ==========================================
# Core API Injection (C# P/Invoke)
# ==========================================
$WinApiCode = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class WinApi {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("kernel32.dll")]
    public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);

    [DllImport("kernel32.dll")]
    public static extern bool SetSystemFileCacheSize(IntPtr minimumFileCacheSize, IntPtr maximumFileCacheSize, int flags);

    [DllImport("ntdll.dll", PreserveSig = false)]
    public static extern void NtSuspendProcess(IntPtr processHandle);

    [DllImport("ntdll.dll", PreserveSig = false, EntryPoint = "NtResumeProcess")]
    public static extern void NtResumeProcess(IntPtr processHandle);

    public static string GetActiveProcessName() {
        try {
            IntPtr hwnd = GetForegroundWindow();
            uint pid;
            GetWindowThreadProcessId(hwnd, out pid);
            return Process.GetProcessById((int)pid).ProcessName;
        } catch { return "Unknown"; }
    }
}
"@
Add-Type -TypeDefinition $WinApiCode -ErrorAction SilentlyContinue

# ==========================================
# Configuration & Lists
# ==========================================
$WhiteList = @("code", "idea64", "chrome", "msedge", "explorer", "powershell", "pwsh", "OBS", "WeChat", "Discord", "devenv", "Adobe Premiere Pro", "WindowsTerminal")
$SystemProtected = @("svchost", "csrss", "smss", "wininit", "services", "lsass", "fontdrvhost", "dwm", "spoolsv", "winlogon", "sihost", "taskhostw", "SearchIndexer", "System", "Idle", "Registry", "Memory Compression")
$PhantomList = @("*crashpad*", "*update*", "*telemetry*", "*report*", "*feedback*", "CompatTelRunner")
$SuspendTargets = @("steam", "epicgameslauncher", "origin", "battlenet", "wechat", "qq", "discord", "slack", "spotify", "wallpaper32", "wallpaper64")
$HibernationServices = @("SysMain", "WSearch", "DiagTrack", "Spooler")

# ==========================================
# Helper Functions
# ==========================================
function Get-MemoryUsage {
    $os = Get-CimInstance Win32_OperatingSystem
    $total = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $free = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $used = $total - $free
    $percent = [math]::Round(($used / $total) * 100, 2)
    return @{ Total=$total; Free=$free; Used=$used; Percent=$percent }
}

function Show-Banner {
    Clear-Host
    Write-Host " +----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host " |      /_\                                                 |" -ForegroundColor Cyan
    Write-Host " |     ( o )    >>> CryoRAM TOOL <<<                        |" -ForegroundColor Cyan
    Write-Host " |    /_____\                                               |" -ForegroundColor Cyan
    Write-Host " +----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host " |  Developer: Lightspeed Sharing (YT)                      |" -ForegroundColor DarkCyan
    Write-Host " |  Project  : Cotton059/Light-Help                         |" -ForegroundColor DarkCyan
    Write-Host " |  Platform : Windows 10 / 11 Optimization                 |" -ForegroundColor DarkCyan
    Write-Host " +----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
}

function Show-DynamicProgressBar {
    param (
        [int]$Percentage,
        [string]$BarColor,
        [string]$Label,
        [string]$MemoryText
    )

    $TotalBlocks = 20
    $FilledBlocks = [math]::Round(($Percentage / 100) * $TotalBlocks)
    if ($FilledBlocks -gt $TotalBlocks) { $FilledBlocks = $TotalBlocks }
    if ($FilledBlocks -lt 0) { $FilledBlocks = 0 }
    $EmptyBlocks = $TotalBlocks - $FilledBlocks

    # Use Hex char codes to bypass file encoding issues completely
    $SolidBlock = [char]0x2588
    $LightBlock = [char]0x2591

    Write-Host "$Label " -NoNewline -ForegroundColor White
    Write-Host "`n[" -NoNewline -ForegroundColor White

    for ($i = 0; $i -lt $FilledBlocks; $i++) {
        Write-Host $SolidBlock -NoNewline -ForegroundColor $BarColor
    }
    for ($i = 0; $i -lt $EmptyBlocks; $i++) {
        Write-Host $LightBlock -NoNewline -ForegroundColor DarkGray
    }

    Write-Host "] " -NoNewline -ForegroundColor White
    Write-Host "$Percentage%  " -NoNewline -ForegroundColor White
    Write-Host $MemoryText -ForegroundColor Gray
    Write-Host ""
}

# ==========================================
# Main Execution Logic
# ==========================================
while ($true) {
    Show-Banner
    
    $MemBefore = Get-MemoryUsage
    $BeforeColor = if ($MemBefore.Percent -ge 80) { "Red" } elseif ($MemBefore.Percent -ge 50) { "Yellow" } else { "Cyan" }
    
    Show-DynamicProgressBar -Percentage $MemBefore.Percent -BarColor $BeforeColor -Label "[Current] Memory Allocation:" -MemoryText "($($MemBefore.Used) GB / $($MemBefore.Total) GB)"
    Write-Host ""

    Write-Host "Please select optimization level:" -ForegroundColor $MenuColor
    Write-Host "[1] Light Clean        " -NoNewline; Write-Host "(Recommended, Zero Risk - Flushes Standby/Cache)" -ForegroundColor DarkGray
    Write-Host "[2] Balanced Optimizer " -NoNewline; Write-Host "(Smart Protect + Background Trim)" -ForegroundColor DarkGray
    Write-Host "[3] Extreme Dehydrate  " -NoNewline; Write-Host "(Powerful, might cause UI reload - Full Trim)" -ForegroundColor DarkGray
    Write-Host "[4] GOD MODE           " -NoNewline; Write-Host "(Absolute Freeze & Service Cull - DANGER)" -ForegroundColor Red
    Write-Host "[5] Restore System     " -NoNewline; Write-Host "(Resume frozen apps & start services)" -ForegroundColor Green
    Write-Host "[0] Exit" -ForegroundColor DarkGray
    Write-Host ""

    $Choice = Read-Host "Enter your choice [0-5]"
    
    if ($Choice -eq '0') {
        Write-Host "Exiting CryoRAM..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 1
        Exit
    }

    $ActionTaken = ""
    $TrimCount = 0

    Write-Host "`n[*] Executing protocol..." -ForegroundColor White

    switch ($Choice) {
        '1' {
            Write-Host "[*] Level 1: Flushing system standby list and cache..." -ForegroundColor $Level1Color
            try { [WinApi]::SetSystemFileCacheSize([IntPtr]-1, [IntPtr]-1, 0) | Out-Null } catch {}
            $ActionTaken = "Flushed system pre-load cache and standby memory"
        }
        '2' {
            $ActiveApp = [WinApi]::GetActiveProcessName()
            Write-Host "[!] Level 2: Smart Working Set Trimming initiated." -ForegroundColor $Level2Color
            Write-Host "[+] Protected Foreground App: [$ActiveApp]" -ForegroundColor "Yellow"
            
            $AllProcs = Get-Process
            foreach ($p in $AllProcs) {
                if ($WhiteList -notcontains $p.ProcessName -and $SystemProtected -notcontains $p.ProcessName -and $p.ProcessName -ne $ActiveApp) {
                    try { if ($p.Handle) { [WinApi]::SetProcessWorkingSetSize($p.Handle, -1, -1) | Out-Null; $TrimCount++ } } catch {}
                }
            }
            $ActionTaken = "Trimmed $TrimCount background processes"
        }
        '3' {
            $ActiveApp = [WinApi]::GetActiveProcessName()
            Write-Host "[!] Level 3: Extreme Dehydration initiated." -ForegroundColor $Level3Color
            Write-Host "[+] Protected Foreground App: [$ActiveApp]" -ForegroundColor "Yellow"
            
            $AllProcs = Get-Process
            foreach ($p in $AllProcs) {
                if ($SystemProtected -notcontains $p.ProcessName -and $p.ProcessName -ne $ActiveApp) {
                    try { if ($p.Handle) { [WinApi]::SetProcessWorkingSetSize($p.Handle, -1, -1) | Out-Null; $TrimCount++ } } catch {}
                }
            }
            try { [WinApi]::SetSystemFileCacheSize([IntPtr]-1, [IntPtr]-1, 0) | Out-Null } catch {}
            
            Write-Host "[*] Restarting Explorer shell..." -ForegroundColor $Level3Color
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Start-Process explorer
            
            $ActionTaken = "Full trim ($TrimCount procs) & Explorer reset"
        }
        '4' {
            Write-Host "WARNING: GOD MODE INITIATED. OS TAKEOVER IN PROGRESS." -ForegroundColor Red -BackgroundColor Black
            for ($i=3; $i -gt 0; $i--) { Write-Host "Freezing non-essential threads in $i..." -ForegroundColor Red; Start-Sleep -Seconds 1 }

            $ActiveApp = [WinApi]::GetActiveProcessName()
            Write-Host "[*] Phase 1: Hibernating heavy OS services..." -ForegroundColor Red
            foreach ($svc in $HibernationServices) { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue }

            Write-Host "[*] Phase 2: Hunting phantom sub-processes..." -ForegroundColor Red
            foreach ($phantom in $PhantomList) { Get-Process -Name $phantom.Replace("*","") -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }

            Write-Host "[*] Phase 3: Suspending heavy background applications..." -ForegroundColor Red
            $SuspendCount = 0
            $SuspendProcs = Get-Process -Name $SuspendTargets -ErrorAction SilentlyContinue
            foreach ($p in $SuspendProcs) {
                if ($p.ProcessName -ne $ActiveApp) { try { if ($p.Handle) { [WinApi]::NtSuspendProcess($p.Handle) | Out-Null; $SuspendCount++ } } catch {} }
            }

            Write-Host "[*] Phase 4: Purging remaining memory blocks..." -ForegroundColor Red
            $AllProcs = Get-Process
            foreach ($p in $AllProcs) {
                if ($SystemProtected -notcontains $p.ProcessName -and $p.ProcessName -ne $ActiveApp) {
                    try { if ($p.Handle) { [WinApi]::SetProcessWorkingSetSize($p.Handle, -1, -1) | Out-Null } } catch {}
                }
            }
            try { [WinApi]::SetSystemFileCacheSize([IntPtr]-1, [IntPtr]-1, 0) | Out-Null } catch {}
            $ActionTaken = "God Mode (Frozen $SuspendCount apps & Services)"
        }
        '5' {
            Write-Host "[*] Waking up suspended processes and services..." -ForegroundColor $Level5Color
            $ResumeCount = 0
            $ResumeProcs = Get-Process -Name $SuspendTargets -ErrorAction SilentlyContinue
            foreach ($p in $ResumeProcs) { try { if ($p.Handle) { [WinApi]::NtResumeProcess($p.Handle) | Out-Null; $ResumeCount++ } } catch {} }
            foreach ($svc in $HibernationServices) { Start-Service -Name $svc -ErrorAction SilentlyContinue }
            $ActionTaken = "System Restored ($ResumeCount apps awoken)"
        }
        default { continue }
    }

    # ==========================================
    # Post-Optimization Report
    # ==========================================
    Start-Sleep -Seconds 2
    $MemAfter = Get-MemoryUsage
    $AfterColor = if ($MemAfter.Percent -ge 80) { "Red" } elseif ($MemAfter.Percent -ge 50) { "Yellow" } else { "Green" }

    Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
    Write-Host "[SUCCESS] Task completed." -ForegroundColor Green
    Write-Host ""
    
    Show-DynamicProgressBar -Percentage $MemAfter.Percent -BarColor $AfterColor -Label "[After]   Memory Allocation:" -MemoryText "($($MemAfter.Used) GB / $($MemAfter.Total) GB)"
    
    if ($Choice -ne '5') {
        $SavedMB = [math]::Round((($MemBefore.Used - $MemAfter.Used) * 1024), 2)
        if ($SavedMB -gt 0) {
            Write-Host "[INFO] Released: $SavedMB MB of RAM ($ActionTaken)" -ForegroundColor White
        } else {
            Write-Host "[INFO] Released: 0 MB ($ActionTaken - Already Optimized)" -ForegroundColor White
        }
    } else {
        Write-Host "[INFO] Released: N/A ($ActionTaken)" -ForegroundColor White
    }

    Write-Host "`n[ACTION] Press ANY KEY to return to the Main Menu." -ForegroundColor Yellow
    Write-Host "Support: Lightspeed Sharing (YT)" -ForegroundColor Magenta
    Write-Host ("=" * 60) -ForegroundColor Cyan

    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}