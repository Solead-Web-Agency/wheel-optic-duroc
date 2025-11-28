import { useState, useEffect, useRef, useMemo } from 'react'
import './index.css'

// Types minimaux
interface WheelSegment {
  id: number;
  title: string;
  color: string;
  textColor: string;
}

type Festival = 'francofolies' | 'goldencoast';

type WinsMap = { [id: number]: number };

type StockMap = { [id: number]: number };

// Config couleurs + segments (sans stocks ni images)
// Palette de couleurs pour 12 segments
const segmentColors = [
  '#ff503b', // Rouge
  '#ffac44', // Orange
  '#42adce', // Bleu
  '#9b59b6', // Violet
  '#2ecc71', // Vert
  '#f39c12', // Jaune-orange
  '#e74c3c', // Rouge foncé
  '#3498db', // Bleu clair
  '#1abc9c', // Turquoise
  '#95a5a6', // Gris
  '#e67e22', // Orange foncé
  '#16a085', // Vert émeraude
];

const festivalConfigs = {
  francofolies: {
    colors: {
      primary: '#ff503b',
      secondary: '#ffac44',
      accent: '#42adce',
    },
    segments: [
      { id: 1, title: 'STYLO', color: segmentColors[0], textColor: '#FFFFFF' },
      { id: 2, title: 'TOTE BAG', color: segmentColors[1], textColor: '#FFFFFF' },
      { id: 3, title: 'TROUSSE VOYAGE', color: segmentColors[2], textColor: '#FFFFFF' },
      { id: 4, title: 'CHARGEUR', color: segmentColors[3], textColor: '#FFFFFF' },
      { id: 5, title: 'BAUME À LÈVRES', color: segmentColors[4], textColor: '#FFFFFF' },
      { id: 6, title: 'PORTE CARTE', color: segmentColors[5], textColor: '#FFFFFF' },
      { id: 7, title: 'SPRAY', color: segmentColors[6], textColor: '#FFFFFF' },
      { id: 8, title: 'HAUT PARLEUR', color: segmentColors[7], textColor: '#FFFFFF' },
      { id: 9, title: '10% DE RÉDUCTION', color: segmentColors[8], textColor: '#FFFFFF' },
      { id: 10, title: 'RIEN', color: segmentColors[9], textColor: '#FFFFFF' },
      { id: 11, title: 'CARTE DE JEU', color: segmentColors[10], textColor: '#FFFFFF' },
      { id: 12, title: 'CHAINES A LUNETTES', color: segmentColors[11], textColor: '#FFFFFF' },
    ],
  },
  goldencoast: {
    colors: {
      primary: '#ff503b',
      secondary: '#ffac44',
      accent: '#42adce',
    },
    segments: [
      { id: 1, title: 'STYLO', color: segmentColors[0], textColor: '#FFFFFF' },
      { id: 2, title: 'TOTE BAG', color: segmentColors[1], textColor: '#FFFFFF' },
      { id: 3, title: 'TROUSSE VOYAGE', color: segmentColors[2], textColor: '#FFFFFF' },
      { id: 4, title: 'CHARGEUR', color: segmentColors[3], textColor: '#FFFFFF' },
      { id: 5, title: 'BAUME À LÈVRES', color: segmentColors[4], textColor: '#FFFFFF' },
      { id: 6, title: 'PORTE CARTE', color: segmentColors[5], textColor: '#FFFFFF' },
      { id: 7, title: 'SPRAY', color: segmentColors[6], textColor: '#FFFFFF' },
      { id: 8, title: 'HAUT PARLEUR', color: segmentColors[7], textColor: '#FFFFFF' },
      { id: 9, title: '10% DE RÉDUCTION', color: segmentColors[8], textColor: '#FFFFFF' },
      { id: 10, title: 'RIEN', color: segmentColors[9], textColor: '#FFFFFF' },
      { id: 11, title: 'CARTE DE JEU', color: segmentColors[10], textColor: '#FFFFFF' },
      { id: 12, title: 'CHAINES A LUNETTES', color: segmentColors[11], textColor: '#FFFFFF' },
    ],
  },
};

const DEFAULT_STOCK: StockMap = { 1: 1500, 2: 350, 3: 300 };

