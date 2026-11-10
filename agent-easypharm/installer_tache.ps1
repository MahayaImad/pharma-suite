# Installe l'agent PharmaSuite comme tache planifiee Windows.
#
# A lancer dans une console PowerShell ouverte EN ADMINISTRATEUR, depuis ce dossier :
#
#     powershell -ExecutionPolicy Bypass -File installer_tache.ps1
#
# La tache demarre avec Windows (sans session ouverte), tourne en continu,
# et redemarre toute seule une minute apres un arret imprevu.
#
# Options :
#   -SessionUtilisateur : la tache demarre a l'ouverture de session de
#       l'utilisateur courant au lieu du demarrage de Windows. Choisi
#       d'office si Python est installe dans le profil d'un utilisateur.
#   -SansSession : avec un Python installe dans un profil, lance quand meme
#       la tache au demarrage de Windows, sous le compte de cet utilisateur,
#       sans session ouverte (mode S4U, aucun mot de passe enregistre).
#   -AvecFenetre : garde la console visible (python.exe). Par defaut la
#       tache tourne sans fenetre (pythonw.exe) ; tout est dans agent.log.
#
# Ce fichier est volontairement sans accents : PowerShell 5.1 lit les scripts
# sans BOM en ANSI.

param(
    [switch]$SessionUtilisateur,
    [switch]$SansSession,
    [switch]$AvecFenetre,
    [string]$Nom = "PharmaSuite Agent EASYPHARM"
)

$ErrorActionPreference = "Stop"
$dossier = $PSScriptRoot

# --- Verifications ---------------------------------------------------------

$estAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $estAdmin) {
    Write-Host "ERREUR : ouvrir PowerShell en administrateur (clic droit, Executer en tant qu'administrateur)." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path (Join-Path $dossier "config.toml"))) {
    Write-Host "ERREUR : config.toml introuvable dans $dossier." -ForegroundColor Red
    exit 1
}

$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) {
    Write-Host "ERREUR : python introuvable dans le PATH." -ForegroundColor Red
    exit 1
}

# Le chemin reel de l'interpreteur et l'emplacement des modules de l'agent.
$infos = & $python -c "import sys, win32com, httpx; print(sys.executable); print(win32com.__file__); print(httpx.__file__)"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR : pywin32 ou httpx manquant. Lancer : python -m pip install -r requirements.txt" -ForegroundColor Red
    exit 1
}
$python = $infos[0]

# Le compte SYSTEM ne voit ni un Python installe dans le profil d'un
# utilisateur, ni les modules installes avec pip --user.
$parUtilisateur = @($infos | Where-Object { $_ -like "$env:USERPROFILE\*" }).Count -gt 0
if ($parUtilisateur -and -not $SessionUtilisateur -and -not $SansSession) {
    Write-Host "Python ou ses modules sont installes dans le profil de $env:USERNAME :" -ForegroundColor Yellow
    Write-Host "  la tache sera lancee a l'ouverture de session de cet utilisateur," -ForegroundColor Yellow
    Write-Host "  pas au demarrage de Windows. (Option -SansSession pour l'eviter.)" -ForegroundColor Yellow
    $SessionUtilisateur = $true
}

# Sans fenetre : pythonw.exe, livre a cote de python.exe.
$executable = $python
if (-not $AvecFenetre) {
    $pythonw = Join-Path (Split-Path $python) "pythonw.exe"
    if (Test-Path $pythonw) {
        $executable = $pythonw
    } else {
        Write-Host "pythonw.exe introuvable a cote de python.exe : la console restera visible." -ForegroundColor Yellow
    }
}

# --- Tache -----------------------------------------------------------------

$action = New-ScheduledTaskAction -Execute $executable `
    -Argument "-m pharmasuite_agent --config config.toml" `
    -WorkingDirectory $dossier

if ($SansSession) {
    $utilisateur = "$env:USERDOMAIN\$env:USERNAME"
    $declencheur = New-ScheduledTaskTrigger -AtStartup
    $compte = New-ScheduledTaskPrincipal -UserId $utilisateur -LogonType S4U -RunLevel Limited
    $quand = "au demarrage de Windows, sous le compte $utilisateur, sans session"
} elseif ($SessionUtilisateur) {
    $utilisateur = "$env:USERDOMAIN\$env:USERNAME"
    $declencheur = New-ScheduledTaskTrigger -AtLogOn -User $utilisateur
    $compte = New-ScheduledTaskPrincipal -UserId $utilisateur -LogonType Interactive -RunLevel Limited
    $quand = "a l'ouverture de session de $utilisateur"
} else {
    $declencheur = New-ScheduledTaskTrigger -AtStartup
    $compte = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $quand = "au demarrage de Windows (compte SYSTEM)"
}

# Sans limite de duree, une seule instance, relance apres un arret imprevu,
# et pas d'arret quand le poste passe sur batterie.
$reglages = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) `
    -MultipleInstances IgnoreNew `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $Nom -Action $action -Trigger $declencheur `
    -Principal $compte -Settings $reglages -Force `
    -Description "Synchronise EASYPHARM (HFSQL) vers PharmaSuite. Journal : $dossier\agent.log" | Out-Null

Start-ScheduledTask -TaskName $Nom
Start-Sleep -Seconds 5
$etat = (Get-ScheduledTask -TaskName $Nom).State

Write-Host ""
Write-Host "Tache '$Nom' installee : demarrage $quand." -ForegroundColor Green
Write-Host "  Etat actuel : $etat"
Write-Host "  Programme   : $executable"
Write-Host "  Dossier     : $dossier"
Write-Host "  Journal     : $dossier\agent.log"
Write-Host ""
Write-Host "Suivre le journal :  Get-Content agent.log -Wait -Tail 20 -Encoding UTF8"
Write-Host "Arreter          :  Stop-ScheduledTask -TaskName '$Nom'"
Write-Host "Desinstaller     :  powershell -ExecutionPolicy Bypass -File desinstaller_tache.ps1"

if ($etat -ne "Running") {
    Write-Host ""
    Write-Host "ATTENTION : la tache ne tourne pas. Voir la fin de agent.log, ou lancer a la main :" -ForegroundColor Yellow
    Write-Host "  python -m pharmasuite_agent --config config.toml --tester" -ForegroundColor Yellow
    exit 1
}
