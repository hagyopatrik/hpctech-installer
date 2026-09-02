# 🚀 HPC Tech App Installer

A menu-driven **PowerShell** tool that provisions a fresh Windows machine in minutes.
Pick apps from a categorized menu, select many at once, and they install **in the exact order you choose** — silently, no clicking through prompts.

Powered by **winget** with automatic **Chocolatey** fallback for packages that aren't on winget (e.g. HP Support Assistant).

---

## ✨ Features

- 📂 **Categorized menu** — 9 categories, numbered for quick selection
- ✅ **Multi-select** — type several numbers at once, installed **in order**
- 📦 **Default App Pack** (`P`) — one key installs a curated everyday set
- 🧰 **Install ALL** (`A`) — everything in the list
- 🗑️ **Uninstall all listed apps** (`X`) — with a `YES` confirmation guard
- 🍫 **winget + Chocolatey** — per-app source; Chocolatey is **auto-installed** only when a `[choco]` app is selected
- 🖥️ **OEM support tools** — HP / Lenovo / Dell driver & firmware helpers
- 🔐 **Self-elevating** — automatically relaunches as Administrator
- 🌍 **Run from anywhere** — single command via a short Cloudflare URL

---

## 📥 Quick start

Run it with a single line — **no download needed**:

```powershell
irm https://installer.hpctech.hu | iex
```

Direct raw URL (if you prefer):

```powershell
irm https://raw.githubusercontent.com/hagyopatrik/hpctech-installer/refs/heads/main/Install-Apps.ps1 | iex
```

If script execution is blocked on the machine:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://installer.hpctech.hu | iex"
```

> 💡 The script **self-elevates**: if it isn't already running as Administrator, it relaunches itself elevated (re-fetching from the raw URL when run via `irm | iex`, since no file exists on disk). For the smoothest run, start an **Administrator** PowerShell first.

---

## 🎮 How to use the menu

Type your selection and press **Enter**:

| Input | Meaning |
|-------|---------|
| `1 4 8` | install items 1, 4 and 8 |
| `1,4,8` | commas work too |
| `A` | install **ALL** listed apps |
| `P` | install the **Default App Pack** |
| `X` | **uninstall all** listed apps (asks for `YES` to confirm) |
| `Q` | quit |

The order you type the numbers is the order they install in. After each run the tool asks **Back to the menu? (Y/N)**.

### 📦 Default App Pack (`P`)

Installs the following, **in this order**:

**Google Chrome → Mozilla Firefox → Brave → WinRAR → VLC → TeamViewer → AnyDesk → Microsoft 365 (Office) → Adobe Acrobat Reader → Driver Booster**

---

## 📦 Included apps

| Category | Apps | Source |
|----------|------|--------|
| **Browsers** | Google Chrome, Mozilla Firefox, Brave Browser | winget |
| **Compression** | 7-Zip, WinRAR | winget |
| **Media** | VLC Media Player, Spotify | winget |
| **Development** | Visual Studio Code, Python 3, Notepad++ | winget |
| **Gaming & Torrent** | Steam, qBittorrent | winget |
| **Communication & Remote** | Microsoft Teams, TeamViewer, AnyDesk | winget |
| **Office & Documents** | Microsoft 365 (Office), Adobe Acrobat Reader | winget |
| **OEM Support Tools** | HP Support Assistant `[choco]`, Lenovo System Update, Dell Command Update | winget / choco |
| **System & Diagnostics** | AIDA64 Extreme, HWiNFO, CrystalDiskMark, Driver Booster | winget |

> Apps marked **`[choco]`** are installed via Chocolatey because they aren't available on winget. The rest use winget.

---

## 🍫 winget + Chocolatey (mixed sources)

Each app defines a `Source` — `winget` (default) or `choco`:

```powershell
# winget (default - no Source needed)
@{ Name = "Google Chrome"; Id = "Google.Chrome" }

# Chocolatey
@{ Name = "HP Support Assistant"; Id = "hpsupportassistant"; Source = "choco" }
```

- If you select a `[choco]` app and Chocolatey isn't present, the script **installs Chocolatey automatically** (official install script), refreshes the session `PATH`, then continues.
- Install / uninstall both respect the per-app source (`winget install/uninstall` or `choco install/uninstall`).

---

## 🖥️ OEM support tools

Vendor equivalents of "HP Support Assistant" for driver, firmware and health updates:

- **HP** — HP Support Assistant (via Chocolatey)
- **Lenovo** — Lenovo System Update (`Lenovo.SystemUpdate`)
- **Dell** — Dell Command | Update (`Dell.CommandUpdate`)

> Package IDs occasionally change. Verify with `winget search "dell command update"` or `choco search hpsupportassistant` if one fails.

---

## 🗑️ Uninstall all (`X`)

Choosing `X` walks the **entire menu list** and removes each app (using its source).
A safety prompt requires typing **`YES`** before anything is removed. Apps that aren't installed are simply skipped.

---

## 🛠️ Customizing the app list

Edit the `$apps` ordered hashtable — add a line under any category:

```powershell
# winget package
@{ Name = "App Name"; Id = "Publisher.Package" }

# Chocolatey package
@{ Name = "App Name"; Id = "choco-package-id"; Source = "choco" }
```

To add something to the **Default App Pack**, add its **Id** to the `$defaultPack` array (order matters).

Find package ids with:

```powershell
winget search "app name"
choco search "app name"
```

## ✅ Requirements

- Windows 10 / 11
- **winget** (App Installer) — preinstalled on modern Windows; otherwise from the Microsoft Store
- Administrator rights (the script self-elevates)
- Internet connection

---



## 📄 License

MIT — free to use, modify and share for personal or internal IT purposes.