// Roue canvas (texte en long comme sur l'exemple)
function SegmentedWheel({ segments, rotationAngle, festival }: {
  segments: WheelSegment[];
  rotationAngle: number;
  festival: Festival;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const config = festivalConfigs[festival];

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const size = 400;
    canvas.width = size;
    canvas.height = size;
    canvas.style.width = `${size}px`;
    canvas.style.height = `${size}px`;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const centerX = canvas.width / 2;
    const centerY = canvas.height / 2;
    const radius = 180;

    ctx.save();
    ctx.translate(centerX, centerY);
    ctx.rotate((rotationAngle * Math.PI) / 180);
    ctx.translate(-centerX, -centerY);

    const segmentAngle = (2 * Math.PI) / segments.length;

    segments.forEach((segment, index) => {
      const startAngle = -Math.PI / 2 + index * segmentAngle;
      const endAngle = startAngle + segmentAngle;

      // Quartier
      ctx.beginPath();
      ctx.moveTo(centerX, centerY);
      ctx.arc(centerX, centerY, radius, startAngle, endAngle);
      ctx.closePath();
      ctx.fillStyle = segment.color;
      ctx.fill();

      ctx.strokeStyle = '#000';
      ctx.lineWidth = 1;
      ctx.stroke();

      // Texte en long dans le quartier (un seul bloc)
      ctx.save();
      ctx.translate(centerX, centerY);
      ctx.rotate(startAngle + segmentAngle / 2);
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillStyle = segment.textColor;

      // Taille de police auto pour tenir dans la largeur du quartier
      const baseSize = 15;
      let fontSize = baseSize;
      ctx.font = `bold ${fontSize}px Arial`;
      const textRadius = radius * 0.62; // encore un peu plus vers l'intérieur
      const maxWidth = radius * 0.5;   // largeur max plus réduite
      let width = ctx.measureText(segment.title).width;
      if (width > maxWidth) {
        const scale = maxWidth / width;
        fontSize = Math.max(10, Math.floor(baseSize * scale));
        ctx.font = `bold ${fontSize}px Arial`;
      }

      ctx.fillText(segment.title, textRadius, 0);
      ctx.restore();
    });

    ctx.restore();

    // Cercle central
    ctx.beginPath();
    ctx.arc(centerX, centerY, 30, 0, 2 * Math.PI);
    ctx.fillStyle = config.colors.accent;
    ctx.fill();
    ctx.strokeStyle = '#000';
    ctx.lineWidth = 1;
    ctx.stroke();
  }, [segments, rotationAngle, festival]);

  return (
    <div
      style={{
        width: '400px',
        height: '400px',
        margin: 0,
        position: 'relative',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {/* Flèche */}
      <div
        style={{
          position: 'absolute',
          top: '10px',
          left: '50%',
          transform: 'translateX(-50%)',
          width: 0,
          height: 0,
          borderLeft: '20px solid transparent',
          borderRight: '20px solid transparent',
          borderTop: `30px solid ${festivalConfigs[festival].colors.primary}`,
          zIndex: 10,
          filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.5))',
        }}
      />

      <canvas
        ref={canvasRef}
        style={{
          border: `8px solid ${festivalConfigs[festival].colors.accent}`,
          borderRadius: '50%',
          boxShadow: `0 0 30px ${festivalConfigs[festival].colors.accent}60`,
          cursor: 'pointer',
        }}
      />
    </div>
  );
}

