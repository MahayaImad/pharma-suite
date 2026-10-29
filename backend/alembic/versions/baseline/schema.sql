--
--

--
-- Name: bordereaux_chifa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bordereaux_chifa (
    id bigint NOT NULL,
    num_bord character varying(50),
    centre character varying(50),
    nbr_fact integer,
    mnt_assure numeric(15,4),
    mnt_officine numeric(15,4),
    mnt_fae numeric(15,4),
    mnt_majoration numeric(15,4),
    mnt_rej numeric(15,4),
    versement numeric(15,4),
    observation character varying(200),
    dt_cloture date,
    dt_validation date,
    dt_encaisse date,
    dt_depot date,
    archive smallint,
    dt_creation date,
    statut character varying(50),
    extra character varying(2000),
    obs_creation character varying(200),
    obs_cloture character varying(200),
    obs_depot character varying(200),
    obs_validation character varying(200),
    obs_encaissement character varying(200)
);

--
-- Name: caisses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.caisses (
    id integer NOT NULL,
    caisse character varying(50),
    date_creation date,
    etat smallint
);

--
-- Name: caisses_regies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.caisses_regies (
    id bigint NOT NULL,
    date_debut date,
    heure_debut character varying(10),
    date_fin date,
    heure_fin character varying(10),
    fond_de_caisse numeric(15,4),
    total_calcule numeric(15,4),
    total_reel numeric(15,4),
    etat_cloture smallint,
    poste integer,
    modif smallint,
    util_ouvre character varying(50),
    util_cloture character varying(50),
    ventes numeric(15,4),
    retours numeric(15,4),
    versements_clients numeric(15,4),
    remboursements_clients numeric(15,4),
    versements_fournisseurs numeric(15,4),
    remboursements_fournisseurs numeric(15,4),
    alimentations numeric(15,4),
    depenses numeric(15,4),
    virement_de_fond_entrant numeric(15,4),
    virement_de_fond_sortant numeric(15,4),
    indice_ouverture numeric(10,4)
);

--
-- Name: chifa_rejet_partiel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chifa_rejet_partiel (
    id bigint NOT NULL,
    num_bordereau character varying(30),
    num_facture character varying(30),
    montant numeric(15,4),
    observation character varying(500)
);

--
-- Name: classe_maladie; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classe_maladie (
    prefix character varying(10) NOT NULL,
    code_maladie character varying(10) NOT NULL
);

--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id bigint NOT NULL,
    client character varying(100),
    code_barre_client character varying(100),
    adresse character varying(200),
    ville character varying(100),
    telephone character varying(100),
    fax character varying(100),
    email character varying(100),
    ventes numeric(15,4),
    versements numeric(15,4),
    credit numeric(15,4),
    solde_initial numeric(15,4),
    n_assure_chifa character varying(20),
    num_assure_cvm character varying(30),
    num_ccp character varying(30),
    date_naissance date,
    sexe smallint,
    situation_familiale smallint,
    type_militaire smallint,
    date_ctl date,
    chronique smallint,
    date_exp_droits date,
    num_carte_chronique character varying(30),
    date_deliv_carte_chronique date,
    pathologie character varying(200),
    nom_cvm character varying(100),
    prenom_cvm character varying(100),
    num_assure_pharmnos character varying(30),
    num_carte_chronique2 character varying(30),
    num_carte_chronique3 character varying(30),
    num_carte_chronique4 character varying(30),
    num_carte_chronique5 character varying(30),
    date_exp_droits2 date,
    date_exp_droits3 date,
    date_exp_droits4 date,
    date_exp_droits5 date,
    blk_comptoir smallint,
    blk_chifa smallint,
    blk_cvm smallint,
    blk_instance smallint,
    reg_com character varying(30),
    nif character varying(30),
    ai character varying(30),
    nis character varying(30),
    solde_max numeric(15,4),
    activer_solde_max smallint,
    is_archive boolean DEFAULT false NOT NULL,
    date_archive date,
    motif_archive character varying(200)
);

--
-- Name: commandes_fournisseurs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commandes_fournisseurs (
    id integer NOT NULL,
    ref character varying(20),
    fournisseur character varying(100),
    date date,
    utilisateur character varying(50),
    poste smallint,
    observation character varying(200),
    type_psy smallint,
    nbr_prod integer,
    sync smallint
);

--
-- Name: commandes_fournisseurs_produits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commandes_fournisseurs_produits (
    id integer NOT NULL,
    id_commande bigint,
    ref_commande character varying(20),
    date_commande date,
    fournisseur character varying(100),
    produit character varying(200),
    quantite bigint,
    utilisateur character varying(50),
    poste integer,
    type_psy smallint,
    stock numeric(15,4),
    offsettt integer,
    per character varying(10),
    p_achat numeric(15,4),
    taux_ug numeric(15,4)
);

--
-- Name: comptes_bancaires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comptes_bancaires (
    id integer NOT NULL,
    compte character varying(500),
    date_creation date
);

