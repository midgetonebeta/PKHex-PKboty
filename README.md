# MidgeTech - Pokebot Setup Guide
**PKHex+PKboty | Python 3.12.12 | Windows 11**
*Tested and working: March 1, 2026*

---

## Prerequisites

Before running the setup script, install **Visual Studio 2022 Community** (free):
https://visualstudio.microsoft.com/vs/community/

During install, select these workloads:
- **Desktop development with C++**
- **Python development**
- Under Individual Components: **Python native development tools**

---

## Quick Start (Fresh Machine)

```powershell
# 1. Open PowerShell as Administrator
# 2. Allow scripts
Set-ExecutionPolicy Bypass -Scope CurrentUser

# 3. Run the full setup script
E:\PKHex+PKboty\setup_pokebot.ps1
```

That's it. The script handles everything automatically.

---

## What the Script Does

| Step | Action |
|------|--------|
| 1 | Creates folder structure |
| 2 | Downloads Python 3.12.12 source (~27MB) |
| 3 | Extracts source (via TEMP to avoid path issues) |
| 4 | Compiles Python with VS 2022 (10-20 min) |
| 5 | Bootstraps pip |
| 6 | Installs `pywin32` into the compiled Python |

> **Note:** Bot dependencies are handled automatically by `pokebot.py` on first launch.
> It checks what's installed and prompts to download anything missing.

---

## Running the Bot

```powershell
$py = "E:\PKHex+PKboty\python\Python-3.12.12\PCbuild\amd64\python.exe"
cd E:\PKHex+PKboty
& $py pokebot.py
```

---

## Known Issues & Fixes

### "The input line is too long" during compile
**Cause:** Windows CMD has an 8191 char limit. A bloated system PATH + VS paths overflow it.
**Fix:** The script resets PATH to Windows essentials before calling `vcvars64.bat`. Already handled automatically.

### `win32api` ModuleNotFoundError
**Cause:** `pywin32` installed to system Python instead of the compiled one.
**Fix:**
```powershell
$py = "E:\PKHex+PKboty\python\Python-3.12.12\PCbuild\amd64\python.exe"
& $py -m pip install pywin32 --force-reinstall --no-user
```

### `git describe` warning during compile
**Cause:** Git is not on PATH during the build.
**Status:** Harmless — 0 errors, just a cosmetic warning. Python builds fine.

### PCbuild folder missing after extraction
**Cause:** The `+` character in `PKHex+PKboty` breaks Windows `tar` when used as output path.
**Fix:** The script extracts to `%TEMP%` first, then moves to final destination. Already handled automatically.

---

## File Locations

| File | Path |
|------|------|
| Compiled Python | `E:\PKHex+PKboty\python\Python-3.12.12\PCbuild\amd64\python.exe` |
| pip | `E:\PKHex+PKboty\python\Python-3.12.12\Scripts\pip.exe` |
| Bot entry point | `E:\PKHex+PKboty\pokebot.py` |
| Bot config | `E:\PKHex+PKboty\cfg.json` |
| Setup script | `E:\PKHex+PKboty\setup_pokebot.ps1` |

---

## Dependencies Installed by Script

- `pywin32` (Windows API access for bot emulator control)
- `pip 26` (latest)

> All other bot packages are handled by `pokebot.py` itself on first run.

---

*Built Different. Fixed Right. — MidgeTech*
