# --- 1. PRE-RESOLVED PATHS ---
if ($env:SSH_CONNECTION) {
    $EZA_BIN = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\*eza*\eza.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    $FNM_BIN = (Get-ChildItem "$env:USERPROFILE\scoop\apps\fnm\*\fnm.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    $ZOXIDE_BIN = $null
} else {
    $EZA_BIN = "eza"
    $ZOXIDE_BIN = "zoxide"
    $FNM_BIN = "fnm"
}

$isInteractive = -not ([Console]::IsOutputRedirected -or [Console]::IsInputRedirected)

# --- CACHE DIRECTORY SETUP ---
$cacheDir = "$env:LOCALAPPDATA\pwsh_cache"
if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null }

# --- 2. CORE VISUALS ---
if ($isInteractive) {
    $ompCache = "$cacheDir\omp.ps1"
    $ompTheme = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\catppuccin_macchiato.omp.json"
    $ompExe = (Get-Command oh-my-posh -ErrorAction SilentlyContinue).Source

    if ($ompExe -and (Test-Path $ompTheme)) {
        $cacheFile = Get-Item $ompCache -ErrorAction SilentlyContinue
        
        $needsUpdate = -not $cacheFile -or 
                       ($cacheFile.LastWriteTime -lt (Get-Item $ompExe).LastWriteTime) -or 
                       ($cacheFile.LastWriteTime -lt (Get-Item $ompTheme).LastWriteTime)
        
        if ($needsUpdate) {
            & $ompExe init pwsh --config $ompTheme --print > $ompCache
        }
        . $ompCache
    }
}

# --- 3. BEHAVIOR & MODULES ---
if ($isInteractive) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
    # Shortcuts
    Set-PSReadlineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit
    Set-PSReadlineKeyHandler -Key Ctrl+l -Function ClearScreen
}

# FNM Initialization
if ($isInteractive -and $FNM_BIN -and ((Test-Path $FNM_BIN -ErrorAction SilentlyContinue) -or ($FNM_BIN -eq "fnm"))) {
    $fnmOutput = & $FNM_BIN env --use-on-cd --shell powershell
    if ($fnmOutput) { Invoke-Expression ($fnmOutput -join "`n") }
}

# Zoxide Initialization
if ($isInteractive -and -not $env:SSH_CONNECTION) {
    $zoxideCache = "$cacheDir\zoxide.ps1"
    
    if ($ZOXIDE_BIN -and ((Test-Path $ZOXIDE_BIN -ErrorAction SilentlyContinue) -or ($ZOXIDE_BIN -eq "zoxide"))) {
        $actualZoxideExe = if ($ZOXIDE_BIN -eq "zoxide") { (Get-Command zoxide -ErrorAction SilentlyContinue).Source } else { $ZOXIDE_BIN }
        
        if ($actualZoxideExe) {
            $cacheFile = Get-Item $zoxideCache -ErrorAction SilentlyContinue
            $exeFile = Get-Item $actualZoxideExe -ErrorAction SilentlyContinue

            $needsUpdate = -not $cacheFile -or ($cacheFile.LastWriteTime -lt $exeFile.LastWriteTime)
            
            if ($needsUpdate) {
                & $actualZoxideExe init powershell --cmd cd > $zoxideCache
            }
            . $zoxideCache
        }
    }
}

# --- 4. LAZY LOADING & OVERRIDES ---
function ls { 
    if (Get-Command $EZA_BIN -ErrorAction SilentlyContinue) {
        & $EZA_BIN --icons --group-directories-first $args 
    } else {
        Get-ChildItem $args
    }
}

if ($env:SSH_CONNECTION) {
    function fnm { & $FNM_BIN $args }
    function eza { & $EZA_BIN $args }
}

function fzf {
    if (!(Get-Module PSFzf)) { 
        Import-Module PSFzf -ErrorAction SilentlyContinue 
        # Set fd as the default search engine for fzf
        $env:FZF_DEFAULT_COMMAND = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git"
        $env:FZF_CTRL_T_COMMAND = $env:FZF_DEFAULT_COMMAND
        Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
    }
    fzf.exe $args
}

function uv {
    if (!($global:uv_init)) {
        $global:uv_init = $true
        uv generate-shell-completion powershell | Out-String | Invoke-Expression
    }
    & (Get-Command uv.exe -CommandType Application).Source $args
}

# --- 5. ALIASES & FUNCTIONS ---
$env:EDITOR = "C:\Program Files\Notepad++\notepad++.exe"

if (Test-Path Alias:ls) { Remove-Item Alias:ls -Force }
if (Test-Path Alias:where) { Remove-Item Alias:where -Force }

if (-not $env:SSH_CONNECTION) {
    Set-Alias -Name sudo -Value gsudo
    function choco { gsudo choco $args }
}

Set-Alias -Name rg -Value ripgrep
Set-Alias -Name f -Value fd

function which { (Get-Command $args[0] -ErrorAction 0).Source }
function npp   { & "C:\Program Files\Notepad++\notepad++.exe" $args }
function subl  { & "C:\Program Files\Sublime Text\subl.exe" $args }
function edit-profile { chezmoi edit "$env:USERPROFILE\.pwsh_profile.ps1" }
function reload-profile { chezmoi apply; . $PROFILE }