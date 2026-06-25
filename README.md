# Modular Cloud Dashboard

A multi-user admin dashboard that runs entirely on free tiers, with real
authentication, shared cloud data, and zero traditional backend server.

> **Demo project.** All data in this repository is fictional. It is a sanitized
> version of a private internal tool, published to showcase the architecture.

---

## What it does

A single-page dashboard for managing operational records (accounts, tasks, a
weekly board, a calendar, and a simple finance ledger). Several users open the
same URL, authenticate, and see and edit the **same shared data** in real time.

## Why it's interesting

The original tool was a single `index.html` that stored everything in the
browser's `localStorage`. That meant two problems: data lived only on one device
(no sharing), and sensitive values sat in plain text inside the file. The goal
was to make it multi-user and secure **without rewriting ~1,300 lines of app
logic** and **without paying for hosting or a server**.

The solution keeps the original front-end almost untouched and wraps it in a
thin cloud layer.

## Architecture

```
Browser
  │  ① Authentication happens at the edge, before the page loads
  ▼
Cloudflare Access (Zero Trust)   — real auth, free for small teams
  │  ② Only allow-listed emails get through
  ▼
Cloudflare Pages                 — static hosting (the dashboard)
  │  ③ The app calls /api/state
  ▼
Pages Function (/functions/api)  — server-side; holds the DB secret
  │  ④
  ▼
Neon (serverless Postgres)       — shared, central data store
```

Key properties:

- **Real security at the edge.** Auth sits *in front of* the file, so it can't be
  bypassed by "view source." The database connection string lives only in a
  server-side environment variable and never reaches the browser.
- **Shared data.** All users read/write the same Postgres rows.
- **Free.** Static hosting, edge auth (small teams), and a Postgres free tier.

## The interesting technical bit: a drop-in storage layer

Rather than rewriting every `localStorage` call, the cloud layer:

1. Marks the original app script as non-executing (`type="text/app-source"`).
2. On load, fetches the full state from `/api/state` and writes it into real
   `localStorage` (so the app's native reads work on every browser).
3. Injects the original app script, which now boots with real data.
4. Intercepts **writes** to keys matching `^cc_` and debounces them to the API,
   keeping the central store in sync.

This made the migration a ~50-line wrapper instead of a full rewrite.

### A real-world bug worth noting

An earlier version intercepted **reads** by overriding `localStorage.getItem`.
It worked on desktop but silently returned nothing on mobile Edge — overriding
built-in `Storage` methods isn't reliably honored across engines. The fix was to
stop intercepting reads entirely: hydrate real `localStorage` up front and let
the app read natively. Good reminder that "works on my machine" and
cross-engine behavior are different things.

## Data model

A single key-value table keeps the migration trivial:

```sql
CREATE TABLE app_state (
  key        TEXT PRIMARY KEY,   -- e.g. 'cc_accounts'
  value      TEXT NOT NULL,      -- JSON, stored verbatim
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by TEXT                -- email from the edge auth header
);
```

`updated_by` is populated from the `Cf-Access-Authenticated-User-Email` header,
giving basic audit info for free.

## Tech stack

- Vanilla JS / HTML / CSS front-end (no framework, no build step)
- Cloudflare Pages (hosting) + Pages Functions (API)
- `@neondatabase/serverless` driver (HTTP, edge-compatible)
- Neon (serverless Postgres)
- Cloudflare Access (Zero Trust) for authentication

## Run it yourself

1. **Database:** create a Postgres database (e.g. Neon). Run `schema.sql`, then
   `seed.sample.sql` for demo data. Copy the connection string.
2. **Deploy:** connect this repo to Cloudflare Pages.
   - Build command: `npm install`
   - Output directory: `public`
3. **Secret:** in the Pages project, set `DATABASE_URL` to your connection
   string (see `.env.example`).
4. **Auth (optional but recommended):** protect the site with Cloudflare Access
   and allow-list the user emails.

## Project structure

```
public/index.html        # the dashboard + cloud bootstrap
public/_headers          # cache rules
functions/api/state.js   # GET/POST state, talks to Postgres
schema.sql               # table definition
seed.sample.sql          # fictional demo data
.env.example             # shows the one secret needed
```

## Security notes

- No secrets are committed. `DATABASE_URL` is provided at runtime via env vars.
- This demo intentionally contains only fictional data.
- For a real deployment, keep the repo private or scrub any seed data, and put
  the site behind authentication.

## License

MIT — see `LICENSE`.
