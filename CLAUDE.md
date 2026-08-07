# Instrucciones para el Agente

> Este archivo está replicado en CLAUDE.md, AGENTS.md y GEMINI.md para que las mismas instrucciones carguen en cualquier entorno de IA.

## Aprendizajes del Agente (Mejora Continua)

> **INSTRUCCIÓN CRÍTICA — LEER PRIMERO:** Esta sección es tu memoria persistente de mejora continua. **Con cada ciclo de ejecución** (al completar una tarea, resolver un error, descubrir un patrón, o ajustar un flujo) **y con cada actualización de cualquier Markdown** (directivas, CLAUDE.md, AGENTS.md, GEMINI.md, READMEs de scripts), **debes agregar aquí un aprendizaje nuevo** si surgió algo no trivial. El objetivo es que este archivo se vuelva más útil y preciso con el tiempo, acumulando conocimiento del proyecto que no se pierde entre sesiones.
>
> **Qué registrar:** restricciones de APIs descubiertas, rate limits reales, patrones que funcionan, errores que se repiten, decisiones de diseño tomadas con el usuario, supuestos que resultaron falsos, atajos útiles, gotchas del entorno.
>
> **Qué NO registrar:** detalles efímeros de una sola tarea, información ya documentada en la directiva correspondiente, cosas triviales derivables del código.
>
> **Formato de cada aprendizaje:**
> ```
> - **YYYY-MM-DD — [Tema corto]:** Descripción del aprendizaje en 1-3 líneas. **Por qué importa:** consecuencia práctica o cómo aplicarlo en el futuro.
> ```
>
> **Higiene:** si un aprendizaje queda obsoleto o se contradice con otro más reciente, actualízalo o elimínalo en vez de acumular ruido. Mantén la lista ordenada por fecha (más recientes arriba). Si superas ~25 entradas, consolida las más antiguas o promuévelas a la directiva que corresponda.

### Registro de aprendizajes

- **2026-08-07 — CDN bloqueado en el entorno cloud:** El navegador del sandbox no pasa por el proxy HTTPS, así que jsdelivr y Google Fonts fallan y `supabase is not defined` rompe el `<script>` entero (las funciones declaradas siguen existiendo, pero los `let` quedan en TDZ). **Por qué importa:** para probar `index.html` con Playwright hay que interceptar `**/cdn.jsdelivr.net/**` con un stub de `supabase.createClient`, y lanzar Chromium con `executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome'`.
- **2026-08-07 — `palets` es el total original, nunca se descuenta:** La invariante del tablero es `ubicados + p_ubicar = palets`; editar Ubicados o P. por ubicar recalcula el otro. **Por qué importa:** si `palets` se descontara al ubicar, esa columna sería idéntica a `p_ubicar` y los KPIs "Total Palets" y "Pendientes Ubicar" medirían exactamente lo mismo.
- **2026-08-07 — Arquitectura de agente inicializada:** Se creó la estructura de 3 capas (`directives/`, `execution/`, `.tmp/`) en el repo Expediciones. **Por qué importa:** el agente debe buscar directivas en `directives/` y scripts en `execution/` antes de improvisar soluciones ad-hoc.

<!-- Agrega nuevas entradas arriba de esta línea. -->

---

Tú operas dentro de una arquitectura de 3 capas que separa responsabilidades para maximizar la confiabilidad. Los LLMs son probabilísticos, mientras que la mayoría de la lógica de negocio es determinista y requiere consistencia. Este sistema resuelve esa incompatibilidad.

## La Arquitectura de 3 Capas

**Capa 1: Directiva (Qué hacer)**
- Básicamente son SOPs escritos en Markdown, ubicados en `directives/`
- Definen los objetivos, entradas, herramientas/scripts a usar, salidas y casos extremos
- Instrucciones en lenguaje natural, como las que le daría a un empleado de nivel medio

**Capa 2: Orquestación (Toma de decisiones)**
- Esta es tu función. Tu trabajo: enrutamiento inteligente.
- Leer directivas, llamar herramientas de ejecución en el orden correcto, manejar errores, pedir aclaraciones, actualizar directivas con los aprendizajes
- Tú eres el puente entre la intención y la ejecución. Por ejemplo, no intentes hacer scraping de sitios web por tu cuenta — lee la directiva correspondiente en `directives/`, define entradas/salidas y luego ejecuta el script en `execution/`

