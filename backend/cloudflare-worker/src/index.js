const JSON_HEADERS = {
  'Content-Type': 'application/json; charset=utf-8',
};
const TOPUP_VALIDITY_MS = 10 * 60 * 1000;
const WALLET_UNITS_PER_VND = 1000;

let cachedAccessToken;
let cachedAccessTokenExpiry = 0;

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...JSON_HEADERS,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    },
  });
}

function firestoreValue(value) {
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'number' && Number.isInteger(value)) {
    return { integerValue: String(value) };
  }
  if (typeof value === 'number') return { doubleValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  throw new TypeError('Unsupported Firestore value');
}

function firestoreDocument(name, fields) {
  return {
    name,
    fields: Object.fromEntries(
      Object.entries(fields).map(([key, value]) => [key, firestoreValue(value)]),
    ),
  };
}

function decodeFirestoreValue(value) {
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('timestampValue' in value) return value.timestampValue;
  return null;
}

function decodeFirestoreDocument(document) {
  return Object.fromEntries(
    Object.entries(document.fields ?? {}).map(([key, value]) => [
      key,
      decodeFirestoreValue(value),
    ]),
  );
}

function firestoreDocumentsName(env) {
  return `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents`;
}

function databaseRoot(env) {
  return `https://firestore.googleapis.com/v1/${firestoreDocumentsName(env)}`;
}

async function serviceAccessToken(env) {
  if (cachedAccessToken && Date.now() < cachedAccessTokenExpiry - 60_000) {
    return cachedAccessToken;
  }

  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = base64UrlEncode(
    JSON.stringify({
      iss: env.GOOGLE_SERVICE_ACCOUNT_EMAIL,
      scope: 'https://www.googleapis.com/auth/datastore',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );
  const signingInput = `${header}.${claims}`;
  const privateKeyPem = env.GOOGLE_PRIVATE_KEY.replace(/\\n/g, '\n');
  const privateKeyBytes = pemToArrayBuffer(privateKeyPem);
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    privateKeyBytes,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signingInput),
  );
  const assertion = `${signingInput}.${base64UrlEncodeBytes(new Uint8Array(signature))}`;
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  const data = await response.json();
  if (!response.ok || typeof data.access_token !== 'string') {
    console.error('Unable to obtain Firestore service token', response.status, {
      error: data.error,
      errorDescription: data.error_description,
    });
    throw new Error('Firestore authentication failed');
  }
  cachedAccessToken = data.access_token;
  cachedAccessTokenExpiry = Date.now() + Number(data.expires_in) * 1000;
  return cachedAccessToken;
}

function base64UrlEncode(value) {
  return base64UrlEncodeBytes(new TextEncoder().encode(value));
}

function base64UrlEncodeBytes(bytes) {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function pemToArrayBuffer(pem) {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s/g, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function firestoreRequest(env, path, options = {}) {
  const { allowNotFound: _allowNotFound, ...fetchOptions } = options;
  const token = await serviceAccessToken(env);
  const response = await fetch(`${databaseRoot(env)}${path}`, {
    ...fetchOptions,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });
  if (response.status === 404 && options.allowNotFound) return null;
  if (!response.ok) {
    const details = await response.text();
    const error = new Error(`Firestore request failed (${response.status})`);
    error.status = response.status;
    console.error(error.message, details);
    throw error;
  }
  if (response.status === 204) return {};
  return response.json();
}

async function verifyFirebaseUser(request, env) {
  const authorization = request.headers.get('Authorization') ?? '';
  const match = /^Bearer\s+(.+)$/i.exec(authorization);
  if (!match) return null;
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${encodeURIComponent(env.FIREBASE_API_KEY)}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ idToken: match[1] }),
    },
  );
  if (!response.ok) return null;
  const body = await response.json();
  const user = body.users?.[0];
  return user && !user.disabled ? user.localId : null;
}