--
-- Name: demandes_conge; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.demandes_conge (
    id integer NOT NULL,
    employe_id integer NOT NULL,
    date_debut date NOT NULL,
    date_fin date NOT NULL,
    nb_jours integer NOT NULL,
    type character varying(20) DEFAULT 'annuel'::character varying NOT NULL,
    statut character varying(20) DEFAULT 'en_attente'::character varying NOT NULL,
    note text,
    note_admin text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

--
-- Name: demandes_conge_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.demandes_conge_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: demandes_conge_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.demandes_conge_id_seq OWNED BY public.demandes_conge.id;

--
-- Name: depenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.depenses (
    id bigint NOT NULL,
    depense character varying(100)
);

--
-- Name: echanges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.echanges (
    id bigint NOT NULL,
    type character varying(5),
    date date,
    id_pharmacie bigint,
    pharmacie character varying(100),
    total numeric(15,4),
    utilisateur character varying(50),
    poste integer,
    modif smallint,
    contient_psy smallint,
    heure character varying(10)
);

--
-- Name: echanges_sorties_produits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.echanges_sorties_produits (
    id bigint NOT NULL,
    id_produit bigint,
    id_nom numeric(15,4),
    nom character varying(150),
    id_famille smallint,
    famille character varying(50),
    prix_achat_ttc numeric(15,4),
    prix_vente numeric(15,4),
    qte bigint,
    lot character varying(50),
    peremption character varying(10),
    id_echange bigint,
    id_pharmacie bigint,
    pharmacie character varying(100),
    date_echange date,
    psychotrope smallint,
    heure character varying(10)
);

--
-- Name: employes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employes (
    id integer NOT NULL,
    user_id integer,
    username character varying(50),
    nom character varying(100) NOT NULL,
    prenom character varying(100),
    poste character varying(100),
    date_entree date,
    actif boolean,
    eligible_prime boolean,
    created_at timestamp with time zone DEFAULT now(),
    conges_annuels integer DEFAULT 30 NOT NULL
);

--
-- Name: employes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: employes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employes_id_seq OWNED BY public.employes.id;

--
-- Name: entrees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entrees (
    id bigint NOT NULL,
    type character varying(5),
    date date,
    heure character varying(10),
    date_piece date,
    id_fournisseur bigint,
    fournisseur character varying(100),
    total_ht numeric(15,4),
    total_tva numeric(15,4),
    total_ttc numeric(15,4),
    remise numeric(15,4),
    total_a_payer numeric(15,4),
    total_ppa numeric(15,4),
    total_shp numeric(15,4),
    num_bl character varying(50),
    num_fact character varying(50),
    num_avoir character varying(30),
    motif_avoir character varying(200),
    attach_bc character varying(50),
    echeance date,
    reglement numeric(15,4),
    montant_facture numeric(15,4),
    montant_difference numeric(15,4),
    type_achat character varying(10),
    type_psy smallint,
    avoir_financier smallint,
    utilisateur character varying(50),
    poste integer,
    modif smallint,
    ouverte smallint,
    observations character varying(1000)
);

--
-- Name: entrees_produits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.entrees_produits (
    id bigint NOT NULL,
    id_entree bigint,
    date_entree date,
    type_entree character varying(10),
    id_fournisseur integer,
    fournisseur character varying(100),
    id_nom bigint,
    nom character varying(150),
    marge numeric(15,4),
    id_famille integer,
    famille character varying(50),
    prix_achat numeric(15,4),
    prix_vente numeric(15,4),
    qte_entree bigint,
    code_barre character varying(30),
    num_bl character varying(50),
    num_fact character varying(50),
    poste integer,
    utilisateur character varying(50),
    observation character varying(100),
    stock bigint,
    peremption character varying(10),
    lot character varying(50),
    shp numeric(15,4),
    tva numeric(15,4),
    prix_achat_ttc numeric(15,4),
    id_cnas bigint,
    id_produit numeric(15,4),
    peremption_date date,
    indice character varying(200),
    ppa numeric(15,4),
    id_echange bigint,
    type_achat character varying(10),
    psychotrope smallint,
    num_avoir character varying(30),
    de_equiv character varying(20),
    date_piece date,
    bloque smallint,
    last_modif_inv_tourn bigint,
    labo character varying(200),
    heure character varying(10),
    cls_trp character varying(200)
);

--
-- Name: facture_anomalies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facture_anomalies (
    id bigint NOT NULL,
    no_facture character varying(100) NOT NULL,
    no_bordereau character varying(100),
    type_anomalie character varying(50) NOT NULL,
    description text,
    date_signalement timestamp with time zone,
    utilisateur_signalement character varying(50),
    utilisateur_erreur character varying(50),
    statut character varying(20) NOT NULL
);

--
-- Name: facture_anomalies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.facture_anomalies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: facture_anomalies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.facture_anomalies_id_seq OWNED BY public.facture_anomalies.id;

--
-- Name: facture_rejets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facture_rejets (
    id bigint NOT NULL,
    no_facture character varying(100) NOT NULL,
    no_bordereau character varying(100),
    caisse character varying(20) NOT NULL,
    motif_rejet text,
    date_rejet timestamp with time zone,
    montant_rejete numeric(15,4),
    statut character varying(20) NOT NULL,
    date_traitement timestamp with time zone
);

--
-- Name: facture_rejets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.facture_rejets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: facture_rejets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.facture_rejets_id_seq OWNED BY public.facture_rejets.id;

--
-- Name: factures_chifa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.factures_chifa (
    id bigint NOT NULL,
    officine character varying(100),
    centre character varying(100),
    centre_as character varying(100),
    no_assure character varying(100),
    rang_ad character varying(100),
    d_soins date,
    no_bordereau_fact character varying(100),
    mt_assure numeric(15,4),
    mt_officine numeric(15,4),
    maj_fact numeric(15,4),
    mt_maj numeric(15,4),
    type_maj character varying(100),
    date_fact date,
    no_facture character varying(100),
    destocke smallint,
    signature character varying(20),
    annule smallint,
    code_affect character varying(10),
    rej smallint,
    txt_prod character varying(10000),
    motif_annulation character varying(100),
    trace_destockage character varying(20)
);

--
-- Name: factures_chifa_produits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.factures_chifa_produits (
    id bigint NOT NULL,
    num_enr bigint,
    prix_ppa numeric(15,4),
    quantite bigint,
    mt_assure numeric(15,4),
    mt_officine numeric(15,4),
    num_enr_prescrit bigint,
    no_fact character varying(50)
);

--
-- Name: familles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.familles (
    id bigint NOT NULL,
    famille character varying(100)
);

--
-- Name: formes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.formes (
    id bigint NOT NULL,
    forme character varying(200),
    forme_abr character varying(200)
);

--
-- Name: fournisseurs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fournisseurs (
    id bigint NOT NULL,
    fournisseur character varying(100),
    adresse character varying(200),
    ville character varying(100),
    telephone character varying(100),
    fax character varying(100),
    mobile character varying(100),
    email character varying(100),
    banque character varying(100),
    achats numeric(15,4),
    avoirs numeric(15,4),
    versements numeric(15,4),
    remboursements numeric(15,4),
    solde_actuel numeric(15,4),
    solde_initial numeric(15,4),
    mode_qr smallint,
    code_efacture smallint,
    filiale_efacture character varying(20),
    delai_livraison integer
);

--
-- Name: COLUMN fournisseurs.delai_livraison; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fournisseurs.delai_livraison IS 'Délai de livraison moyen en jours (saisi manuellement)';

--
-- Name: groupware; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groupware (
    id bigint NOT NULL,
    utilisateur character varying(50),
    mot_de_passe character varying(100),
    nom character varying(100),
    prenom character varying(100),
    role integer,
    actif smallint
);

--
-- Name: historique_stock_jour; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historique_stock_jour (
    id_nom bigint NOT NULL,
    date date NOT NULL,
    stock_eod numeric(12,2),
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: COLUMN historique_stock_jour.stock_eod; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.historique_stock_jour.stock_eod IS 'Stock fin de journée reconstitué';

--
-- Name: holidays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.holidays (
    id integer NOT NULL,
    date date NOT NULL,
    label character varying(100)
);

--
-- Name: holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.holidays_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.holidays_id_seq OWNED BY public.holidays.id;

--
-- Name: instance_produits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_produits (
    id bigint NOT NULL,
    date date,
    id_client bigint,
    client character varying(100),
    id_nom bigint,
    nom character varying(150),
    id_famille integer,
    famille character varying(50),
    prix_vente numeric(15,4),
    qte_sortie bigint,
    heure character varying(10),
    prix_achat_ttc numeric(15,4),
    id_produit bigint,
    lot character varying(50),
    peremption character varying(10),
    psychotrope smallint,
    type smallint,
    n_assure_chifa character varying(30),
    n_assure_cvm character varying(30),
    utilisateur character varying(50),
    motif character varying(200),
    echeance date,
    indice character varying(10),
    archive boolean DEFAULT false NOT NULL,
    date_archive timestamp with time zone,
    utilisateur_validation character varying(50),
    archive_trace character varying(50)
);

--
-- Name: inventaires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventaires (
    id bigint NOT NULL,
    date date,
    heure character varying(10),
    utilisateur character varying(50),
    poste integer,
    etat smallint,
    observations character varying(500)
);

--
-- Name: inventaires_produits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventaires_produits (
    id bigint NOT NULL,
    id_inventaire bigint,
    date date,
    id_nom bigint,
    nom character varying(150),
    id_famille integer,
    famille character varying(50),
    code_barre character varying(30),
    lot character varying(50),
    peremption character varying(10),
    peremption_date date,
    stock_theorique bigint,
    stock_reel bigint,
    ecart bigint,
    prix_achat_ttc numeric(15,4),
    prix_vente numeric(15,4),
    motif character varying(200),
    utilisateur character varying(50),
    poste integer
);

--
-- Name: kpi_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kpi_definitions (
    id integer NOT NULL,
    code character varying(50) NOT NULL,
    libelle character varying(200) NOT NULL,
    description text,
    categorie character varying(30),
    unite character varying(20),
    poids numeric(5,2),
    actif boolean
);

--
-- Name: kpi_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.kpi_definitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: kpi_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.kpi_definitions_id_seq OWNED BY public.kpi_definitions.id;

--
-- Name: laboratoires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.laboratoires (
    id bigint NOT NULL,
    labo character varying(200),
    is_generique boolean DEFAULT false NOT NULL
);

--
-- Name: maladies_chroniques; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maladies_chroniques (
    id integer NOT NULL,
    code character varying(10) NOT NULL,
    maladie character varying(150) NOT NULL,
    specialite character varying(50),
    taux_cnas integer,
    type_cnas character varying(10)
);

--
-- Name: maladies_chroniques_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maladies_chroniques_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: maladies_chroniques_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maladies_chroniques_id_seq OWNED BY public.maladies_chroniques.id;

--
-- Name: motif_instance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.motif_instance (
    id bigint NOT NULL,
    motif character varying(200)
);

--
-- Name: mouchard; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mouchard (
    id bigint NOT NULL,
    date date,
    heure character varying(10),
    utilisateur character varying(50),
    poste integer,
    action character varying(100),
    description character varying(200),
    vnt_tier_ini character varying(100),
    vnt_montant_ini numeric(15,4),
    vnt_versement_ini numeric(15,4),
    vnt_tier_fin character varying(100),
    vnt_montant_fin numeric(15,4),
    vnt_versement_fin numeric(15,4),
    ach_date_ini date,
    ach_fournisseur_ini character varying(100),
    ach_type_ini character varying(20),
    ach_num_fact_ini character varying(50),
    ach_num_bl_ini character varying(50),
    ach_total_ppa_ini numeric(15,4),
    ach_total_a_payer_ini numeric(15,4),
    ach_remise_ini numeric(15,4),
    ach_ech_ini date,
    ach_date_fin date,
    ach_fournisseur_fin character varying(100),
    ach_type_fin character varying(20),
    ach_num_fact_fin character varying(50),
    ach_num_bl_fin character varying(50),
    ach_total_ppa_fin numeric(15,4),
    ach_total_a_payer_fin numeric(15,4),
    ach_remise_fin numeric(15,4),
    ach_ech_fin date,
    stk_ppa_ini numeric(15,4),
    stk_lot_ini character varying(50),
    stk_per_ini character varying(10),
    stk_cdb_ini character varying(50),
    stk_ppa_fin numeric(15,4),
    stk_lot_fin character varying(50),
    stk_per_fin character varying(10),
    stk_cdb_fin character varying(50),
    stk_prod character varying(200),
    op_caisse_ini character varying(100),
    op_tier_ini character varying(150),
    op_montant_ini numeric(15,4),
    op_mode_ini character varying(50),
    op_ref_ini character varying(50),
    op_obs_ini character varying(200),
    op_caisse_fin character varying(100),
    op_tier_fin character varying(150),
    op_montant_fin numeric(15,4),
    op_mode_fin character varying(50),
    op_ref_fin character varying(50),
    op_obs_fin character varying(200),
    stk_blok_ini smallint,
    stk_blok_fin smallint
);

--
-- Name: mouchard_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mouchard_details (
    id bigint NOT NULL,
    id_mouchard bigint,
    produit character varying(200),
    prix_achat_ttc numeric(15,4),
    ppa numeric(15,4),
    lot character varying(50),
    per character varying(10),
    sts character varying(5),
    qte integer
);

--
-- Name: nomenclature; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nomenclature (
    id bigint NOT NULL,
    nom character varying(150),
    id_famille bigint,
    famille character varying(100),
    prix_vente numeric(15,4),
    prix_achat_moyen numeric(15,4),
    quantite_entree numeric(15,4),
    quantite_sortie numeric(15,4),
    stock numeric(15,4),
    dci character varying(200),
    dosage character varying(200),
    conditionnement character varying(200),
    id_forme bigint,
    forme character varying(200),
    forme_abr character varying(200),
    id_cnas bigint,
    psychotrope smallint,
    qte_alerte bigint,
    de_equiv character varying(20),
    remb_cvm smallint,
    code_barre_original character varying(50),
    cle_compo_nom_cdb character varying(200),
    desactiv_alrt_rup smallint,
    ord_trois_souche smallint,
    labo character varying(200),
    cls_trp character varying(200),
    generique smallint,
    etagere character varying(50),
    archive boolean DEFAULT false NOT NULL,
    segment_abc character varying(1),
    segment_xyz character varying(1),
    disponibilite character varying(10) DEFAULT '''oui'''::character varying NOT NULL,
    categorie character varying(20)
);

--
-- Name: mv_stock_produits; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.mv_stock_produits AS
 SELECT n.id AS id_nom,
    (COALESCE(sum(ep.stock), (0)::numeric))::bigint AS stock_actuel,
    (COALESCE(sum(ep.qte_entree), (0)::numeric))::bigint AS qte_entree_totale,
    (COALESCE((sum(((ep.stock)::numeric * ep.prix_achat)) / NULLIF(sum(ep.stock), (0)::numeric)), (0)::numeric))::numeric(15,4) AS prix_moyen_pondere
   FROM (public.nomenclature n
     LEFT JOIN public.entrees_produits ep ON (((ep.id_nom = n.id) AND (ep.stock > 0))))
  GROUP BY n.id
  WITH NO DATA;

--
-- Name: nomenclature_chifa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nomenclature_chifa (
    id bigint NOT NULL,
    nom character varying(150),
    id_famille bigint,
    famille character varying(100),
    prix_vente numeric(15,4),
    prix_achat_moyen numeric(15,4),
    quantite_entree numeric(15,4),
    quantite_sortie numeric(15,4),
    stock numeric(15,4),
    dci character varying(200),
    dosage character varying(200),
    conditionnement character varying(200),
    id_forme bigint,
    forme character varying(200),
    forme_abr character varying(200),
    id_cnas bigint,
    psychotrope smallint,
    qte_alerte bigint,
    nom_court character varying(150),
    de_equiv character varying(20),
    tarif_ref numeric(15,4),
    date_fin_remb date
);

--
-- Name: nomenclature_classification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nomenclature_classification (
    id integer NOT NULL,
    prefix character varying(10) NOT NULL,
    designation character varying(200),
    etagere character varying(50),
    employe_id integer,
    categorie character varying(20),
    niveau smallint DEFAULT 1 NOT NULL
);

--
-- Name: nomenclature_classification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nomenclature_classification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: nomenclature_classification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nomenclature_classification_id_seq OWNED BY public.nomenclature_classification.id;

--
-- Name: objectifs_mensuels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.objectifs_mensuels (
    id integer NOT NULL,
    annee integer NOT NULL,
    mois integer NOT NULL,
    mode_prime character varying(10),
    objectif_benefice numeric(14,2),
    pct_enveloppe_prime numeric(5,2),
    enveloppe_calculee numeric(14,2),
    notes text
);

--
-- Name: objectifs_mensuels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.objectifs_mensuels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: objectifs_mensuels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.objectifs_mensuels_id_seq OWNED BY public.objectifs_mensuels.id;

--
-- Name: operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operations (
    id bigint NOT NULL,
    date date,
    operation character varying(50),
    montant numeric(15,4),
    observation character varying(100),
    utilisateur character varying(50),
    id_relatif numeric(15,4),
    modif smallint,
    origine character varying(100),
    destinataire character varying(100),
    heure character varying(10),
    id_tier bigint,
    mode character varying(50),
    ref character varying(50),
    n_assure character varying(50),
    n_facture_chifa character varying(30),
    n_bordereau_chifa character varying(30),
    cloture smallint,
    indice_creation numeric(20,0),
    mois_cvm character varying(10),
    num_bord_pharmnos character varying(30),
    num_fact_cvm_4eme integer,
    id_session bigint,
    id_ph_echange integer
);

--
-- Name: ordonnancier; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordonnancier (
    id bigint NOT NULL,
    num bigint,
    date date,
    ordonnateur character varying(50),
    client character varying(50),
    adresse character varying(50),
    num_cin character varying(20),
    observation character varying(200),
    utilisateur character varying(30),
    id_vente numeric(15,4),
    adresse_medecin character varying(50),
    type smallint,
    porteur character varying(200),
    porteur_adresse character varying(50),
    porteur_cin character varying(20),
    date_soin date,
    id_vente_2 bigint,
    txt_duree character varying(5000),
    age_malade smallint,
    taille_malade character varying(10),
    poids_malade character varying(10),
    structure_ordo character varying(100),
    num_serie_ordo character varying(20),
    mld_lui_meme smallint,
    prescripteur_ordre character varying(20)
);

--
-- Name: parametres_stock; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parametres_stock (
    id_nom bigint NOT NULL,
    delai_moyen_j numeric(8,2),
    demande_moy_j numeric(10,4),
    demande_std_j numeric(10,4),
    stock_securite numeric(10,2),
    rop numeric(10,2),
    eoq numeric(10,2),
    holding_cost_pct numeric(5,4) DEFAULT 0.20,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: parametres_stock_id_nom_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parametres_stock_id_nom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: parametres_stock_id_nom_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parametres_stock_id_nom_seq OWNED BY public.parametres_stock.id_nom;

--
-- Name: patients_chifa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patients_chifa (
    id integer NOT NULL,
    no_assure character varying(20) NOT NULL,
    rang_ad character varying(4) NOT NULL,
    type_beneficiaire character varying(20),
    centre character varying(50),
    premiere_visite date,
    derniere_visite date,
    nb_visites integer,
    intervalle_moyen numeric(6,1),
    prochain_visite_est date,
    statut character varying(20) NOT NULL,
    mt_total_assure numeric(12,2),
    mt_total_officine numeric(12,2),
    taux_remb_moyen numeric(5,2),
    maladies character varying(10)[],
    classes_medicaments character varying(10)[],
    specialites character varying(50)[],
    medicaments character varying(200)[],
    calcule_le timestamp with time zone DEFAULT now()
);

--
-- Name: patients_chifa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.patients_chifa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: patients_chifa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.patients_chifa_id_seq OWNED BY public.patients_chifa.id;

--
-- Name: performance_mensuelle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.performance_mensuelle (
    id integer NOT NULL,
    employe_id integer NOT NULL,
    annee integer NOT NULL,
    mois integer NOT NULL,
    kpis jsonb,
    score_global numeric(5,2),
    pct_prime numeric(5,2),
    prime_calculee numeric(14,2),
    valide boolean,
    valide_par character varying(50),
    valide_le timestamp with time zone
);

--
-- Name: performance_mensuelle_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.performance_mensuelle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: performance_mensuelle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.performance_mensuelle_id_seq OWNED BY public.performance_mensuelle.id;

--
-- Name: pharmacies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pharmacies (
    id bigint NOT NULL,
    pharmacie character varying(100),
    adresse character varying(200),
    ville character varying(100),
    telephone character varying(100),
    fax character varying(100),
    mobile character varying(100),
    email character varying(100),
    ecart_initial numeric(15,4)
);

--
-- Name: pharmnos_factures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pharmnos_factures (
    id bigint NOT NULL,
    matricule character varying(20),
    num_dec character varying(20),
    date_soin date,
    taux integer,
    total_ppa numeric(15,4),
    total_remb numeric(15,4),
    total_non_remb numeric(15,4),
    num_brd character varying(20),
    date_dec date,
    destocke smallint,
    annule smallint,
    majoration numeric(15,4),
    fae numeric(15,4)
);

--
-- Name: postes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.postes (
    id bigint NOT NULL,
    km bigint,
    langue character varying(10),
    enr bigint,
    etat_caisse smallint,
    image_fond character varying(200),
    sauvegarde_a_partir_ce_poste smallint,
    gerer_tiroir_caisse smallint,
    port_tiroir_caisse smallint,
    gerer_imp_tk smallint,
    nom_imp_cdb character varying(50),
    type_impression_ticket smallint,
    port_imp_tk smallint,
    imprimante_tk character varying(100),
    dngl bigint,
    ouv_tir_caisse smallint,
    recherche_vente smallint,
    sur_comptoir smallint,
    type_imp_cdb smallint,
    chemin_chifa_local character varying(500),
    att_ect_1 integer,
    att_ect_2 integer,
    serveur_chifa smallint,
    ent_easychifa smallint,
    att_ect_3 integer,
    ident_vend_chaq_vnt smallint,
    nom_pc character varying(50),
    caisse_associee character varying(50),
    cim_test character varying(5000),
    quitter_agent_ect smallint,
    att_ect_4 integer
);

--
-- Name: presences_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.presences_overrides (
    id integer NOT NULL,
    employe_id integer NOT NULL,
    date date NOT NULL,
    statut character varying(20) NOT NULL,
    note text,
    created_by character varying(50),
    created_at timestamp with time zone DEFAULT now()
);

--
-- Name: presences_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.presences_overrides_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: presences_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.presences_overrides_id_seq OWNED BY public.presences_overrides.id;

--
-- Name: prestations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prestations (
    id integer NOT NULL,
    prestation character varying(100),
    prix numeric(15,4)
);

--
-- Name: previsions_demande; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.previsions_demande (
    id_nom bigint NOT NULL,
    modele character varying(30),
    prevision_30j numeric(12,2),
    prevision_90j numeric(12,2),
    mape_holdout numeric(7,4),
    serie_corrigee jsonb,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: previsions_demande_id_nom_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.previsions_demande_id_nom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: previsions_demande_id_nom_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.previsions_demande_id_nom_seq OWNED BY public.previsions_demande.id_nom;

--
-- Name: prime_taux_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prime_taux_config (
    id integer NOT NULL,
    nom character varying(100) NOT NULL,
    taux_pct numeric(5,3) NOT NULL,
    filtre_famille character varying(200),
    actif boolean NOT NULL,
    updated_at timestamp with time zone DEFAULT now()
);

--
-- Name: prime_taux_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prime_taux_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: prime_taux_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prime_taux_config_id_seq OWNED BY public.prime_taux_config.id;

--
-- Name: reg_client_association; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reg_client_association (
    id bigint NOT NULL,
    id_operation bigint,
    id_vente bigint,
    tranche numeric(15,4),
    date date,
    mode character varying(50),
    ref character varying(50),
    observation character varying(100),
    utilisateur character varying(50)
);

--
-- Name: reg_fourn_association; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reg_fourn_association (
    id bigint NOT NULL,
    id_operation bigint,
    id_entree bigint,
    tranche numeric(15,4),
    date date,
    mode character varying(50),
    ref character varying(50),
    observation character varying(100),
    utilisateur character varying(50)
);

--
-- Name: sms_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sms_logs (
    id character varying(36) NOT NULL,
    phone character varying(20) NOT NULL,
    message text NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    error text,
    retries smallint DEFAULT '0'::smallint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sent_at timestamp with time zone,
    utilisateur character varying(50)
);

--
-- Name: COLUMN sms_logs.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sms_logs.id IS 'UUID';

--
-- Name: COLUMN sms_logs.phone; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sms_logs.phone IS 'Numéro destinataire';

--
-- Name: COLUMN sms_logs.message; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sms_logs.message IS 'Corps du SMS';

--
-- Name: COLUMN sms_logs.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sms_logs.status IS 'pending | sent | failed | cancelled';

--
-- Name: COLUMN sms_logs.error; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sms_logs.error IS 'Message d''erreur';

--
-- Name: sorties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sorties (
    id bigint NOT NULL,
    type character varying(5),
    date date,
    id_client bigint,
    client character varying(100),
    total numeric(15,4),
    remise numeric(15,4),
    total_a_payer numeric(15,4),
    versement numeric(15,4),
    utilisateur character varying(50),
    poste integer,
    modif smallint,
    heure character varying(10),
    benefices numeric(15,4),
    type_versement character varying(10),
    no_facture_chifa character varying(50),
    montant_cnas numeric(15,4),
    montant_assure numeric(15,4),
    n_assure character varying(50),
    etat_cloture smallint,
    reglement_ult numeric(15,4),
    num_assure_cvm character varying(30),
    ayant_droit_cvm bigint,
    rang_cvm character varying(10),
    cabinet_medical_cvm character varying(200),
    date_soins_cvm date,
    chronique_cvm smallint,
    mld_cvm1 character varying(10),
    mld_cvm2 character varying(10),
    mld_cvm3 character varying(10),
    mld_cvm4 character varying(10),
    mld_cvm5 character varying(10),
    id_facture_cvm bigint,
    pharmnos_num_fact character varying(50),
    pharmnos_num_assure character varying(50),
    pharmnos_total_remb numeric(15,4),
    pharmnos_total_non_remb numeric(15,4),
    num_fact integer,
    specialite_cvm character varying(100),
    caisse character varying(50),
    id_session bigint,
    mdc character varying(200),
    majoration numeric(15,4),
    observation character varying(200)
);

--
-- Name: sorties_produits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sorties_produits (
    id bigint NOT NULL,
    id_sortie bigint,
    date date,
    type_sortie character varying(5),
    id_client bigint,
    client character varying(100),
    id_nom bigint,
    nom character varying(150),
    id_famille integer,
    famille character varying(50),
    prix_vente numeric(15,4),
    qte_sortie bigint,
    heure character varying(10),
    poste integer,
    prix_achat_ttc numeric(15,4),
    id_produit bigint,
    lot character varying(50),
    peremption character varying(10),
    no_facture_chifa character varying(50),
    psychotrope smallint,
    remb_cvm smallint,
    pharmnos_num_fact character varying(50),
    caisse character varying(50),
    id_session bigint,
    utilisateur character varying(50),
    mdc character varying(200)
);

--
-- Name: suivi_caisses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suivi_caisses (
    id bigint NOT NULL,
    date_debut date,
    heure_debut character varying(10),
    date_fin date,
    heure_fin character varying(10),
    fond_de_caisse numeric(15,4),
    total_calcule numeric(15,4),
    total_reel numeric(15,4),
    etat_cloture smallint,
    util_ouvre character varying(50),
    util_cloture character varying(50),
    ventes numeric(15,4),
    retours numeric(15,4),
    versements_clients numeric(15,4),
    remboursements_clients numeric(15,4),
    versements_fournisseurs numeric(15,4),
    remboursements_fournisseurs numeric(15,4),
    alimentations numeric(15,4),
    depenses numeric(15,4),
    virement_de_fond_entrant numeric(15,4),
    virement_de_fond_sortant numeric(15,4),
    indice_ouverture numeric(10,4),
    caisse character varying(50),
    ecart numeric(15,4)
);

--
-- Name: sync_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sync_status (
    id bigint NOT NULL,
    table_name character varying(100) NOT NULL,
    last_id bigint NOT NULL,
    total_synced integer NOT NULL,
    last_sync_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: sync_status_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sync_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: sync_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sync_status_id_seq OWNED BY public.sync_status.id;

--
-- Name: task_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_assignments (
    id character varying(36) NOT NULL,
    template_id character varying(36),
    title character varying(200) NOT NULL,
    category character varying(50) NOT NULL,
    duration_min integer DEFAULT 30 NOT NULL,
    priority character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    assigned_to bigint NOT NULL,
    assigned_date date DEFAULT CURRENT_DATE NOT NULL,
    scheduled_time time without time zone,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    note text,
    created_at timestamp with time zone DEFAULT now()
);

--
-- Name: COLUMN task_assignments.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_assignments.id IS 'UUID';

--
-- Name: COLUMN task_assignments.title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_assignments.title IS 'Dénormalisé — conservé si template supprimé';

--
-- Name: COLUMN task_assignments.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_assignments.status IS 'pending | in_progress | done | skipped';

--
-- Name: task_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_templates (
    id character varying(36) NOT NULL,
    title character varying(200) NOT NULL,
    category character varying(50) NOT NULL,
    duration_min integer DEFAULT 30 NOT NULL,
    recurrence character varying(20) DEFAULT 'manual'::character varying NOT NULL,
    auto_assign boolean DEFAULT false NOT NULL,
    day_of_week smallint,
    day_of_month smallint,
    priority character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now()
);

--
-- Name: COLUMN task_templates.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_templates.id IS 'UUID';

--
-- Name: COLUMN task_templates.category; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_templates.category IS 'stock | accueil | administrative | maintenance';

--
-- Name: COLUMN task_templates.recurrence; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_templates.recurrence IS 'manual | daily | weekly | monthly';

--
-- Name: COLUMN task_templates.day_of_week; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_templates.day_of_week IS 'weekly: 0=lun 6=dim';

--
-- Name: COLUMN task_templates.day_of_month; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_templates.day_of_month IS 'monthly: 1-31';

--
-- Name: COLUMN task_templates.priority; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.task_templates.priority IS 'low | normal | high | urgent';

--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    username character varying(50) NOT NULL,
    hashed_password character varying(200) NOT NULL,
    is_active boolean NOT NULL,
    role character varying(20) NOT NULL,
    last_seen_at timestamp with time zone
);

--
-- Name: COLUMN users.last_seen_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.last_seen_at IS 'Dernière activité — mis à jour par le middleware';

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;

--
-- Name: demandes_conge id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandes_conge ALTER COLUMN id SET DEFAULT nextval('public.demandes_conge_id_seq'::regclass);

--
-- Name: employes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employes ALTER COLUMN id SET DEFAULT nextval('public.employes_id_seq'::regclass);

--
-- Name: facture_anomalies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facture_anomalies ALTER COLUMN id SET DEFAULT nextval('public.facture_anomalies_id_seq'::regclass);

--
-- Name: facture_rejets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facture_rejets ALTER COLUMN id SET DEFAULT nextval('public.facture_rejets_id_seq'::regclass);

--
-- Name: holidays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays ALTER COLUMN id SET DEFAULT nextval('public.holidays_id_seq'::regclass);

--
-- Name: kpi_definitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpi_definitions ALTER COLUMN id SET DEFAULT nextval('public.kpi_definitions_id_seq'::regclass);

--
-- Name: maladies_chroniques id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maladies_chroniques ALTER COLUMN id SET DEFAULT nextval('public.maladies_chroniques_id_seq'::regclass);

--
-- Name: nomenclature_classification id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nomenclature_classification ALTER COLUMN id SET DEFAULT nextval('public.nomenclature_classification_id_seq'::regclass);

--
-- Name: objectifs_mensuels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs_mensuels ALTER COLUMN id SET DEFAULT nextval('public.objectifs_mensuels_id_seq'::regclass);

--
-- Name: parametres_stock id_nom; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parametres_stock ALTER COLUMN id_nom SET DEFAULT nextval('public.parametres_stock_id_nom_seq'::regclass);

--
-- Name: patients_chifa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients_chifa ALTER COLUMN id SET DEFAULT nextval('public.patients_chifa_id_seq'::regclass);

--
-- Name: performance_mensuelle id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_mensuelle ALTER COLUMN id SET DEFAULT nextval('public.performance_mensuelle_id_seq'::regclass);

--
-- Name: presences_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presences_overrides ALTER COLUMN id SET DEFAULT nextval('public.presences_overrides_id_seq'::regclass);

--
-- Name: previsions_demande id_nom; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.previsions_demande ALTER COLUMN id_nom SET DEFAULT nextval('public.previsions_demande_id_nom_seq'::regclass);

--
-- Name: prime_taux_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prime_taux_config ALTER COLUMN id SET DEFAULT nextval('public.prime_taux_config_id_seq'::regclass);

--
-- Name: sync_status id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_status ALTER COLUMN id SET DEFAULT nextval('public.sync_status_id_seq'::regclass);

--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);

--
-- Name: bordereaux_chifa bordereaux_chifa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bordereaux_chifa
    ADD CONSTRAINT bordereaux_chifa_pkey PRIMARY KEY (id);

--
-- Name: caisses caisses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caisses
    ADD CONSTRAINT caisses_pkey PRIMARY KEY (id);

--
-- Name: caisses_regies caisses_regies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caisses_regies
    ADD CONSTRAINT caisses_regies_pkey PRIMARY KEY (id);

--
-- Name: chifa_rejet_partiel chifa_rejet_partiel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chifa_rejet_partiel
    ADD CONSTRAINT chifa_rejet_partiel_pkey PRIMARY KEY (id);

--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);

--
-- Name: commandes_fournisseurs commandes_fournisseurs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commandes_fournisseurs
    ADD CONSTRAINT commandes_fournisseurs_pkey PRIMARY KEY (id);

--
-- Name: commandes_fournisseurs_produits commandes_fournisseurs_produits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commandes_fournisseurs_produits
    ADD CONSTRAINT commandes_fournisseurs_produits_pkey PRIMARY KEY (id);

--
-- Name: comptes_bancaires comptes_bancaires_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comptes_bancaires
    ADD CONSTRAINT comptes_bancaires_pkey PRIMARY KEY (id);

--
-- Name: demandes_conge demandes_conge_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandes_conge
    ADD CONSTRAINT demandes_conge_pkey PRIMARY KEY (id);

--
-- Name: depenses depenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.depenses
    ADD CONSTRAINT depenses_pkey PRIMARY KEY (id);

--
-- Name: echanges echanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.echanges
    ADD CONSTRAINT echanges_pkey PRIMARY KEY (id);

--
-- Name: echanges_sorties_produits echanges_sorties_produits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.echanges_sorties_produits
    ADD CONSTRAINT echanges_sorties_produits_pkey PRIMARY KEY (id);

--
-- Name: employes employes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employes
    ADD CONSTRAINT employes_pkey PRIMARY KEY (id);

--
-- Name: employes employes_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employes
    ADD CONSTRAINT employes_username_key UNIQUE (username);

--
-- Name: entrees entrees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entrees
    ADD CONSTRAINT entrees_pkey PRIMARY KEY (id);

--
-- Name: entrees_produits entrees_produits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entrees_produits
    ADD CONSTRAINT entrees_produits_pkey PRIMARY KEY (id);

--
-- Name: facture_anomalies facture_anomalies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facture_anomalies
    ADD CONSTRAINT facture_anomalies_pkey PRIMARY KEY (id);

--
-- Name: facture_rejets facture_rejets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facture_rejets
    ADD CONSTRAINT facture_rejets_pkey PRIMARY KEY (id);

--
-- Name: factures_chifa factures_chifa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factures_chifa
    ADD CONSTRAINT factures_chifa_pkey PRIMARY KEY (id);

--
-- Name: factures_chifa_produits factures_chifa_produits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factures_chifa_produits
    ADD CONSTRAINT factures_chifa_produits_pkey PRIMARY KEY (id);

--
-- Name: familles familles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familles
    ADD CONSTRAINT familles_pkey PRIMARY KEY (id);

--
-- Name: formes formes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.formes
    ADD CONSTRAINT formes_pkey PRIMARY KEY (id);

--
-- Name: fournisseurs fournisseurs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fournisseurs
    ADD CONSTRAINT fournisseurs_pkey PRIMARY KEY (id);

--
-- Name: groupware groupware_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groupware
    ADD CONSTRAINT groupware_pkey PRIMARY KEY (id);

--
-- Name: historique_stock_jour historique_stock_jour_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historique_stock_jour
    ADD CONSTRAINT historique_stock_jour_pkey PRIMARY KEY (id_nom, date);

--
-- Name: holidays holidays_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_date_key UNIQUE (date);

--
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);

--
-- Name: instance_produits instance_produits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_produits
    ADD CONSTRAINT instance_produits_pkey PRIMARY KEY (id);

--
-- Name: inventaires inventaires_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventaires
    ADD CONSTRAINT inventaires_pkey PRIMARY KEY (id);

--
-- Name: inventaires_produits inventaires_produits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventaires_produits
    ADD CONSTRAINT inventaires_produits_pkey PRIMARY KEY (id);

--
-- Name: kpi_definitions kpi_definitions_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpi_definitions
    ADD CONSTRAINT kpi_definitions_code_key UNIQUE (code);

--
-- Name: kpi_definitions kpi_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpi_definitions
    ADD CONSTRAINT kpi_definitions_pkey PRIMARY KEY (id);

--
-- Name: laboratoires laboratoires_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.laboratoires
    ADD CONSTRAINT laboratoires_pkey PRIMARY KEY (id);

--
-- Name: maladies_chroniques maladies_chroniques_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maladies_chroniques
    ADD CONSTRAINT maladies_chroniques_code_key UNIQUE (code);

--
-- Name: maladies_chroniques maladies_chroniques_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maladies_chroniques
    ADD CONSTRAINT maladies_chroniques_pkey PRIMARY KEY (id);

--
-- Name: motif_instance motif_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.motif_instance
    ADD CONSTRAINT motif_instance_pkey PRIMARY KEY (id);

--
-- Name: mouchard_details mouchard_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mouchard_details
    ADD CONSTRAINT mouchard_details_pkey PRIMARY KEY (id);

--
-- Name: mouchard mouchard_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mouchard
    ADD CONSTRAINT mouchard_pkey PRIMARY KEY (id);

--
-- Name: nomenclature_chifa nomenclature_chifa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nomenclature_chifa
    ADD CONSTRAINT nomenclature_chifa_pkey PRIMARY KEY (id);

--
-- Name: nomenclature_classification nomenclature_classification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nomenclature_classification
    ADD CONSTRAINT nomenclature_classification_pkey PRIMARY KEY (id);

--
-- Name: nomenclature nomenclature_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nomenclature
    ADD CONSTRAINT nomenclature_pkey PRIMARY KEY (id);

--
-- Name: objectifs_mensuels objectifs_mensuels_annee_mois_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs_mensuels
    ADD CONSTRAINT objectifs_mensuels_annee_mois_key UNIQUE (annee, mois);

--
-- Name: objectifs_mensuels objectifs_mensuels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs_mensuels
    ADD CONSTRAINT objectifs_mensuels_pkey PRIMARY KEY (id);

--
-- Name: operations operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations
    ADD CONSTRAINT operations_pkey PRIMARY KEY (id);

--
-- Name: ordonnancier ordonnancier_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordonnancier
    ADD CONSTRAINT ordonnancier_pkey PRIMARY KEY (id);

--
-- Name: parametres_stock parametres_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parametres_stock
    ADD CONSTRAINT parametres_stock_pkey PRIMARY KEY (id_nom);

--
-- Name: patients_chifa patients_chifa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients_chifa
    ADD CONSTRAINT patients_chifa_pkey PRIMARY KEY (id);

--
-- Name: performance_mensuelle performance_mensuelle_employe_id_annee_mois_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_mensuelle
    ADD CONSTRAINT performance_mensuelle_employe_id_annee_mois_key UNIQUE (employe_id, annee, mois);

--
-- Name: performance_mensuelle performance_mensuelle_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_mensuelle
    ADD CONSTRAINT performance_mensuelle_pkey PRIMARY KEY (id);

--
-- Name: pharmacies pharmacies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pharmacies
    ADD CONSTRAINT pharmacies_pkey PRIMARY KEY (id);

--
-- Name: pharmnos_factures pharmnos_factures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pharmnos_factures
    ADD CONSTRAINT pharmnos_factures_pkey PRIMARY KEY (id);

--
-- Name: postes postes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postes
    ADD CONSTRAINT postes_pkey PRIMARY KEY (id);

--
-- Name: presences_overrides presences_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presences_overrides
    ADD CONSTRAINT presences_overrides_pkey PRIMARY KEY (id);

--
-- Name: prestations prestations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestations
    ADD CONSTRAINT prestations_pkey PRIMARY KEY (id);

--
-- Name: previsions_demande previsions_demande_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.previsions_demande
    ADD CONSTRAINT previsions_demande_pkey PRIMARY KEY (id_nom);

--
-- Name: prime_taux_config prime_taux_config_nom_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prime_taux_config
    ADD CONSTRAINT prime_taux_config_nom_key UNIQUE (nom);

--
-- Name: prime_taux_config prime_taux_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prime_taux_config
    ADD CONSTRAINT prime_taux_config_pkey PRIMARY KEY (id);

--
-- Name: reg_client_association reg_client_association_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reg_client_association
    ADD CONSTRAINT reg_client_association_pkey PRIMARY KEY (id);

--
-- Name: reg_fourn_association reg_fourn_association_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reg_fourn_association
    ADD CONSTRAINT reg_fourn_association_pkey PRIMARY KEY (id);

--
-- Name: sms_logs sms_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sms_logs
    ADD CONSTRAINT sms_logs_pkey PRIMARY KEY (id);

--
-- Name: sorties sorties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorties
    ADD CONSTRAINT sorties_pkey PRIMARY KEY (id);

--
-- Name: sorties_produits sorties_produits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorties_produits
    ADD CONSTRAINT sorties_produits_pkey PRIMARY KEY (id);

--
-- Name: suivi_caisses suivi_caisses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suivi_caisses
    ADD CONSTRAINT suivi_caisses_pkey PRIMARY KEY (id);

--
-- Name: sync_status sync_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_status
    ADD CONSTRAINT sync_status_pkey PRIMARY KEY (id);

--
-- Name: task_assignments task_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_assignments
    ADD CONSTRAINT task_assignments_pkey PRIMARY KEY (id);

--
-- Name: task_templates task_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_templates
    ADD CONSTRAINT task_templates_pkey PRIMARY KEY (id);

--
-- Name: classe_maladie uq_classe_maladie; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classe_maladie
    ADD CONSTRAINT uq_classe_maladie PRIMARY KEY (prefix, code_maladie);

--
-- Name: patients_chifa uq_patient_chifa; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients_chifa
    ADD CONSTRAINT uq_patient_chifa UNIQUE (no_assure, rang_ad);

--
-- Name: presences_overrides uq_presence_employe_date; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presences_overrides
    ADD CONSTRAINT uq_presence_employe_date UNIQUE (employe_id, date);

--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

--
-- Name: ix_bordereaux_chifa_centre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_bordereaux_chifa_centre ON public.bordereaux_chifa USING btree (centre);

--
-- Name: ix_bordereaux_chifa_num_bord; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_bordereaux_chifa_num_bord ON public.bordereaux_chifa USING btree (num_bord);

--
-- Name: ix_caisses_caisse; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_caisses_caisse ON public.caisses USING btree (caisse);

--
-- Name: ix_classe_maladie_prefix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_classe_maladie_prefix ON public.classe_maladie USING btree (prefix);

--
-- Name: ix_clients_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_clients_client ON public.clients USING btree (client);

--
-- Name: ix_clients_is_archive; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_clients_is_archive ON public.clients USING btree (is_archive);

--
-- Name: ix_clients_n_assure_chifa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_clients_n_assure_chifa ON public.clients USING btree (n_assure_chifa);

--
-- Name: ix_clients_num_assure_cvm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_clients_num_assure_cvm ON public.clients USING btree (num_assure_cvm);

--
-- Name: ix_commandes_fournisseurs_produits_id_commande; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_commandes_fournisseurs_produits_id_commande ON public.commandes_fournisseurs_produits USING btree (id_commande);

--
-- Name: ix_demandes_conge_employe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_demandes_conge_employe ON public.demandes_conge USING btree (employe_id);

--
-- Name: ix_demandes_conge_statut; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_demandes_conge_statut ON public.demandes_conge USING btree (statut);

--
-- Name: ix_echanges_sorties_produits_id_echange; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_echanges_sorties_produits_id_echange ON public.echanges_sorties_produits USING btree (id_echange);

--
-- Name: ix_entrees_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_entrees_date ON public.entrees USING btree (date);

--
-- Name: ix_entrees_id_fournisseur; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_entrees_id_fournisseur ON public.entrees USING btree (id_fournisseur);

--
-- Name: ix_entrees_produits_code_barre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_entrees_produits_code_barre ON public.entrees_produits USING btree (code_barre);

--
-- Name: ix_entrees_produits_de_equiv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_entrees_produits_de_equiv ON public.entrees_produits USING btree (de_equiv);

--
-- Name: ix_entrees_produits_id_entree; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_entrees_produits_id_entree ON public.entrees_produits USING btree (id_entree);

--
-- Name: ix_entrees_produits_id_nom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_entrees_produits_id_nom ON public.entrees_produits USING btree (id_nom);

--
-- Name: ix_entrees_produits_nom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_entrees_produits_nom ON public.entrees_produits USING btree (nom);

--
-- Name: ix_facture_anomalies_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_facture_anomalies_date ON public.facture_anomalies USING btree (date_signalement);

--
-- Name: ix_facture_anomalies_no_facture; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_facture_anomalies_no_facture ON public.facture_anomalies USING btree (no_facture);

--
-- Name: ix_facture_anomalies_statut; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_facture_anomalies_statut ON public.facture_anomalies USING btree (statut);

--
-- Name: ix_facture_rejets_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_facture_rejets_date ON public.facture_rejets USING btree (date_rejet);

--
-- Name: ix_facture_rejets_no_facture; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_facture_rejets_no_facture ON public.facture_rejets USING btree (no_facture);

--
-- Name: ix_facture_rejets_statut; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_facture_rejets_statut ON public.facture_rejets USING btree (statut);

--
-- Name: ix_factures_chifa_no_facture; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_factures_chifa_no_facture ON public.factures_chifa USING btree (no_facture);

--
-- Name: ix_fournisseurs_fournisseur; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_fournisseurs_fournisseur ON public.fournisseurs USING btree (fournisseur);

--
-- Name: ix_histo_stock_id_nom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_histo_stock_id_nom ON public.historique_stock_jour USING btree (id_nom);

--
-- Name: ix_instance_produits_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_instance_produits_client ON public.instance_produits USING btree (client);

--
-- Name: ix_instance_produits_date_archive; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_instance_produits_date_archive ON public.instance_produits USING btree (date_archive) WHERE (date_archive IS NOT NULL);

--
-- Name: ix_inventaires_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventaires_date ON public.inventaires USING btree (date);

--
-- Name: ix_inventaires_produits_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventaires_produits_date ON public.inventaires_produits USING btree (date);

--
-- Name: ix_inventaires_produits_id_inventaire; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inventaires_produits_id_inventaire ON public.inventaires_produits USING btree (id_inventaire);

--
-- Name: ix_mouchard_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mouchard_date ON public.mouchard USING btree (date);

--
-- Name: ix_mouchard_details_id_mouchard; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mouchard_details_id_mouchard ON public.mouchard_details USING btree (id_mouchard);

--
-- Name: ix_nomenclature_categorie; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nomenclature_categorie ON public.nomenclature USING btree (categorie) WHERE (categorie IS NOT NULL);

--
-- Name: ix_nomenclature_chifa_id_cnas; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nomenclature_chifa_id_cnas ON public.nomenclature_chifa USING btree (id_cnas);

--
-- Name: ix_nomenclature_chifa_nom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nomenclature_chifa_nom ON public.nomenclature_chifa USING btree (nom);

--
-- Name: ix_nomenclature_classification_categorie; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nomenclature_classification_categorie ON public.nomenclature_classification USING btree (categorie) WHERE (categorie IS NOT NULL);

--
-- Name: ix_nomenclature_classification_employe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nomenclature_classification_employe ON public.nomenclature_classification USING btree (employe_id);

--
-- Name: ix_nomenclature_classification_prefix; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_nomenclature_classification_prefix ON public.nomenclature_classification USING btree (prefix);

--
-- Name: ix_nomenclature_cle_compo_nom_cdb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nomenclature_cle_compo_nom_cdb ON public.nomenclature USING btree (cle_compo_nom_cdb);

--
-- Name: ix_nomenclature_disponibilite; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nomenclature_disponibilite ON public.nomenclature USING btree (disponibilite) WHERE ((disponibilite)::text <> 'oui'::text);

--
-- Name: ix_nomenclature_nom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nomenclature_nom ON public.nomenclature USING btree (nom);

--
-- Name: ix_nomenclature_segment_abc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_nomenclature_segment_abc ON public.nomenclature USING btree (segment_abc);

--
-- Name: ix_operations_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_operations_date ON public.operations USING btree (date);

--
-- Name: ix_operations_id_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_operations_id_session ON public.operations USING btree (id_session);

--
-- Name: ix_operations_n_assure; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_operations_n_assure ON public.operations USING btree (n_assure);

--
-- Name: ix_ordonnancier_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ordonnancier_date ON public.ordonnancier USING btree (date);

--
-- Name: ix_patients_chifa_derniere_visite; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_patients_chifa_derniere_visite ON public.patients_chifa USING btree (derniere_visite);

--
-- Name: ix_patients_chifa_no_assure; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_patients_chifa_no_assure ON public.patients_chifa USING btree (no_assure);

--
-- Name: ix_patients_chifa_statut; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_patients_chifa_statut ON public.patients_chifa USING btree (statut);

--
-- Name: ix_pharmnos_factures_num_dec; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pharmnos_factures_num_dec ON public.pharmnos_factures USING btree (num_dec);

--
-- Name: ix_presences_overrides_employe_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_presences_overrides_employe_date ON public.presences_overrides USING btree (employe_id, date);

--
-- Name: ix_sms_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sms_logs_created_at ON public.sms_logs USING btree (created_at);

--
-- Name: ix_sms_logs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sms_logs_status ON public.sms_logs USING btree (status);

--
-- Name: ix_sms_logs_utilisateur; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sms_logs_utilisateur ON public.sms_logs USING btree (utilisateur);

--
-- Name: ix_sorties_caisse; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_caisse ON public.sorties USING btree (caisse);

--
-- Name: ix_sorties_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_client ON public.sorties USING btree (client);

--
-- Name: ix_sorties_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_date ON public.sorties USING btree (date);

--
-- Name: ix_sorties_id_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_id_session ON public.sorties USING btree (id_session);

--
-- Name: ix_sorties_n_assure; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_n_assure ON public.sorties USING btree (n_assure);

--
-- Name: ix_sorties_poste; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_poste ON public.sorties USING btree (poste);

--
-- Name: ix_sorties_produits_caisse; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_produits_caisse ON public.sorties_produits USING btree (caisse);

--
-- Name: ix_sorties_produits_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_produits_date ON public.sorties_produits USING btree (date);

--
-- Name: ix_sorties_produits_id_nom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_produits_id_nom ON public.sorties_produits USING btree (id_nom);

--
-- Name: ix_sorties_produits_id_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_produits_id_session ON public.sorties_produits USING btree (id_session);

--
-- Name: ix_sorties_utilisateur; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sorties_utilisateur ON public.sorties USING btree (utilisateur);

--
-- Name: ix_suivi_caisses_caisse; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_suivi_caisses_caisse ON public.suivi_caisses USING btree (caisse);

--
-- Name: ix_sync_status_table_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_sync_status_table_name ON public.sync_status USING btree (table_name);

--
-- Name: ix_task_assignments_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_task_assignments_date ON public.task_assignments USING btree (assigned_date);

--
-- Name: ix_task_assignments_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_task_assignments_status ON public.task_assignments USING btree (status);

--
-- Name: ix_task_assignments_user_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_task_assignments_user_date ON public.task_assignments USING btree (assigned_to, assigned_date);

--
-- Name: ix_task_templates_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_task_templates_category ON public.task_templates USING btree (category);

--
-- Name: ix_task_templates_recurrence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_task_templates_recurrence ON public.task_templates USING btree (recurrence);

--
-- Name: ix_users_last_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_users_last_seen_at ON public.users USING btree (last_seen_at);

--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);

