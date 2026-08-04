# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Tablero Expediciones** is a real-time logistics dashboard for Solaufil, managing shipment tracking (expeditions/parcels). It is a zero-dependency single-page application — everything lives in one `index.html` file (~1460 lines) with embedded CSS and JavaScript. There is no build step, no package manager, and no test suite.

## Git Workflow

All new work goes on the feature branch; `main` only receives merges via PR.

```bash
# Start / continue work
git checkout claude/claude-md-docs-0by7ke

# After committing changes, push the feature branch
git push -u origin claude/claude-md-docs-0by7ke

# Then open a PR on GitHub to merge feature → main
# (never push directly to main)
```

## Running the App

Open `index.html` directly in a browser, or serve it locally:

```bash
python3 -m http.server 8080
# then visit http://localhost:8080
```

No installation, compilation, or environment setup is required. All dependencies are loaded via CDN (Supabase JS client, Google Fonts).

## Architecture

### Single-file structure (`index.html`)

| Section | Content |
|---------|---------|
| `<style>` | All CSS — dark theme variables, layout, table, modals, historial panels, accordion |
| `<body>` | Login modal, KPI cards, expediciones table, historial panels (facturas + ubicados) |
| `<script>` | All JavaScript — Supabase client, loadData, renderTable/renderMobile, KPI logic, historial |

### Backend: Supabase

Credentials are hardcoded at the top of the `<script>` block:
```js
const SUPABASE_URL = 'https://ojjcyizjcofbdynrwpql.supabase.co';
const SUPABASE_KEY = 'sb_publishable_...';
```
The key is a publishable (anon) key; Row Level Security enforces that only authenticated users can read/write data (`update_rls.sql` tightened this from the original open policy in `setup.sql`).

### Database schema

**`expediciones`** — active shipments:
- `id` uuid PK, `fecha` date, `dest` text (destination), `factura` text (invoice), `palets` int (total pallets), `p_ubicar` int (pallets still to locate), `calle` text (warehouse aisle), `obs` text (notes), `estado` text CHECK (`'en_preparacion'|'en_transito'|'entregado'`)

**`historial_cierres`** — snapshots created when the board is "cleared":
- `id` uuid, `cerrado_at` timestamptz, `total_facturas`, `total_palets`, `total_pendientes` int, `expediciones` jsonb (full snapshot)

**`historial_ubicados_dia`** — daily located-pallet count:
- `id` uuid, `fecha` date UNIQUE, `palets_ubicados` int, `nota` text

All tables have RLS enabled. Realtime is enabled on `expediciones` for cross-tab sync.

### Key JavaScript conventions

- **XSS prevention**: all user-generated content rendered through `esc()` (HTML-escapes `&`, `<`, `>`, `"`, `'`).
- **Pencil-edit mode**: gated fields (fecha, dest, factura, calle, obs) are `disabled` by default; clicking the pencil icon calls `toggleEditRow(i)` to enable them and show a save button. `palets` is always editable on `en_preparacion` rows; on `en_transito` rows it is locked but the pencil also unlocks it.
- **Inline editing for p_ubicar**: blur on the `ci-num` input calls `saveUbicados(i, newVal, oldVal)`, which computes the delta and updates `historial_ubicados_dia` via upsert.
- **KPIs**: computed on the fly from the in-memory `data` array after every load. `kpiHoy` reads today's row from `historial_ubicados_dia`.
- **Historial panels**: data loaded once into `histAllCierres` / `histAllUbicados`; client-side `filterByDate()` re-renders the filtered accordion without extra DB calls.
- **Mobile vs desktop**: `renderMobile()` generates card-based HTML (shown below 700 px); `renderTable()` builds `<tr>` rows (shown above 700 px). Both are called on every `loadData()`.

### CSS conventions

- CSS custom properties (variables) defined on `:root` for the entire dark theme.
- Accent colors: `--accent` `#00e5a0` (cyan), `--blue` `#0099ff`.
- Animations (`fade-up`, `pulse`, `spin`) are defined as `@keyframes` and applied with utility classes.
- No CSS preprocessor — plain CSS only.

## Recent changes (context)

- **Pencil-edit gate** — fields `fecha/dest/factura/calle/obs` disabled by default; pencil enables them + shows save button. Cancel reverts via `data-orig`.
- **`palets` editable on en_transito via pencil** — pencil now also unlocks `palets` for locked rows; blur-save is skipped while save button is visible to avoid saving before cancel.
- **KPI "Ubicados Hoy" bidirectional** — `saveUbicados` computes `delta = oldVal - newVal`; applies positive (more located) or negative (un-located) delta to today's `historial_ubicados_dia` row; result clamped to ≥ 0.
- **Accordion + ⚙ filter in both historial panels** — each item collapses to date + key stat, expands on click; gear button opens date filter bar (Todo / 3 meses / Este mes / Última semana); filtering is client-side from in-memory cache.
- **Historial facturas detail redesigned as cards** — each expedición inside a cierre shows as a 2-line card (destino + factura number on line 1, palets + estado badge on line 2) instead of a 5-column table; fits the 440 px panel without squishing. Detail scrolls vertically if many rows.

## Database migrations

To apply schema changes, run the SQL files directly in the Supabase SQL editor or via the Supabase CLI:

```bash
# Initial schema
supabase db push  # or paste setup.sql into the dashboard SQL editor

# Tighten RLS to require authentication
# paste update_rls.sql into the dashboard SQL editor
```

`setup.sql` creates tables and enables realtime. `update_rls.sql` drops the public-access policy and replaces it with an authenticated-users-only policy.
