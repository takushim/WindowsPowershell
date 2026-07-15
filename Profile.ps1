# ============================================================
# Color mode
#   $true  : light background
#   $false : dark background
# ============================================================
$UseLightBackground = $true


Set-Alias grep Select-String
Set-Alias which Get-Command

Set-PSReadLineKeyHandler -Key Ctrl+d    -Function DeleteCharOrExit
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab       -Function Complete

(Get-PSReadLineOption).HistorySearchCursorMovesToEnd = $true


# ============================================================
# Color definitions
# ============================================================
if ($UseLightBackground) {
    # Light-background colors
    $PSReadLineColors = @{
        Command            = 'DarkBlue'
        Number             = 'DarkCyan'
        Member             = 'DarkBlue'
        Operator           = 'DarkGray'
        Type               = 'DarkMagenta'
        Variable           = 'DarkGreen'
        Parameter          = 'DarkMagenta'
        String             = 'DarkRed'
        Keyword            = 'DarkBlue'
        Comment            = 'DarkGray'
        Error              = 'DarkRed'
        Emphasis           = 'DarkMagenta'
        ContinuationPrompt = 'DarkGray'
        Default            = 'Black'
    }

    $PromptNormalColor    = 'DarkGreen'
    $PromptAdminColor     = 'DarkRed'
    $PromptSeparatorColor = 'DarkGray'

    $Host.PrivateData.ErrorForegroundColor   = 'DarkRed'
    $Host.PrivateData.ErrorBackgroundColor   = 'White'
    $Host.PrivateData.WarningForegroundColor = 'DarkMagenta'
    $Host.PrivateData.WarningBackgroundColor = 'White'
    $Host.PrivateData.VerboseForegroundColor = 'DarkCyan'
    $Host.PrivateData.VerboseBackgroundColor = 'White'
    $Host.PrivateData.DebugForegroundColor   = 'DarkGray'
    $Host.PrivateData.DebugBackgroundColor   = 'White'
}
else {
    # Dark-background colors
    $PSReadLineColors = @{
        Command            = 'White'
        Number             = 'Green'
        Member             = 'White'
        Operator           = 'Green'
        Type               = 'Cyan'
        Variable           = 'Green'
        Parameter          = 'Green'
        String             = 'Yellow'
        Keyword            = 'Cyan'
        Comment            = 'DarkGray'
        Error              = 'Red'
        Emphasis           = 'Cyan'
        ContinuationPrompt = 'White'
        Default            = 'White'
    }

    $PromptNormalColor    = 'Green'
    $PromptAdminColor     = 'Red'
    $PromptSeparatorColor = 'White'

    $Host.PrivateData.ErrorForegroundColor   = 'Red'
    $Host.PrivateData.ErrorBackgroundColor   = 'Black'
    $Host.PrivateData.WarningForegroundColor = 'Yellow'
    $Host.PrivateData.WarningBackgroundColor = 'Black'
    $Host.PrivateData.VerboseForegroundColor = 'Cyan'
    $Host.PrivateData.VerboseBackgroundColor = 'Black'
    $Host.PrivateData.DebugForegroundColor   = 'Gray'
    $Host.PrivateData.DebugBackgroundColor   = 'Black'
}

Set-PSReadLineOption -Colors $PSReadLineColors

$env:VIRTUAL_ENV_DISABLE_PROMPT = "1"
function prompt {
    $cdn = $pwd.ProviderPath

    (Get-Host).UI.RawUI.WindowTitle = $cdn + " (" + $pwd + ") "

    $isAdministrator = (
        [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    $venvName = $null

    if ($env:VIRTUAL_ENV) {
        $venvName = Split-Path -Leaf $env:VIRTUAL_ENV
    }

    if ($isAdministrator) {
        if ($venvName) {
            Write-Host "($venvName) " `
                -NoNewline `
                -ForegroundColor $PromptAdminColor
        }

        Write-Host $env:OS `
            -NoNewline `
            -ForegroundColor $PromptAdminColor

        Write-Host ":" `
            -NoNewline `
            -ForegroundColor $PromptSeparatorColor

        Write-Host $cdn `
            -ForegroundColor $PromptAdminColor

        return "# "
    }

    if ($venvName) {
        Write-Host "($venvName) " `
            -NoNewline `
            -ForegroundColor $PromptNormalColor
    }

    Write-Host $env:OS `
        -NoNewline `
        -ForegroundColor $PromptNormalColor

    Write-Host ":" `
        -NoNewline `
        -ForegroundColor $PromptSeparatorColor

    Write-Host $cdn `
        -ForegroundColor $PromptNormalColor

    return "% "
}


if ($env:PATHEXT -notmatch '(^|;)\.PY($|;)') {
    $env:PATHEXT += ';.PY'
}


$dropbox_reg = "HKCU:\Software\SyncEngines\Providers\Dropbox"

$dropbox_ids = Get-ChildItem -Path $dropbox_reg -ErrorAction Stop |
    ForEach-Object {
        $n = $_.PSChildName
        $v = 0L

        if ([Int64]::TryParse($n, [ref]$v)) {
            [pscustomobject]@{
                Name   = $n
                Id     = $v
                PsPath = $_.PsPath
            }
        }
    } |
    Sort-Object Id

if ($dropbox_ids) {
    $dropbox_id = $dropbox_ids[0]

    $mountpoint = (
        Get-ItemProperty `
            -Path $dropbox_id.PsPath `
            -Name "MountPoint" `
            -ErrorAction Stop
    ).MountPoint

    $dropbox_folder = (
        Get-ChildItem `
            -LiteralPath "$mountpoint" `
            -Directory `
            -Force `
            -ErrorAction Stop |
        Where-Object {
            $_.Name -notlike '.*'
        }
    )[0].FullName

    $bin_path = Join-Path $dropbox_folder "bin"

    if (Test-Path -LiteralPath $bin_path -PathType Container) {
        $bin_folders = Get-ChildItem `
            -LiteralPath $bin_path `
            -Directory `
            -ErrorAction SilentlyContinue

        foreach ($folder in $bin_folders) {
            $env:PATH += ";$($folder.FullName)"

            $psh_path = Join-Path `
                -Path $folder.FullName `
                -ChildPath "scripts"

            if (Test-Path -LiteralPath $psh_path -PathType Container) {
                $env:PATH += ";$psh_path"
            }
        }
    }
}


function goenv ($name = "gpu2") {
    $envfile = [IO.Path]::Combine($HOME, ".venv", $name, "Scripts\Activate.ps1")
    if (Test-Path($envfile)) {
        . $envfile
    }
    else {
        Write-Host "No environment named:" $name 
    }
}

function lsenv {
    $envfolder = [IO.Path]::Combine($HOME, ".venv")
    $envlist = (Get-ChildItem -Directory -Name $envfolder)
    Write-Host "Folder:" $envfolder
    Write-Host "Environments:" $envlist
}

function cdenv {
    $envfolder = [IO.Path]::Combine($HOME, ".venv")
    Set-Location $envfolder
}

function goto ($name = "home") {
    switch ($name) {
    "bin"  {$folder = [IO.Path]::Combine($HOME, $name)}
    "env"  {$folder = [IO.Path]::Combine($HOME, $name)}
    "home" {$folder = "$HOME"}
    "config" {$folder = [IO.Path]::Combine($HOME, "Documents", "WindowsPowershell")}
    default {
        Write-Host "Not matched: {0}" -f $name
        $folder = "."
    }
    }
    Set-Location $folder
}

function pshell {
    Start-Process powershell
}

goenv
