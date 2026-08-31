# Payment functions

The checkout flow uses two Edge Functions:

- `swift-task`: authenticated checkout initialization and status queries.
- `iyzico-callback`: public iyzico callback; deploy this function with JWT verification disabled.

Apply migration `016_create_payment_checkout_sessions.sql`, then configure these Edge Function secrets:

- `IYZICO_API_KEY`
- `IYZICO_SECRET_KEY`
- `IYZICO_BASE_URL` (`https://sandbox-api.iyzipay.com` for sandbox)
- `IYZICO_BUYER_IDENTITY_NUMBER` (required for production; sandbox falls back to iyzico's documented test value)
- `PAYMENT_RETURN_URL` (for example `https://app.example.com/#/payment-result`)
- `PAYMENT_ALLOWED_RETURN_ORIGINS` (comma-separated origins, for example `https://app.example.com,http://localhost:3000`)

Deployment commands:

```sh
supabase functions deploy swift-task
supabase functions deploy iyzico-callback --no-verify-jwt
```

The callback never trusts redirect query parameters. It retrieves the payment from iyzico, verifies the response signature, price, currency, basket, conversation and token, then calls the transactional `finalize_paid_checkout` database function. Repeated callbacks return the existing order.
