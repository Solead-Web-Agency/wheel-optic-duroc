-- ============================================
-- FICHIER COMPLET POUR LA ROUE DE LA FORTUNE
-- ============================================
-- Ce fichier contient :
-- 1. Les CREATE TABLE (schéma de base de données)
-- 2. La fonction RPC pour décrémenter le stock
-- 3. Les politiques RLS (Row Level Security)
-- 4. Tous les INSERT pour :
--    - Les segments (lots) disponibles
--    - Les boutiques participantes
--    - Le stock initial de chaque lot par boutique
--
-- MODIFIER CE FICHIER POUR :
-- - Ajouter/modifier les lots (segments)
-- - Modifier les noms des boutiques
-- - Ajuster les quantités de stock
-- ============================================

-- ============================================
-- 0. EXTENSIONS ET CRÉATION DES TABLES
-- ============================================

-- Extension pour générer des UUID
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

-- Table des boutiques
CREATE TABLE IF NOT EXISTS public.shops (
  id text PRIMARY KEY,
  name text NOT NULL
);

-- Table des segments (lots)
CREATE TABLE IF NOT EXISTS public.segments (
  id int PRIMARY KEY,
  title text NOT NULL
);

-- Table du stock par boutique
CREATE TABLE IF NOT EXISTS public.shop_stock (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id text NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  segment_id int NOT NULL REFERENCES public.segments(id) ON DELETE CASCADE,
  remaining int NOT NULL,
  UNIQUE (shop_id, segment_id)
);

