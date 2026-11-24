# Changelog

## 1.5.9 (2026-11-24)

- First release of the Railway template: Shoutrrr 1.5.9 (`ghcr.io/coollabsio/shoutrrr:1.5.9@sha256:a5835ba9255d9ba17e2fbd98efd6c1ea5c83114df9b9ba07cb50fc05d090118d`).
- One service with SQLite, media and API keys on one volume at `/var/www/html/storage`.
- Owner account created on first boot from generated variables; public sign-up stays closed.
- Worker count and PHP memory sized from the service's limits; fits the 0.5 GB Free plan.
- Unexpected stops exit non-zero so Railway restarts the service.
- Deploy on Railway button in the README.
