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
const TEST_EMAIL = process.env.TEST_EMAIL || ''; // Si défini, envoi en CCI (copie cachée)

// On tape req/res en any pour éviter d'ajouter la dépendance @vercel/node
export default async function handler(req: any, res: any) {
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
    const shopEmail = shop.email; // Toujours envoyer à la boutique
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

    // 3. Récupérer le stock restant pour TOUS les lots de cette boutique
    const stockUrl = new URL(`${SUPABASE_URL}/rest/v1/shop_stock`);
    stockUrl.searchParams.set('shop_id', `eq.${shopId}`);
    stockUrl.searchParams.set('select', 'segment_id,remaining');

    const stockResponse = await fetch(stockUrl.toString(), {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        Accept: 'application/json',
      },
    });

    const segmentLabels: Record<number, string> = {
      1: 'STYLO',
      2: 'TOTE BAG',
      3: 'TROUSSE VOYAGE',
      4: 'CHARGEUR',
      5: 'BAUME À LÈVRES',
      6: 'PORTE CARTE',
      7: 'SPRAY',
      8: 'HAUT PARLEUR',
      9: 'CHAINETTES',
      10: 'MASQUE',
      11: 'ETUIS SOUPLE',
    };

    let stockPerSegment: Array<{ segment_id: number; remaining: number }> = [];
    let stockRemainingForWon = 0;
    if (stockResponse.ok) {
      const stockData = await stockResponse.json();
      if (Array.isArray(stockData)) {
        stockPerSegment = stockData;
        const found = stockData.find((row: any) => row.segment_id === segmentId);
        if (found) {
          stockRemainingForWon = found.remaining || 0;
        }
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
    const participantName =
      firstName && lastName ? `${firstName} ${lastName}` : 'le participant';
    const subject = `Nouveau gain à la roue - ${shopName}`;

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
          .stock-info ul { margin: 8px 0 0 18px; padding: 0; }
          .stock-info li { margin: 3px 0; }
          .footer { text-align: center; margin-top: 20px; color: #666; font-size: 0.9em; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Nouveau gain à la roue de la fortune</h1>
          </div>
          <div class="content">
            <p>Bonjour,</p>
            
            <p>Dans le cadre de l'opération commerciale en cours, un prospect — <strong>${participantName}</strong> — a gagné un <span class="highlight">${segmentTitle}</span> et a choisi votre boutique pour le récupérer.</p>
            
            <div class="info-box">
              <p><strong>Lot gagné :</strong> <span class="highlight">${segmentTitle}</span></p>
              <p><strong>Participant :</strong> ${participantName}</p>
              <p><strong>Email :</strong> ${userEmail}</p>
            </div>
            
            <p><strong>Merci de bien vouloir mettre le cadeau de côté.</strong></p>
            
            <p>Le client se présentera prochainement en magasin pour le récupérer, avec présentation du mail garant.</p>

            <p>Un <strong>code marketing “Roue de Noël”</strong> a été créé spécialement : pensez à l’intégrer systématiquement dès qu’une vente est générée grâce au cadeau récupéré dans le cadre de l’opération. Un <strong>bilan</strong> sera réalisé en fin de mois afin d’analyser le nombre de ventes déclenchées par l’action, pour chaque boutique.</p>
            
            <div class="stock-info">
              <p><strong>📦 Stock disponible dans votre boutique (par lot) :</strong></p>
              <ul>
                ${
                  stockPerSegment
                    .map(
                      (row) =>
                        `<li>${segmentLabels[row.segment_id] || `Lot ${row.segment_id}`} : <strong>${row.remaining}</strong> unité(s)</li>`
                    )
                    .join('')
                }
              </ul>
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

Stocks disponibles dans votre boutique (par lot) :
${stockPerSegment
  .map(
    (row) =>
      `- ${segmentLabels[row.segment_id] || `Lot ${row.segment_id}`} : ${row.remaining} unité(s)`
  )
  .join('\n')}

Bonne journée,
L'équipe Optic Duroc
    `;

    // 6. Envoyer l'email
    const mailOptions: any = {
      from: `"${FROM_NAME}" <${FROM_EMAIL}>`,
      to: shopEmail,
      subject: subject,
      text: textContent,
      html: htmlContent,
    };

    // Ajouter TEST_EMAIL en CCI si défini
    if (TEST_EMAIL) {
      mailOptions.bcc = TEST_EMAIL;
    }

    const info = await transporter.sendMail(mailOptions);

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


