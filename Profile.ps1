Set-Alias grep Select-String
Set-Alias which Get-Command
Set-PSReadlineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Key Tab -Function Complete
(Get-PSReadLineOption).HistorySearchCursorMovesToEnd = $True

$onedrive = "OneDrive - National Institutes of Health"
$onepath = "N:"
if ((Test-Path $onepath) -eq $false) {
    Write-Host ("Assigning {0} as {1}" -f $onedrive, $onepath)
    subst $onepath [IO.Path]::Combine($HOME, $onedrive)
}

#$host.PrivateData.ErrorForegroundColor = 'Black'
#$host.PrivateData.ErrorBackgroundColor = 'White'
Set-PSReadLineOption -Colors @{
  Command            = 'White'
  Number             = 'Green'
  Member             = 'White'
  Operator           = 'Green'
  Type               = 'White'
  Variable           = 'Green'
  Parameter          = 'Green'
  ContinuationPrompt = 'White'
  Default            = 'White'
}

function prompt {
    #$idx = $pwd.ProviderPath.LastIndexof("\") + 1
    #$cdn = $pwd.ProviderPath.Remove(0, $idx)
    $cdn = $pwd.ProviderPath

    (Get-Host).UI.RawUI.WindowTitle = $cdn + " (" + $pwd + ") "

   if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
         [Security.Principal.WindowsBuiltInRole] "Administrator")) {
        #Write-Host $env:UserDomain -NoNewLine -ForegroundColor "Red"
        Write-Host $env:OS -NoNewLine -ForegroundColor "Red"
        Write-Host ":" -NoNewLine -ForegroundColor "White"
        Write-Host $cdn -NoNewLine -ForegroundColor "Red"
        return "# "
    }

    #Write-Host $env:UserDomain -NoNewLine -ForegroundColor "Green"
    Write-Host $env:OS -NoNewLine -ForegroundColor "Green"
    Write-Host ":" -NoNewLine -ForegroundColor "White"
    Write-Host $cdn -NoNewLine -ForegroundColor "Green"
    return "% "
}

function goenv ($name = "gpu") {
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
    $spim = "Y:\spim\"
    $lsm = "Y:\lsm"
    $tirf = "Y:\tirf"
    switch ($name) {
    "bin"  {$folder = [IO.Path]::Combine($HOME, $name)}
    "env"  {$folder = [IO.Path]::Combine($HOME, $name)}
    "home" {$folder = "$HOME"}
    "2021" {$folder = [IO.Path]::Combine($spim, $name)}
    "2020" {$folder = [IO.Path]::Combine($spim, $name)}
    "2019" {$folder = [IO.Path]::Combine($spim, $name)}
    "lsm"  {$folder = $lsm}
    "tirf" {$folder = $tirf}
    "conf" {$folder = [IO.Path]::Combine($HOME, "Documents", "WindowsPowershell")}
    "one" {$folder = $onepath}
    "data" {$folder = [IO.Path]::Combine($onepath, "analysis")}
    default {
        Write-Host "Not matched: {0}" -f $name
        $folder = "."
    }
    }
    Set-Location $folder
}

function keepconnect {
    while (1) {
        Write-Output "keepalive" > temporary_file_to_keep_connection.txt
        Write-Output "keeping access"
        Start-Sleep 5
    }
}

function pshell {
    start-process powershell
}

Import-Module posh-git
