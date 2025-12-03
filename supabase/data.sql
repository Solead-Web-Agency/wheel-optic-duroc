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
-- 0. SUPPRESSION ET RECRÉATION DES TABLES
-- ============================================
-- Extension pour générer des UUID
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
-- Supprimer toutes les tables existantes (CASCADE pour supprimer les dépendances)
DROP TABLE IF EXISTS public.wins CASCADE;
DROP TABLE IF EXISTS public.shop_stock CASCADE;
DROP TABLE IF EXISTS public.participants CASCADE;
DROP TABLE IF EXISTS public.segments CASCADE;
DROP TABLE IF EXISTS public.shops CASCADE;
-- Supprimer la fonction RPC si elle existe
DROP FUNCTION IF EXISTS public.decrement_stock(text, int);
-- Table des boutiques
CREATE TABLE public.shops (
  id text PRIMARY KEY,
  name text NOT NULL,
  email text NOT NULL
);
-- Table des segments (lots)
CREATE TABLE public.segments (
  id int PRIMARY KEY,
  title text NOT NULL
);
-- Table du stock par boutique
CREATE TABLE public.shop_stock (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id text NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  segment_id int NOT NULL REFERENCES public.segments(id) ON DELETE CASCADE,
  remaining int NOT NULL,
  UNIQUE (shop_id, segment_id)
);
-- Table des gains
CREATE TABLE public.wins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id text NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  segment_id int NOT NULL REFERENCES public.segments(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);
-- Table des participants (emails uniques)
CREATE TABLE public.participants (
  email text PRIMARY KEY,
  first_name text NOT NULL,
  last_name text NOT NULL,
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
  (9, 'CHAINETTES'),
  (10, 'MASQUE'),
  (11, 'ETUIS SOUPLE');
-- ============================================
-- 2. BOUTIQUES - MODIFIER ICI POUR LES NOMS DES BOUTIQUES
-- ============================================
-- Format: ('shop-X', 'Nom de la boutique', 'email@opticduroc.com')
-- Modifiez les noms selon vos besoins
-- Pour ajouter/supprimer des boutiques, ajoutez/retirez des lignes
INSERT INTO public.shops(id, name, email) VALUES
  ('shop-1', 'OPTIC DUROC PARIS 7 SÈVRES', 'sevres@opticduroc.com'),
  ('shop-2', 'OPTIC DUROC PARIS 11 VOLTAIRE', 'voltaire@opticduroc.com'),
  ('shop-3', 'OPTIC DUROC REIMS', 'reims@opticduroc.com'),
  ('shop-4', 'OPTIC DUROC STRASBOURG', 'strasbourg@opticduroc.com'),
  ('shop-5', 'OPTIC DUROC METZ', 'metz@opticduroc.com'),
  ('shop-6', 'OPTIC DUROC PARIS 7 MOTTE PICQUET', 'motte-picquet@opticduroc.com'),
  ('shop-7', 'OPTIC DUROC AIX EN PROVENCE', 'aix@opticduroc.com'),
  ('shop-8', 'OPTIC DUROC TOULOUSE', 'toulouse@opticduroc.com'),
  ('shop-9', 'OPTIC DUROC PARIS 11 OBERKAMPF', 'oberkampf@opticduroc.com'),
  ('shop-10', 'OPTIC DUROC MONTROUGE', 'montrouge@opticduroc.com'),
  ('shop-11', 'OPTIC DUROC PARIS 08 BOETIE', 'boetie@opticduroc.com'),
  ('shop-12', 'OPTIC DUROC SAINT MAUR DES FOSSÉS', 'saint-maur@opticduroc.com'),
  ('shop-13', 'OPTIC DUROC NEUILLY SUR SEINE', 'neuilly@opticduroc.com'),
  ('shop-14', 'OPTIC DUROC PARIS 14', 'paris14@opticduroc.com'),
  ('shop-15', 'OPTIC DUROC CAEN THEATRE', 'caentheatre@opticduroc.com'),
  ('shop-16', 'DUROC AUDITION NEUILLY SUR SEINE', 'neuilly@durocaudition.com'),
  ('shop-17', 'OPTIC DUROC CHARENTON LE PONT', 'charenton@opticduroc.com'),
  ('shop-18', 'DUROC AUDITION MAISON LAFFITTE', 'maisonlaffitte@durocaudition.com'),
  ('shop-19', 'OPTIC DUROC DIJON', 'dijon@opticduroc.com'),
  ('shop-20', 'OPTIC DUROC MULHOUSE', 'mulhouse@opticduroc.com'),
  ('shop-21', 'OPTIC DUROC VERSAILLES', 'versailles@opticduroc.com'),
  ('shop-22', 'OPTIC DUROC LES LILAS', 'leslilas@opticduroc.com'),
  ('shop-23', 'OPTIC DUROC DREUX', 'dreux@opticduroc.com'),
  ('shop-24', 'OPTIC DUROC EVREUX', 'evreux@opticduroc.com'),
  ('shop-25', 'OPTIC DUROC MONTPELLIER', 'montpellier@opticduroc.com'),
  ('shop-26', 'OPTIC DUROC NIMES', 'nimes@opticduroc.com'),
  ('shop-27', 'OPTIC DUROC ST CLEMENT - SENS', 'sens@opticduroc.com'),
  ('shop-28', 'OPTIC DUROC PARIS 18', 'paris18@opticduroc.com'),
  ('shop-29', 'OPTIC DUROC LYON', 'lyon02@opticduroc.com'),
  ('shop-30', 'OPTIC DUROC PARIS 10', 'paris10@opticduroc.com'),
  ('shop-31', 'OPTIC DUROC COLMAR', 'colmar@opticduroc.com'),
  ('shop-32', 'OPTIC DUROC PARIS 11 REPUBLIQUE', 'republique@opticduroc.com'),
  ('shop-33', 'OPTIC DUROC CHAVILLE', 'chaville@opticduroc.com'),
  ('shop-34', 'OPTIC DUROC LEVALLOIS PERRET', 'levallois@opticduroc.com'),
  ('shop-35', 'OPTIC DUROC CLAMART', 'clamart@opticduroc.com'),
  ('shop-36', 'OPTIC DUROC ASNIERES', 'asnieres@opticduroc.com'),
  ('shop-37', 'OPTIC DUROC PARIS 16', 'paris16@opticduroc.com'),
  ('shop-38', 'OPTIC DUROC PARIS 17 NIEL', 'niel@opticduroc.com'),
  ('shop-39', 'OPTIC DUROC DAMMARIE LES LYS', 'colmar@opticduroc.com'),
  ('shop-40', 'OPTIC DUROC BOULOGNE BILLANCOURT', 'boulogne@opticduroc.com'),
  ('shop-41', 'OPTIC DUROC ST NAZAIRE', 'saint-nazaire@opticduroc.com'),
  ('shop-42', 'OPTIC DUROC PARIS 17 CLICHY', 'clichy@opticduroc.com'),
  ('shop-43', 'OPTIC DUROC TREMBLAY', 'tremblay@opticduroc.com'),
  ('shop-44', 'OPTIC DUROC PARIS 15', 'paris15@opticduroc.com'),
  ('shop-45', 'OPTIC DUROC SAINT CYR', 'saint-cyr@opticduroc.com'),
  ('shop-46', 'OPTIC DUROC PARIS 19', 'paris19@opticduroc.com'),
  ('shop-47', 'OPTIC DUROC NOYELLES', 'noyelles@opticduroc.com'),
  ('shop-48', 'OPTIC DUROC PARIS 2', 'paris02@opticduroc.com'),
  ('shop-49', 'OPTIC DUROC LE RAINCY', 'leraincy@opticduroc.com'),
  ('shop-50', 'OPTIC DUROC ISTRES', 'istres@opticduroc.com'),
  ('shop-51', 'OPTIC DUROC Saint-Germain-en-Laye', 'saintgermainenlaye@opticduroc.com'),
  ('shop-52', 'OPTIC DUROC MOULINS LES METZ', 'augny@opticduroc.com'),
  ('shop-53', 'OPTIC DUROC PARIS 12', 'bercy@opticduroc.com'),
  ('shop-53', 'OPTIC DUROC PARIS 12', 'bercy@opticduroc.com');
-- ============================================
-- 3. STOCK INITIAL PAR BOUTIQUE ET PAR LOT
-- ============================================
-- Format: ('shop-X', segment_id, quantité)
-- MODIFIER ICI POUR AJUSTER LES QUANTITÉS
-- 
-- Structure actuelle (quantités par boutique) :
-- - STYLO (segment_id: 1) : 5 unités (275 total / 55 boutiques)
-- - TOTE BAG (segment_id: 2) : 10 unités (550 total / 55 boutiques)
-- - TROUSSE VOYAGE (segment_id: 3) : 3 unités (165 total / 55 boutiques)
-- - CHARGEUR (segment_id: 4) : 3 unités (165 total / 55 boutiques)
-- - BAUME À LÈVRES (segment_id: 5) : 5 unités (275 total / 55 boutiques)
-- - PORTE CARTE (segment_id: 6) : 3 unités (165 total / 55 boutiques)
-- - SPRAY (segment_id: 7) : 4 unités (220 total / 55 boutiques)
-- - HAUT PARLEUR (segment_id: 8) : 2 unités (110 total / 55 boutiques)
-- - CHAINETTES (segment_id: 9) : 5 unités (275 total / 55 boutiques)
-- - MASQUE (segment_id: 10) : 2 unités (110 total / 55 boutiques)
-- - ETUIS SOUPLE (segment_id: 11) : 5 unités (275 total / 55 boutiques)
-- Stock pour shop-1
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-1', 1, 5),  -- STYLO
  ('shop-1', 2, 10),  -- TOTE BAG
  ('shop-1', 3, 3),  -- TROUSSE VOYAGE
  ('shop-1', 4, 3),  -- CHARGEUR
  ('shop-1', 5, 5),  -- BAUME À LÈVRES
  ('shop-1', 6, 3),  -- PORTE CARTE
  ('shop-1', 7, 4),  -- SPRAY
  ('shop-1', 8, 2),  -- HAUT PARLEUR
  ('shop-1', 9, 5),  -- CHAINETTES
  ('shop-1', 10, 2),  -- MASQUE
  ('shop-1', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-2
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-2', 1, 5),  -- STYLO
  ('shop-2', 2, 10),  -- TOTE BAG
  ('shop-2', 3, 3),  -- TROUSSE VOYAGE
  ('shop-2', 4, 3),  -- CHARGEUR
  ('shop-2', 5, 5),  -- BAUME À LÈVRES
  ('shop-2', 6, 3),  -- PORTE CARTE
  ('shop-2', 7, 4),  -- SPRAY
  ('shop-2', 8, 2),  -- HAUT PARLEUR
  ('shop-2', 9, 5),  -- CHAINETTES
  ('shop-2', 10, 2),  -- MASQUE
  ('shop-2', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-3
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-3', 1, 5),  -- STYLO
  ('shop-3', 2, 10),  -- TOTE BAG
  ('shop-3', 3, 3),  -- TROUSSE VOYAGE
  ('shop-3', 4, 3),  -- CHARGEUR
  ('shop-3', 5, 5),  -- BAUME À LÈVRES
  ('shop-3', 6, 3),  -- PORTE CARTE
  ('shop-3', 7, 4),  -- SPRAY
  ('shop-3', 8, 2),  -- HAUT PARLEUR
  ('shop-3', 9, 5),  -- CHAINETTES
  ('shop-3', 10, 2),  -- MASQUE
  ('shop-3', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-4
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-4', 1, 5),  -- STYLO
  ('shop-4', 2, 10),  -- TOTE BAG
  ('shop-4', 3, 3),  -- TROUSSE VOYAGE
  ('shop-4', 4, 3),  -- CHARGEUR
  ('shop-4', 5, 5),  -- BAUME À LÈVRES
  ('shop-4', 6, 3),  -- PORTE CARTE
  ('shop-4', 7, 4),  -- SPRAY
  ('shop-4', 8, 2),  -- HAUT PARLEUR
  ('shop-4', 9, 5),  -- CHAINETTES
  ('shop-4', 10, 2),  -- MASQUE
  ('shop-4', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-5
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-5', 1, 5),  -- STYLO
  ('shop-5', 2, 10),  -- TOTE BAG
  ('shop-5', 3, 3),  -- TROUSSE VOYAGE
  ('shop-5', 4, 3),  -- CHARGEUR
  ('shop-5', 5, 5),  -- BAUME À LÈVRES
  ('shop-5', 6, 3),  -- PORTE CARTE
  ('shop-5', 7, 4),  -- SPRAY
  ('shop-5', 8, 2),  -- HAUT PARLEUR
  ('shop-5', 9, 5),  -- CHAINETTES
  ('shop-5', 10, 2),  -- MASQUE
  ('shop-5', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-6
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-6', 1, 5),  -- STYLO
  ('shop-6', 2, 10),  -- TOTE BAG
  ('shop-6', 3, 3),  -- TROUSSE VOYAGE
  ('shop-6', 4, 3),  -- CHARGEUR
  ('shop-6', 5, 5),  -- BAUME À LÈVRES
  ('shop-6', 6, 3),  -- PORTE CARTE
  ('shop-6', 7, 4),  -- SPRAY
  ('shop-6', 8, 2),  -- HAUT PARLEUR
  ('shop-6', 9, 5),  -- CHAINETTES
  ('shop-6', 10, 2),  -- MASQUE
  ('shop-6', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-7
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-7', 1, 5),  -- STYLO
  ('shop-7', 2, 10),  -- TOTE BAG
  ('shop-7', 3, 3),  -- TROUSSE VOYAGE
  ('shop-7', 4, 3),  -- CHARGEUR
  ('shop-7', 5, 5),  -- BAUME À LÈVRES
  ('shop-7', 6, 3),  -- PORTE CARTE
  ('shop-7', 7, 4),  -- SPRAY
  ('shop-7', 8, 2),  -- HAUT PARLEUR
  ('shop-7', 9, 5),  -- CHAINETTES
  ('shop-7', 10, 2),  -- MASQUE
  ('shop-7', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-8
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-8', 1, 5),  -- STYLO
  ('shop-8', 2, 10),  -- TOTE BAG
  ('shop-8', 3, 3),  -- TROUSSE VOYAGE
  ('shop-8', 4, 3),  -- CHARGEUR
  ('shop-8', 5, 5),  -- BAUME À LÈVRES
  ('shop-8', 6, 3),  -- PORTE CARTE
  ('shop-8', 7, 4),  -- SPRAY
  ('shop-8', 8, 2),  -- HAUT PARLEUR
  ('shop-8', 9, 5),  -- CHAINETTES
  ('shop-8', 10, 2),  -- MASQUE
  ('shop-8', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-9
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-9', 1, 5),  -- STYLO
  ('shop-9', 2, 10),  -- TOTE BAG
  ('shop-9', 3, 3),  -- TROUSSE VOYAGE
  ('shop-9', 4, 3),  -- CHARGEUR
  ('shop-9', 5, 5),  -- BAUME À LÈVRES
  ('shop-9', 6, 3),  -- PORTE CARTE
  ('shop-9', 7, 4),  -- SPRAY
  ('shop-9', 8, 2),  -- HAUT PARLEUR
  ('shop-9', 9, 5),  -- CHAINETTES
  ('shop-9', 10, 2),  -- MASQUE
  ('shop-9', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-10
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-10', 1, 5),  -- STYLO
  ('shop-10', 2, 10),  -- TOTE BAG
  ('shop-10', 3, 3),  -- TROUSSE VOYAGE
  ('shop-10', 4, 3),  -- CHARGEUR
  ('shop-10', 5, 5),  -- BAUME À LÈVRES
  ('shop-10', 6, 3),  -- PORTE CARTE
  ('shop-10', 7, 4),  -- SPRAY
  ('shop-10', 8, 2),  -- HAUT PARLEUR
  ('shop-10', 9, 5),  -- CHAINETTES
  ('shop-10', 10, 2),  -- MASQUE
  ('shop-10', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-11
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-11', 1, 5),  -- STYLO
  ('shop-11', 2, 10),  -- TOTE BAG
  ('shop-11', 3, 3),  -- TROUSSE VOYAGE
  ('shop-11', 4, 3),  -- CHARGEUR
  ('shop-11', 5, 5),  -- BAUME À LÈVRES
  ('shop-11', 6, 3),  -- PORTE CARTE
  ('shop-11', 7, 4),  -- SPRAY
  ('shop-11', 8, 2),  -- HAUT PARLEUR
  ('shop-11', 9, 5),  -- CHAINETTES
  ('shop-11', 10, 2),  -- MASQUE
  ('shop-11', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-12
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-12', 1, 5),  -- STYLO
  ('shop-12', 2, 10),  -- TOTE BAG
  ('shop-12', 3, 3),  -- TROUSSE VOYAGE
  ('shop-12', 4, 3),  -- CHARGEUR
  ('shop-12', 5, 5),  -- BAUME À LÈVRES
  ('shop-12', 6, 3),  -- PORTE CARTE
  ('shop-12', 7, 4),  -- SPRAY
  ('shop-12', 8, 2),  -- HAUT PARLEUR
  ('shop-12', 9, 5),  -- CHAINETTES
  ('shop-12', 10, 2),  -- MASQUE
  ('shop-12', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-13
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-13', 1, 5),  -- STYLO
  ('shop-13', 2, 10),  -- TOTE BAG
  ('shop-13', 3, 3),  -- TROUSSE VOYAGE
  ('shop-13', 4, 3),  -- CHARGEUR
  ('shop-13', 5, 5),  -- BAUME À LÈVRES
  ('shop-13', 6, 3),  -- PORTE CARTE
  ('shop-13', 7, 4),  -- SPRAY
  ('shop-13', 8, 2),  -- HAUT PARLEUR
  ('shop-13', 9, 5),  -- CHAINETTES
  ('shop-13', 10, 2),  -- MASQUE
  ('shop-13', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-14
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-14', 1, 5),  -- STYLO
  ('shop-14', 2, 10),  -- TOTE BAG
  ('shop-14', 3, 3),  -- TROUSSE VOYAGE
  ('shop-14', 4, 3),  -- CHARGEUR
  ('shop-14', 5, 5),  -- BAUME À LÈVRES
  ('shop-14', 6, 3),  -- PORTE CARTE
  ('shop-14', 7, 4),  -- SPRAY
  ('shop-14', 8, 2),  -- HAUT PARLEUR
  ('shop-14', 9, 5),  -- CHAINETTES
  ('shop-14', 10, 2),  -- MASQUE
  ('shop-14', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-15
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-15', 1, 5),  -- STYLO
  ('shop-15', 2, 10),  -- TOTE BAG
  ('shop-15', 3, 3),  -- TROUSSE VOYAGE
  ('shop-15', 4, 3),  -- CHARGEUR
  ('shop-15', 5, 5),  -- BAUME À LÈVRES
  ('shop-15', 6, 3),  -- PORTE CARTE
  ('shop-15', 7, 4),  -- SPRAY
  ('shop-15', 8, 2),  -- HAUT PARLEUR
  ('shop-15', 9, 5),  -- CHAINETTES
  ('shop-15', 10, 2),  -- MASQUE
  ('shop-15', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-16
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-16', 1, 5),  -- STYLO
  ('shop-16', 2, 10),  -- TOTE BAG
  ('shop-16', 3, 3),  -- TROUSSE VOYAGE
  ('shop-16', 4, 3),  -- CHARGEUR
  ('shop-16', 5, 5),  -- BAUME À LÈVRES
  ('shop-16', 6, 3),  -- PORTE CARTE
  ('shop-16', 7, 4),  -- SPRAY
  ('shop-16', 8, 2),  -- HAUT PARLEUR
  ('shop-16', 9, 5),  -- CHAINETTES
  ('shop-16', 10, 2),  -- MASQUE
  ('shop-16', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-17
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-17', 1, 5),  -- STYLO
  ('shop-17', 2, 10),  -- TOTE BAG
  ('shop-17', 3, 3),  -- TROUSSE VOYAGE
  ('shop-17', 4, 3),  -- CHARGEUR
  ('shop-17', 5, 5),  -- BAUME À LÈVRES
  ('shop-17', 6, 3),  -- PORTE CARTE
  ('shop-17', 7, 4),  -- SPRAY
  ('shop-17', 8, 2),  -- HAUT PARLEUR
  ('shop-17', 9, 5),  -- CHAINETTES
  ('shop-17', 10, 2),  -- MASQUE
  ('shop-17', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-18
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-18', 1, 5),  -- STYLO
  ('shop-18', 2, 10),  -- TOTE BAG
  ('shop-18', 3, 3),  -- TROUSSE VOYAGE
  ('shop-18', 4, 3),  -- CHARGEUR
  ('shop-18', 5, 5),  -- BAUME À LÈVRES
  ('shop-18', 6, 3),  -- PORTE CARTE
  ('shop-18', 7, 4),  -- SPRAY
  ('shop-18', 8, 2),  -- HAUT PARLEUR
  ('shop-18', 9, 5),  -- CHAINETTES
  ('shop-18', 10, 2),  -- MASQUE
  ('shop-18', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-19
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-19', 1, 5),  -- STYLO
  ('shop-19', 2, 10),  -- TOTE BAG
  ('shop-19', 3, 3),  -- TROUSSE VOYAGE
  ('shop-19', 4, 3),  -- CHARGEUR
  ('shop-19', 5, 5),  -- BAUME À LÈVRES
  ('shop-19', 6, 3),  -- PORTE CARTE
  ('shop-19', 7, 4),  -- SPRAY
  ('shop-19', 8, 2),  -- HAUT PARLEUR
  ('shop-19', 9, 5),  -- CHAINETTES
  ('shop-19', 10, 2),  -- MASQUE
  ('shop-19', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-20
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-20', 1, 5),  -- STYLO
  ('shop-20', 2, 10),  -- TOTE BAG
  ('shop-20', 3, 3),  -- TROUSSE VOYAGE
  ('shop-20', 4, 3),  -- CHARGEUR
  ('shop-20', 5, 5),  -- BAUME À LÈVRES
  ('shop-20', 6, 3),  -- PORTE CARTE
  ('shop-20', 7, 4),  -- SPRAY
  ('shop-20', 8, 2),  -- HAUT PARLEUR
  ('shop-20', 9, 5),  -- CHAINETTES
  ('shop-20', 10, 2),  -- MASQUE
  ('shop-20', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-21
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-21', 1, 5),  -- STYLO
  ('shop-21', 2, 10),  -- TOTE BAG
  ('shop-21', 3, 3),  -- TROUSSE VOYAGE
  ('shop-21', 4, 3),  -- CHARGEUR
  ('shop-21', 5, 5),  -- BAUME À LÈVRES
  ('shop-21', 6, 3),  -- PORTE CARTE
  ('shop-21', 7, 4),  -- SPRAY
  ('shop-21', 8, 2),  -- HAUT PARLEUR
  ('shop-21', 9, 5),  -- CHAINETTES
  ('shop-21', 10, 2),  -- MASQUE
  ('shop-21', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-22
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-22', 1, 5),  -- STYLO
  ('shop-22', 2, 10),  -- TOTE BAG
  ('shop-22', 3, 3),  -- TROUSSE VOYAGE
  ('shop-22', 4, 3),  -- CHARGEUR
  ('shop-22', 5, 5),  -- BAUME À LÈVRES
  ('shop-22', 6, 3),  -- PORTE CARTE
  ('shop-22', 7, 4),  -- SPRAY
  ('shop-22', 8, 2),  -- HAUT PARLEUR
  ('shop-22', 9, 5),  -- CHAINETTES
  ('shop-22', 10, 2),  -- MASQUE
  ('shop-22', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-23
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-23', 1, 5),  -- STYLO
  ('shop-23', 2, 10),  -- TOTE BAG
  ('shop-23', 3, 3),  -- TROUSSE VOYAGE
  ('shop-23', 4, 3),  -- CHARGEUR
  ('shop-23', 5, 5),  -- BAUME À LÈVRES
  ('shop-23', 6, 3),  -- PORTE CARTE
  ('shop-23', 7, 4),  -- SPRAY
  ('shop-23', 8, 2),  -- HAUT PARLEUR
  ('shop-23', 9, 5),  -- CHAINETTES
  ('shop-23', 10, 2),  -- MASQUE
  ('shop-23', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-24
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-24', 1, 5),  -- STYLO
  ('shop-24', 2, 10),  -- TOTE BAG
  ('shop-24', 3, 3),  -- TROUSSE VOYAGE
  ('shop-24', 4, 3),  -- CHARGEUR
  ('shop-24', 5, 5),  -- BAUME À LÈVRES
  ('shop-24', 6, 3),  -- PORTE CARTE
  ('shop-24', 7, 4),  -- SPRAY
  ('shop-24', 8, 2),  -- HAUT PARLEUR
  ('shop-24', 9, 5),  -- CHAINETTES
  ('shop-24', 10, 2),  -- MASQUE
  ('shop-24', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-25
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-25', 1, 5),  -- STYLO
  ('shop-25', 2, 10),  -- TOTE BAG
  ('shop-25', 3, 3),  -- TROUSSE VOYAGE
  ('shop-25', 4, 3),  -- CHARGEUR
  ('shop-25', 5, 5),  -- BAUME À LÈVRES
  ('shop-25', 6, 3),  -- PORTE CARTE
  ('shop-25', 7, 4),  -- SPRAY
  ('shop-25', 8, 2),  -- HAUT PARLEUR
  ('shop-25', 9, 5),  -- CHAINETTES
  ('shop-25', 10, 2),  -- MASQUE
  ('shop-25', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-26
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-26', 1, 5),  -- STYLO
  ('shop-26', 2, 10),  -- TOTE BAG
  ('shop-26', 3, 3),  -- TROUSSE VOYAGE
  ('shop-26', 4, 3),  -- CHARGEUR
  ('shop-26', 5, 5),  -- BAUME À LÈVRES
  ('shop-26', 6, 3),  -- PORTE CARTE
  ('shop-26', 7, 4),  -- SPRAY
  ('shop-26', 8, 2),  -- HAUT PARLEUR
  ('shop-26', 9, 5),  -- CHAINETTES
  ('shop-26', 10, 2),  -- MASQUE
  ('shop-26', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-27
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-27', 1, 5),  -- STYLO
  ('shop-27', 2, 10),  -- TOTE BAG
  ('shop-27', 3, 3),  -- TROUSSE VOYAGE
  ('shop-27', 4, 3),  -- CHARGEUR
  ('shop-27', 5, 5),  -- BAUME À LÈVRES
  ('shop-27', 6, 3),  -- PORTE CARTE
  ('shop-27', 7, 4),  -- SPRAY
  ('shop-27', 8, 2),  -- HAUT PARLEUR
  ('shop-27', 9, 5),  -- CHAINETTES
  ('shop-27', 10, 2),  -- MASQUE
  ('shop-27', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-28
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-28', 1, 5),  -- STYLO
  ('shop-28', 2, 10),  -- TOTE BAG
  ('shop-28', 3, 3),  -- TROUSSE VOYAGE
  ('shop-28', 4, 3),  -- CHARGEUR
  ('shop-28', 5, 5),  -- BAUME À LÈVRES
  ('shop-28', 6, 3),  -- PORTE CARTE
  ('shop-28', 7, 4),  -- SPRAY
  ('shop-28', 8, 2),  -- HAUT PARLEUR
  ('shop-28', 9, 5),  -- CHAINETTES
  ('shop-28', 10, 2),  -- MASQUE
  ('shop-28', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-29
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-29', 1, 5),  -- STYLO
  ('shop-29', 2, 10),  -- TOTE BAG
  ('shop-29', 3, 3),  -- TROUSSE VOYAGE
  ('shop-29', 4, 3),  -- CHARGEUR
  ('shop-29', 5, 5),  -- BAUME À LÈVRES
  ('shop-29', 6, 3),  -- PORTE CARTE
  ('shop-29', 7, 4),  -- SPRAY
  ('shop-29', 8, 2),  -- HAUT PARLEUR
  ('shop-29', 9, 5),  -- CHAINETTES
  ('shop-29', 10, 2),  -- MASQUE
  ('shop-29', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-30
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-30', 1, 5),  -- STYLO
  ('shop-30', 2, 10),  -- TOTE BAG
  ('shop-30', 3, 3),  -- TROUSSE VOYAGE
  ('shop-30', 4, 3),  -- CHARGEUR
  ('shop-30', 5, 5),  -- BAUME À LÈVRES
  ('shop-30', 6, 3),  -- PORTE CARTE
  ('shop-30', 7, 4),  -- SPRAY
  ('shop-30', 8, 2),  -- HAUT PARLEUR
  ('shop-30', 9, 5),  -- CHAINETTES
  ('shop-30', 10, 2),  -- MASQUE
  ('shop-30', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-31
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-31', 1, 5),  -- STYLO
  ('shop-31', 2, 10),  -- TOTE BAG
  ('shop-31', 3, 3),  -- TROUSSE VOYAGE
  ('shop-31', 4, 3),  -- CHARGEUR
  ('shop-31', 5, 5),  -- BAUME À LÈVRES
  ('shop-31', 6, 3),  -- PORTE CARTE
  ('shop-31', 7, 4),  -- SPRAY
  ('shop-31', 8, 2),  -- HAUT PARLEUR
  ('shop-31', 9, 5),  -- CHAINETTES
  ('shop-31', 10, 2),  -- MASQUE
  ('shop-31', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-32
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-32', 1, 5),  -- STYLO
  ('shop-32', 2, 10),  -- TOTE BAG
  ('shop-32', 3, 3),  -- TROUSSE VOYAGE
  ('shop-32', 4, 3),  -- CHARGEUR
  ('shop-32', 5, 5),  -- BAUME À LÈVRES
  ('shop-32', 6, 3),  -- PORTE CARTE
  ('shop-32', 7, 4),  -- SPRAY
  ('shop-32', 8, 2),  -- HAUT PARLEUR
  ('shop-32', 9, 5),  -- CHAINETTES
  ('shop-32', 10, 2),  -- MASQUE
  ('shop-32', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-33
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-33', 1, 5),  -- STYLO
  ('shop-33', 2, 10),  -- TOTE BAG
  ('shop-33', 3, 3),  -- TROUSSE VOYAGE
  ('shop-33', 4, 3),  -- CHARGEUR
  ('shop-33', 5, 5),  -- BAUME À LÈVRES
  ('shop-33', 6, 3),  -- PORTE CARTE
  ('shop-33', 7, 4),  -- SPRAY
  ('shop-33', 8, 2),  -- HAUT PARLEUR
  ('shop-33', 9, 5),  -- CHAINETTES
  ('shop-33', 10, 2),  -- MASQUE
  ('shop-33', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-34
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-34', 1, 5),  -- STYLO
  ('shop-34', 2, 10),  -- TOTE BAG
  ('shop-34', 3, 3),  -- TROUSSE VOYAGE
  ('shop-34', 4, 3),  -- CHARGEUR
  ('shop-34', 5, 5),  -- BAUME À LÈVRES
  ('shop-34', 6, 3),  -- PORTE CARTE
  ('shop-34', 7, 4),  -- SPRAY
  ('shop-34', 8, 2),  -- HAUT PARLEUR
  ('shop-34', 9, 5),  -- CHAINETTES
  ('shop-34', 10, 2),  -- MASQUE
  ('shop-34', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-35
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-35', 1, 5),  -- STYLO
  ('shop-35', 2, 10),  -- TOTE BAG
  ('shop-35', 3, 3),  -- TROUSSE VOYAGE
  ('shop-35', 4, 3),  -- CHARGEUR
  ('shop-35', 5, 5),  -- BAUME À LÈVRES
  ('shop-35', 6, 3),  -- PORTE CARTE
  ('shop-35', 7, 4),  -- SPRAY
  ('shop-35', 8, 2),  -- HAUT PARLEUR
  ('shop-35', 9, 5),  -- CHAINETTES
  ('shop-35', 10, 2),  -- MASQUE
  ('shop-35', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-36
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-36', 1, 5),  -- STYLO
  ('shop-36', 2, 10),  -- TOTE BAG
  ('shop-36', 3, 3),  -- TROUSSE VOYAGE
  ('shop-36', 4, 3),  -- CHARGEUR
  ('shop-36', 5, 5),  -- BAUME À LÈVRES
  ('shop-36', 6, 3),  -- PORTE CARTE
  ('shop-36', 7, 4),  -- SPRAY
  ('shop-36', 8, 2),  -- HAUT PARLEUR
  ('shop-36', 9, 5),  -- CHAINETTES
  ('shop-36', 10, 2),  -- MASQUE
  ('shop-36', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-37
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-37', 1, 5),  -- STYLO
  ('shop-37', 2, 10),  -- TOTE BAG
  ('shop-37', 3, 3),  -- TROUSSE VOYAGE
  ('shop-37', 4, 3),  -- CHARGEUR
  ('shop-37', 5, 5),  -- BAUME À LÈVRES
  ('shop-37', 6, 3),  -- PORTE CARTE
  ('shop-37', 7, 4),  -- SPRAY
  ('shop-37', 8, 2),  -- HAUT PARLEUR
  ('shop-37', 9, 5),  -- CHAINETTES
  ('shop-37', 10, 2),  -- MASQUE
  ('shop-37', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-38
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-38', 1, 5),  -- STYLO
  ('shop-38', 2, 10),  -- TOTE BAG
  ('shop-38', 3, 3),  -- TROUSSE VOYAGE
  ('shop-38', 4, 3),  -- CHARGEUR
  ('shop-38', 5, 5),  -- BAUME À LÈVRES
  ('shop-38', 6, 3),  -- PORTE CARTE
  ('shop-38', 7, 4),  -- SPRAY
  ('shop-38', 8, 2),  -- HAUT PARLEUR
  ('shop-38', 9, 5),  -- CHAINETTES
  ('shop-38', 10, 2),  -- MASQUE
  ('shop-38', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-39
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-39', 1, 5),  -- STYLO
  ('shop-39', 2, 10),  -- TOTE BAG
  ('shop-39', 3, 3),  -- TROUSSE VOYAGE
  ('shop-39', 4, 3),  -- CHARGEUR
  ('shop-39', 5, 5),  -- BAUME À LÈVRES
  ('shop-39', 6, 3),  -- PORTE CARTE
  ('shop-39', 7, 4),  -- SPRAY
  ('shop-39', 8, 2),  -- HAUT PARLEUR
  ('shop-39', 9, 5),  -- CHAINETTES
  ('shop-39', 10, 2),  -- MASQUE
  ('shop-39', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-40
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-40', 1, 5),  -- STYLO
  ('shop-40', 2, 10),  -- TOTE BAG
  ('shop-40', 3, 3),  -- TROUSSE VOYAGE
  ('shop-40', 4, 3),  -- CHARGEUR
  ('shop-40', 5, 5),  -- BAUME À LÈVRES
  ('shop-40', 6, 3),  -- PORTE CARTE
  ('shop-40', 7, 4),  -- SPRAY
  ('shop-40', 8, 2),  -- HAUT PARLEUR
  ('shop-40', 9, 5),  -- CHAINETTES
  ('shop-40', 10, 2),  -- MASQUE
  ('shop-40', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-41
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-41', 1, 5),  -- STYLO
  ('shop-41', 2, 10),  -- TOTE BAG
  ('shop-41', 3, 3),  -- TROUSSE VOYAGE
  ('shop-41', 4, 3),  -- CHARGEUR
  ('shop-41', 5, 5),  -- BAUME À LÈVRES
  ('shop-41', 6, 3),  -- PORTE CARTE
  ('shop-41', 7, 4),  -- SPRAY
  ('shop-41', 8, 2),  -- HAUT PARLEUR
  ('shop-41', 9, 5),  -- CHAINETTES
  ('shop-41', 10, 2),  -- MASQUE
  ('shop-41', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-42
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-42', 1, 5),  -- STYLO
  ('shop-42', 2, 10),  -- TOTE BAG
  ('shop-42', 3, 3),  -- TROUSSE VOYAGE
  ('shop-42', 4, 3),  -- CHARGEUR
  ('shop-42', 5, 5),  -- BAUME À LÈVRES
  ('shop-42', 6, 3),  -- PORTE CARTE
  ('shop-42', 7, 4),  -- SPRAY
  ('shop-42', 8, 2),  -- HAUT PARLEUR
  ('shop-42', 9, 5),  -- CHAINETTES
  ('shop-42', 10, 2),  -- MASQUE
  ('shop-42', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-43
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-43', 1, 5),  -- STYLO
  ('shop-43', 2, 10),  -- TOTE BAG
  ('shop-43', 3, 3),  -- TROUSSE VOYAGE
  ('shop-43', 4, 3),  -- CHARGEUR
  ('shop-43', 5, 5),  -- BAUME À LÈVRES
  ('shop-43', 6, 3),  -- PORTE CARTE
  ('shop-43', 7, 4),  -- SPRAY
  ('shop-43', 8, 2),  -- HAUT PARLEUR
  ('shop-43', 9, 5),  -- CHAINETTES
  ('shop-43', 10, 2),  -- MASQUE
  ('shop-43', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-44
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-44', 1, 5),  -- STYLO
  ('shop-44', 2, 10),  -- TOTE BAG
  ('shop-44', 3, 3),  -- TROUSSE VOYAGE
  ('shop-44', 4, 3),  -- CHARGEUR
  ('shop-44', 5, 5),  -- BAUME À LÈVRES
  ('shop-44', 6, 3),  -- PORTE CARTE
  ('shop-44', 7, 4),  -- SPRAY
  ('shop-44', 8, 2),  -- HAUT PARLEUR
  ('shop-44', 9, 5),  -- CHAINETTES
  ('shop-44', 10, 2),  -- MASQUE
  ('shop-44', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-45
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-45', 1, 5),  -- STYLO
  ('shop-45', 2, 10),  -- TOTE BAG
  ('shop-45', 3, 3),  -- TROUSSE VOYAGE
  ('shop-45', 4, 3),  -- CHARGEUR
  ('shop-45', 5, 5),  -- BAUME À LÈVRES
  ('shop-45', 6, 3),  -- PORTE CARTE
  ('shop-45', 7, 4),  -- SPRAY
  ('shop-45', 8, 2),  -- HAUT PARLEUR
  ('shop-45', 9, 5),  -- CHAINETTES
  ('shop-45', 10, 2),  -- MASQUE
  ('shop-45', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-46
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-46', 1, 5),  -- STYLO
  ('shop-46', 2, 10),  -- TOTE BAG
  ('shop-46', 3, 3),  -- TROUSSE VOYAGE
  ('shop-46', 4, 3),  -- CHARGEUR
  ('shop-46', 5, 5),  -- BAUME À LÈVRES
  ('shop-46', 6, 3),  -- PORTE CARTE
  ('shop-46', 7, 4),  -- SPRAY
  ('shop-46', 8, 2),  -- HAUT PARLEUR
  ('shop-46', 9, 5),  -- CHAINETTES
  ('shop-46', 10, 2),  -- MASQUE
  ('shop-46', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-47
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-47', 1, 5),  -- STYLO
  ('shop-47', 2, 10),  -- TOTE BAG
  ('shop-47', 3, 3),  -- TROUSSE VOYAGE
  ('shop-47', 4, 3),  -- CHARGEUR
  ('shop-47', 5, 5),  -- BAUME À LÈVRES
  ('shop-47', 6, 3),  -- PORTE CARTE
  ('shop-47', 7, 4),  -- SPRAY
  ('shop-47', 8, 2),  -- HAUT PARLEUR
  ('shop-47', 9, 5),  -- CHAINETTES
  ('shop-47', 10, 2),  -- MASQUE
  ('shop-47', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-48
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-48', 1, 5),  -- STYLO
  ('shop-48', 2, 10),  -- TOTE BAG
  ('shop-48', 3, 3),  -- TROUSSE VOYAGE
  ('shop-48', 4, 3),  -- CHARGEUR
  ('shop-48', 5, 5),  -- BAUME À LÈVRES
  ('shop-48', 6, 3),  -- PORTE CARTE
  ('shop-48', 7, 4),  -- SPRAY
  ('shop-48', 8, 2),  -- HAUT PARLEUR
  ('shop-48', 9, 5),  -- CHAINETTES
  ('shop-48', 10, 2),  -- MASQUE
  ('shop-48', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-49
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-49', 1, 5),  -- STYLO
  ('shop-49', 2, 10),  -- TOTE BAG
  ('shop-49', 3, 3),  -- TROUSSE VOYAGE
  ('shop-49', 4, 3),  -- CHARGEUR
  ('shop-49', 5, 5),  -- BAUME À LÈVRES
  ('shop-49', 6, 3),  -- PORTE CARTE
  ('shop-49', 7, 4),  -- SPRAY
  ('shop-49', 8, 2),  -- HAUT PARLEUR
  ('shop-49', 9, 5),  -- CHAINETTES
  ('shop-49', 10, 2),  -- MASQUE
  ('shop-49', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-50
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-50', 1, 5),  -- STYLO
  ('shop-50', 2, 10),  -- TOTE BAG
  ('shop-50', 3, 3),  -- TROUSSE VOYAGE
  ('shop-50', 4, 3),  -- CHARGEUR
  ('shop-50', 5, 5),  -- BAUME À LÈVRES
  ('shop-50', 6, 3),  -- PORTE CARTE
  ('shop-50', 7, 4),  -- SPRAY
  ('shop-50', 8, 2),  -- HAUT PARLEUR
  ('shop-50', 9, 5),  -- CHAINETTES
  ('shop-50', 10, 2),  -- MASQUE
  ('shop-50', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-51
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-51', 1, 5),  -- STYLO
  ('shop-51', 2, 10),  -- TOTE BAG
  ('shop-51', 3, 3),  -- TROUSSE VOYAGE
  ('shop-51', 4, 3),  -- CHARGEUR
  ('shop-51', 5, 5),  -- BAUME À LÈVRES
  ('shop-51', 6, 3),  -- PORTE CARTE
  ('shop-51', 7, 4),  -- SPRAY
  ('shop-51', 8, 2),  -- HAUT PARLEUR
  ('shop-51', 9, 5),  -- CHAINETTES
  ('shop-51', 10, 2),  -- MASQUE
  ('shop-51', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-52
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-52', 1, 5),  -- STYLO
  ('shop-52', 2, 10),  -- TOTE BAG
  ('shop-52', 3, 3),  -- TROUSSE VOYAGE
  ('shop-52', 4, 3),  -- CHARGEUR
  ('shop-52', 5, 5),  -- BAUME À LÈVRES
  ('shop-52', 6, 3),  -- PORTE CARTE
  ('shop-52', 7, 4),  -- SPRAY
  ('shop-52', 8, 2),  -- HAUT PARLEUR
  ('shop-52', 9, 5),  -- CHAINETTES
  ('shop-52', 10, 2),  -- MASQUE
  ('shop-52', 11, 5);  -- ETUIS SOUPLE
-- Stock pour shop-53
INSERT INTO public.shop_stock(shop_id, segment_id, remaining) VALUES
  ('shop-53', 1, 5),  -- STYLO
  ('shop-53', 2, 10),  -- TOTE BAG
  ('shop-53', 3, 3),  -- TROUSSE VOYAGE
  ('shop-53', 4, 3),  -- CHARGEUR
  ('shop-53', 5, 5),  -- BAUME À LÈVRES
  ('shop-53', 6, 3),  -- PORTE CARTE
  ('shop-53', 7, 4),  -- SPRAY
  ('shop-53', 8, 2),  -- HAUT PARLEUR
  ('shop-53', 9, 5),  -- CHAINETTES
  ('shop-53', 10, 2),  -- MASQUE
  ('shop-53', 11, 5);  -- ETUIS SOUPLE
