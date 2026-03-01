# ================================================================
#  MidgeTech - Pokebot Full Setup Script
#  Python 3.12.12 Compile + Dependency Install for PKHex+PKboty
#  Author: MidgeTech
#  Tested: 3/1/2026 - Windows 11, VS 2022 Community
# ================================================================
#
#  REQUIREMENTS BEFORE RUNNING:
#    - Visual Studio 2022 with:
#        [x] Desktop development with C++
#        [x] Python development workload
#        [x] Python native development tools component
#    - Internet connection (downloads Python source + packages)
#    - Run PowerShell as Administrator
#
#  USAGE:
#    powershell -ExecutionPolicy Bypass -File setup_pokebot.ps1
# ================================================================

$ErrorActionPreference = "Stop"

$ROOT     = "E:\PKHex+PKboty"
$PY_ROOT  = "$ROOT\python"
$VERSION  = "3.12.12"
$SRC_DIR  = "$PY_ROOT\Python-$VERSION"
$TGZ_FILE = "$PY_ROOT\Python-$VERSION.tgz"
$TGZ_URL  = "https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tgz"
$PCBUILD  = "$SRC_DIR\PCbuild"
$PY       = "$PCBUILD\amd64\python.exe"

$VS_PATHS = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
)

function Banner($msg, $color="Magenta") {
    Write-Host "`n=============================================" -ForegroundColor $color
    Write-Host "  $msg" -ForegroundColor $color
    Write-Host "=============================================`n" -ForegroundColor $color
}

function Step($n, $msg) {
    Write-Host "[$n] $msg" -ForegroundColor Cyan
}

function OK($msg)   { Write-Host "     OK: $msg" -ForegroundColor Green }
function WARN($msg) { Write-Host "     WARN: $msg" -ForegroundColor Yellow }
function FAIL($msg) { Write-Host "`n[FAIL] $msg" -ForegroundColor Red; Exit 1 }

Banner "MidgeTech - Pokebot Full Setup"

# ── STEP 1: Root folder ───────────────────────────────────────────────────────
Step 1 "Checking folders..."
If (!(Test-Path $PY_ROOT)) { New-Item -ItemType Directory -Path $PY_ROOT | Out-Null }
OK $PY_ROOT

# ── STEP 2: Download Python source ───────────────────────────────────────────
Step 2 "Checking Python $VERSION source download..."
If (!(Test-Path $TGZ_FILE)) {
    Write-Host "     Downloading (~27MB)..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $TGZ_URL -OutFile $TGZ_FILE -UseBasicParsing
    OK "Downloaded: $TGZ_FILE"
} Else {
    $sz = [math]::Round((Get-Item $TGZ_FILE).Length/1MB,1)
    OK "Already downloaded ($sz MB)"
}

# ── STEP 3: Extract source ────────────────────────────────────────────────────
Step 3 "Checking extraction..."
If (Test-Path $PCBUILD) {
    OK "PCbuild already exists - skipping extract"
} Else {
    If (Test-Path $SRC_DIR) {
        WARN "Incomplete folder found - removing..."
        Remove-Item -Recurse -Force $SRC_DIR
    }
    # Extract to TEMP first — avoids '+' in path breaking tar
    $TMP = "$env:TEMP\py_build_temp"
    If (Test-Path $TMP) { Remove-Item -Recurse -Force $TMP }
    New-Item -ItemType Directory -Path $TMP | Out-Null
    Write-Host "     Extracting to temp path..." -ForegroundColor Yellow
    & tar -xzf "$TGZ_FILE" -C "$TMP"
    If ($LASTEXITCODE -ne 0) { FAIL "tar extraction failed" }
    $extracted = Get-ChildItem $TMP | Select-Object -First 1
    Move-Item "$TMP\$($extracted.Name)" $SRC_DIR
    Remove-Item -Recurse -Force $TMP -ErrorAction SilentlyContinue
    If (!(Test-Path $PCBUILD)) { FAIL "PCbuild missing after extraction" }
    OK "Extracted: $SRC_DIR"
}

# ── STEP 4: Compile Python ────────────────────────────────────────────────────
Step 4 "Compiling Python $VERSION..."

If (Test-Path $PY) {
    OK "python.exe already built - skipping compile"
} Else {
    $VS_PATH = $VS_PATHS | Where-Object { Test-Path $_ } | Select-Object -First 1
    If (!$VS_PATH) {
        Write-Host "`n     Visual Studio 2022 not found. Install it with:" -ForegroundColor Red
        Write-Host "       - Desktop development with C++" -ForegroundColor Yellow
        Write-Host "       - Python development workload" -ForegroundColor Yellow
        Write-Host "       - Python native development tools" -ForegroundColor Yellow
        Write-Host "     https://visualstudio.microsoft.com/vs/community/" -ForegroundColor White
        FAIL "Visual Studio not found"
    }
    OK "VS found: $VS_PATH"
    Write-Host "     Stripping PATH to avoid CMD 8191-char overflow..." -ForegroundColor Gray
    Write-Host "     Building... this takes 10-20 min. Coffee time." -ForegroundColor Yellow

    $BATCH = "$env:TEMP\run_python_build.bat"
    $stream = [System.IO.StreamWriter]::new($BATCH, $false, [System.Text.Encoding]::ASCII)
    $stream.WriteLine("@echo off")
    $stream.WriteLine("set PATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0")
    $stream.WriteLine("call `"$VS_PATH`"")
    $stream.WriteLine("if errorlevel 1 ( echo [FAIL] vcvars64 failed & exit /b 1 )")
    $stream.WriteLine("cd /d `"$PCBUILD`"")
    $stream.WriteLine("if errorlevel 1 ( echo [FAIL] cd to PCbuild failed & exit /b 1 )")
    $stream.WriteLine("call build.bat -p x64")
    $stream.WriteLine("exit /b %ERRORLEVEL%")
    $stream.Close()

    cmd /c "`"$BATCH`""
    $buildExit = $LASTEXITCODE
    Remove-Item $BATCH -ErrorAction SilentlyContinue

    If (!(Test-Path $PY) -or $buildExit -ne 0) {
        FAIL "Compile failed (exit $buildExit) - check MSBuild output above"
    }
    OK "Python compiled: $PY"
    & $PY --version
}

# ── STEP 5: Bootstrap pip ─────────────────────────────────────────────────────
Step 5 "Bootstrapping pip..."
& $PY -m ensurepip --upgrade 2>&1 | Out-Null
& $PY -m pip install --upgrade pip --quiet
OK "pip ready"

# ── STEP 6: Install pywin32 (must be force-installed into THIS Python) ────────
Step 6 "Installing pywin32 into compiled Python..."
& $PY -m pip install pywin32 --force-reinstall --no-user --quiet
# Verify
$win32test = & $PY -c "import win32api; print('OK')" 2>&1
If ($win32test -match "OK") {
    OK "win32api working"
} Else {
    FAIL "win32api import failed after install: $win32test"
}

# ── DONE ──────────────────────────────────────────────────────────────────────
Banner "SETUP COMPLETE - Ready to run Pokebot!" "Green"
Write-Host "  Python: $PY" -ForegroundColor White
Write-Host "  To launch the bot:" -ForegroundColor Cyan
Write-Host "  `$py = `"$PY`"" -ForegroundColor White
Write-Host "  & `$py pokebot.py" -ForegroundColor White
Write-Host ""
