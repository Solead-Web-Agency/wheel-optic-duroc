import type { VercelRequest, VercelResponse } from '@vercel/node';
import nodemailer from 'nodemailer';

const SUPABASE_URL = process.env.SUPABASE_URL as string;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY as string;

// Configuration SMTP (à remplir avec tes identifiants)
const SMTP_HOST = process.env.SMTP_HOST || 'smtp.example.com';
const SMTP_PORT = parseInt(process.env.SMTP_PORT || '587');
const SMTP_USER = process.env.SMTP_USER || 'noreply@opticduroc.com';
const SMTP_PASS = process.env.SMTP_PASS || '';
const FROM_EMAIL = process.env.FROM_EMAIL || 'noreply@opticduroc.com';
const FROM_NAME = process.env.FROM_NAME || 'Roue de la Fortune - Optic Duroc';
const TEST_EMAIL = process.env.TEST_EMAIL || ''; // Si défini, tous les emails vont ici (mode test)

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { shopId, segmentTitle, segmentId, userEmail } = req.body;

    if (!shopId || !segmentTitle || !segmentId || !userEmail) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // 1. Récupérer l'email de la boutique depuis Supabase
    const shopUrl = new URL(`${SUPABASE_URL}/rest/v1/shops`);
    shopUrl.searchParams.set('id', `eq.${shopId}`);
    shopUrl.searchParams.set('select', 'name,email');

    const shopResponse = await fetch(shopUrl.toString(), {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        Accept: 'application/json',
      },
    });

    if (!shopResponse.ok) {
      return res.status(502).json({ error: 'Failed to fetch shop data' });
    }

    const shops = await shopResponse.json();
    if (!shops || shops.length === 0) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    const shop = shops[0];
    const shopEmail = TEST_EMAIL || shop.email; // Mode test : utilise TEST_EMAIL si défini
    const shopName = shop.name;

    // 2. Récupérer les infos du participant (prénom, nom)
    const participantUrl = new URL(`${SUPABASE_URL}/rest/v1/participants`);
    participantUrl.searchParams.set('email', `eq.${userEmail}`);
    participantUrl.searchParams.set('select', 'first_name,last_name');

    const participantResponse = await fetch(participantUrl.toString(), {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        Accept: 'application/json',
      },
    });

    let firstName = '';
    let lastName = '';
    if (participantResponse.ok) {
      const participants = await participantResponse.json();
      if (participants && participants.length > 0) {
        firstName = participants[0].first_name || '';
        lastName = participants[0].last_name || '';
      }
    }

    // 3. Récupérer le stock restant pour ce lot dans cette boutique
    const stockUrl = new URL(`${SUPABASE_URL}/rest/v1/shop_stock`);
    stockUrl.searchParams.set('shop_id', `eq.${shopId}`);
    stockUrl.searchParams.set('segment_id', `eq.${segmentId}`);
    stockUrl.searchParams.set('select', 'remaining');

    const stockResponse = await fetch(stockUrl.toString(), {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        Accept: 'application/json',
      },
    });

    let stockRemaining = 0;
    if (stockResponse.ok) {
      const stockData = await stockResponse.json();
      if (stockData && stockData.length > 0) {
        stockRemaining = stockData[0].remaining || 0;
      }
    }

    // 4. Créer le transporteur SMTP avec Nodemailer
    const transporter = nodemailer.createTransport({
      host: SMTP_HOST,
      port: SMTP_PORT,
      secure: SMTP_PORT === 465, // true pour port 465, false pour autres ports
      auth: {
        user: SMTP_USER,
        pass: SMTP_PASS,
      },
    });

    // 5. Composer l'email
    const participantName = firstName && lastName ? `${firstName} ${lastName}` : 'le participant';
    const subject = `Nouveau gain à la roue - ${shopName}${TEST_EMAIL ? ' [MODE TEST]' : ''}`;
    
    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; background: #f9f9f9; }
          .header { background: linear-gradient(135deg, #FFD700, #FFA500); padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .header h1 { color: white; margin: 0; font-size: 1.5em; }
          .content { background: white; padding: 30px; border-radius: 0 0 8px 8px; }
          .info-box { background: #f0f8ff; padding: 15px; border-left: 4px solid #FFD700; margin: 20px 0; }
          .info-box p { margin: 8px 0; }
          .highlight { color: #ff6b35; font-weight: bold; }
          .stock-info { background: #e8f5e9; padding: 10px; border-radius: 5px; margin-top: 15px; }
          .footer { text-align: center; margin-top: 20px; color: #666; font-size: 0.9em; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Nouveau gain à la roue de la fortune</h1>
          </div>
          <div class="content">
            ${TEST_EMAIL ? '<p style="background: #ff6b35; color: white; padding: 10px; border-radius: 5px; font-weight: bold;">⚠️ MODE TEST - Email de destination réelle : ' + shop.email + '</p>' : ''}
            
            <p>Bonjour,</p>
            
            <p>Dans le cadre de l'opération commerciale en cours, un prospect — <strong>${participantName}</strong> — a gagné un <span class="highlight">${segmentTitle}</span> et a choisi votre boutique pour le récupérer.</p>
            
            <div class="info-box">
              <p><strong>Lot gagné :</strong> <span class="highlight">${segmentTitle}</span></p>
              <p><strong>Participant :</strong> ${participantName}</p>
              <p><strong>Email :</strong> ${userEmail}</p>
            </div>
            
            <p><strong>Merci de bien vouloir mettre le cadeau de côté.</strong></p>
            
            <p>Le client se présentera prochainement en magasin pour le récupérer, avec présentation du mail garant.</p>
            
            <div class="stock-info">
              <p><strong>📦 Stock disponible pour ce lot :</strong> ${stockRemaining} unité(s) restante(s)</p>
            </div>
            
            <p style="margin-top: 30px;">Bonne journée,<br><strong>L'équipe Optic Duroc</strong></p>
          </div>
          <div class="footer">
            <p>Cet email a été envoyé automatiquement par la roue de la fortune Optic Duroc.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    const textContent = `
Nouveau gain à la roue de la fortune

Bonjour,

Dans le cadre de l'opération commerciale en cours, un prospect — ${participantName} — a gagné un ${segmentTitle} et a choisi votre boutique pour le récupérer.

Lot gagné : ${segmentTitle}
Participant : ${participantName}
Email : ${userEmail}

Merci de bien vouloir mettre le cadeau de côté.

Le client se présentera prochainement en magasin pour le récupérer, avec présentation du mail garant.

Stock disponible pour ce lot : ${stockRemaining} unité(s) restante(s)

Bonne journée,
L'équipe Optic Duroc
    `;

    // 6. Envoyer l'email
    const info = await transporter.sendMail({
      from: `"${FROM_NAME}" <${FROM_EMAIL}>`,
      to: shopEmail,
      subject: subject,
      text: textContent,
      html: htmlContent,
    });

    console.log('Email sent:', info.messageId);

    return res.status(200).json({
      success: true,
      messageId: info.messageId,
      shopEmail: shopEmail,
    });
  } catch (error: any) {
    console.error('Error sending email:', error);
    return res.status(500).json({
      error: 'Failed to send email',
      details: error?.message || 'Unknown error',
    });
  }
}

