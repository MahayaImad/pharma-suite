# Guide d'utilisation — Agent EASYPHARM → PharmaSuite

Ce guide s'adresse à la personne qui exploite l'agent sur le PC de
l'officine. Pour l'installation initiale et le fonctionnement interne, voir
`README.md`.

Toutes les commandes se lancent depuis le dossier de l'agent :

```bat
cd D:\Sync_server\agent-easypharm
```

---

## 1. Ce que fait l'agent

Il copie les données d'EASYPHARM (39 tables : ventes, achats, stock, clients,
caisse, CHIFA…) vers le serveur PharmaSuite, en continu.

- Il **lit seulement** EASYPHARM. Il n'y écrit jamais.
- Il ne sort pas du réseau local : il parle uniquement au serveur PharmaSuite.
- Chaque table est relue à son rythme :

| Rythme | Tables |
|---|---|
| 15 min | lignes de ventes et d'achats, journal, ordonnancier, instances |
| 30 min | ventes, achats, opérations de caisse, factures CHIFA |
| 1 h | commandes, échanges, règlements, rejets CHIFA |
| 4 h | produits, clients, fournisseurs, comptes, bordereaux, sessions de caisse |
| 24 h | familles, formes, laboratoires, postes, inventaires… |

Une vente saisie dans EASYPHARM apparaît donc dans PharmaSuite dans la
demi-heure environ.

---

## 2. Au quotidien : rien à faire

L'agent est installé en tâche planifiée Windows, nommée
**« PharmaSuite Agent EASYPHARM »**. Il démarre tout seul, tourne sans
fenêtre, et redémarre une minute après un arrêt imprévu.

Si le PC est éteint, ou le réseau coupé, rien n'est perdu : au retour,
l'agent reprend là où il s'était arrêté.

---

## 3. Vérifier que tout va bien

### L'agent tourne-t-il ?

```bat
powershell -Command "(Get-ScheduledTask -TaskName 'PharmaSuite Agent EASYPHARM').State"
```

Réponse attendue : `Running`.

### Que fait-il en ce moment ?

```bat
powershell -Command "Get-Content agent.log -Wait -Tail 20 -Encoding UTF8"
```

(Ctrl+C pour quitter l'affichage ; l'agent continue.) En temps normal, une
ligne de ce genre apparaît toutes les 5 minutes :

```
Passe terminée en 12.4s — 87 ligne(s) sur 9 table(s)
```

### Y a-t-il eu des erreurs ?

```bat
findstr /C:"ERROR" agent.log
```

Aucune ligne = aucun problème.

### Les données sont-elles toutes arrivées ?

```bat
python -m pharmasuite_agent --config config.toml --verifier
```

Cette commande ne modifie rien. Pour chaque table, elle compare le nombre de
lignes dans EASYPHARM et dans PharmaSuite :

| Colonne « Écart » | Signification |
|---|---|
| `+0` | tout est arrivé |
| petit nombre positif | des lignes saisies depuis la dernière passe ; elles arrivent à la prochaine |
| grand nombre positif | la table n'est pas chargée : voir les erreurs du journal |
| nombre négatif | des lignes supprimées dans EASYPHARM sont encore dans PharmaSuite |

