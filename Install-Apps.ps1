#Requires -Version 5.1
<#
=================================================================
  HPC Tech App Installer (PowerShell / winget + Chocolatey)
  - Categorized menu, multi-select, installs in chosen order
  - Per-app source: winget OR choco (auto-installs choco if needed)
  - Default App Pack (P), Install all (A), Uninstall all (X)
  - Run from anywhere:

      irm https://installer.hpctech.hu | iex

  Run PowerShell as Administrator for silent installs.
=================================================================
#>

# ---------------- Self-elevate to Administrator ----------------
$curr = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $curr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevation required - restarting as Administrator..." -ForegroundColor Yellow
    $self = $MyInvocation.MyCommand.Definition
    if ($self -and (Test-Path $self)) {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$self`"" -Verb RunAs
    } else {
        # Running via irm | iex (no file on disk) -> re-fetch and run elevated
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/hagyopatrik/hpctech-installer/refs/heads/main/Install-Apps.ps1 | iex`"" -Verb RunAs
    }
    return
}

# ---------------- Check winget ----------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[!] winget was not found. Install 'App Installer' from the Microsoft Store." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    return
}

# ---------------- Ensure Chocolatey (only when a choco app is selected) ----------------
function Ensure-Choco {
    if (Get-Command choco -ErrorAction SilentlyContinue) { return $true }
    Write-Host ""
    Write-Host " Chocolatey not found - installing it now..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        # refresh PATH for current session
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
    } catch {
        Write-Host " [!!] Chocolatey install failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host " [OK] Chocolatey ready." -ForegroundColor Green
        return $true
    }
    Write-Host " [!!] Chocolatey is still not available." -ForegroundColor Red
    return $false
}

# ---------------- App catalog (ordered, categorized) ----------------
# Each app: Name, Id, Source ('winget' default, or 'choco')
$apps = [ordered]@{
    "Browsers" = @(
        @{ Name = "Google Chrome";          Id = "Google.Chrome" }
        @{ Name = "Mozilla Firefox";        Id = "Mozilla.Firefox" }
        @{ Name = "Brave Browser";          Id = "Brave.Brave" }
    )
    "Compression" = @(
        @{ Name = "7-Zip";                  Id = "7zip.7zip" }
        @{ Name = "WinRAR";                 Id = "RARLab.WinRAR" }
    )
    "Media" = @(
        @{ Name = "VLC Media Player";       Id = "VideoLAN.VLC" }
        @{ Name = "Spotify";                Id = "Spotify.Spotify" }
    )
    "Development" = @(
        @{ Name = "Visual Studio Code";     Id = "Microsoft.VisualStudioCode" }
        @{ Name = "Python 3";               Id = "Python.Python.3.12" }
        @{ Name = "Notepad++";              Id = "Notepad++.Notepad++" }
    )
    "Gaming & Torrent" = @(
        @{ Name = "Steam";                  Id = "Valve.Steam" }
        @{ Name = "qBittorrent";            Id = "qBittorrent.qBittorrent" }
    )
    "Communication & Remote" = @(
        @{ Name = "Microsoft Teams";        Id = "Microsoft.Teams" }
        @{ Name = "TeamViewer";             Id = "TeamViewer.TeamViewer" }
        @{ Name = "AnyDesk";                Id = "AnyDeskSoftwareGmbH.AnyDesk" }
    )
    "Office & Documents" = @(
        @{ Name = "Microsoft 365 (Office)"; Id = "Microsoft.Office" }
        @{ Name = "Adobe Acrobat Reader";   Id = "Adobe.Acrobat.Reader.64-bit" }
    )
    "OEM Support Tools" = @(
        @{ Name = "HP Support Assistant";   Id = "hpsupportassistant"; Source = "choco" }
        @{ Name = "Lenovo System Update";   Id = "Lenovo.SystemUpdate" }
        @{ Name = "Dell Command Update";    Id = "Dell.CommandUpdate" }
    )
    "System & Diagnostics" = @(
        @{ Name = "AIDA64 Extreme";         Id = "FinalWire.AIDA64.Extreme" }
        @{ Name = "HWiNFO";                 Id = "REALiX.HWiNFO" }
        @{ Name = "CrystalDiskMark";        Id = "CrystalDewWorld.CrystalDiskMark" }
        @{ Name = "Driver Booster";         Id = "IObit.DriverBooster" }
    )
}

# ---- Default App Pack (in order) ----
$defaultPack = @(
    "Google.Chrome"
    "Mozilla.Firefox"
    "Brave.Brave"
    "RARLab.WinRAR"
    "VideoLAN.VLC"
    "TeamViewer.TeamViewer"
    "AnyDeskSoftwareGmbH.AnyDesk"
    "Microsoft.Office"
    "Adobe.Acrobat.Reader.64-bit"
    "IObit.DriverBooster"
)