CREATE TABLE IF NOT EXISTS public.wins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id text NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  segment_id int NOT NULL REFERENCES public.segments(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Table des participants (emails uniques)
CREATE TABLE IF NOT EXISTS public.participants (
  email text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================
-- 0.1. FONCTION RPC POUR DÉCRÉMENTER LE STOCK
-- ============================================

CREATE OR REPLACE FUNCTION public.decrement_stock(p_shop text, p_segment int)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE new_remaining int;
BEGIN
  UPDATE public.shop_stock
     SET remaining = remaining - 1
   WHERE shop_id = p_shop
     AND segment_id = p_segment
     AND remaining > 0
  RETURNING remaining INTO new_remaining;

  IF new_remaining IS NULL THEN
    RAISE EXCEPTION 'OUT_OF_STOCK';
  END IF;

  INSERT INTO public.wins(shop_id, segment_id) VALUES (p_shop, p_segment);
  RETURN new_remaining;
END;
$$;

-- ============================================
-- 0.2. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Activer RLS sur les tables
ALTER TABLE public.shop_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.participants ENABLE ROW LEVEL SECURITY;

-- Policies pour shop_stock (lecture publique pour anon, nécessaire pour le frontend)
DROP POLICY IF EXISTS shop_stock_read_public ON public.shop_stock;
DROP POLICY IF EXISTS shop_stock_select ON public.shop_stock;
CREATE POLICY shop_stock_read_public ON public.shop_stock FOR SELECT TO anon USING (true);

-- Policies pour wins (lecture via service role uniquement)
DROP POLICY IF EXISTS wins_select ON public.wins;
CREATE POLICY wins_select ON public.wins FOR SELECT TO authenticated, anon USING (false);

-- Policies pour participants : insert autorisé pour anon, pas de lecture
DROP POLICY IF EXISTS participants_insert_anon ON public.participants;
DROP POLICY IF EXISTS participants_select ON public.participants;
CREATE POLICY participants_insert_anon ON public.participants FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY participants_select ON public.participants FOR SELECT TO authenticated, anon USING (false);

-- Permission d'exécuter la fonction RPC pour anon
GRANT EXECUTE ON FUNCTION public.decrement_stock(text, int) TO anon;

-- ============================================
-- 0.3. NETTOYAGE DES DONNÉES EXISTANTES
-- ============================================
-- Supprime toutes les données existantes avant réinsertion
-- (à exécuter dans l'ordre pour respecter les contraintes de clés étrangères)

DELETE FROM public.wins;
DELETE FROM public.shop_stock;
DELETE FROM public.participants;
DELETE FROM public.shops;
DELETE FROM public.segments;

-- ============================================
-- 1. SEGMENTS (LOTS) - MODIFIER ICI POUR AJOUTER/MODIFIER LES LOTS
-- ============================================
-- Format: (id, 'Nom du lot')
-- Les IDs doivent être uniques et séquentiels (1, 2, 3, ...)
-- Pour ajouter un lot, ajoutez une nouvelle ligne avec un nouvel ID

INSERT INTO public.segments(id, title) VALUES
  (1, 'STYLO'),
  (2, 'TOTE BAG'),
  (3, 'TROUSSE VOYAGE'),
  (4, 'CHARGEUR'),
  (5, 'BAUME À LÈVRES'),
  (6, 'PORTE CARTE'),
  (7, 'SPRAY'),
  (8, 'HAUT PARLEUR'),
  (9, '10% DE RÉDUCTION'),
  (10, 'RIEN'),
  (11, 'CARTE DE JEU'),
  (12, 'CHAINES A LUNETTES')
ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title;

-- ============================================
-- 2. BOUTIQUES - MODIFIER ICI POUR LES NOMS DES BOUTIQUES
-- ============================================
-- Format: ('shop-X', 'Nom de la boutique')
-- Modifiez les noms selon vos besoins
-- Pour ajouter/supprimer des boutiques, ajoutez/retirez des lignes

INSERT INTO public.shops(id, name) VALUES
  ('shop-1', '88 Rue de Sèvres 75007 PARIS'),
  ('shop-2', '113, Bd Voltaire 75011 PARIS'),
  ('shop-3', '25 Rue de l''Etape 51100 REIMS'),
  ('shop-4', '22 Rue du 22 Novembre 67000 STRASBOURG'),
  ('shop-5', '14 Rue de Ladoucette 57000 METZ'),
  ('shop-6', '25 Av. de la Motte Picquet 75007 PARIS'),
  ('shop-7', '2 Place des Prêcheurs (1 rue Thiers r/c) 13100 AIX EN PROVENCE'),
  ('shop-8', '50, Rue d''Alsace Lorraine 31000 TOULOUSE'),
  ('shop-9', '31 Bd Voltaire 75011 PARIS'),
  ('shop-10', '62 Avenue de la République 92120 MONTROUGE'),
  ('shop-11', '22 rue de la Boetie 75008 PARIS'),
  ('shop-12', '3-5 ave Foch 94100 STM'),
  ('shop-13', '130 bis ave Charles de Gaulle 92200 NEUILLY SUR SEINE'),
  ('shop-14', '19 Avenue du Général Leclerc 75014 PARIS'),
  ('shop-15', '130 bis ave Marechal Leclerc 14000 CAEN'),
  ('shop-16', '16/18 Rue des huissiers 92200 Neuilly Sur Seine'),
  ('shop-17', '59 Rue de Paris 94220 Charenton le pont'),
  ('shop-18', '23 bis Avenue de Longueil 78600 MAISON LAFFITTE'),
  ('shop-19', '61 Rue de la liberté 21000 DIJON'),
  ('shop-20', '3-5 rue du Sauvage 68100 MULHOUSE'),
  ('shop-21', '92 rue de la Paroisse 78000 VERSAILLES'),
  ('shop-22', '116 rue de Paris 93260 LES LILAS'),
  ('shop-23', '34 Grande rue Maurice Viollette 28100 DREUX'),
  ('shop-24', '62 rue du Dr Oursel 27000 EVREUX'),
  ('shop-25', '27 rue de la Loge 34000 MONTPELLIER'),
  ('shop-26', '3 Bld de l''Amiral Courbet 30000 NIMES'),
  ('shop-27', '4 Rue de la Gaillarde 89100 ST CLEMENT'),
  ('shop-28', '2/4 Place Charles Bernard 75018 PARIS'),
  ('shop-29', '40 Rue Victor Hugo 68002 LYON'),
  ('shop-30', '28, bd St Denis 75010 PARIS'),
  ('shop-31', '5, rue des prêtres 68000 COLMAR'),
  ('shop-32', '38, Avenue de la République 75011 PARIS'),
  ('shop-33', '611 av Roger Salengro 93270 CHAVILLE'),
  ('shop-34', '49 rue Louise Michel 92300 LEVALLOIS PERRET'),
  ('shop-35', '19 rue Paul Vaillant Couturier 92140 CLAMART'),
  ('shop-36', '23 bis rue Pierre Brossolette 92600 ASNIERES'),
  ('shop-37', '195 av de Versailles 75016 PARIS'),
  ('shop-38', '22 av Niel 75017 PARIS'),
  ('shop-39', '609 av André Ampère - ZAC Leclerc 77190 DAMMARIE LES LYS'),
  ('shop-40', '189 rue Galliéni 92100 BOULOGNE BILLANCOURT'),
  ('shop-41', '5 rue Varlet 56630 BOURBOURG'),
  ('shop-42', '6 rue Francois Marceau - CC Ruban Bleu 44600 ST NAZAIRE'),
  ('shop-43', '91 Av. de Clichy 75017 PARIS'),
  ('shop-44', '8 Allée des Conviviales - CC Peychotte 33700 MERIGNAC'),
  ('shop-45', '23 ave Pasteur 93290 TREMBLAY'),
  ('shop-46', '140 bld Robert Ballanger 93420 VILLEPINTE'),
  ('shop-47', '223 rue de la Convention 75015 PARIS'),
  ('shop-48', '12 place Jean Baptiste Lully 78210 SAINT CYR'),
  ('shop-49', '114 Avenue Jean Jaures 75019 PARIS'),
  ('shop-50', 'Rue emile zola 62119 DOURGES'),
  ('shop-51', '10 RUE VIVIENNE 75002 PARIS'),
  ('shop-52', '1 Bis Pl. du Général de Gaulle 93340 Le Raincy'),
  ('shop-53', 'Chem. de Trigance ZAC 13800 Istres'),
  ('shop-54', '2 rue Vavin (Luxembourg) 75006 PARIS'),
  ('shop-55', '9 Rue Collignon 78100 Saint-Germain-en-Laye')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- ============================================
-- 3. STOCK INITIAL PAR BOUTIQUE ET PAR LOT
-- ============================================
-- Format: ('shop-X', segment_id, quantité)
-- MODIFIER ICI POUR AJUSTER LES QUANTITÉS
-- 
-- Structure actuelle (quantités par boutique) :
-- - STYLO (segment_id: 1) : 6 unités (325 total / 55 boutiques ≈ 6)
-- - TOTE BAG (segment_id: 2) : 6 unités (325 total / 55 boutiques ≈ 6)
-- - TROUSSE VOYAGE (segment_id: 3) : 4 unités (195 total / 55 boutiques ≈ 4)
-- - CHARGEUR (segment_id: 4) : 4 unités (195 total / 55 boutiques ≈ 4)
-- - BAUME À LÈVRES (segment_id: 5) : 6 unités (325 total / 55 boutiques ≈ 6)
-- - PORTE CARTE (segment_id: 6) : 4 unités (195 total / 55 boutiques ≈ 4)
-- - SPRAY (segment_id: 7) : 6 unités (325 total / 55 boutiques ≈ 6)
-- - HAUT PARLEUR (segment_id: 8) : 2 unités (130 total / 55 boutiques ≈ 2)
-- - 10% DE RÉDUCTION (segment_id: 9) : 5 unités (260 total / 55 boutiques ≈ 5)
-- - RIEN (segment_id: 10) : 9 unités (520 total / 55 boutiques ≈ 9)
-- - CARTE DE JEU (segment_id: 11) : 6 unités (325 total / 55 boutiques ≈ 6)
-- - CHAINES A LUNETTES (segment_id: 12) : 6 unités (325 total / 55 boutiques ≈ 6)
--
-- Note: Les quantités sont arrondies pour simplifier. Pour une distribution exacte,
-- ajustez manuellement certaines boutiques si nécessaire.

-- Stock pour shop-1
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-1', 1, 6),   -- STYLO
  ('shop-1', 2, 6),   -- TOTE BAG
  ('shop-1', 3, 4),   -- TROUSSE VOYAGE
  ('shop-1', 4, 4),   -- CHARGEUR
  ('shop-1', 5, 6),   -- BAUME À LÈVRES
  ('shop-1', 6, 4),   -- PORTE CARTE
  ('shop-1', 7, 6),   -- SPRAY
  ('shop-1', 8, 2),   -- HAUT PARLEUR
  ('shop-1', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-1', 10, 9),  -- RIEN
  ('shop-1', 11, 6),  -- CARTE DE JEU
  ('shop-1', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-2
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-2', 1, 6),   -- STYLO
  ('shop-2', 2, 6),   -- TOTE BAG
  ('shop-2', 3, 4),   -- TROUSSE VOYAGE
  ('shop-2', 4, 4),   -- CHARGEUR
  ('shop-2', 5, 6),   -- BAUME À LÈVRES
  ('shop-2', 6, 4),   -- PORTE CARTE
  ('shop-2', 7, 6),   -- SPRAY
  ('shop-2', 8, 2),   -- HAUT PARLEUR
  ('shop-2', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-2', 10, 9),  -- RIEN
  ('shop-2', 11, 6),  -- CARTE DE JEU
  ('shop-2', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-3
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-3', 1, 6),   -- STYLO
  ('shop-3', 2, 6),   -- TOTE BAG
  ('shop-3', 3, 4),   -- TROUSSE VOYAGE
  ('shop-3', 4, 4),   -- CHARGEUR
  ('shop-3', 5, 6),   -- BAUME À LÈVRES
  ('shop-3', 6, 4),   -- PORTE CARTE
  ('shop-3', 7, 6),   -- SPRAY
  ('shop-3', 8, 2),   -- HAUT PARLEUR
  ('shop-3', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-3', 10, 9),  -- RIEN
  ('shop-3', 11, 6),  -- CARTE DE JEU
  ('shop-3', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-4
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-4', 1, 6),   -- STYLO
  ('shop-4', 2, 6),   -- TOTE BAG
  ('shop-4', 3, 4),   -- TROUSSE VOYAGE
  ('shop-4', 4, 4),   -- CHARGEUR
  ('shop-4', 5, 6),   -- BAUME À LÈVRES
  ('shop-4', 6, 4),   -- PORTE CARTE
  ('shop-4', 7, 6),   -- SPRAY
  ('shop-4', 8, 2),   -- HAUT PARLEUR
  ('shop-4', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-4', 10, 9),  -- RIEN
  ('shop-4', 11, 6),  -- CARTE DE JEU
  ('shop-4', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-5
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-5', 1, 6),   -- STYLO
  ('shop-5', 2, 6),   -- TOTE BAG
  ('shop-5', 3, 4),   -- TROUSSE VOYAGE
  ('shop-5', 4, 4),   -- CHARGEUR
  ('shop-5', 5, 6),   -- BAUME À LÈVRES
  ('shop-5', 6, 4),   -- PORTE CARTE
  ('shop-5', 7, 6),   -- SPRAY
  ('shop-5', 8, 2),   -- HAUT PARLEUR
  ('shop-5', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-5', 10, 9),  -- RIEN
  ('shop-5', 11, 6),  -- CARTE DE JEU
  ('shop-5', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-6
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-6', 1, 6),   -- STYLO
  ('shop-6', 2, 6),   -- TOTE BAG
  ('shop-6', 3, 4),   -- TROUSSE VOYAGE
  ('shop-6', 4, 4),   -- CHARGEUR
  ('shop-6', 5, 6),   -- BAUME À LÈVRES
  ('shop-6', 6, 4),   -- PORTE CARTE
  ('shop-6', 7, 6),   -- SPRAY
  ('shop-6', 8, 2),   -- HAUT PARLEUR
  ('shop-6', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-6', 10, 9),  -- RIEN
  ('shop-6', 11, 6),  -- CARTE DE JEU
  ('shop-6', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-7
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-7', 1, 6),   -- STYLO
  ('shop-7', 2, 6),   -- TOTE BAG
  ('shop-7', 3, 4),   -- TROUSSE VOYAGE
  ('shop-7', 4, 4),   -- CHARGEUR
  ('shop-7', 5, 6),   -- BAUME À LÈVRES
  ('shop-7', 6, 4),   -- PORTE CARTE
  ('shop-7', 7, 6),   -- SPRAY
  ('shop-7', 8, 2),   -- HAUT PARLEUR
  ('shop-7', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-7', 10, 9),  -- RIEN
  ('shop-7', 11, 6),  -- CARTE DE JEU
  ('shop-7', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-8
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-8', 1, 6),   -- STYLO
  ('shop-8', 2, 6),   -- TOTE BAG
  ('shop-8', 3, 4),   -- TROUSSE VOYAGE
  ('shop-8', 4, 4),   -- CHARGEUR
  ('shop-8', 5, 6),   -- BAUME À LÈVRES
  ('shop-8', 6, 4),   -- PORTE CARTE
  ('shop-8', 7, 6),   -- SPRAY
  ('shop-8', 8, 2),   -- HAUT PARLEUR
  ('shop-8', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-8', 10, 9),  -- RIEN
  ('shop-8', 11, 6),  -- CARTE DE JEU
  ('shop-8', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-9
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-9', 1, 6),   -- STYLO
  ('shop-9', 2, 6),   -- TOTE BAG
  ('shop-9', 3, 4),   -- TROUSSE VOYAGE
  ('shop-9', 4, 4),   -- CHARGEUR
  ('shop-9', 5, 6),   -- BAUME À LÈVRES
  ('shop-9', 6, 4),   -- PORTE CARTE
  ('shop-9', 7, 6),   -- SPRAY
  ('shop-9', 8, 2),   -- HAUT PARLEUR
  ('shop-9', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-9', 10, 9),  -- RIEN
  ('shop-9', 11, 6),  -- CARTE DE JEU
  ('shop-9', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-10
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-10', 1, 6),   -- STYLO
  ('shop-10', 2, 6),   -- TOTE BAG
  ('shop-10', 3, 4),   -- TROUSSE VOYAGE
  ('shop-10', 4, 4),   -- CHARGEUR
  ('shop-10', 5, 6),   -- BAUME À LÈVRES
  ('shop-10', 6, 4),   -- PORTE CARTE
  ('shop-10', 7, 6),   -- SPRAY
  ('shop-10', 8, 2),   -- HAUT PARLEUR
  ('shop-10', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-10', 10, 9),  -- RIEN
  ('shop-10', 11, 6),  -- CARTE DE JEU
  ('shop-10', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-11
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-11', 1, 6),   -- STYLO
  ('shop-11', 2, 6),   -- TOTE BAG
  ('shop-11', 3, 4),   -- TROUSSE VOYAGE
  ('shop-11', 4, 4),   -- CHARGEUR
  ('shop-11', 5, 6),   -- BAUME À LÈVRES
  ('shop-11', 6, 4),   -- PORTE CARTE
  ('shop-11', 7, 6),   -- SPRAY
  ('shop-11', 8, 2),   -- HAUT PARLEUR
  ('shop-11', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-11', 10, 9),  -- RIEN
  ('shop-11', 11, 6),  -- CARTE DE JEU
  ('shop-11', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-12
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-12', 1, 6),   -- STYLO
  ('shop-12', 2, 6),   -- TOTE BAG
  ('shop-12', 3, 4),   -- TROUSSE VOYAGE
  ('shop-12', 4, 4),   -- CHARGEUR
  ('shop-12', 5, 6),   -- BAUME À LÈVRES
  ('shop-12', 6, 4),   -- PORTE CARTE
  ('shop-12', 7, 6),   -- SPRAY
  ('shop-12', 8, 2),   -- HAUT PARLEUR
  ('shop-12', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-12', 10, 9),  -- RIEN
  ('shop-12', 11, 6),  -- CARTE DE JEU
  ('shop-12', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-13
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-13', 1, 6),   -- STYLO
  ('shop-13', 2, 6),   -- TOTE BAG
  ('shop-13', 3, 4),   -- TROUSSE VOYAGE
  ('shop-13', 4, 4),   -- CHARGEUR
  ('shop-13', 5, 6),   -- BAUME À LÈVRES
  ('shop-13', 6, 4),   -- PORTE CARTE
  ('shop-13', 7, 6),   -- SPRAY
  ('shop-13', 8, 2),   -- HAUT PARLEUR
  ('shop-13', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-13', 10, 9),  -- RIEN
  ('shop-13', 11, 6),  -- CARTE DE JEU
  ('shop-13', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-14
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-14', 1, 6),   -- STYLO
  ('shop-14', 2, 6),   -- TOTE BAG
  ('shop-14', 3, 4),   -- TROUSSE VOYAGE
  ('shop-14', 4, 4),   -- CHARGEUR
  ('shop-14', 5, 6),   -- BAUME À LÈVRES
  ('shop-14', 6, 4),   -- PORTE CARTE
  ('shop-14', 7, 6),   -- SPRAY
  ('shop-14', 8, 2),   -- HAUT PARLEUR
  ('shop-14', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-14', 10, 9),  -- RIEN
  ('shop-14', 11, 6),  -- CARTE DE JEU
  ('shop-14', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-15
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-15', 1, 6),   -- STYLO
  ('shop-15', 2, 6),   -- TOTE BAG
  ('shop-15', 3, 4),   -- TROUSSE VOYAGE
  ('shop-15', 4, 4),   -- CHARGEUR
  ('shop-15', 5, 6),   -- BAUME À LÈVRES
  ('shop-15', 6, 4),   -- PORTE CARTE
  ('shop-15', 7, 6),   -- SPRAY
  ('shop-15', 8, 2),   -- HAUT PARLEUR
  ('shop-15', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-15', 10, 9),  -- RIEN
  ('shop-15', 11, 6),  -- CARTE DE JEU
  ('shop-15', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-16
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-16', 1, 6),   -- STYLO
  ('shop-16', 2, 6),   -- TOTE BAG
  ('shop-16', 3, 4),   -- TROUSSE VOYAGE
  ('shop-16', 4, 4),   -- CHARGEUR
  ('shop-16', 5, 6),   -- BAUME À LÈVRES
  ('shop-16', 6, 4),   -- PORTE CARTE
  ('shop-16', 7, 6),   -- SPRAY
  ('shop-16', 8, 2),   -- HAUT PARLEUR
  ('shop-16', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-16', 10, 9),  -- RIEN
  ('shop-16', 11, 6),  -- CARTE DE JEU
  ('shop-16', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-17
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-17', 1, 6),   -- STYLO
  ('shop-17', 2, 6),   -- TOTE BAG
  ('shop-17', 3, 4),   -- TROUSSE VOYAGE
  ('shop-17', 4, 4),   -- CHARGEUR
  ('shop-17', 5, 6),   -- BAUME À LÈVRES
  ('shop-17', 6, 4),   -- PORTE CARTE
  ('shop-17', 7, 6),   -- SPRAY
  ('shop-17', 8, 2),   -- HAUT PARLEUR
  ('shop-17', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-17', 10, 9),  -- RIEN
  ('shop-17', 11, 6),  -- CARTE DE JEU
  ('shop-17', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-18
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-18', 1, 6),   -- STYLO
  ('shop-18', 2, 6),   -- TOTE BAG
  ('shop-18', 3, 4),   -- TROUSSE VOYAGE
  ('shop-18', 4, 4),   -- CHARGEUR
  ('shop-18', 5, 6),   -- BAUME À LÈVRES
  ('shop-18', 6, 4),   -- PORTE CARTE
  ('shop-18', 7, 6),   -- SPRAY
  ('shop-18', 8, 2),   -- HAUT PARLEUR
  ('shop-18', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-18', 10, 9),  -- RIEN
  ('shop-18', 11, 6),  -- CARTE DE JEU
  ('shop-18', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-19
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-19', 1, 6),   -- STYLO
  ('shop-19', 2, 6),   -- TOTE BAG
  ('shop-19', 3, 4),   -- TROUSSE VOYAGE
  ('shop-19', 4, 4),   -- CHARGEUR
  ('shop-19', 5, 6),   -- BAUME À LÈVRES
  ('shop-19', 6, 4),   -- PORTE CARTE
  ('shop-19', 7, 6),   -- SPRAY
  ('shop-19', 8, 2),   -- HAUT PARLEUR
  ('shop-19', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-19', 10, 9),  -- RIEN
  ('shop-19', 11, 6),  -- CARTE DE JEU
  ('shop-19', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-20
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-20', 1, 6),   -- STYLO
  ('shop-20', 2, 6),   -- TOTE BAG
  ('shop-20', 3, 4),   -- TROUSSE VOYAGE
  ('shop-20', 4, 4),   -- CHARGEUR
  ('shop-20', 5, 6),   -- BAUME À LÈVRES
  ('shop-20', 6, 4),   -- PORTE CARTE
  ('shop-20', 7, 6),   -- SPRAY
  ('shop-20', 8, 2),   -- HAUT PARLEUR
  ('shop-20', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-20', 10, 9),  -- RIEN
  ('shop-20', 11, 6),  -- CARTE DE JEU
  ('shop-20', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-21
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-21', 1, 6),   -- STYLO
  ('shop-21', 2, 6),   -- TOTE BAG
  ('shop-21', 3, 4),   -- TROUSSE VOYAGE
  ('shop-21', 4, 4),   -- CHARGEUR
  ('shop-21', 5, 6),   -- BAUME À LÈVRES
  ('shop-21', 6, 4),   -- PORTE CARTE
  ('shop-21', 7, 6),   -- SPRAY
  ('shop-21', 8, 2),   -- HAUT PARLEUR
  ('shop-21', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-21', 10, 9),  -- RIEN
  ('shop-21', 11, 6),  -- CARTE DE JEU
  ('shop-21', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-22
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-22', 1, 6),   -- STYLO
  ('shop-22', 2, 6),   -- TOTE BAG
  ('shop-22', 3, 4),   -- TROUSSE VOYAGE
  ('shop-22', 4, 4),   -- CHARGEUR
  ('shop-22', 5, 6),   -- BAUME À LÈVRES
  ('shop-22', 6, 4),   -- PORTE CARTE
  ('shop-22', 7, 6),   -- SPRAY
  ('shop-22', 8, 2),   -- HAUT PARLEUR
  ('shop-22', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-22', 10, 9),  -- RIEN
  ('shop-22', 11, 6),  -- CARTE DE JEU
  ('shop-22', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-23
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-23', 1, 6),   -- STYLO
  ('shop-23', 2, 6),   -- TOTE BAG
  ('shop-23', 3, 4),   -- TROUSSE VOYAGE
  ('shop-23', 4, 4),   -- CHARGEUR
  ('shop-23', 5, 6),   -- BAUME À LÈVRES
  ('shop-23', 6, 4),   -- PORTE CARTE
  ('shop-23', 7, 6),   -- SPRAY
  ('shop-23', 8, 2),   -- HAUT PARLEUR
  ('shop-23', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-23', 10, 9),  -- RIEN
  ('shop-23', 11, 6),  -- CARTE DE JEU
  ('shop-23', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-24
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-24', 1, 6),   -- STYLO
  ('shop-24', 2, 6),   -- TOTE BAG
  ('shop-24', 3, 4),   -- TROUSSE VOYAGE
  ('shop-24', 4, 4),   -- CHARGEUR
  ('shop-24', 5, 6),   -- BAUME À LÈVRES
  ('shop-24', 6, 4),   -- PORTE CARTE
  ('shop-24', 7, 6),   -- SPRAY
  ('shop-24', 8, 2),   -- HAUT PARLEUR
  ('shop-24', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-24', 10, 9),  -- RIEN
  ('shop-24', 11, 6),  -- CARTE DE JEU
  ('shop-24', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-25
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-25', 1, 6),   -- STYLO
  ('shop-25', 2, 6),   -- TOTE BAG
  ('shop-25', 3, 4),   -- TROUSSE VOYAGE
  ('shop-25', 4, 4),   -- CHARGEUR
  ('shop-25', 5, 6),   -- BAUME À LÈVRES
  ('shop-25', 6, 4),   -- PORTE CARTE
  ('shop-25', 7, 6),   -- SPRAY
  ('shop-25', 8, 2),   -- HAUT PARLEUR
  ('shop-25', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-25', 10, 9),  -- RIEN
  ('shop-25', 11, 6),  -- CARTE DE JEU
  ('shop-25', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-26
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-26', 1, 6),   -- STYLO
  ('shop-26', 2, 6),   -- TOTE BAG
  ('shop-26', 3, 4),   -- TROUSSE VOYAGE
  ('shop-26', 4, 4),   -- CHARGEUR
  ('shop-26', 5, 6),   -- BAUME À LÈVRES
  ('shop-26', 6, 4),   -- PORTE CARTE
  ('shop-26', 7, 6),   -- SPRAY
  ('shop-26', 8, 2),   -- HAUT PARLEUR
  ('shop-26', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-26', 10, 9),  -- RIEN
  ('shop-26', 11, 6),  -- CARTE DE JEU
  ('shop-26', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-27
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-27', 1, 6),   -- STYLO
  ('shop-27', 2, 6),   -- TOTE BAG
  ('shop-27', 3, 4),   -- TROUSSE VOYAGE
  ('shop-27', 4, 4),   -- CHARGEUR
  ('shop-27', 5, 6),   -- BAUME À LÈVRES
  ('shop-27', 6, 4),   -- PORTE CARTE
  ('shop-27', 7, 6),   -- SPRAY
  ('shop-27', 8, 2),   -- HAUT PARLEUR
  ('shop-27', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-27', 10, 9),  -- RIEN
  ('shop-27', 11, 6),  -- CARTE DE JEU
  ('shop-27', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-28
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-28', 1, 6),   -- STYLO
  ('shop-28', 2, 6),   -- TOTE BAG
  ('shop-28', 3, 4),   -- TROUSSE VOYAGE
  ('shop-28', 4, 4),   -- CHARGEUR
  ('shop-28', 5, 6),   -- BAUME À LÈVRES
  ('shop-28', 6, 4),   -- PORTE CARTE
  ('shop-28', 7, 6),   -- SPRAY
  ('shop-28', 8, 2),   -- HAUT PARLEUR
  ('shop-28', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-28', 10, 9),  -- RIEN
  ('shop-28', 11, 6),  -- CARTE DE JEU
  ('shop-28', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-29
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-29', 1, 6),   -- STYLO
  ('shop-29', 2, 6),   -- TOTE BAG
  ('shop-29', 3, 4),   -- TROUSSE VOYAGE
  ('shop-29', 4, 4),   -- CHARGEUR
  ('shop-29', 5, 6),   -- BAUME À LÈVRES
  ('shop-29', 6, 4),   -- PORTE CARTE
  ('shop-29', 7, 6),   -- SPRAY
  ('shop-29', 8, 2),   -- HAUT PARLEUR
  ('shop-29', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-29', 10, 9),  -- RIEN
  ('shop-29', 11, 6),  -- CARTE DE JEU
  ('shop-29', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-30
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-30', 1, 6),   -- STYLO
  ('shop-30', 2, 6),   -- TOTE BAG
  ('shop-30', 3, 4),   -- TROUSSE VOYAGE
  ('shop-30', 4, 4),   -- CHARGEUR
  ('shop-30', 5, 6),   -- BAUME À LÈVRES
  ('shop-30', 6, 4),   -- PORTE CARTE
  ('shop-30', 7, 6),   -- SPRAY
  ('shop-30', 8, 2),   -- HAUT PARLEUR
  ('shop-30', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-30', 10, 9),  -- RIEN
  ('shop-30', 11, 6),  -- CARTE DE JEU
  ('shop-30', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-31
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-31', 1, 6),   -- STYLO
  ('shop-31', 2, 6),   -- TOTE BAG
  ('shop-31', 3, 4),   -- TROUSSE VOYAGE
  ('shop-31', 4, 4),   -- CHARGEUR
  ('shop-31', 5, 6),   -- BAUME À LÈVRES
  ('shop-31', 6, 4),   -- PORTE CARTE
  ('shop-31', 7, 6),   -- SPRAY
  ('shop-31', 8, 2),   -- HAUT PARLEUR
  ('shop-31', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-31', 10, 9),  -- RIEN
  ('shop-31', 11, 6),  -- CARTE DE JEU
  ('shop-31', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-32
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-32', 1, 6),   -- STYLO
  ('shop-32', 2, 6),   -- TOTE BAG
  ('shop-32', 3, 4),   -- TROUSSE VOYAGE
  ('shop-32', 4, 4),   -- CHARGEUR
  ('shop-32', 5, 6),   -- BAUME À LÈVRES
  ('shop-32', 6, 4),   -- PORTE CARTE
  ('shop-32', 7, 6),   -- SPRAY
  ('shop-32', 8, 2),   -- HAUT PARLEUR
  ('shop-32', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-32', 10, 9),  -- RIEN
  ('shop-32', 11, 6),  -- CARTE DE JEU
  ('shop-32', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-33
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-33', 1, 6),   -- STYLO
  ('shop-33', 2, 6),   -- TOTE BAG
  ('shop-33', 3, 4),   -- TROUSSE VOYAGE
  ('shop-33', 4, 4),   -- CHARGEUR
  ('shop-33', 5, 6),   -- BAUME À LÈVRES
  ('shop-33', 6, 4),   -- PORTE CARTE
  ('shop-33', 7, 6),   -- SPRAY
  ('shop-33', 8, 2),   -- HAUT PARLEUR
  ('shop-33', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-33', 10, 9),  -- RIEN
  ('shop-33', 11, 6),  -- CARTE DE JEU
  ('shop-33', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-34
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-34', 1, 6),   -- STYLO
  ('shop-34', 2, 6),   -- TOTE BAG
  ('shop-34', 3, 4),   -- TROUSSE VOYAGE
  ('shop-34', 4, 4),   -- CHARGEUR
  ('shop-34', 5, 6),   -- BAUME À LÈVRES
  ('shop-34', 6, 4),   -- PORTE CARTE
  ('shop-34', 7, 6),   -- SPRAY
  ('shop-34', 8, 2),   -- HAUT PARLEUR
  ('shop-34', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-34', 10, 9),  -- RIEN
  ('shop-34', 11, 6),  -- CARTE DE JEU
  ('shop-34', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-35
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-35', 1, 6),   -- STYLO
  ('shop-35', 2, 6),   -- TOTE BAG
  ('shop-35', 3, 4),   -- TROUSSE VOYAGE
  ('shop-35', 4, 4),   -- CHARGEUR
  ('shop-35', 5, 6),   -- BAUME À LÈVRES
  ('shop-35', 6, 4),   -- PORTE CARTE
  ('shop-35', 7, 6),   -- SPRAY
  ('shop-35', 8, 2),   -- HAUT PARLEUR
  ('shop-35', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-35', 10, 9),  -- RIEN
  ('shop-35', 11, 6),  -- CARTE DE JEU
  ('shop-35', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-36
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-36', 1, 6),   -- STYLO
  ('shop-36', 2, 6),   -- TOTE BAG
  ('shop-36', 3, 4),   -- TROUSSE VOYAGE
  ('shop-36', 4, 4),   -- CHARGEUR
  ('shop-36', 5, 6),   -- BAUME À LÈVRES
  ('shop-36', 6, 4),   -- PORTE CARTE
  ('shop-36', 7, 6),   -- SPRAY
  ('shop-36', 8, 2),   -- HAUT PARLEUR
  ('shop-36', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-36', 10, 9),  -- RIEN
  ('shop-36', 11, 6),  -- CARTE DE JEU
  ('shop-36', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-37
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-37', 1, 6),   -- STYLO
  ('shop-37', 2, 6),   -- TOTE BAG
  ('shop-37', 3, 4),   -- TROUSSE VOYAGE
  ('shop-37', 4, 4),   -- CHARGEUR
  ('shop-37', 5, 6),   -- BAUME À LÈVRES
  ('shop-37', 6, 4),   -- PORTE CARTE
  ('shop-37', 7, 6),   -- SPRAY
  ('shop-37', 8, 2),   -- HAUT PARLEUR
  ('shop-37', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-37', 10, 9),  -- RIEN
  ('shop-37', 11, 6),  -- CARTE DE JEU
  ('shop-37', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-38
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-38', 1, 6),   -- STYLO
  ('shop-38', 2, 6),   -- TOTE BAG
  ('shop-38', 3, 4),   -- TROUSSE VOYAGE
  ('shop-38', 4, 4),   -- CHARGEUR
  ('shop-38', 5, 6),   -- BAUME À LÈVRES
  ('shop-38', 6, 4),   -- PORTE CARTE
  ('shop-38', 7, 6),   -- SPRAY
  ('shop-38', 8, 2),   -- HAUT PARLEUR
  ('shop-38', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-38', 10, 9),  -- RIEN
  ('shop-38', 11, 6),  -- CARTE DE JEU
  ('shop-38', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-39
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-39', 1, 6),   -- STYLO
  ('shop-39', 2, 6),   -- TOTE BAG
  ('shop-39', 3, 4),   -- TROUSSE VOYAGE
  ('shop-39', 4, 4),   -- CHARGEUR
  ('shop-39', 5, 6),   -- BAUME À LÈVRES
  ('shop-39', 6, 4),   -- PORTE CARTE
  ('shop-39', 7, 6),   -- SPRAY
  ('shop-39', 8, 2),   -- HAUT PARLEUR
  ('shop-39', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-39', 10, 9),  -- RIEN
  ('shop-39', 11, 6),  -- CARTE DE JEU
  ('shop-39', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-40
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-40', 1, 6),   -- STYLO
  ('shop-40', 2, 6),   -- TOTE BAG
  ('shop-40', 3, 4),   -- TROUSSE VOYAGE
  ('shop-40', 4, 4),   -- CHARGEUR
  ('shop-40', 5, 6),   -- BAUME À LÈVRES
  ('shop-40', 6, 4),   -- PORTE CARTE
  ('shop-40', 7, 6),   -- SPRAY
  ('shop-40', 8, 2),   -- HAUT PARLEUR
  ('shop-40', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-40', 10, 9),  -- RIEN
  ('shop-40', 11, 6),  -- CARTE DE JEU
  ('shop-40', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-41
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-41', 1, 6),   -- STYLO
  ('shop-41', 2, 6),   -- TOTE BAG
  ('shop-41', 3, 4),   -- TROUSSE VOYAGE
  ('shop-41', 4, 4),   -- CHARGEUR
  ('shop-41', 5, 6),   -- BAUME À LÈVRES
  ('shop-41', 6, 4),   -- PORTE CARTE
  ('shop-41', 7, 6),   -- SPRAY
  ('shop-41', 8, 2),   -- HAUT PARLEUR
  ('shop-41', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-41', 10, 9),  -- RIEN
  ('shop-41', 11, 6),  -- CARTE DE JEU
  ('shop-41', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-42
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-42', 1, 6),   -- STYLO
  ('shop-42', 2, 6),   -- TOTE BAG
  ('shop-42', 3, 4),   -- TROUSSE VOYAGE
  ('shop-42', 4, 4),   -- CHARGEUR
  ('shop-42', 5, 6),   -- BAUME À LÈVRES
  ('shop-42', 6, 4),   -- PORTE CARTE
  ('shop-42', 7, 6),   -- SPRAY
  ('shop-42', 8, 2),   -- HAUT PARLEUR
  ('shop-42', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-42', 10, 9),  -- RIEN
  ('shop-42', 11, 6),  -- CARTE DE JEU
  ('shop-42', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-43
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-43', 1, 6),   -- STYLO
  ('shop-43', 2, 6),   -- TOTE BAG
  ('shop-43', 3, 4),   -- TROUSSE VOYAGE
  ('shop-43', 4, 4),   -- CHARGEUR
  ('shop-43', 5, 6),   -- BAUME À LÈVRES
  ('shop-43', 6, 4),   -- PORTE CARTE
  ('shop-43', 7, 6),   -- SPRAY
  ('shop-43', 8, 2),   -- HAUT PARLEUR
  ('shop-43', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-43', 10, 9),  -- RIEN
  ('shop-43', 11, 6),  -- CARTE DE JEU
  ('shop-43', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-44
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-44', 1, 6),   -- STYLO
  ('shop-44', 2, 6),   -- TOTE BAG
  ('shop-44', 3, 4),   -- TROUSSE VOYAGE
  ('shop-44', 4, 4),   -- CHARGEUR
  ('shop-44', 5, 6),   -- BAUME À LÈVRES
  ('shop-44', 6, 4),   -- PORTE CARTE
  ('shop-44', 7, 6),   -- SPRAY
  ('shop-44', 8, 2),   -- HAUT PARLEUR
  ('shop-44', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-44', 10, 9),  -- RIEN
  ('shop-44', 11, 6),  -- CARTE DE JEU
  ('shop-44', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-45
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-45', 1, 6),   -- STYLO
  ('shop-45', 2, 6),   -- TOTE BAG
  ('shop-45', 3, 4),   -- TROUSSE VOYAGE
  ('shop-45', 4, 4),   -- CHARGEUR
  ('shop-45', 5, 6),   -- BAUME À LÈVRES
  ('shop-45', 6, 4),   -- PORTE CARTE
  ('shop-45', 7, 6),   -- SPRAY
  ('shop-45', 8, 2),   -- HAUT PARLEUR
  ('shop-45', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-45', 10, 9),  -- RIEN
  ('shop-45', 11, 6),  -- CARTE DE JEU
  ('shop-45', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-46
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-46', 1, 6),   -- STYLO
  ('shop-46', 2, 6),   -- TOTE BAG
  ('shop-46', 3, 4),   -- TROUSSE VOYAGE
  ('shop-46', 4, 4),   -- CHARGEUR
  ('shop-46', 5, 6),   -- BAUME À LÈVRES
  ('shop-46', 6, 4),   -- PORTE CARTE
  ('shop-46', 7, 6),   -- SPRAY
  ('shop-46', 8, 2),   -- HAUT PARLEUR
  ('shop-46', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-46', 10, 9),  -- RIEN
  ('shop-46', 11, 6),  -- CARTE DE JEU
  ('shop-46', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-47
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-47', 1, 6),   -- STYLO
  ('shop-47', 2, 6),   -- TOTE BAG
  ('shop-47', 3, 4),   -- TROUSSE VOYAGE
  ('shop-47', 4, 4),   -- CHARGEUR
  ('shop-47', 5, 6),   -- BAUME À LÈVRES
  ('shop-47', 6, 4),   -- PORTE CARTE
  ('shop-47', 7, 6),   -- SPRAY
  ('shop-47', 8, 2),   -- HAUT PARLEUR
  ('shop-47', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-47', 10, 9),  -- RIEN
  ('shop-47', 11, 6),  -- CARTE DE JEU
  ('shop-47', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-48
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-48', 1, 6),   -- STYLO
  ('shop-48', 2, 6),   -- TOTE BAG
  ('shop-48', 3, 4),   -- TROUSSE VOYAGE
  ('shop-48', 4, 4),   -- CHARGEUR
  ('shop-48', 5, 6),   -- BAUME À LÈVRES
  ('shop-48', 6, 4),   -- PORTE CARTE
  ('shop-48', 7, 6),   -- SPRAY
  ('shop-48', 8, 2),   -- HAUT PARLEUR
  ('shop-48', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-48', 10, 9),  -- RIEN
  ('shop-48', 11, 6),  -- CARTE DE JEU
  ('shop-48', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-49
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-49', 1, 6),   -- STYLO
  ('shop-49', 2, 6),   -- TOTE BAG
  ('shop-49', 3, 4),   -- TROUSSE VOYAGE
  ('shop-49', 4, 4),   -- CHARGEUR
  ('shop-49', 5, 6),   -- BAUME À LÈVRES
  ('shop-49', 6, 4),   -- PORTE CARTE
  ('shop-49', 7, 6),   -- SPRAY
  ('shop-49', 8, 2),   -- HAUT PARLEUR
  ('shop-49', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-49', 10, 9),  -- RIEN
  ('shop-49', 11, 6),  -- CARTE DE JEU
  ('shop-49', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-50
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-50', 1, 6),   -- STYLO
  ('shop-50', 2, 6),   -- TOTE BAG
  ('shop-50', 3, 4),   -- TROUSSE VOYAGE
  ('shop-50', 4, 4),   -- CHARGEUR
  ('shop-50', 5, 6),   -- BAUME À LÈVRES
  ('shop-50', 6, 4),   -- PORTE CARTE
  ('shop-50', 7, 6),   -- SPRAY
  ('shop-50', 8, 2),   -- HAUT PARLEUR
  ('shop-50', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-50', 10, 9),  -- RIEN
  ('shop-50', 11, 6),  -- CARTE DE JEU
  ('shop-50', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-51
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-51', 1, 6),   -- STYLO
  ('shop-51', 2, 6),   -- TOTE BAG
  ('shop-51', 3, 4),   -- TROUSSE VOYAGE
  ('shop-51', 4, 4),   -- CHARGEUR
  ('shop-51', 5, 6),   -- BAUME À LÈVRES
  ('shop-51', 6, 4),   -- PORTE CARTE
  ('shop-51', 7, 6),   -- SPRAY
  ('shop-51', 8, 2),   -- HAUT PARLEUR
  ('shop-51', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-51', 10, 9),  -- RIEN
  ('shop-51', 11, 6),  -- CARTE DE JEU
  ('shop-51', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-52
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-52', 1, 6),   -- STYLO
  ('shop-52', 2, 6),   -- TOTE BAG
  ('shop-52', 3, 4),   -- TROUSSE VOYAGE
  ('shop-52', 4, 4),   -- CHARGEUR
  ('shop-52', 5, 6),   -- BAUME À LÈVRES
  ('shop-52', 6, 4),   -- PORTE CARTE
  ('shop-52', 7, 6),   -- SPRAY
  ('shop-52', 8, 2),   -- HAUT PARLEUR
  ('shop-52', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-52', 10, 9),  -- RIEN
  ('shop-52', 11, 6),  -- CARTE DE JEU
  ('shop-52', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-53
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-53', 1, 6),   -- STYLO
  ('shop-53', 2, 6),   -- TOTE BAG
  ('shop-53', 3, 4),   -- TROUSSE VOYAGE
  ('shop-53', 4, 4),   -- CHARGEUR
  ('shop-53', 5, 6),   -- BAUME À LÈVRES
  ('shop-53', 6, 4),   -- PORTE CARTE
  ('shop-53', 7, 6),   -- SPRAY
  ('shop-53', 8, 2),   -- HAUT PARLEUR
  ('shop-53', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-53', 10, 9),  -- RIEN
  ('shop-53', 11, 6),  -- CARTE DE JEU
  ('shop-53', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-54
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-54', 1, 6),   -- STYLO
  ('shop-54', 2, 6),   -- TOTE BAG
  ('shop-54', 3, 4),   -- TROUSSE VOYAGE
  ('shop-54', 4, 4),   -- CHARGEUR
  ('shop-54', 5, 6),   -- BAUME À LÈVRES
  ('shop-54', 6, 4),   -- PORTE CARTE
  ('shop-54', 7, 6),   -- SPRAY
  ('shop-54', 8, 2),   -- HAUT PARLEUR
  ('shop-54', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-54', 10, 9),  -- RIEN
  ('shop-54', 11, 6),  -- CARTE DE JEU
  ('shop-54', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- Stock pour shop-55
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-55', 1, 6),   -- STYLO
  ('shop-55', 2, 6),   -- TOTE BAG
  ('shop-55', 3, 4),   -- TROUSSE VOYAGE
  ('shop-55', 4, 4),   -- CHARGEUR
  ('shop-55', 5, 6),   -- BAUME À LÈVRES
  ('shop-55', 6, 4),   -- PORTE CARTE
  ('shop-55', 7, 6),   -- SPRAY
  ('shop-55', 8, 2),   -- HAUT PARLEUR
  ('shop-55', 9, 5),   -- 10% DE RÉDUCTION
  ('shop-55', 10, 9),  -- RIEN
  ('shop-55', 11, 6),  -- CARTE DE JEU
  ('shop-55', 12, 6)   -- CHAINES A LUNETTES
ON CONFLICT (shop_id, segment_id) DO UPDATE SET remaining = EXCLUDED.remaining;

-- ============================================
-- FIN DU FICHIER
-- ============================================
-- Après modification, exécutez ce fichier dans Supabase SQL Editor
-- ou via psql pour mettre à jour la base de données

