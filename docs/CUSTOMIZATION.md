# Customization Plan

The deployment is designed so you can start with stable upstream images and later switch individual services to local source builds.

## Recommended Path

1. Run the platform with official/community images.
2. Confirm domains, data persistence, HTTPS, and service-to-service traffic.
3. Fork only the services you need to change.
4. Put source code under `services/<service-name>`.
5. Copy `infra/docker-compose.source.example.yml` to `infra/docker-compose.source.yml`.
6. Enable local builds with:

```bash
cd infra
docker compose --env-file ../.env -f docker-compose.yml -f docker-compose.source.yml up -d --build
```

Or use the helper script from the project root:

```bash
./scripts/deploy-source.sh
```

## Service Ownership

- `portal`: best place for your brand website, public pricing page, onboarding page, and links to dashboards.
- `new-api`: suitable for API relay, token/credit rules, channel management, and simple user-facing API billing behavior.
- `sub2api`: suitable for lightweight subscription-to-API user flows.
- `litellm`: suitable for enterprise routing, provider abstraction, usage logs, budgets, and model policy.
- `open-webui`: suitable for chat UI customization and user experience changes.

See `docs/SOURCE_IMPORTS.md` for the current imported upstream source directories and the recommended path for replacing zip imports with your own forks.

## Payment Integration

Do not put payment keys in source code or Compose files.

Use `.env` variables such as:

```env
PAYMENT_PROVIDER=stripe
STRIPE_SECRET_KEY=change-me-stripe-secret-key
STRIPE_WEBHOOK_SECRET=change-me-stripe-webhook-secret
PAYMENT_SUCCESS_URL=https://example.com/billing/success
PAYMENT_CANCEL_URL=https://example.com/billing/cancel
```

Then pass only the variables needed by the service you customize. A practical first implementation is:

- Keep public pricing and checkout entry in `portal`.
- Handle payment webhooks in the service that owns user balance or quota.
- Update `new-api` or your own user service after successful payment.
- Keep LiteLLM focused on gateway/routing unless you explicitly want enterprise billing there.

## UI Changes

For small portal changes, edit `infra/portal/index.html`.

For product UI changes in open-source apps, fork the upstream project and build it locally through `docker-compose.source.yml`. This keeps the production deployment interface stable while giving you full control over frontend code.

## Upgrade Strategy

When using published images, pin versions after the first successful deployment:

```env
NEW_API_IMAGE=calciumion/new-api:v0.x.x
SUB2API_IMAGE=weishaw/sub2api:0.1.x
```

When using forks, track upstream in your fork and merge deliberately. Keep local changes small and documented so payment/UI changes survive upgrades.