# ---------------- Flatten into a numbered list ----------------
$flat = New-Object System.Collections.ArrayList
$index = 0
foreach ($cat in $apps.Keys) {
    foreach ($app in $apps[$cat]) {
        $index++
        $src = if ($app.ContainsKey('Source')) { $app.Source } else { 'winget' }
        [void]$flat.Add([pscustomobject]@{
            Num      = $index
            Name     = $app.Name
            Id       = $app.Id
            Source   = $src
            Category = $cat
        })
    }
}

# ---------------- Draw the menu ----------------
function Show-Menu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "               HPC Tech App INSTALLER  (winget + choco)"          -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    $lastCat = ""
    foreach ($item in $flat) {
        if ($item.Category -ne $lastCat) {
            Write-Host ""
            Write-Host "  --- $($item.Category) ---" -ForegroundColor DarkGray
            $lastCat = $item.Category
        }
        $tag = if ($item.Source -eq 'choco') { "  [choco]" } else { "" }
        ("{0,4})  {1}{2}" -f $item.Num, $item.Name, $tag) | Write-Host
    }
    Write-Host "----------------------------------------------------------------"
    Write-Host "     A)  Install ALL of the above" -ForegroundColor Green
    Write-Host "     P)  Default App Pack"         -ForegroundColor Green
    Write-Host "     X)  Uninstall all listed apps" -ForegroundColor Magenta
    Write-Host "     Q)  Quit"                     -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Type numbers separated by spaces or commas (order = install order)."
    Write-Host "  Example:  1 4 8 15"
    Write-Host ""
}

# ---------------- Install one app ----------------
function Install-App($item) {
    Write-Host ""
    Write-Host "----------------------------------------------------------------"
    Write-Host " Installing: $($item.Name)  ($($item.Id)) [$($item.Source)]" -ForegroundColor White
    Write-Host "----------------------------------------------------------------"

    if ($item.Source -eq 'choco') {
        if (-not (Ensure-Choco)) { return $false }
        choco install $item.Id -y --no-progress
    } else {
        winget install --id $item.Id --exact --silent `
            --accept-package-agreements --accept-source-agreements
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host " [OK] $($item.Name) done." -ForegroundColor Green
        return $true
    } else {
        Write-Host " [!!] $($item.Name) failed (exit $LASTEXITCODE)." -ForegroundColor Red
        return $false
    }
}

# ---------------- Uninstall one app ----------------
function Uninstall-App($item) {
    Write-Host ""
    Write-Host "----------------------------------------------------------------"
    Write-Host " Uninstalling: $($item.Name)  ($($item.Id)) [$($item.Source)]" -ForegroundColor White
    Write-Host "----------------------------------------------------------------"

    if ($item.Source -eq 'choco') {
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Host " [skip] Chocolatey not installed - nothing to remove." -ForegroundColor Yellow
            return $false
        }
        choco uninstall $item.Id -y
    } else {
        winget uninstall --id $item.Id --exact --silent
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host " [OK] $($item.Name) removed." -ForegroundColor Green
        return $true
    } else {
        Write-Host " [!!] $($item.Name) not removed (exit $LASTEXITCODE - maybe not installed)." -ForegroundColor Yellow
        return $false
    }
}

# ---------------- Main loop ----------------
$again = "Y"
do {
    Show-Menu
    $choice = Read-Host "Your selection"
    if ([string]::IsNullOrWhiteSpace($choice)) { continue }

    $c = $choice.Trim().ToUpper()
    if ($c -eq "Q") { break }

    # --- Uninstall all listed apps ---
    if ($c -eq "X") {
        Write-Host ""
        Write-Host " WARNING: This will uninstall EVERY app listed in this menu." -ForegroundColor Magenta
        $confirm = Read-Host " Type YES to continue"
        if ($confirm -ne "YES") { Write-Host " Cancelled." -ForegroundColor Yellow; Start-Sleep 2; continue }

        $ok = 0; $fail = 0
        foreach ($item in $flat) {
            if (Uninstall-App $item) { $ok++ } else { $fail++ }
        }
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host " Finished.  Removed: $ok   Skipped/Failed: $fail"               -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""
        $again = Read-Host "Back to the menu? (Y/N)"
        continue
    }

    # --- Build selection for install ---
    if ($c -eq "A") {
        $selection = $flat
    }
    elseif ($c -eq "P") {
        $selection = foreach ($id in $defaultPack) {
            $flat | Where-Object { $_.Id -eq $id }
        }
    }
    else {
        $tokens = $choice -split '[,\s]+' | Where-Object { $_ -match '^\d+$' }
        $selection = foreach ($t in $tokens) {
            $found = $flat | Where-Object { $_.Num -eq [int]$t }
            if ($found) { $found } else { Write-Host " [skip] '$t' is not a valid number." -ForegroundColor Yellow }
        }
    }

    $ok = 0; $fail = 0
    foreach ($item in $selection) {
        if (Install-App $item) { $ok++ } else { $fail++ }
    }

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " Finished.  Installed OK: $ok   Failed/Skipped: $fail"           -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    $again = Read-Host "Back to the menu? (Y/N)"
} while ($again.Trim().ToUpper() -eq "Y")

Write-Host ""
Write-Host " Bye!" -ForegroundColor Cyan