La colonne « Remarques » doit dire `OK`. « colonnes PERDUES » signifie
qu'EASYPHARM a de nouvelles colonnes que PharmaSuite ne connaît pas encore
(après une mise à jour d'EASYPHARM, par exemple) : le signaler.

À faire une fois par semaine, et après toute mise à jour d'EASYPHARM.

---

## 4. Commandes utiles

| Besoin | Commande |
|---|---|
| Tester les deux connexions | `python -m pharmasuite_agent --config config.toml --tester` |
| Comparer EASYPHARM et PharmaSuite | `python -m pharmasuite_agent --config config.toml --verifier` |
| Voir les tables et leur rythme | `python -m pharmasuite_agent --lister` |
| Resynchroniser une table tout de suite | `python -m pharmasuite_agent --config config.toml --table sorties` |
| Faire une passe complète à la main | `python -m pharmasuite_agent --config config.toml --une-passe` |

Ces commandes peuvent être lancées pendant que la tâche tourne.

### Arrêter et relancer la tâche

```bat
powershell -Command "Stop-ScheduledTask -TaskName 'PharmaSuite Agent EASYPHARM'"
powershell -Command "Start-ScheduledTask -TaskName 'PharmaSuite Agent EASYPHARM'"
```

Arrêter est sans risque à tout moment.

---

## 5. Mettre à jour l'agent

```bat
powershell -Command "Stop-ScheduledTask -TaskName 'PharmaSuite Agent EASYPHARM'"
git pull
python -m pip install -r requirements.txt
powershell -Command "Start-ScheduledTask -TaskName 'PharmaSuite Agent EASYPHARM'"
```

Si la mise à jour change la tâche elle-même (c'est indiqué quand c'est le
cas), la réinstaller dans PowerShell **en administrateur** :

```bat
powershell -ExecutionPolicy Bypass -File installer_tache.ps1
```

Réinstaller remplace la tâche existante ; il n'y a pas besoin de la
désinstaller avant.

---

## 6. En cas de problème

Commencer toujours par :

```bat
python -m pharmasuite_agent --config config.toml --tester
```

Il teste EASYPHARM puis PharmaSuite, et dit lequel des deux ne répond pas.

| Message | Cause | Que faire |
|---|---|---|
| `PharmaSuite … ECHEC — connexion refusée` (10061) | l'API ne tourne pas, ou le pare-feu bloque | sur le serveur : `cd ~/pharma-suite/docker && docker compose up -d api`, puis `curl http://localhost:8000/health` |
| `Authentification refusée (401)` | mot de passe de `sync_agent` différent entre le PC et le serveur | `[api] password` de `config.toml` doit égaler `SYNC_AGENT_PASSWORD` de `docker/.env` |
| `EASYPHARM … code HFSQL 70207 — est déjà décrit` | un fichier sans extension traîne dans le dossier de la base, à côté de son `.fic` | le déplacer hors du dossier (EASYPHARM fermé), sans le supprimer |
| `Provider cannot be found` | provider OLE DB HFSQL absent, ou Python d'une autre architecture (32/64 bits) | installer le provider ; utiliser un Python de même architecture |
| `N ligne(s) refusée(s) par le serveur sur <table> — colonnes en cause : …` | une valeur ne rentre pas dans la colonne PharmaSuite | **signaler le message complet** : la table reste bloquée à cet endroit jusqu'à correction, les autres continuent |
| la tâche n'est pas `Running` | Python déplacé, `config.toml` absent… | regarder la fin de `agent.log`, puis relancer `installer_tache.ps1` |

Quand une table est en erreur, l'agent **ne saute aucune ligne** : il
s'arrête sur cette table et réessaie à chaque passe. Une fois la cause
corrigée, il rattrape tout seul.

### Ce qu'il faut envoyer pour obtenir de l'aide

1. la sortie de `--tester` ;
2. les erreurs du journal : `findstr /C:"ERROR" agent.log` ;
3. la sortie de `--verifier`.

Ne jamais envoyer `config.toml` : il contient des mots de passe.

---

## 7. Fichiers du dossier

| Fichier | Rôle | À sauvegarder ? |
|---|---|---|
| `config.toml` | adresses et mots de passe | oui, en lieu sûr — **jamais** dans Git ni par e-mail |
| `agent.log` (+ `.1` à `.5`) | journal, 5 Mo par fichier, les plus anciens sont effacés | non |
| `agent_state.json` | heure de dernière synchro de chaque table, lots ayant du stock | non — s'il est supprimé, toutes les tables sont simplement relues une fois |
| `installer_tache.ps1` / `desinstaller_tache.ps1` | installation de la tâche Windows | — |

L'endroit où chaque table en est (son « curseur ») est gardé sur le serveur,
pas sur ce PC : réinstaller l'agent, ou le déplacer sur un autre poste, ne
fait rien recharger.

---

## 8. Limites connues

- **Suppressions** : une ligne supprimée dans EASYPHARM reste dans
  PharmaSuite (sauf pour les instances, qui sont archivées). `--verifier` le
  montre par un écart négatif.
- **Tables non copiées** : EASYPHARM contient d'autres fichiers que les 39
  synchronisés ; `--verifier` les liste en fin de rapport.
- **Données sensibles** : `ordonnancier`, `clients`, `instance_produits` et
  `groupware` contiennent des données de patients et des comptes. Elles ne
  doivent pas quitter le réseau de l'officine.
