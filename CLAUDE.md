# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Tablero Expediciones** is a real-time logistics dashboard for Solaufil, managing shipment tracking (expeditions/parcels). It is a zero-dependency single-page application — everything lives in one `index.html` file (~885 lines) with embedded CSS and JavaScript. There is no build step, no package manager, and no test suite.

## Running the App

Open `index.html` directly in a browser, or serve it locally:

```bash
python3 -m http.server 8080
# then visit http://localhost:8080
```

No installation, compilation, or environment setup is required. All dependencies are loaded via CDN (Supabase JS client, Google Fonts).

## Architecture

### Single-file structure (`index.html`)

| Lines | Content |
|-------|---------|
| 1–8 | HTML head, CDN imports |
| 9–391 | `<style>` — all CSS |
| 392–536 | HTML body (login modal, KPI cards, table, modals, history panel) |
| 537–883 | `<script>` — all JavaScript |

### Backend: Supabase

Credentials are hardcoded at the top of the `<script>` block:
```js
const SUPABASE_URL = 'https://ojjcyizjcofbdynrwpql.supabase.co';
const SUPABASE_KEY = 'sb_publishable_...';
```
The key is a publishable (anon) key; Row Level Security enforces that only authenticated users can read/write data (`update_rls.sql` tightened this from the original open policy in `setup.sql`).

### Database schema

**`expediciones`** — active shipments:
- `id` uuid PK, `fecha` date, `dest` text (destination), `factura` text (invoice), `palets` int (total pallets), `p_ubicar` int (pallets still to locate), `calle` text (warehouse aisle), `obs` text (notes), `estado` text CHECK (`'pendiente'|'ok'|'tarde'`)

**`historial_cierres`** — snapshots created when the board is "cleared":
- `id` uuid, `cerrado_at` timestamptz, `total_facturas`, `total_palets`, `total_pendientes` int, `expediciones` jsonb (full snapshot)

Both tables have RLS enabled. Realtime is enabled on `expediciones` for cross-tab sync.

### Real-time sync pattern

```js
sb.channel('expediciones-sync')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'expediciones' }, () => {
    // Only reload if the user is not actively typing in an input
    const active = document.activeElement;
    if (!active || !['INPUT','SELECT','TEXTAREA'].includes(active.tagName)) loadData();
  }).subscribe();
```

### Key JavaScript conventions

- **XSS prevention**: all user-generated content rendered through `esc()` (HTML-escapes `&`, `<`, `>`, `"`, `'`).
- **Inline editing**: table cells use `contenteditable` or `<select>` with `blur`/`change` event listeners that call Supabase `update` directly — there is no intermediate state layer.
- **KPIs**: computed on the fly from the in-memory `data` array after every load; never stored separately.
- **Mobile vs desktop**: a `renderMobile()` path generates card-based HTML (shown below 700 px); `renderTable()` builds `<tr>` rows (shown above 700 px). Both are called on every `loadData()`.

### CSS conventions

- CSS custom properties (variables) defined on `:root` for the entire dark theme.
- Accent colors: `--accent` `#00e5a0` (cyan), `--blue` `#0099ff`.
- Animations (`fade-up`, `pulse`, `spin`) are defined as `@keyframes` and applied with utility classes.
- No CSS preprocessor — plain CSS only.

## Database migrations

To apply schema changes, run the SQL files directly in the Supabase SQL editor or via the Supabase CLI:

```bash
# Initial schema
supabase db push  # or paste setup.sql into the dashboard SQL editor

# Tighten RLS to require authentication
# paste update_rls.sql into the dashboard SQL editor
```

`setup.sql` creates tables and enables realtime. `update_rls.sql` drops the public-access policy and replaces it with an authenticated-users-only policy.
