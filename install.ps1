<#
=================================================================
  Bootstrap launcher for the Everyday Apps Installer
  -----------------------------------------------------------------
  This tiny script simply downloads and runs the main installer
  (Install-Apps.ps1) from the GitHub repository.

  Usage from any machine (PowerShell):

      irm https://raw.githubusercontent.com/USER/REPO/main/install.ps1 | iex

  Replace USER/REPO below with your own GitHub username / repo name.
=================================================================
#>

$mainScript = "https://raw.githubusercontent.com/hagyopatrik/hpctech-installer/refs/heads/main/Install-Apps.ps1"

Write-Host "Fetching the latest installer..." -ForegroundColor Cyan

try {
    $code = Invoke-RestMethod -Uri $mainScript -UseBasicParsing
    Invoke-Expression $code
}
catch {
    Write-Host "[!] Failed to download or run the installer." -ForegroundColor Red
    Write-Host "    URL: $mainScript" -ForegroundColor DarkGray
    Write-Host "    $($_.Exception.Message)" -ForegroundColor DarkGray
    Read-Host "Press Enter to exit"
}
