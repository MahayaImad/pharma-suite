# Arrete et supprime la tache planifiee de l'agent PharmaSuite.
# A lancer dans une console PowerShell ouverte EN ADMINISTRATEUR :
#
#     powershell -ExecutionPolicy Bypass -File desinstaller_tache.ps1
#
# Ne touche ni a config.toml ni a agent.log.

param([string]$Nom = "PharmaSuite Agent EASYPHARM")

$tache = Get-ScheduledTask -TaskName $Nom -ErrorAction SilentlyContinue
if (-not $tache) {
    Write-Host "Aucune tache '$Nom' : rien a faire."
    exit 0
}

Stop-ScheduledTask -TaskName $Nom -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $Nom -Confirm:$false
Write-Host "Tache '$Nom' arretee et supprimee." -ForegroundColor Green
