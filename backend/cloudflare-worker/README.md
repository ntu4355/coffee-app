# SePay top-up webhook

This Worker creates authenticated top-up requests, checks SePay incoming-transfer
webhooks, and credits a user's Firestore wallet atomically. It is designed for
the QDT Coffee project and its wallet balance unit (1 balance unit = 1,000 VND).
Cloudflare Workers Free and Firebase/Google free quotas may cover a small project,
but provider limits and eligibility can change; monitor usage and do not treat
the free tier as a guaranteed zero-cost payment service.

## Configure Firebase credentials

1. In Google Cloud Console, create a dedicated service account for this Worker.
2. Enable the Cloud Firestore API and grant the service account the minimum
   Firestore data access role needed for the project (`Cloud Datastore User`).
   The key can read and write project Firestore data, so keep it private and
   rotate it immediately if it is exposed.
3. Create a service-account key and keep the downloaded JSON outside the repo.
4. Set the Worker secrets from `backend/cloudflare-worker`:

   ```powershell
   npx wrangler secret put GOOGLE_SERVICE_ACCOUNT_EMAIL
   npx wrangler secret put GOOGLE_PRIVATE_KEY
   npx wrangler secret put SEPAY_WEBHOOK_TOKEN
   ```

   Use the service account's `client_email` and full `private_key` values.
   Configure SePay's webhook authentication as **API Key** using the same
   `SEPAY_WEBHOOK_TOKEN`; SePay sends `Authorization: Apikey <token>`.
5. `FIREBASE_API_KEY` in `wrangler.toml` is set to this project's Firebase Web
   API key. It identifies the project for Firebase ID-token verification; it is
   not a service-account credential.

## Deploy and connect the Flutter app

```powershell
npm install
npx wrangler login
npm run deploy
```

Set the deployed Worker URL when running/building Flutter:

```powershell
flutter run --dart-define=TOPUP_API_BASE_URL=https://coffee-app-topup-webhook.<account>.workers.dev
```

On Android Studio/VS Code, pass the same value in the Flutter run configuration
as an additional argument. After changing this value, stop and restart the app;
hot reload does not change compile-time `--dart-define` values. For a release
build, pass it to the build command as well:

```powershell
flutter build apk --dart-define=TOPUP_API_BASE_URL=https://coffee-app-topup-webhook.<account>.workers.dev
```

In the SePay dashboard, configure a webhook pointing to
`https://<worker-host>/webhook/sepay` for **incoming transfers only** and
select API Key authentication. Keep the API key in Cloudflare Worker secrets.

## Processing behavior

- The app must be signed in with Firebase Auth to create/check its own top-up.
- The Worker creates a unique reference with an exact amount and ten-minute QR
  display deadline. The expiration hides the QR in the app; it cannot invalidate
  a bank transfer QR already saved by the user. A matching late-arriving bank
  transfer is still credited to avoid losing a completed payment.
- Only incoming transfers to the configured MB Bank account with the exact
  amount and reference are eligible.
- SePay transaction IDs are recorded with a create-only Firestore precondition.
  The wallet increment, transaction record, and top-up state are committed
  atomically, so webhook retries cannot credit the same bank transaction twice.
- Wallet values and transaction amounts are stored in thousands of VND to match
  the existing app model. Top-ups are therefore restricted to multiples of
  1,000 VND.
- A mismatched amount/reference is not credited. Check Worker logs and resolve
  those payments manually.

The application needs the Worker URL at build/run time. Do not commit the
service-account key, SePay token, `.dev.vars`, or a deployed credentials file.

Before using real money, review Firestore Security Rules. The existing app
performs wallet deductions from the client; automatic top-ups are server-side,
but client-side balance writes must not be allowed to bypass the payment flow.
