# Axiora Account unified login plan

This note records the current authentication surface and the safest path toward a unified Axiora Account.

## Current portal

- The public Axiora site is a static Caddy-served portal in `infra/portal`.
- There is no portal backend, user database, password hashing, email verification, or session service yet.
- The new `/register/` page is intentionally front-end only. It does not write users anywhere.

## Current services

| Service | Current auth | SSO / external auth evidence | User provisioning option | Notes |
| --- | --- | --- | --- | --- |
| Sub2API | Local email/password plus admin-created setup | Source includes OIDC login settings and `/api/v1/auth/oauth/oidc/*` routes. It also exposes normal `/api/v1/auth/register` and `/api/v1/auth/login`. | Likely possible through its auth APIs or admin integration API after confirming required payload/auth. | Best candidate for OIDC with Keycloak/Authentik. Do not merge its DB with other services. |
| New API | Local username/password, admin user creation, built-in OAuth providers | Source includes `oauth/oidc.go`, generic OAuth provider support, GitHub/LinuxDO/Telegram/etc., plus `controller.Register` and admin `CreateUser`. | Possible through existing registration endpoint or admin create-user endpoint, but permissions and settings must be respected. | Good candidate for OIDC. Needs admin configuration and callback URL validation. |
| LiteLLM | UI username/password plus master-key protected API | Official LiteLLM docs describe Admin UI SSO/OIDC providers and `/sso/callback`. Current container has no SSO env configured. | LiteLLM has management APIs for users/keys; exact provisioning should be scripted through official proxy APIs. | SSO availability depends on LiteLLM version/licensing limits. Keep local admin login enabled. |
| Open WebUI | Local signup/login currently enabled by default behavior | Source supports OIDC/OAuth (`OPENID_PROVIDER_URL`, `ENABLE_OAUTH_SIGNUP`), LDAP, trusted header auth, and SCIM. | Possible through signup API, OAuth auto-signup, LDAP, or SCIM. | Strong candidate for OIDC or SCIM. Header auth is powerful but riskier behind public proxy. |

## Options considered

1. **OAuth2 / OIDC / SSO**
   - Best long-term fit.
   - Use Keycloak or Authentik as the Axiora Account identity provider.
   - Configure each service as an OIDC client where supported.

2. **External authentication**
   - Open WebUI supports external auth patterns such as OIDC, LDAP, trusted headers, and SCIM.
   - Sub2API and New API have OIDC/login source code support.
   - LiteLLM supports SSO for its Admin UI through documented environment variables.

3. **Reverse-proxy authentication**
   - Authelia/Authentik forward-auth can protect entrypoints, but it does not automatically create native users inside each service.
   - This is useful as a gate, not enough by itself for service-level accounts, quotas, billing, or API keys.

4. **API-created users**
   - Practical as a bridge: Axiora Account registration calls per-service APIs to create users on first login.
   - Must handle duplicate emails, password rotation, service-specific roles, and failures.

5. **Shared database user tables**
   - Not recommended.
   - The four services have different schemas, password hashing, roles, sessions, billing, and migrations.

6. **LDAP / Authentik / Keycloak / Authelia**
   - Recommended: Keycloak or Authentik as OIDC provider.
   - Authelia is better for reverse-proxy gatekeeping than app-native provisioning.
   - Keycloak/Authentik gives a real account center, user lifecycle, email verification, groups, and OIDC clients.

## Recommended phased plan

### Phase 1: Portal shell

- Keep the four services unchanged.
- Add `Register` and `/register/` to Axiora.
- Make it clear the account backend is not connected yet.

### Phase 2: Identity provider

- Add `authentik` or `keycloak` to Docker Compose as `account.axiora`.
- Use it as Axiora Account.
- Configure email, password policy, password reset, and admin account.

### Phase 3: OIDC per service

- Configure Sub2API OIDC.
- Configure New API OIDC.
- Configure Open WebUI OIDC with OAuth signup enabled.
- Configure LiteLLM Admin UI SSO if licensing/version permits.
- Keep existing local admin/password login enabled for recovery.

### Phase 4: Provisioning and billing bridge

- Add an Axiora Account backend only after the identity provider is stable.
- On first login or registration webhook, create or sync service users through APIs.
- Do not share or merge service databases.

## Main risks

- LiteLLM SSO may have version or license limitations.
- Password synchronization is weaker than OIDC; avoid storing the same password in four databases.
- Reverse-proxy auth alone does not create billing/API identities inside the apps.
- Header-based auth must be locked down so clients cannot spoof identity headers.
- Service API provisioning can partially fail and needs retry/audit logic.
