# Survivor

An online Survivor-style game for a host and a group of friends. See [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) for how the game plays and [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) for the engineering spec.

## Stack

Rails 8 + Hotwire, Postgres via [Supabase](https://supabase.com) (free tier), file storage via [Cloudflare R2](https://developers.cloudflare.com/r2/) (free tier), email via [Resend](https://resend.com) (free tier), hosted on [Render](https://render.com) (free tier). No Redis, no background worker process, no WebSockets — see the architecture plan for why.

## Local setup

1. `bundle install`
2. Copy `.env.example` to `.env` and fill in a Supabase dev project's connection string at minimum (`DATABASE_URL`) — see the one-time account setup below.
3. `bin/rails db:prepare`
4. `bin/dev` (or `bin/rails server`)

## One-time account setup (do this yourself — these are your accounts)

Each of these has a genuinely-free tier at this app's scale (see docs/plan for the specific limits and gotchas):

1. **Supabase** — create two projects: `survivor-dev` and `survivor-prod`. Grab each project's pooled connection string (Settings → Database → Connection string → "Transaction pooler" mode) — dev's goes in your local `.env`, prod's goes in Render's environment variables as `DATABASE_URL`.
2. **Cloudflare R2** — create a bucket (e.g. `survivor-prod`, and optionally `survivor-dev`), then an R2 API token (Manage API Tokens) for `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` / `R2_ENDPOINT`.
3. **Resend** — create an API key for `RESEND_API_KEY`. Verify a sending domain (or use their sandbox domain to start).
4. **Render** — create a new Web Service from this repo (it'll pick up `render.yaml`). Set the env vars marked `sync: false` in `render.yaml` in the Render dashboard: `RAILS_MASTER_KEY` (from `config/master.key`, generated locally — keep this file out of git, which `.gitignore` already handles), `DATABASE_URL` (prod), the `R2_*` vars, `RESEND_API_KEY`, `SCHEDULER_TOKEN` (any long random string — `bin/rails secret | cut -c1-40` works), and `APP_HOST` (the `*.onrender.com` domain Render assigns, once you know it).
5. **GitHub** — push this repo to a GitHub repo, then add two Actions secrets (Settings → Secrets and variables → Actions): `APP_URL` (your Render app's URL) and `SCHEDULER_TOKEN` (same value as in Render). This makes `.github/workflows/scheduler.yml` start firing every 20 minutes.
6. **cron-job.org** (backup pinger, optional but recommended) — free account, one job hitting `POST https://<your-app>.onrender.com/internal/scheduler/run` with header `Authorization: Bearer <SCHEDULER_TOKEN>` every ~20 minutes. Insurance against GitHub Actions disabling the schedule after 60 days of repo inactivity.
