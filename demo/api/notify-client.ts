// Route API pour envoyer un email au client (gagnant) via Dialog Insight
// Version simplifiée : envoi direct par email sans Get/Merge du contact

const DIALOG_IDKEY = process.env.DIALOG_IDKEY as string;
const DIALOG_KEY = process.env.DIALOG_KEY as string;
const DIALOG_PROJECT_ID = parseInt(process.env.DIALOG_PROJECT_ID || '17265784');
const DIALOG_MESSAGE_ID_WHEEL = parseInt(process.env.DIALOG_MESSAGE_ID_WHEEL || '528');

const DIALOG_API_BASE = 'https://app.mydialoginsight.com/webservices/ofc4';

// Fonction pour envoyer un email via Dialog Insight (SendSingle2)
async function sendingsSendSingle2(
  idContact: number,
  firstName: string,
  lastName: string,
  shopName: string,
  segmentTitle: string
): Promise<{ Success: boolean; ErrorCode?: any; ErrorMessage?: any }> {
  const response = await fetch(`${DIALOG_API_BASE}/sendings.ashx?method=SendSingle2`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      AuthKey: {
        idKey: parseInt(DIALOG_IDKEY),
        Key: DIALOG_KEY,
      },
      idProject: DIALOG_PROJECT_ID,
      idMessage: DIALOG_MESSAGE_ID_WHEEL,
      ContactFilter: {
        Mode: 'Single',
        idContact: idContact,
      },
      SendSingleOptions: {
        idMessageVersion: null,
        MessageParameterValues: {
          client_prenom: firstName,
          client_nom: lastName,
          lot_gagne: segmentTitle,
          boutique_nom: shopName,
        },
        DiscardParametersAfterSending: false,
      },
      Attachments: null,
    }),
  });

  if (!response.ok) {
    throw new Error(`Dialog Insight API error: ${response.status}`);
  }

  return await response.json();
}

export default async function handler(req: any, res: any) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Logger l'IP de Vercel pour référence
    const vercelIP = req.headers['x-forwarded-for'] || req.connection?.remoteAddress || 'unknown';
    console.log(`📍 IP Vercel utilisée: ${vercelIP}`);

    const { firstName, lastName, email, shopName, segmentTitle } = req.body;

    if (!firstName || !lastName || !email || !shopName || !segmentTitle) {
      return res.status(400).json({ error: 'Missing required fields: firstName, lastName, email, shopName, segmentTitle' });
    }

    if (!DIALOG_IDKEY || !DIALOG_KEY) {
      return res.status(500).json({ error: 'Dialog Insight credentials not configured' });
    }

    console.log(`📧 Envoi email Dialog Insight à: ${email}`);
    console.log(`   Gagnant: ${firstName} ${lastName}`);
    console.log(`   Lot: ${segmentTitle}`);
    console.log(`   Boutique: ${shopName}`);

    // 1. Chercher ou créer le contact
    let idContact: number | null = null;
    const contactsGetResp = await contactsGet(email);

    if (contactsGetResp.Success && contactsGetResp.Records && contactsGetResp.Records.length > 0) {
      idContact = contactsGetResp.Records[0].idContact;
      console.log(`✅ Contact trouvé: idContact=${idContact}`);
    } else {
      console.log('ℹ️  Contact non trouvé, création...');
      const contactsMergeResp = await contactsMerge(email, firstName, lastName);

      if (!contactsMergeResp.Success) {
        console.error('❌ Erreur lors de la création du contact:', contactsMergeResp.ErrorCode, contactsMergeResp.ErrorMessage);
        return res.status(500).json({
          error: 'Failed to create contact in Dialog Insight',
          details: contactsMergeResp.ErrorMessage || contactsMergeResp.ErrorCode,
        });
      }

      // Refaire un Get pour obtenir l'idContact
      const contactsGetResp2 = await contactsGet(email);
      if (contactsGetResp2.Success && contactsGetResp2.Records && contactsGetResp2.Records.length > 0) {
        idContact = contactsGetResp2.Records[0].idContact;
        console.log(`✅ Contact créé: idContact=${idContact}`);
      } else {
        return res.status(500).json({ error: 'Failed to retrieve contact ID after creation' });
      }
    }

    if (!idContact) {
      return res.status(500).json({ error: 'Could not determine contact ID' });
    }

    // 2. Envoyer l'email avec les paramètres de message
    const sendResp = await sendingsSendSingle2(idContact, firstName, lastName, shopName, segmentTitle);

    if (!sendResp.Success) {
      console.error('❌ Erreur lors de l\'envoi de l\'email:', sendResp.ErrorCode, sendResp.ErrorMessage);
      return res.status(500).json({
        error: 'Failed to send email via Dialog Insight',
        details: sendResp.ErrorMessage || sendResp.ErrorCode,
      });
    }

    console.log('✅ Email envoyé au client via Dialog Insight avec succès');

    return res.status(200).json({
      success: true,
      idContact,
      message: 'Email sent to client via Dialog Insight',
    });
  } catch (error: any) {
    console.error('❌ Error in notify-client:', error);
    return res.status(500).json({
      error: 'Failed to send email to client',
      details: error?.message || 'Unknown error',
    });
  }
}
