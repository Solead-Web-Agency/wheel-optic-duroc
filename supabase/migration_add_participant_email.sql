-- Migration pour ajouter la protection anti-abus
-- Ajoute participant_email à la table wins pour tracker les gains par participant

-- 1. Ajouter la colonne participant_email (nullable pour ne pas casser l'existant)
ALTER TABLE public.wins 
ADD COLUMN IF NOT EXISTS participant_email text REFERENCES public.participants(email) ON DELETE SET NULL;

-- 2. Créer une fonction RPC pour vérifier si un participant a déjà gagné il y a moins d'1 heure
-- Blocage uniquement par nom ET prénom (le blocage par email est déjà géré par la contrainte d'unicité sur participants.email)
CREATE OR REPLACE FUNCTION public.check_recent_win(
  p_email text,
  p_first_name text,
  p_last_name text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  recent_win_count int;
BEGIN
  -- Vérification uniquement par nom ET prénom (même nom + même prénom = même personne)
  -- Le blocage par email est déjà géré lors de l'inscription dans participants (contrainte d'unicité)
  -- On joint wins avec participants pour récupérer les noms/prénoms
  SELECT COUNT(*) INTO recent_win_count
  FROM public.wins w
  INNER JOIN public.participants p ON w.participant_email = p.email
  WHERE LOWER(TRIM(p.first_name)) = LOWER(TRIM(p_first_name))
    AND LOWER(TRIM(p.last_name)) = LOWER(TRIM(p_last_name))
    AND w.created_at > NOW() - INTERVAL '1 hour';
  
  -- Retourne true si un gain récent existe (blocage), false sinon (autorisation)
  RETURN recent_win_count > 0;
END;
$$;

-- 3. Modifier la fonction decrement_stock pour accepter et enregistrer l'email du participant
CREATE OR REPLACE FUNCTION public.decrement_stock(
  p_shop text, 
  p_segment int,
  p_participant_email text DEFAULT NULL
)
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
  INSERT INTO public.wins(shop_id, segment_id, participant_email) 
  VALUES (p_shop, p_segment, p_participant_email);
  RETURN new_remaining;
END;
$$;

-- 4. Permettre à anon d'exécuter la nouvelle fonction check_recent_win
GRANT EXECUTE ON FUNCTION public.check_recent_win(text, text, text) TO anon;

-- 5. Mettre à jour les permissions pour la fonction decrement_stock modifiée
GRANT EXECUTE ON FUNCTION public.decrement_stock(text, int, text) TO anon;