export default function App() {
  const [festival] = useState<Festival>('goldencoast');
  const [spinning, setSpinning] = useState(false);
  const [rotationAngle, setRotationAngle] = useState(0);
  const [showWinnerPopup, setShowWinnerPopup] = useState(false);
  const [lastWon, setLastWon] = useState<WheelSegment | null>(null);

  // Étape email (obligatoire avant la boutique)
  const [email, setEmail] = useState<string>(() => {
    const saved = localStorage.getItem('wheel-email');
    return saved || '';
  });
  const [emailError, setEmailError] = useState<string | null>(null);
  const [isCheckingEmail, setIsCheckingEmail] = useState(false);
  const [emailValidated, setEmailValidated] = useState(false);

  // Boutique courante - sélection obligatoire pour tous les joueurs
  const [shopId, setShopId] = useState<string>(() => {
    // Pré-remplit avec la boutique sauvegardée si elle existe, mais le modal reste visible
    const saved = localStorage.getItem('wheel-current-shop');
    const urlParam = new URLSearchParams(window.location.search).get('shopId');
    if (urlParam && urlParam.startsWith('shop-')) {
      return urlParam;
    } else if (saved && saved.startsWith('shop-')) {
      return saved;
    }
    return 'shop-1'; // Valeur par défaut pour le select
  });
  const [showShopSelection, setShowShopSelection] = useState<boolean>(false);
  
  // Ne ferme le modal que quand l'utilisateur valide explicitement
  const handleShopValidation = () => {
    if (shopId && shopId.startsWith('shop-')) {
      localStorage.setItem('wheel-current-shop', shopId);
      const params = new URLSearchParams(window.location.search);
      params.set('shopId', shopId);
      const newUrl = `${window.location.pathname}?${params.toString()}`;
      window.history.replaceState(null, '', newUrl);
      setShowShopSelection(false);
    }
  };

  // Validation d'email côté Supabase (1 participation par email)
  const handleEmailValidation = async () => {
    setEmailError(null);
    const trimmed = email.trim();
    if (!trimmed) {
      setEmailError('Merci de renseigner un email.');
      return;
    }
    // Validation basique du format
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(trimmed)) {
      setEmailError('Format d’email invalide.');
      return;
    }

    const SUPA_URL = (import.meta as any).env.VITE_SUPABASE_URL || (import.meta as any).env.NEXT_PUBLIC_SUPABASE_URL;
    const SUPA_ANON = (import.meta as any).env.VITE_SUPABASE_ANON_KEY || (import.meta as any).env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!SUPA_URL || !SUPA_ANON) {
      setEmailError('Configuration Supabase manquante.');
      return;
    }

    try {
      setIsCheckingEmail(true);
      const resp = await fetch(`${SUPA_URL}/rest/v1/participants`, {
        method: 'POST',
        headers: {
          apikey: SUPA_ANON,
          Authorization: `Bearer ${SUPA_ANON}`,
          'Content-Type': 'application/json',
          Accept: 'application/json',
          Prefer: 'return=minimal',
        },
        body: JSON.stringify({ email: trimmed }),
      });

      if (resp.status === 409) {
        // Contrainte d'unicité violée -> email déjà utilisé
        setEmailError('Cet email a déjà participé à la roue.');
        setEmailValidated(false);
        return;
      }

      if (!resp.ok) {
        const txt = await resp.text();
        console.error('Erreur API participants:', resp.status, txt);
        setEmailError('Impossible de valider cet email pour le moment.');
        setEmailValidated(false);
        return;
      }

      // OK
      localStorage.setItem('wheel-email', trimmed);
      setEmailValidated(true);
      setShowShopSelection(true);
    } catch (e) {
      console.error('Erreur réseau participants:', e);
      setEmailError('Erreur réseau, merci de réessayer.');
      setEmailValidated(false);
    } finally {
      setIsCheckingEmail(false);
    }
  };

  // Comptage des gains par lot (persisté toutes boutiques confondues)
  const [winsById, setWinsById] = useState<WinsMap>({});
  useEffect(() => {
    const saved = localStorage.getItem('wheel-wins');
    if (saved) setWinsById(JSON.parse(saved));
  }, []);
  const persistWins = (wins: WinsMap) => {
    localStorage.setItem('wheel-wins', JSON.stringify(wins));
  };

  // Stock par boutique (via API, sans fallback local)
  const [stockById, setStockById] = useState<StockMap>({});
  useEffect(() => {
    let cancelled = false;
    (async () => {
      const SUPA_URL = (import.meta as any).env.VITE_SUPABASE_URL || (import.meta as any).env.NEXT_PUBLIC_SUPABASE_URL;
      const SUPA_ANON = (import.meta as any).env.VITE_SUPABASE_ANON_KEY || (import.meta as any).env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
      try {
        if (!SUPA_URL || !SUPA_ANON) throw new Error('missing supabase env');
        const url = new URL(`${SUPA_URL}/rest/v1/shop_stock`);
        url.searchParams.set('shop_id', `eq.${shopId}`);
        url.searchParams.set('select', 'segment_id,remaining');
        const r = await fetch(url.toString(), {
          headers: { apikey: SUPA_ANON, Authorization: `Bearer ${SUPA_ANON}`, Accept: 'application/json' },
        });
        if (!r.ok) throw new Error('stock api');
        const rows: Array<{ segment_id: number; remaining: number }> = await r.json();
        const next: StockMap = {};
        rows.forEach((s) => { next[s.segment_id] = s.remaining; });
        if (!cancelled) setStockById(next);
      } catch {
        // pas de fallback local
        setStockById({});
      }
    })();
    return () => { cancelled = true; };
  }, [shopId]);
  const persistStock = (_stock: StockMap) => {};

  // Admin (toggle caché 4 clics coin haut droit)
  const [showAdminInterface, setShowAdminInterface] = useState(false);
  const [clickCount, setClickCount] = useState(0);
  const clickTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const handleCornerClick = () => {
    const newCount = clickCount + 1;
    setClickCount(newCount);
    if (clickTimeoutRef.current) clearTimeout(clickTimeoutRef.current);
    clickTimeoutRef.current = setTimeout(() => setClickCount(0), 2000);
    if (newCount >= 4) {
      setShowAdminInterface(!showAdminInterface);
      setClickCount(0);
      if (clickTimeoutRef.current) clearTimeout(clickTimeoutRef.current);
    }
  };

  const resetWheel = () => {
    setRotationAngle(0);
    setSpinning(false);
  };

  const resetWins = () => {
    setWinsById({});
    persistWins({});
  };

  const resetStock = () => {
    setStockById(DEFAULT_STOCK);
    persistStock(DEFAULT_STOCK);
  };

  const baseSegments = festivalConfigs[festival].segments;
  const availableSegments: WheelSegment[] = useMemo(() => {
    return baseSegments.filter((s) => (stockById[s.id] ?? 0) > 0);
  }, [baseSegments, stockById]);

  const spinWheel = () => {
    if (spinning || !shopId || showShopSelection || !emailValidated) return;
    setSpinning(true);

    const segments = availableSegments;
    if (segments.length === 0) {
      setSpinning(false);
      return;
    }

    const selectedIndex = Math.floor(Math.random() * segments.length);
    const selectedSegment = segments[selectedIndex];
    const selectedId = selectedSegment.id;

    const calculerAngleCible = (): number => {
      const nombreSegments = segments.length;
      const segmentAngles: number[] = [];
      if (nombreSegments === 3) segmentAngles.push(120, 120, 120);
      else if (nombreSegments === 2) segmentAngles.push(180, 180);
      else if (nombreSegments === 1) segmentAngles.push(360);
      else {
        const angleParSegment = 360 / nombreSegments;
        for (let i = 0; i < nombreSegments; i++) segmentAngles.push(angleParSegment);
      }

      let currentAngle = -90;
      for (let i = 0; i < selectedIndex; i++) currentAngle += segmentAngles[i];
      return currentAngle + segmentAngles[selectedIndex] / 2;
    };

    const targetAngleForFlèche = calculerAngleCible();
    const flechePosition = -90;
    const rotationNeeded = -(targetAngleForFlèche - flechePosition);
    const totalRotation = 360 * 3 + rotationNeeded; // 3 tours + stop

    let startTime: number;
    const animate = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / 3000, 1);
      const easeOut = (t: number) => 1 - Math.pow(1 - t, 3);
      const currentRotation = easeOut(progress) * totalRotation;
      setRotationAngle(currentRotation);

      if (progress < 1) requestAnimationFrame(animate);
      else setTimeout(() => {
        setSpinning(false);
        // Incrémente le compteur de gains (global)
        setWinsById((prev) => {
          const next = { ...prev, [selectedId]: (prev[selectedId] || 0) + 1 };
          persistWins(next);
          return next;
        });
        // Décrémente en base (Supabase direct)
        (async () => {
          const SUPA_URL = (import.meta as any).env.VITE_SUPABASE_URL || (import.meta as any).env.NEXT_PUBLIC_SUPABASE_URL;
          const SUPA_ANON = (import.meta as any).env.VITE_SUPABASE_ANON_KEY || (import.meta as any).env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
          try {
            if (!SUPA_URL || !SUPA_ANON) throw new Error('missing supabase env');
            const rpcUrl = `${SUPA_URL}/rest/v1/rpc/decrement_stock`;
            const resp = await fetch(rpcUrl, {
              method: 'POST',
              headers: {
                apikey: SUPA_ANON,
                Authorization: `Bearer ${SUPA_ANON}`,
                'Content-Type': 'application/json',
                Accept: 'application/json',
              },
              body: JSON.stringify({ p_shop: shopId, p_segment: selectedId }),
            });
            if (resp.status === 409) {
              setStockById((prev) => ({ ...prev, [selectedId]: 0 }));
            } else if (resp.ok) {
              const contentType = resp.headers.get('content-type') || '';
              const payload = contentType.includes('application/json') ? await resp.json() : await resp.text();
              const remaining = typeof payload === 'number' ? payload : Number((payload as any)?.decrement_stock ?? payload);
              setStockById((prev) => ({ ...prev, [selectedId]: remaining }));
            } else {
              throw new Error('spin api');
            }
          } catch {
            // pas de fallback local
          } finally {
            setLastWon(selectedSegment);
            setShowWinnerPopup(true);
          }
        })();
      }, 300);
    };

    requestAnimationFrame(animate);
  };

  return (
    <div
      className="app-container"
      style={{
        padding: '1rem',
        position: 'relative',
        minHeight: '100vh',
        background: '#000000',
      }}
    >
      {/* Étape 1 : saisie de l'email */}
      {!emailValidated && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0,0,0,0.9)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 2100,
          }}
        >
          <div
            style={{
              background: 'linear-gradient(135deg, #1a1a1a, #2d2d2d)',
              padding: '40px',
              borderRadius: '20px',
              color: '#fff',
              textAlign: 'center',
              maxWidth: '500px',
              margin: '16px',
              boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
              border: '2px solid #FFD700',
            }}
          >
            <h2 style={{ fontSize: '1.8rem', marginBottom: '12px', color: '#FFD700' }}>
              Entrez votre email
            </h2>
            <p style={{ fontSize: '1rem', marginBottom: '20px', color: '#ccc' }}>
              Un seul passage sur la roue par adresse email.
            </p>
            <input
              type="email"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                setEmailError(null);
              }}
              placeholder="vous@example.com"
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: emailError ? '2px solid #ef4444' : '1px solid #444',
                background: '#111',
                color: '#fff',
                marginBottom: '12px',
              }}
            />
            {emailError && (
              <div style={{ color: '#fca5a5', fontSize: '0.9rem', marginBottom: '12px' }}>
                {emailError}
              </div>
            )}
            <button
              onClick={handleEmailValidation}
              disabled={isCheckingEmail}
              style={{
                background: 'linear-gradient(135deg, #FFD700 0%, #FFA500 50%, #FF6B35 100%)',
                color: 'white',
                border: 'none',
                padding: '12px 28px',
                borderRadius: '50px',
                fontSize: '1.1rem',
                fontWeight: 'bold',
                cursor: isCheckingEmail ? 'wait' : 'pointer',
                boxShadow: '0 8px 25px rgba(0, 0, 0, 0.3), 0 0 20px rgba(255, 215, 0, 0.5)',
                transition: 'all 0.3s ease',
                textShadow: '1px 1px 3px rgba(0,0,0,0.5)',
                minWidth: '180px',
                opacity: isCheckingEmail ? 0.7 : 1,
              }}
            >
              {isCheckingEmail ? 'Vérification…' : 'Valider mon email'}
            </button>
          </div>
        </div>
      )}

      {/* Étape 2 : sélection de boutique */}
      {emailValidated && showShopSelection && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0,0,0,0.9)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 2000,
          }}
        >
          <div
            style={{
              background: 'linear-gradient(135deg, #1a1a1a, #2d2d2d)',
              padding: '40px',
              borderRadius: '20px',
              color: '#fff',
              textAlign: 'center',
              maxWidth: '500px',
              margin: '16px',
              boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
              border: '2px solid #FFD700',
            }}
          >
            <div style={{ fontSize: '48px', marginBottom: '20px' }}>Boutique</div>
            <h2 style={{ fontSize: '1.8rem', marginBottom: '12px', color: '#FFD700' }}>
              Sélectionnez votre boutique
            </h2>
            <p style={{ fontSize: '1rem', marginBottom: '24px', color: '#ccc' }}>
              Choisissez la boutique sur laquelle vous participez
            </p>
            <select
              value={shopId}
              onChange={(e) => setShopId(e.target.value)}
              style={{
                width: '100%',
                background: '#111',
                color: '#fff',
                border: '2px solid #FFD700',
                padding: '12px 16px',
                borderRadius: '10px',
                fontSize: '1.1rem',
                marginBottom: '24px',
                cursor: 'pointer',
                fontWeight: 'bold',
              }}
            >
              {Array.from({ length: 55 }, (_, i) => {
                const id = `shop-${i + 1}`;
                return (
                  <option key={id} value={id}>
                    Boutique {i + 1}
                  </option>
                );
              })}
            </select>
            <button
              onClick={handleShopValidation}
              disabled={!shopId}
              style={{
                background: shopId
                  ? 'linear-gradient(135deg, #FFD700 0%, #FFA500 50%, #FF6B35 100%)'
                  : '#555',
                color: 'white',
                border: 'none',
                padding: '14px 32px',
                borderRadius: '50px',
                fontSize: '1.1rem',
                fontWeight: 'bold',
                cursor: shopId ? 'pointer' : 'not-allowed',
                boxShadow: shopId
                  ? '0 8px 25px rgba(0, 0, 0, 0.3), 0 0 20px rgba(255, 215, 0, 0.5)'
                  : 'none',
                transition: 'all 0.3s ease',
                textShadow: '1px 1px 3px rgba(0, 0, 0, 0.5)',
                minWidth: '180px',
                opacity: shopId ? 1 : 0.6,
              }}
              onMouseOver={(e) => {
                if (shopId) {
                  e.currentTarget.style.transform = 'scale(1.05)';
                  e.currentTarget.style.boxShadow =
                    '0 12px 35px rgba(0, 0, 0, 0.4), 0 0 30px rgba(255, 215, 0, 0.8)';
                }
              }}
              onMouseOut={(e) => {
                if (shopId) {
                  e.currentTarget.style.transform = 'scale(1)';
                  e.currentTarget.style.boxShadow =
                    '0 8px 25px rgba(0, 0, 0, 0.3), 0 0 20px rgba(255, 215, 0, 0.5)';
                }
              }}
            >
              Valider
            </button>
          </div>
        </div>
      )}

      {/* Zone cliquable invisible pour activer le mode admin */}
      <div
        onClick={handleCornerClick}
        style={{
          position: 'absolute',
          top: 0,
          right: 0,
          width: '60px',
          height: '60px',
          cursor: 'pointer',
          zIndex: 1000,
          background: clickCount > 0 ? `rgba(255, 255, 255, ${clickCount * 0.1})` : 'transparent',
          borderRadius: '0 0 0 50px',
        }}
        title={`${clickCount}/4 clics pour ${showAdminInterface ? 'masquer' : 'activer'} le mode admin`}
      />

      <div className="wheel-container" style={{ position: 'absolute', top: '20px', left: '20px' }}>
        {/* Bouton pour changer de boutique (visible pour tous) */}
        {emailValidated && !showShopSelection && shopId && (
          <button
            onClick={() => setShowShopSelection(true)}
            style={{
              display: 'block',
              marginBottom: '10px',
              background: 'linear-gradient(135deg, #3b82f6, #2563eb)',
              color: '#fff',
              border: 'none',
              padding: '10px 16px',
              borderRadius: '25px',
              cursor: 'pointer',
              fontWeight: 'bold',
              fontSize: '0.9rem',
              boxShadow: '0 4px 15px rgba(0, 0, 0, 0.3)',
              transition: 'all 0.3s ease',
            }}
            onMouseOver={(e) => {
              e.currentTarget.style.transform = 'scale(1.05)';
              e.currentTarget.style.boxShadow = '0 6px 20px rgba(0, 0, 0, 0.4)';
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.transform = 'scale(1)';
              e.currentTarget.style.boxShadow = '0 4px 15px rgba(0, 0, 0, 0.3)';
            }}
          >
            {shopId.replace('shop-', 'Boutique ')}
          </button>
        )}
        <div
          style={{
            position: 'relative',
            filter: !spinning || showShopSelection ? 'brightness(0.5)' : 'brightness(0.9)',
            transition: 'filter 0.3s ease',
            pointerEvents: showShopSelection ? 'none' : 'auto',
          }}
        >
          <SegmentedWheel
            segments={availableSegments}
            rotationAngle={rotationAngle}
            festival={festival}
          />
        </div>

        {!spinning && (
          <button
            onClick={spinWheel}
            disabled={!shopId || showShopSelection || !emailValidated}
            className="spin-button"
            style={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              fontSize: '1.1rem',
              padding: '15px 25px',
              background: !shopId || showShopSelection || !emailValidated
                ? 'linear-gradient(135deg, #555 0%, #333 50%, #222 100%)'
                : 'linear-gradient(135deg, #FFD700 0%, #FFA500 50%, #FF6B35 100%)',
              color: 'white',
              border: 'none',
              borderRadius: '50px',
              fontWeight: 'bold',
              cursor: !shopId || showShopSelection || !emailValidated ? 'not-allowed' : 'pointer',
              boxShadow: !shopId || showShopSelection || !emailValidated
                ? 'none'
                : '0 8px 25px rgba(0, 0, 0, 0.3), 0 0 20px rgba(255, 215, 0, 0.5)',
              zIndex: 10,
              transition: 'all 0.3s ease',
              textShadow: '1px 1px 3px rgba(0, 0, 0, 0.5)',
              minWidth: '180px',
              opacity: !shopId || showShopSelection || !emailValidated ? 0.6 : 1,
            }}
            onMouseOver={(e) => {
              if (shopId && !showShopSelection && emailValidated) {
                e.currentTarget.style.transform =
                  'translate(-50%, -50%) scale(1.1)';
                e.currentTarget.style.boxShadow =
                  '0 12px 35px rgba(0, 0, 0, 0.4), 0 0 30px rgba(255, 215, 0, 0.8)';
              }
            }}
            onMouseOut={(e) => {
              if (shopId && !showShopSelection && emailValidated) {
                e.currentTarget.style.transform = 'translate(-50%, -50%) scale(1)';
                e.currentTarget.style.boxShadow =
                  '0 8px 25px rgba(0, 0, 0, 0.3), 0 0 20px rgba(255, 215, 0, 0.5)';
              }
            }}
          >
            {!emailValidated
              ? 'Entrez votre email'
              : !shopId || showShopSelection
              ? 'Sélectionnez une boutique'
              : 'TENTER SA CHANCE'}
          </button>
        )}

        {spinning && (
          <div
            style={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              background: 'rgba(0, 0, 0, 0.8)',
              color: 'white',
              padding: '15px 25px',
              borderRadius: '25px',
              fontSize: '1.1rem',
              fontWeight: 'bold',
              zIndex: 10,
              textAlign: 'center',
              boxShadow: '0 8px 25px rgba(0, 0, 0, 0.5)',
            }}
          >
            Tirage en cours...
          </div>
        )}
      </div>

      {/* Panneau admin minimal */}
      {showAdminInterface && (
        <div
          style={{
            position: 'fixed',
            bottom: '10px',
            right: '10px',
            background: 'rgba(0,0,0,0.85)',
            color: 'white',
            padding: '12px',
            borderRadius: '10px',
            fontSize: '12px',
            width: '260px',
            zIndex: 1001,
          }}
        >
          <div style={{ fontWeight: 'bold', marginBottom: '8px' }}>Admin</div>
          <div style={{ marginBottom: '10px' }}>
            <label style={{ color: '#ccc', fontSize: '11px', marginRight: '6px' }}>
              Boutique:
            </label>
            <select
              value={shopId}
              onChange={(e) => setShopId(e.target.value)}
              style={{
                background: '#111',
                color: '#fff',
                border: '1px solid #444',
                padding: '6px 8px',
                borderRadius: '6px',
              }}
            >
              {Array.from({ length: 55 }, (_, i) => `shop-${i + 1}`).map((id) => (
                <option key={id} value={id}>
                  {id}
                </option>
              ))}
            </select>
          </div>

          <div style={{ marginBottom: '8px', fontWeight: 'bold' }}>Stock restant</div>
          <div style={{ display: 'grid', gap: '6px' }}>
            {baseSegments.map((s) => (
              <div
                key={s.id}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  opacity: (stockById[s.id] ?? 0) > 0 ? 1 : 0.6,
                }}
              >
                <span>{s.title}</span>
                <span style={{ fontWeight: 'bold' }}>{stockById[s.id] ?? 0}</span>
              </div>
            ))}
          </div>

          <div style={{ marginTop: '10px', fontWeight: 'bold' }}>Gains (global)</div>
          <div style={{ display: 'grid', gap: '6px' }}>
            {baseSegments.map((s) => (
              <div
                key={s.id}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                }}
              >
                <span>{s.title}</span>
                <span style={{ fontWeight: 'bold' }}>{winsById[s.id] || 0}</span>
              </div>
            ))}
          </div>

          <div style={{ display: 'flex', gap: '8px', marginTop: '10px' }}>
            <button
              onClick={resetWheel}
              style={{
                background: 'linear-gradient(to right, #6b7280, #374151)',
                color: '#fff',
                border: 'none',
                padding: '8px 12px',
                borderRadius: '8px',
                cursor: 'pointer',
                fontWeight: 'bold',
                flex: 1,
              }}
            >
              Reset roue
            </button>
            <button
              onClick={resetWins}
              style={{
                background: 'linear-gradient(to right, #ef4444, #b91c1c)',
                color: '#fff',
                border: 'none',
                padding: '8px 12px',
                borderRadius: '8px',
                cursor: 'pointer',
                fontWeight: 'bold',
                flex: 1,
              }}
            >
              Reset gains
            </button>
          </div>
          <button
            onClick={resetStock}
            style={{
              width: '100%',
              marginTop: '8px',
              background: 'linear-gradient(to right, #10b981, #047857)',
              color: '#fff',
              border: 'none',
              padding: '8px 12px',
              borderRadius: '8px',
              cursor: 'pointer',
              fontWeight: 'bold',
            }}
          >
            Reset stock boutique
          </button>

          <button
            onClick={() => { setShowWinnerPopup(false); setShowAdminInterface(false); }}
            style={{
              width: '100%',
              background: '#333',
              color: '#fff',
              border: 'none',
              padding: '6px 10px',
              borderRadius: '6px',
              cursor: 'pointer',
              fontSize: '11px',
              marginTop: '8px',
            }}
          >
            Masquer
          </button>
        </div>
      )}

      {/* Popup de gain */}
      {showWinnerPopup && lastWon && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0,0,0,0.9)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1100,
          }}
        >
          <div
            style={{
              background: 'linear-gradient(135deg, #FFD700, #FFA500)',
              padding: '32px',
              borderRadius: '16px',
              color: '#fff',
              textAlign: 'center',
              maxWidth: '520px',
              margin: '16px',
              boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
            }}
          >
            <div style={{ fontSize: '56px', marginBottom: '16px' }}>Gagné</div>
            <h2 style={{ fontSize: '2rem', marginBottom: '12px' }}>Félicitations !</h2>
            <p style={{ fontSize: '1.2rem', marginBottom: '20px' }}>Vous avez gagné :</p>
            <div
              style={{
                background: 'rgba(255,255,255,0.2)',
                padding: '18px',
                borderRadius: '12px',
                marginBottom: '24px',
                fontWeight: 'bold',
                fontSize: '1.5rem',
              }}
            >
              {lastWon.title}
            </div>
            <button
              onClick={() => {
                setShowWinnerPopup(false);
                // On revient à l'étape email pour le participant suivant
                setEmail('');
                localStorage.removeItem('wheel-email');
                setEmailValidated(false);
                // On réinitialise la boutique sélectionnée
                setShopId('shop-1');
                localStorage.removeItem('wheel-current-shop');
                setShowShopSelection(false);
              }}
              style={{
                background: 'linear-gradient(135deg, #FFD700 0%, #FFA500 50%, #FF6B35 100%)',
                color: 'white',
                border: 'none',
                padding: '12px 28px',
                borderRadius: '50px',
                fontSize: '1.1rem',
                fontWeight: 'bold',
                cursor: 'pointer',
                boxShadow: '0 8px 25px rgba(0, 0, 0, 0.3), 0 0 20px rgba(255, 215, 0, 0.5)',
                transition: 'all 0.3s ease',
                textShadow: '1px 1px 3px rgba(0, 0, 0, 0.5)',
                minWidth: '160px',
              }}
              onMouseOver={(e) => {
                e.currentTarget.style.transform = 'scale(1.05)';
                e.currentTarget.style.boxShadow =
                  '0 12px 35px rgba(0, 0, 0, 0.4), 0 0 30px rgba(255, 215, 0, 0.8)';
              }}
              onMouseOut={(e) => {
                e.currentTarget.style.transform = 'scale(1)';
                e.currentTarget.style.boxShadow =
                  '0 8px 25px rgba(0, 0, 0, 0.3), 0 0 20px rgba(255, 215, 0, 0.5)';
              }}
            >
              J'ai compris
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