async function ensureWalletExists(env, uid) {
  const walletPath = `/wallets/${encodeURIComponent(uid)}`;
  const existing = await firestoreRequest(env, walletPath, { allowNotFound: true });
  if (existing) return;
  try {
    await firestoreRequest(env, ':commit', {
      method: 'POST',
      body: JSON.stringify({
        writes: [
          {
            update: firestoreDocument(
              `${firestoreDocumentsName(env)}/wallets/${uid}`,
              { amount: 0 },
            ),
            currentDocument: { exists: false },
          },
        ],
      }),
    });
  } catch (error) {
    if (error.status !== 409) {
      const createdByConcurrentRequest = await firestoreRequest(
        env,
        walletPath,
        { allowNotFound: true },
      );
      if (!createdByConcurrentRequest) throw error;
    }
  }
}

async function createTopup(request, env) {
  const uid = await verifyFirebaseUser(request, env);
  if (!uid) return jsonResponse({ error: 'Vui lòng đăng nhập lại.' }, 401);

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ error: 'Dữ liệu yêu cầu không hợp lệ.' }, 400);
  }
  const amountVnd = body.amountVnd;
  if (
    !Number.isSafeInteger(amountVnd) ||
    amountVnd < WALLET_UNITS_PER_VND ||
    amountVnd % WALLET_UNITS_PER_VND !== 0
  ) {
    return jsonResponse({ error: 'Số tiền nạp không hợp lệ.' }, 400);
  }

  const reference = `QDT${Date.now()}${crypto.randomUUID().replace(/-/g, '').slice(0, 8).toUpperCase()}`;
  const now = Date.now();
  const expiresAt = new Date(now + TOPUP_VALIDITY_MS);
  await ensureWalletExists(env, uid);
  await firestoreRequest(env, ':commit', {
    method: 'POST',
    body: JSON.stringify({
      writes: [
        {
          update: firestoreDocument(
            `${firestoreDocumentsName(env)}/topupRequests/${reference}`,
            {
              uid,
              amountVnd,
              status: 'pending',
              createdAt: new Date(now),
              expiresAt,
            },
          ),
          currentDocument: { exists: false },
        },
      ],
    }),
  });

  return jsonResponse({ reference, expiresAt: expiresAt.toISOString() });
}

async function getTopupStatus(request, env, reference) {
  const uid = await verifyFirebaseUser(request, env);
  if (!uid) return jsonResponse({ error: 'Vui lòng đăng nhập lại.' }, 401);
  if (!/^QDT[A-Z0-9]{10,40}$/.test(reference)) {
    return jsonResponse({ error: 'Mã yêu cầu không hợp lệ.' }, 400);
  }

  const document = await firestoreRequest(env, `/topupRequests/${reference}`, {
    allowNotFound: true,
  });
  if (!document) return jsonResponse({ error: 'Không tìm thấy yêu cầu.' }, 404);
  const fields = decodeFirestoreDocument(document);
  if (fields.uid !== uid) return jsonResponse({ error: 'Không có quyền truy cập.' }, 403);

  const status =
    fields.status === 'pending' &&
    typeof fields.expiresAt === 'string' &&
    Date.parse(fields.expiresAt) <= Date.now()
      ? 'expired'
      : fields.status;
  return jsonResponse({ status });
}

function authorizedSePay(request, env) {
  const expected = `Apikey ${env.SEPAY_WEBHOOK_TOKEN}`;
  const actual = request.headers.get('Authorization') ?? '';
  const encoder = new TextEncoder();
  const a = encoder.encode(expected);
  const b = encoder.encode(actual);
  if (a.length !== b.length) return false;
  let difference = 0;
  for (let i = 0; i < a.length; i++) difference |= a[i] ^ b[i];
  return difference === 0;
}

