# Local Source Overrides

Put forked upstream projects here when you are ready to customize them.

Recommended layout:

```text
services/
  new-api/
  sub2api/
  open-webui/
```

Current imported source directories:

- `new-api`: Calcium-Ion/new-api
- `sub2api`: Wei-Shaw/sub2api
- `open-webui`: open-webui/open-webui

Keep the default deployment on published images first. When you need custom features such as payment integration, UI changes, or new admin flows, enable `infra/docker-compose.source.example.yml` as a Compose override, or copy it to `infra/docker-compose.source.yml` and adjust only the services you want to build locally.