**Capa 3: Ejecución (Hacer el trabajo)**
- Scripts de Python deterministas en `execution/`
- Variables de entorno, tokens de API, etc. se almacenan en `.env`
- Manejan llamadas a APIs, procesamiento de datos, operaciones de archivos e interacciones con bases de datos
- Confiables, testeables, rápidos. Usa scripts en vez de trabajo manual.

**Por qué funciona esto:** si tú haces todo por tu cuenta, los errores se acumulan. Un 90% de precisión por paso = 59% de éxito en 5 pasos. La solución es empujar la complejidad hacia código determinista. Así tú te concentras solo en la toma de decisiones.

## Principios de Operación

**1. Revisa primero si existen herramientas**
Antes de escribir un script, revisa `execution/` según tu directiva. Solo crea scripts nuevos si no existe ninguno.

**2. Auto-corrección cuando algo falla**
- Lee el mensaje de error y el stack trace
- Corrige el script y pruébalo de nuevo (a menos que use tokens/créditos de pago — en ese caso consulta primero con el usuario)
- Actualiza la directiva con lo que aprendiste (límites o rate limits de API, tiempos, casos extremos)
- Ejemplo: si llegas al rate limit de una API → investigas la API → encuentras un endpoint batch que soluciona el problema → reescribes el script → pruebas → actualizas la directiva.

**3. Actualiza las directivas a medida que aprendes**
Las directivas son documentos vivos. Cuando descubras restricciones de API, mejores enfoques, errores comunes o expectativas de tiempo — actualiza la directiva. Pero no crees ni sobreescribas directivas sin preguntar, a menos que se te indique explícitamente. Las directivas son tu conjunto de instrucciones y deben preservarse y mejorarse con el tiempo.

## Ciclo de Auto-corrección

Los errores son oportunidades de aprendizaje. Cuando algo falla:
1. Corrige el problema
2. Actualiza la herramienta
3. Prueba la herramienta, asegúrate de que funcione
4. Actualiza la directiva con el nuevo flujo
5. El sistema ahora es más robusto

## Organización de Archivos

**Estructura de directorios:**
- `.tmp/` - Todos los archivos intermedios (datos scrapeados, exportaciones temporales). Nunca se suben al repositorio, siempre se regeneran.
- `execution/` - Scripts de Python (las herramientas deterministas).
- `directives/` - SOPs en Markdown (el conjunto de instrucciones).
- `.env` - Variables de entorno y claves de API.
- `credentials.json`, `token.json` - Credenciales de OAuth de Google (solo cuando el flujo los requiera; en `.gitignore`).

**Principio clave:** Los archivos intermedios viven en `.tmp/` y pueden borrarse siempre. Cualquier salida del flujo debe ser reproducible ejecutando el flujo de nuevo, nunca editada a mano.

## Resumen

Tú estás entre la intención humana (directivas) y la ejecución determinista (scripts de Python). Lee instrucciones, toma decisiones, llama herramientas, maneja errores y mejora el sistema continuamente.

Sé pragmático. Sé confiable. Auto-corríjete.

---

# Documentación del Proyecto: Tablero Expediciones

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
- `id` uuid PK, `fecha` date, `dest` text (destination), `factura` text (invoice), `palets` int (**original** invoice total — never decremented), `ubicados` int (pallets already located), `p_ubicar` int (pallets still to locate), `calle` text (warehouse aisle), `obs` text (notes), `estado` text CHECK (`'en_transito'|'recepcion'|'en_preparacion'|'completado'`)
- **Invariant**: `ubicados + p_ubicar = palets`, enforced both in JS (`editarReposicion`, `guardarFila`) and by the `expediciones_coherencia_check` constraint.

### Estado flow

`en_transito` → `recepcion` → `en_preparacion` → `completado`

UI labels differ from the DB values: `en_preparacion` displays as **"Reponer"** and `completado` as **"Completo"**. `normEstado()` maps legacy values (`pendiente`/`ok`/`tarde`) onto the current set, so old `historial_cierres` snapshots still render.

| Estado | Total Palets | Ubicados / P. por ubicar |
|--------|--------------|--------------------------|
| En tránsito | locked (pencil unlocks) | locked |
| Recepción | locked (pencil unlocks) | locked |
| Reponer | locked (pencil unlocks) | **editable** |
| Completo | — archives the invoice immediately | — |

Reaching `p_ubicar = 0` in Reponer auto-archives the invoice: it moves to `historial_cierres` and disappears from the board.

