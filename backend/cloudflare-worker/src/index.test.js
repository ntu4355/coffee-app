import { generateKeyPairSync } from 'node:crypto';
import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import worker from './index.js';

const transferReference = 'QDT12345678901234567890';
const transactionId = 92704;
let commitCount = 0;
let duplicateRecordExists = false;
let privateKey;
const committedDocumentNames = [];

const pendingRequest = {
  name: `projects/coffee-app-77675/databases/(default)/documents/topupRequests/${transferReference}`,
  updateTime: '2026-10-11T10:00:00.000000Z',
  fields: {
    uid: { stringValue: 'firebase-user-1' },
    amountVnd: { integerValue: '50000' },
    status: { stringValue: 'pending' },
  },
};

const env = {
  FIREBASE_PROJECT_ID: 'coffee-app-77675',
  BANK_ACCOUNT_NUMBER: '0332038511',
  SEPAY_WEBHOOK_TOKEN: 'test-webhook-token',
  GOOGLE_SERVICE_ACCOUNT_EMAIL: 'worker@example.iam.gserviceaccount.com',
  get GOOGLE_PRIVATE_KEY() {
    return privateKey;
  },
};

before(() => {
  const keyPair = generateKeyPairSync('rsa', {
    modulusLength: 2048,
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
    publicKeyEncoding: { type: 'spki', format: 'pem' },
  });
  privateKey = keyPair.privateKey;

  globalThis.fetch = async (input, init = {}) => {
    const url = String(input);
    if (url === 'https://oauth2.googleapis.com/token') {
      return Response.json({ access_token: 'test-access-token', expires_in: 3600 });
    }
    if (url.startsWith('https://identitytoolkit.googleapis.com/')) {
      return Response.json({ users: [{ localId: 'firebase-user-1' }] });
    }
    if (url.endsWith(`/topupRequests/${transferReference}`)) {
      return Response.json(pendingRequest);
    }
    if (url.endsWith('/wallets/firebase-user-1')) {
      return new Response('Not found', { status: 404 });
    }
    if (url.endsWith('/sepayTransactions')) {
      return new Response('Not found', { status: 404 });
    }
    if (url.includes('/sepayTransactions/')) {
      return duplicateRecordExists
        ? Response.json({ name: url, fields: {} })
        : new Response('Not found', { status: 404 });
    }
    if (url.endsWith(':commit')) {
      const commit = JSON.parse(init.body);
      const documentNames = commit.writes
        .filter((write) => write.update)
        .map((write) => write.update.name);
      assert.ok(
        documentNames.every((name) =>
          name.startsWith(
            'projects/coffee-app-77675/databases/(default)/documents/',
          ),
        ),
        'commit document names use Firestore resource names, not REST URLs',
      );
      committedDocumentNames.push(...documentNames);

      const increment = commit.writes.find((write) => write.transform);
      if (increment && duplicateRecordExists) {
        return Response.json(
          { error: { message: 'Already exists' } },
          { status: 409 },
        );
      }
      if (increment) {
        assert.equal(
          increment.transform.fieldTransforms[0].increment.doubleValue,
          50,
        );
        commitCount += 1;
        duplicateRecordExists = true;
      }
      return Response.json({ writeResults: [] });
    }
    throw new Error(`Unexpected test fetch: ${url}`);
  };
});

after(() => {
  delete globalThis.fetch;
});

function webhookRequest(overrides = {}) {
  return new Request('https://worker.example/webhook/sepay', {
    method: 'POST',
    headers: {
      Authorization: 'Apikey test-webhook-token',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      id: transactionId,
      accountNumber: '0332038511',
      transferType: 'in',
      transferAmount: 50000,
      content: `Thanh toan ${transferReference}`,
      ...overrides,
    }),
  });
}

test('creates top-up requests with Firestore resource document names', async () => {
  const documentNameStart = committedDocumentNames.length;
  const response = await worker.fetch(
    new Request('https://worker.example/topups', {
      method: 'POST',
      headers: {
        Authorization: 'Bearer firebase-test-token',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ amountVnd: 50000 }),
    }),
    env,
  );

  assert.equal(response.status, 200);
  const { reference } = await response.json();
  const newDocumentNames = committedDocumentNames.slice(documentNameStart);
  assert.ok(
    newDocumentNames.includes(
      'projects/coffee-app-77675/databases/(default)/documents/wallets/firebase-user-1',
    ),
  );
  assert.ok(
    newDocumentNames.includes(
      `projects/coffee-app-77675/databases/(default)/documents/topupRequests/${reference}`,
    ),
  );
});

test('credits a matching incoming transfer in wallet units', async () => {
  const response = await worker.fetch(webhookRequest(), env);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { success: true });
  assert.equal(commitCount, 1);
});

test('does not credit a duplicate bank transaction twice', async () => {
  const response = await worker.fetch(webhookRequest(), env);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { success: true });
  assert.equal(commitCount, 1);
});

test('does not credit a transfer with a mismatched amount', async () => {
  const response = await worker.fetch(
    webhookRequest({ id: 92705, transferAmount: 40000 }),
    env,
  );
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { success: true });
  assert.equal(commitCount, 1);
});

test('rejects webhook requests without the SePay API key', async () => {
  const request = webhookRequest();
  const headers = new Headers(request.headers);
  headers.set('Authorization', 'Apikey incorrect-token');
  const unauthorizedRequest = new Request(request, { headers });

  const response = await worker.fetch(unauthorizedRequest, env);
  assert.equal(response.status, 401);
  assert.equal(commitCount, 1);
});
