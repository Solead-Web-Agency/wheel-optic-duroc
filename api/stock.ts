import type { VercelRequest, VercelResponse } from '@vercel/node';

const SUPABASE_URL = process.env.SUPABASE_URL as string;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY as string;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  try {
    const shopId = (req.query.shopId as string) || 'shop-1';
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return res.status(500).json({ error: 'Supabase env not configured' });
    }

    const url = new URL(`${SUPABASE_URL}/rest/v1/shop_stock`);
    url.searchParams.set('shop_id', `eq.${shopId}`);
    // Pas de jointure, on renvoie uniquement les restants; le front mappe les titres localement
    url.searchParams.set('select', 'segment_id,remaining');

    const r = await fetch(url.toString(), {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        Accept: 'application/json',
      },
    });

    if (!r.ok) {
      const text = await r.text();
      return res.status(502).json({ error: 'Supabase error', detail: text });
    }

    const rows: Array<{ segment_id: number; remaining: number }> = await r.json();
    const data = rows.map((row) => ({ id: row.segment_id, remaining: row.remaining }));
    return res.status(200).json({ shopId, segments: data });
  } catch (e: any) {
    return res.status(500).json({ error: e?.message || 'Unknown error' });
  }
}


