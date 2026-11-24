[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/shoutrrr?utm_medium=integration&utm_source=button&utm_campaign=shoutrrr)

# Shoutrrr on Railway

Shoutrrr is an open-source social media scheduler from the Coolify team, an alternative to Buffer, Typefully and Hootsuite. You write a post once and publish or schedule it to X, Bluesky, LinkedIn, Facebook Pages, Instagram, Threads and Discord from one calendar, with workspaces and roles for teams.

## About Hosting Shoutrrr

This template runs Shoutrrr 1.5.9 as one Railway service, built from the official image pinned by digest. One container runs the web app (Laravel Octane on FrankenPHP), the queue worker that publishes posts and the scheduler that sends queued posts on time. Data lives in SQLite on one Railway volume, together with uploaded media and the API key pair, so it survives redeploys. On first boot the start script runs the migrations and creates your owner account before the web port opens, so public sign-up stays closed. Social networks are connected later in the app, with your own developer app keys where a network needs them.

## Common Use Cases

* Write a post once and publish it to several social accounts at the same time
* Keep a posting queue with recurring time slots and a month calendar
* Separate clients or brands into workspaces and invite teammates by email

## Dependencies for Shoutrrr Hosting

* One Railway service built from the template's GitHub repo, with a volume for the database and media
* Developer app keys for X, LinkedIn, Facebook/Instagram or Threads if you want to connect those networks (Bluesky and Discord need none)

### Deployment Dependencies

* Shoutrrr source and docs: https://github.com/coollabsio/shoutrrr
* Shoutrrr 1.5.9 release: https://github.com/coollabsio/shoutrrr/releases/tag/v1.5.9
* Template repo: https://github.com/aalfath/shoutrrr-railway-template

### Implementation Details

**After deploy:** open the service's Railway URL and sign in as `admin@example.com` with the password in the `SHOUTRRR_ADMIN_PASSWORD` variable. Change the email and password under Settings. Invite teammates from your workspace; open sign-up stays off (you can turn it on in the instance settings).

**What the template sets for you:** `APP_KEY` (generated, keep it: it encrypts stored social tokens), `APP_URL` (your Railway domain), the owner account, HTTPS behind Railway's proxy, and worker and memory sizes read from the service's limits. It fits Railway's 0.5 GB Free plan limit (about 140 MB idle).

**Connecting networks:** Bluesky (app password) and Discord (channel webhook) work right away. For X, LinkedIn, Facebook/Instagram and Threads, create a developer app with the network, add the callback `https://YOUR-DOMAIN/accounts/callback/x` (or `/linkedin`, `/meta`, `/threads`), then add `X_CLIENT_ID` and `X_CLIENT_SECRET` (or `LINKEDIN_…`, `FACEBOOK_…`, `THREADS_…`) as service variables and redeploy. Email invites need SMTP variables (`MAIL_MAILER=smtp`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM_ADDRESS`).

**Updates:** the service builds from the template's GitHub repo, so Railway shows you an update notice when we move it to a newer Shoutrrr release. Read the repo's CHANGELOG, then apply it; migrations run on start.

## What this repo contains

| File | Purpose |
|---|---|
| `Dockerfile` | `FROM ghcr.io/coollabsio/shoutrrr:1.5.9@sha256:a5835ba9255d9ba17e2fbd98efd6c1ea5c83114df9b9ba07cb50fc05d090118d` plus the wrapper below; fixed settings for Railway as `ENV` |
| `railway/start.sh` | Start script: sizes Octane workers and the PHP memory limit from the service's CPU and memory limits, checks `APP_KEY` and `APP_URL`, fixes volume ownership, then runs the upstream entrypoint and supervisord as `www-data`. Exits non-zero on any unexpected stop so Railway's `ON_FAILURE` restart policy brings it back |
| `railway/60-railway-owner.sh`, `railway/bootstrap-owner.php` | First boot: creates the instance owner from `SHOUTRRR_ADMIN_EMAIL` / `SHOUTRRR_ADMIN_PASSWORD` after migrations and before the web port opens. If it fails, the container stops |
| `railway/supervisord.conf` | Web server (Octane on `$PORT`), queue worker and scheduler; a program that keeps crashing stops the container |
| `railway/ffmpeg.sh` | Caps ffmpeg threads (GIF to MP4 for Bluesky) to the service's CPUs |

## Variables

| Variable | Default | Notes |
|---|---|---|
| `APP_KEY` | `${{secret(32)}}` | Encrypts sessions and stored social tokens. Don't change it after the first boot |
| `APP_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL, used for links and OAuth callbacks. Change it if you add a custom domain |
| `SHOUTRRR_ADMIN_EMAIL` | `admin@example.com` | Owner account created on first boot |
| `SHOUTRRR_ADMIN_PASSWORD` | `${{secret(24)}}` | Its password; only read on first boot |
| `PORT` | `8080` | Port Octane listens on |

Optional: `X_CLIENT_ID`/`X_CLIENT_SECRET`, `LINKEDIN_…`, `FACEBOOK_…`, `THREADS_…` for those networks, `MAIL_…` for email, `FILESYSTEM_DISK=s3` with `AWS_…` for object storage, `OCTANE_WORKERS` and `SHOUTRRR_PHP_MEMORY_LIMIT` to override the automatic sizing. See upstream's [`.env.example.prod`](https://github.com/coollabsio/shoutrrr/blob/v1.5.9/.env.example.prod).

## Resources

Runs within Railway's 0.5 GB / 1 vCPU Free plan limit: about 140–160 MB of app memory after normal use, 2 Octane workers, PHP memory limit 256M below 1 GB of RAM. Large video uploads go straight to disk, so they don't need more RAM, but keep an eye on the volume size.

## Updates

Railway notifies everyone who deployed this template when `main` changes. We bump the pinned image here (patch and minor Shoutrrr releases), with notes in [CHANGELOG.md](CHANGELOG.md). Migrations run automatically on start. Back up the volume before a major version.

## Licence

The wrapper in this repo is MIT. Shoutrrr itself is Apache-2.0, © coollabsio.