--
-- Name: uix_mv_stock_produits_id_nom; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uix_mv_stock_produits_id_nom ON public.mv_stock_produits USING btree (id_nom);

--
-- Name: classe_maladie classe_maladie_code_maladie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classe_maladie
    ADD CONSTRAINT classe_maladie_code_maladie_fkey FOREIGN KEY (code_maladie) REFERENCES public.maladies_chroniques(code);

--
-- Name: demandes_conge demandes_conge_employe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandes_conge
    ADD CONSTRAINT demandes_conge_employe_id_fkey FOREIGN KEY (employe_id) REFERENCES public.employes(id) ON DELETE CASCADE;

--
-- Name: nomenclature_classification nomenclature_classification_employe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nomenclature_classification
    ADD CONSTRAINT nomenclature_classification_employe_id_fkey FOREIGN KEY (employe_id) REFERENCES public.employes(id) ON DELETE SET NULL;

--
-- Name: presences_overrides presences_overrides_employe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presences_overrides
    ADD CONSTRAINT presences_overrides_employe_id_fkey FOREIGN KEY (employe_id) REFERENCES public.employes(id) ON DELETE CASCADE;

--
-- Name: task_assignments task_assignments_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_assignments
    ADD CONSTRAINT task_assignments_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE CASCADE;

--
-- Name: task_assignments task_assignments_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_assignments
    ADD CONSTRAINT task_assignments_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.task_templates(id) ON DELETE CASCADE;

--
-- Name: task_templates task_templates_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_templates
    ADD CONSTRAINT task_templates_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;

--
--