**`historial_cierres`** — snapshots created when the board is "cleared":
- `id` uuid, `cerrado_at` timestamptz, `total_facturas`, `total_palets`, `total_pendientes` int, `expediciones` jsonb (full snapshot)

**`historial_ubicados_dia`** — daily located-pallet count:
- `id` uuid, `fecha` date UNIQUE, `palets_ubicados` int, `nota` text

All tables have RLS enabled. Realtime is enabled on `expediciones` for cross-tab sync.

### Key JavaScript conventions

- **XSS prevention**: all user-generated content rendered through `esc()` (HTML-escapes `&`, `<`, `>`, `"`, `'`).
- **Pencil-edit mode**: gated fields (fecha, dest, factura, **palets**, calle, obs) are `disabled` by default; clicking the pencil icon calls `toggleEditRow(i)` to enable them and show a save button. `palets` is only ever editable through the pencil (in any estado) or at registration — never inline. Saving routes through `guardarFila()`, which rewrites `p_ubicar` from the new total while preserving `ubicados`.
- **Coupled editing of ubicados / p_ubicar**: blur on either input calls `editarReposicion(i, campo, val)`. It clamps the value to `[0, palets]`, derives the other field, persists both in one update, applies the difference to today's `historial_ubicados_dia` row, and auto-archives when `p_ubicar` hits 0. Editing is only enabled in `en_preparacion`.
- **KPIs**: computed on the fly from the in-memory `data` array after every load. `kpiHoy` reads today's row from `historial_ubicados_dia`. `Total Palets`, `Pendientes Ubicar` and `Ubicados` are scoped to `en_preparacion` rows only; `Palets en Tránsito` and `Palets en Recepción` sum `palets` for their respective estados.
- **Historial panels**: data loaded once into `histAllCierres` / `histAllUbicados`; client-side `filterByDate()` re-renders the filtered accordion without extra DB calls.
- **Mobile vs desktop**: `renderMobile()` generates card-based HTML (shown below 700 px); `renderTable()` builds `<tr>` rows (shown above 700 px). Both are called on every `loadData()`.

### CSS conventions

- CSS custom properties (variables) defined on `:root` for the entire dark theme.
- Accent colors: `--accent` `#00e5a0` (cyan), `--blue` `#0099ff`.
- Animations (`fade-up`, `pulse`, `spin`) are defined as `@keyframes` and applied with utility classes.
- No CSS preprocessor — plain CSS only.

## Recent changes (context)

- **New `recepcion` estado + `Reponer`/`Completo` labels** — the flow is now `en_transito → recepcion → en_preparacion → completado`. Recepción behaves exactly like tránsito (everything locked); it only records that the goods arrived. DB values were left untouched apart from adding `recepcion`, so no historical data had to be migrated.
- **New `Ubicados` column** — coupled to `P. por ubicar` so that `ubicados + p_ubicar = palets` always holds. Entering either one derives the other, which makes states like "8 located + 5 pending on a 10-pallet invoice" unrepresentable.
- **`Total Palets` is now read-only on the board** — it holds the original invoice total and is only editable at registration or through the pencil. It no longer counts down, which keeps it distinct from `P. por ubicar`.
- **Auto-archive at zero** — when `p_ubicar` reaches 0 the invoice is snapshotted to `historial_cierres` and removed from the board without any extra click.
- **New KPI "Palets en Recepción"** — sums `palets` across `recepcion` rows. The KPI grid switched to `auto-fit`/`minmax` to absorb the sixth card.
- **KPI "Ubicados Hoy" bidirectional** — `editarReposicion` computes `delta = nuevoUbicados - ubicadosPrevios`; applies positive (more located) or negative (un-located) delta to today's `historial_ubicados_dia` row; result clamped to ≥ 0.
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

Apply them in this order:

| File | What it does |
|------|--------------|
| `setup.sql` | Creates tables, enables realtime |
| `update_rls.sql` | Replaces the public-access policy with an authenticated-users-only one |
| `alter_estados.sql` | Migrates the legacy `pendiente/ok/tarde` values to `en_transito/completado/en_preparacion` |
| `create_historial_ubicados.sql`, `add_nota_historial_ubicados.sql` | Daily located-pallet table and its `nota` column |
| `add_recepcion_ubicados.sql` | Adds the `recepcion` estado, the `ubicados` column, backfills existing rows and enforces the coherence constraint |

`add_recepcion_ubicados.sql` is idempotent and safe to re-run. Its last statement adds `expediciones_coherencia_check`; skip that block if you would rather validate the invariant only in the app.
