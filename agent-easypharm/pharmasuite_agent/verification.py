"""
Vérification de complétude : HFSQL contre PostgreSQL.

Répond à trois questions, table par table, sans rien écrire nulle part :

1. **La table existe-t-elle côté HFSQL** sous le nom configuré ? Les noms
   source de la plupart des tables ne sont pas attestés
   (docs/02-sync-contrat.md §6.1) ; c'est ici qu'on le découvre.
2. **Toutes les colonnes arrivent-elles ?** Une colonne HFSQL sans équivalent
   PostgreSQL est ignorée par le serveur : sa donnée est perdue.
3. **Les volumes concordent-ils ?** Nombre de lignes HFSQL contre nombre de
   lignes en base. Un écart positif = des lignes pas encore synchronisées ;
   un écart négatif = des lignes supprimées dans EASYPHARM et encore
   présentes en base (§6.8).

Elle liste aussi les tables HFSQL que l'agent ne lit pas du tout.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from .tables import TABLES, Table

# Colonnes qui n'existent que côté PostgreSQL : leur absence côté HFSQL est
# normale (docs/02-sync-contrat.md §5.4).
_COLONNES_POSTGRES_SEULEMENT = {
    "instance_produits": {"archive", "date_archive", "utilisateur_validation", "archive_trace"},
    # Calculées ou saisies dans PharmaSuite : segmentation ABC/XYZ et
    # disponibilité (services/stock_segmentation.py), catégorie de prime et
    # étagère (stock.py).
    "nomenclature": {"archive", "categorie", "disponibilite", "etagere", "segment_abc", "segment_xyz"},
    "laboratoires": {"is_generique"},
    "clients": {"is_archive", "date_archive", "motif_archive"},
    "groupware": {"droits", "nom", "prenom", "role", "actif"},
}

# Tables dont les colonnes HFSQL sans équivalent sont regroupées par le
# serveur dans une colonne JSONB, donc conservées.
_COLONNES_EMPAQUETEES = {"groupware": "droits"}

# Tables HFSQL lues par un autre biais que leur propre entrée de TABLES.
_SOURCES_ANNEXES = {"instance_produits_trt"}


@dataclass
class LigneRapport:
    table: str
    source: str
    existe: bool
    erreur: str | None = None
    lignes_hfsql: int | None = None
    lignes_postgres: int | None = None
    colonnes_perdues: list[str] = field(default_factory=list)
    colonnes_jamais_remplies: list[str] = field(default_factory=list)
    optionnelle: bool = False

    @property
    def ecart(self) -> int | None:
        if self.lignes_hfsql is None or self.lignes_postgres is None:
            return None
        return self.lignes_hfsql - self.lignes_postgres

    @property
    def complete(self) -> bool:
        return self.existe and not self.colonnes_perdues and self.ecart == 0


@dataclass
class Rapport:
    lignes: list[LigneRapport] = field(default_factory=list)
    tables_hfsql_non_lues: list[str] = field(default_factory=list)
    tables_serveur_non_lues: list[str] = field(default_factory=list)

    @property
    def complet(self) -> bool:
        return all(l.complete or (l.optionnelle and not l.existe) for l in self.lignes)


def _verifier_table(table: Table, source, schema_serveur: dict) -> LigneRapport:
    ligne = LigneRapport(table=table.cible, source=table.source, existe=True,
                         optionnelle=table.optionnelle)
    try:
        colonnes_hfsql = set(source.colonnes(table.source))
        ligne.lignes_hfsql = source.compter(table.source)
    except Exception as erreur:
        ligne.existe = False
        ligne.erreur = str(erreur).splitlines()[0][:120] if str(erreur) else type(erreur).__name__
        return ligne

    serveur = schema_serveur.get(table.cible)
    if serveur is None:
        ligne.erreur = "table inconnue du serveur"
        return ligne

    colonnes_hfsql = {dict(table.renommer).get(c, c) for c in colonnes_hfsql}
    colonnes_pg = set(serveur["columns"])
    ligne.lignes_postgres = serveur["count"]
    if _COLONNES_EMPAQUETEES.get(table.cible) not in colonnes_pg:
        ligne.colonnes_perdues = sorted(colonnes_hfsql - colonnes_pg)
    ligne.colonnes_jamais_remplies = sorted(
        colonnes_pg - colonnes_hfsql - _COLONNES_POSTGRES_SEULEMENT.get(table.cible, set())
    )
    return ligne


def verifier(source, client) -> Rapport:
    schema_serveur = {t["table"]: t for t in client.schema()}
    rapport = Rapport(lignes=[_verifier_table(t, source, schema_serveur) for t in TABLES])

    configurees = {t.source.lower() for t in TABLES} | _SOURCES_ANNEXES
    try:
        rapport.tables_hfsql_non_lues = [
            nom for nom in source.lister_tables() if nom.lower() not in configurees
        ]
    except Exception:
        # Tous les drivers n'exposent pas le catalogue ; le reste du rapport tient.
        pass

    cibles = {t.cible for t in TABLES}
    rapport.tables_serveur_non_lues = sorted(set(schema_serveur) - cibles)
    return rapport


def afficher(rapport: Rapport) -> None:
    print(f"\n{'Table':<32} {'HFSQL':>10} {'Postgres':>10} {'Écart':>9}  Remarques")
    print("-" * 100)
    for l in rapport.lignes:
        if not l.existe:
            etat = "optionnelle, absente" if l.optionnelle else "INTROUVABLE"
            print(f"{l.table:<32} {'—':>10} {'—':>10} {'—':>9}  {etat} ({l.source}) : {l.erreur}")
            continue
        remarques = []
        if l.erreur:
            remarques.append(l.erreur)
        if l.colonnes_perdues:
            remarques.append(f"colonnes PERDUES : {', '.join(l.colonnes_perdues)}")
        if l.colonnes_jamais_remplies:
            remarques.append(f"jamais remplies : {', '.join(l.colonnes_jamais_remplies)}")
        ecart = "" if l.ecart is None else f"{l.ecart:+d}"
        pg = "" if l.lignes_postgres is None else str(l.lignes_postgres)
        print(f"{l.table:<32} {l.lignes_hfsql:>10} {pg:>10} {ecart:>9}  {' | '.join(remarques) or 'OK'}")

    if rapport.tables_hfsql_non_lues:
        print("\nTables HFSQL que l'agent ne lit pas :")
        for nom in rapport.tables_hfsql_non_lues:
            print(f"  - {nom}")
    if rapport.tables_serveur_non_lues:
        print("\nTables attendues par le serveur et non configurées dans l'agent :")
        for nom in rapport.tables_serveur_non_lues:
            print(f"  - {nom}")

    print("\nRésultat :", "COMPLET" if rapport.complet else "INCOMPLET — voir ci-dessus")
