#Requires -Version 5.1
<#
=================================================================
  Everyday Apps Installer (PowerShell / winget)
  - Categorized menu, multi-select, installs in chosen order
  - Designed to run from anywhere with a single command:

      irm https://<your-raw-url>/Install-Apps.ps1 | iex

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

# ---------------- App catalog (ordered, categorized) ----------------
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
    "System & Diagnostics" = @(
        @{ Name = "AIDA64 Extreme";         Id = "FinalWire.AIDA64.Extreme" }
        @{ Name = "HWiNFO";                 Id = "REALiX.HWiNFO" }
        @{ Name = "CrystalDiskMark";        Id = "CrystalDewWorld.CrystalDiskMark" }
    )
}

# ---------------- Flatten into a numbered list ----------------
$flat = New-Object System.Collections.ArrayList
$index = 0
foreach ($cat in $apps.Keys) {
    foreach ($app in $apps[$cat]) {
        $index++
        [void]$flat.Add([pscustomobject]@{
            Num      = $index
            Name     = $app.Name
            Id       = $app.Id
            Category = $cat
        })
    }
}

# ---------------- Draw the menu ----------------
function Show-Menu {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "               EVERYDAY APPS INSTALLER  (winget)"                  -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    $lastCat = ""
    foreach ($item in $flat) {
        if ($item.Category -ne $lastCat) {
            Write-Host ""
            Write-Host "  --- $($item.Category) ---" -ForegroundColor DarkGray
            $lastCat = $item.Category
        }
        "{0,4})  {1}" -f $item.Num, $item.Name | Write-Host
    }
    Write-Host "----------------------------------------------------------------"
    Write-Host "     A)  Install ALL of the above" -ForegroundColor Green
    Write-Host "     Q)  Quit"                     -ForegroundColor Green
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
    Write-Host " Installing: $($item.Name)  ($($item.Id))" -ForegroundColor White
    Write-Host "----------------------------------------------------------------"
    winget install --id $item.Id --exact --silent `
        --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host " [OK] $($item.Name) done." -ForegroundColor Green
        return $true
    } else {
        Write-Host " [!!] $($item.Name) failed (exit $LASTEXITCODE)." -ForegroundColor Red
        return $false
    }
}

# ---------------- Main loop ----------------
do {
    Show-Menu
    $choice = Read-Host "Your selection"
    if ([string]::IsNullOrWhiteSpace($choice)) { continue }

    if ($choice.Trim().ToUpper() -eq "Q") { break }

    if ($choice.Trim().ToUpper() -eq "A") {
        $selection = $flat
    } else {
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
