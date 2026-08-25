# 🚀 HPC Tech App Installer

A tiny, menu-driven **winget** installer for setting up a fresh Windows machine in minutes.
Pick apps from a categorized menu, select many at once, and they install **in the exact order you choose** — silently, no clicking through prompts.

> Two flavors included: a **PowerShell** version (recommended, one-line run) and a **Batch** version.

---

## ✨ Features

- 📂 **Categorized menu** — Browsers, Essentials, Media, Comms, Dev, Utilities
- ✅ **Multi-select** — type several numbers at once, installed **in order**
- 🔤 **One-letter presets** — whole categories with a single key
- 🔢 **Ranges** — e.g. `20-24`
- ⚡ **Fully silent** — `--silent --disable-interactivity`, runs unattended
- 🧩 **Easy to customize** — just edit one list to add/remove apps

---

## 📥 Quick start

### PowerShell (recommended)
Run it with a single line — **no download needed**:

```powershell
irm https://installer.hpctech.hu | iex
```

If script execution is blocked on the machine:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://installer.hpctech.hu | iex"
```

> 💡 For system-wide apps, start PowerShell as **Administrator** first — a one-liner can't self-elevate because nothing is written to disk.

### Batch
Download and run (needs a temp file — `.bat` can't be piped):

```cmd
curl -L https://installer.hpctech.hu -o a.bat && a.bat
```

Then **right-click ▸ Run as administrator**.

---

## 🎮 How to use the menu

Type your selection and press **Enter**. Everything is mixable:

| Input | Meaning |
|-------|---------|
| `1 4 7` | install items 1, 4 and 7 |
| `1,4,7` | commas work too |
| `20-24` | a range of items |
| `E` | preset: all **Essentials** |
| `E B 20-24 30` | mix presets, ranges & numbers — installed **in that order** |
| `A` | install **everything** |
| `Q` | quit |

### Preset letters

| Key | Category |
|-----|----------|
| **E** | Essentials |
| **B** | Browsers |
| **D** | Dev |
| **M** | Media |
| **C** | Comms |
| **U** | Utilities |

---

## 📦 Included apps

| Category | Apps |
|----------|------|
| **Browsers** | Google Chrome, Mozilla Firefox, Brave |
| **Essentials** | 7-Zip, Notepad++, VLC, Adobe Acrobat Reader, PowerToys, Everything |
| **Media** | Spotify, K-Lite Codec Pack, GIMP, ShareX, OBS Studio |
| **Comms** | Microsoft Teams, Zoom, Discord, Slack, Telegram |
| **Dev** | VS Code, Git, Python 3, Node.js LTS, Windows Terminal, PowerShell 7, PuTTY, WinSCP |
| **Utilities** | Google Drive, Dropbox, TeamViewer, AnyDesk, Malwarebytes, Steam |

---

## 🛠️ Customizing the app list

**PowerShell** — edit the `$Apps` array:

```powershell
@{N='App Name'; Id='Publisher.Package'; C='Category'}
```

**Batch** — add a line in the catalog:

```bat
call :add "App Name" "Publisher.Package" "Category"
```

Find any package id with:

```powershell
winget search "app name"
```

---

## ✅ Requirements

- Windows 10 / 11
- **winget** (App Installer) — preinstalled on modern Windows; otherwise grab it from the Microsoft Store
- Administrator rights for system-wide installs

---

## 📄 License

MIT — free to use, modify and share.
