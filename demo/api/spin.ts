import type { VercelRequest, VercelResponse } from '@vercel/node';

const SUPABASE_URL = process.env.SUPABASE_URL as string;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY as string;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  try {
    const { shopId, segmentId } = req.body || {};
    if (!shopId || !segmentId) return res.status(400).json({ error: 'shopId and segmentId are required' });
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return res.status(500).json({ error: 'Supabase env not configured' });
    }

    const url = `${SUPABASE_URL}/rest/v1/rpc/decrement_stock`;
    const r = await fetch(url, {
      method: 'POST',
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ p_shop: shopId, p_segment: segmentId }),
    });

    const text = await r.text();
    if (!r.ok) {
      if (text.includes('OUT_OF_STOCK')) return res.status(409).json({ error: 'OUT_OF_STOCK' });
      return res.status(502).json({ error: 'Supabase error', detail: text });
    }

    const newRemaining = Number(text);
    return res.status(200).json({ remaining: newRemaining });
  } catch (e: any) {
    return res.status(500).json({ error: e?.message || 'Unknown error' });
  }
}