async function hashTransactionId(transactionId) {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(String(transactionId)),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

async function receiveSePayWebhook(request, env) {
  if (!env.SEPAY_WEBHOOK_TOKEN || !authorizedSePay(request, env)) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  let event;
  try {
    event = await request.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON' }, 400);
  }
  const transactionId = event.id;
  const transferAmount = Number(event.transferAmount);
  const reference = String(event.content ?? '').match(/QDT[A-Z0-9]{10,40}/i)?.[0]?.toUpperCase();
  const incomingAccount = String(event.accountNumber ?? '').replace(/\D/g, '');
  if (
    event.transferType !== 'in' ||
    !(
      (typeof transactionId === 'number' &&
        Number.isSafeInteger(transactionId) &&
        transactionId > 0) ||
      (typeof transactionId === 'string' &&
        transactionId.trim().length > 0 &&
        transactionId.length <= 200)
    ) ||
    !Number.isSafeInteger(transferAmount) ||
    transferAmount <= 0 ||
    incomingAccount !== String(env.BANK_ACCOUNT_NUMBER).replace(/\D/g, '') ||
    !reference
  ) {
    console.warn('Ignoring unmatched SePay transfer notification', {
      transactionId,
      transferType: event.transferType,
      incomingAccount,
    });
    return jsonResponse({ success: true });
  }

  const requestDoc = await firestoreRequest(
    env,
    `/topupRequests/${reference}`,
    { allowNotFound: true },
  );
  if (!requestDoc) {
    console.warn('No top-up request for incoming transfer', transactionId, reference);
    return jsonResponse({ success: true });
  }
  const topup = decodeFirestoreDocument(requestDoc);
  if (
    topup.status === 'paid' ||
    topup.amountVnd !== transferAmount
  ) {
    console.warn('Duplicate or amount-mismatched SePay transfer', {
      transactionId,
      reference,
      expectedAmount: topup.amountVnd,
      receivedAmount: transferAmount,
      status: topup.status,
    });
    return jsonResponse({ success: true });
  }

  const walletName = `${firestoreDocumentsName(env)}/wallets/${topup.uid}`;
  const transactionKey = await hashTransactionId(transactionId);
  const transactionName = `${firestoreDocumentsName(env)}/sepayTransactions/${transactionKey}`;
  const walletTransactionName =
    `${firestoreDocumentsName(env)}/wallets/${topup.uid}/transactions/sepay_${transactionKey}`;
  const receivedAt = new Date();
  try {
    await firestoreRequest(env, ':commit', {
      method: 'POST',
      body: JSON.stringify({
        writes: [
          {
            update: firestoreDocument(transactionName, {
              sepayTransactionId: String(transactionId),
              reference,
              uid: topup.uid,
              amountVnd: transferAmount,
              receivedAt,
            }),
            currentDocument: { exists: false },
          },
          {
            update: firestoreDocument(
              `${firestoreDocumentsName(env)}/topupRequests/${reference}`,
              {
                status: 'paid',
                sepayTransactionId: String(transactionId),
                paidAt: receivedAt,
              },
            ),
            updateMask: {
              fieldPaths: ['status', 'sepayTransactionId', 'paidAt'],
            },
            currentDocument: { updateTime: requestDoc.updateTime },
          },
          {
            transform: {
              document: walletName,
              fieldTransforms: [
                {
                  fieldPath: 'amount',
                  increment: {
                    doubleValue: transferAmount / WALLET_UNITS_PER_VND,
                  },
                },
              ],
            },
          },
          {
            update: firestoreDocument(walletTransactionName, {
              type: 'topup',
              amount: transferAmount / WALLET_UNITS_PER_VND,
              description: `Nạp tiền qua SePay (${reference})`,
              createdAt: receivedAt,
            }),
            currentDocument: { exists: false },
          },
        ],
      }),
    });
  } catch (error) {
    const existingTransaction = await firestoreRequest(
      env,
      `/sepayTransactions/${transactionKey}`,
      { allowNotFound: true },
    );
    if (existingTransaction) return jsonResponse({ success: true });
    throw error;
  }

  return jsonResponse({ success: true });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    try {
      if (request.method === 'OPTIONS') {
        return new Response(null, {
          status: 204,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Authorization, Content-Type',
          },
        });
      }
      if (request.method === 'POST' && url.pathname === '/topups') {
        return await createTopup(request, env);
      }
      if (request.method === 'POST' && url.pathname === '/webhook/sepay') {
        return await receiveSePayWebhook(request, env);
      }
      const statusMatch = /^\/topups\/(QDT[A-Z0-9]{10,40})$/i.exec(url.pathname);
      if (request.method === 'GET' && statusMatch) {
        return await getTopupStatus(
          request,
          env,
          statusMatch[1].toUpperCase(),
        );
      }
      return jsonResponse({ error: 'Not found' }, 404);
    } catch (error) {
      console.error('Top-up Worker request failed', error);
      return jsonResponse({ error: 'Dịch vụ nạp tiền tạm thời gặp lỗi.' }, 500);
    }
  },
};
