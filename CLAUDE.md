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

- **2026-08-11 — Un color asignado por posición CSS es incompatible con reordenar elementos:** Los 6 KPI tomaban su color de `.kpi-card:nth-child(N){--kc:...}`, así que al añadir arrastrar-para-reordenar los colores se habrían barajado (la tarjeta movida adoptaba el color de su nueva posición). Hubo que mover el color a un dato por KPI (`KPI_DEFS[].color` → `style="--kc:..."` en cada tarjeta) y dejar en `nth-child` solo el `animation-delay`. **Por qué importa:** antes de hacer reordenable cualquier lista, revisar si algún estilo depende de `nth-child`/`:first-child`/`:last-child`; ese estilo debe pasar a ser un atributo del elemento, no de su posición.
- **2026-08-11 — Al permitir ocultar elementos, todo `getElementById(...).textContent = x` se vuelve una bomba:** Con los KPI ocultables, sus nodos dejan de existir y los ~11 accesos directos que había en `updateKPIs`, `renderKpiExtraUbicados`, `registrarUbicadosHoy`, `saveHistUbic` y `deleteHistUbic` lanzarían `TypeError` tumbando el render entero. Se centralizó en `setKpiText()`/`setKpiHtml()`, que comprueban existencia. **Por qué importa:** cualquier función de visibilidad opcional obliga a auditar TODOS los accesos al DOM de esos elementos, no solo el sitio obvio donde se pintan.
- **2026-08-11 — Cambiar el significado de un KPI obliga a revisar sus estadísticas derivadas:** Al pasar `Total Palets` de "solo Reponer" a "todos los estados", dos números del desplegable quedaban incoherentes sin tocarlos: el `%` de pendientes se diluía al dividir por el total global, y "Media por factura" dividía palets de todos los estados entre solo las facturas en Reponer. **Por qué importa:** un cambio de fórmula en un KPI rara vez es una línea; hay que rastrear qué otros cálculos reutilizan esa variable (aquí `totalPalets` alimentaba `pctPend` y `avg`) y decidir explícitamente si siguen el cambio o conservan el ámbito antiguo.
- **2026-08-10 — "Facturas" en la cabecera de un cierre es un contador, no el número de factura:** Primer intento hice editables `total_facturas`/`total_palets`/`total_pendientes` (los 3 agregados de la cabecera), pero el usuario aclaró que casi siempre hay una sola factura por cierre y lo que realmente quiere corregir es el **número de factura** de esa factura puntual — un dato que vive dentro de `expediciones[i].factura`, no en `total_facturas` (que es solo un conteo). **Por qué importa:** cuando un campo se llama igual a nivel de agregado y a nivel de detalle ("facturas" = cantidad vs. "factura" = identificador), preguntar explícitamente cuál de los dos quiere editar el usuario antes de implementar, en vez de asumir por la etiqueta visible más prominente (la cabecera, en este caso, era la equivocada).
- **2026-08-10 — El usuario prefirió un único lápiz/disquete por cierre en vez de uno por campo/fila:** Primer diseño le dio a cada expedición su propio lápiz (y otro aparte para la nota), lo cual exigía escopar cada control a un wrapper con id único para que no se pisaran entre sí. El usuario pidió simplificarlo: un solo lápiz que desbloquee nota + todas las expediciones del cierre a la vez, y un solo disquete que las guarde todas juntas en una llamada. **Por qué importa:** con un único par edit/save por cierre, escopar a `card.querySelector` vuelve a ser seguro (ya no hay ambigüedad de "cuál .edit-btn"); `saveCierre` recorre `card.querySelectorAll('.exp-row')` en orden para reconstruir el array `expediciones` completo y lo persiste junto con `nota` en un solo `update`.
- **2026-08-10 — La cabecera de un cierre debe recalcularse al guardar, no quedar congelada:** Primer diseño de `saveCierre` solo persistía `{ nota, expediciones }`, dejando `total_facturas`/`total_palets`/`total_pendientes` (escritos una vez al archivar) sin tocar — el usuario editaba "pendientes" de la única factura de un cierre y la cabecera seguía mostrando el valor viejo, porque son columnas separadas que nadie recalculaba. **Por qué importa:** aunque técnicamente son agregados de solo visualización que ningún KPI consulta, mostrarle al usuario un número que no refleja lo que acaba de guardar es confuso — no basta con que "no rompa nada", tiene que quedar coherente. Fix: `saveCierre` recalcula los 3 totales sumando el array `expediciones` ya editado (`exps.length`, `Σpalets`, `Σp_ubicar`) y los manda en el mismo `update`; el DOM se actualiza in-place vía `hc-fact-{id}`/`hc-pal-{id}`/`hc-pend-{id}` sin re-renderizar todo el panel (evita colapsar el acordeón o perder el scroll).
- **2026-08-10 — En los paneles de historial hay que expandir la tarjeta antes de poder editar:** los controles de edición viven dentro de `.cierre-detail`, que arranca con `max-height:0; overflow:hidden`; hasta que no se hace clic en `.cierre-head` no son alcanzables (Playwright falla con "intercepts pointer events" si se intenta clicar antes). **Por qué importa:** si el usuario reporta "no me aparece la opción de editar", la primera pregunta es si desplegó la tarjeta; y cualquier test de estos paneles debe hacer `click('.cierre-head')` + esperar la transición de 300 ms antes de tocar los botones.

- **2026-08-10 — Rama `claude/claude-md-docs-0by7ke` había quedado desactualizada respecto a `main`:** Los paneles de historial en el móvil del usuario ya mostraban paginación y colores semánticos (features de las PR #5-#9, ya fusionadas en `main`), pero esta rama seguía basada en un commit anterior a esas fusiones — el código local no coincidía con lo que el usuario realmente veía en producción. **Por qué importa:** antes de depurar un bug reportado por el usuario sobre la app en vivo, verificar primero que la rama de trabajo esté al día con `main` (`git log --oneline origin/main -5` vs `git rev-list --left-right --count origin/main...HEAD`); si no lo está, hacer merge antes de tocar nada, o el fix se aplicaría sobre código que ya no representa lo desplegado.
- **2026-08-10 — Los paneles `.historial-panel` no tenían override de ancho para móvil:** `width: 440px; right: -440px` es fijo sin media query, así que en pantallas angostas (<440px, la mayoría de celulares) el panel se abre con su borde izquierdo fuera de la pantalla, cortando el texto del lado izquierdo (títulos, fechas, labels) — visible en capturas como columnas de texto truncadas. **Por qué importa:** cualquier panel/modal con ancho fijo en px debe revisarse contra el breakpoint móvil existente (`@media (max-width:700px)`); el fix fue `width:100%; right:-100%` dentro de ese media query, verificado sin overflow horizontal en 360/375/390/412px con Playwright (`getBoundingClientRect` de todos los hijos del panel, colapsado y expandido).
- **2026-08-07 — Migraciones nuevas quedan pendientes de aplicar hasta que el usuario las pegue en Supabase:** Al agregar una columna nueva (ej. `nota` en `historial_cierres`), el código que la usa (`saveHistCierre`) se puede escribir y probar en el navegador sin que la columna exista todavía — el fallo solo aparece al intentar guardar contra la base real (error "column does not exist"). **Por qué importa:** no asumir que una migración está aplicada solo porque el código ya la usa; verificar contra Supabase (ahora tengo acceso vía Composio) o preguntar al usuario antes de dar la tarea por completa.
- **2026-08-07 — Patrón de edición reutilizable entre paneles de historial:** El patrón editar/guardar/nota (input `.ci-nota` deshabilitado + `.edit-btn` que lo habilita y muestra `.save-btn` + `.del-btn` con "✕") ya existía en Historial Ubicados por Día; para replicarlo en Historial de Facturas Anteriores bastó copiar la estructura HTML y las 2 funciones (`toggleEdit*`/`save*`) cambiando la tabla/columna de destino — no hizo falta CSS nueva. **Por qué importa:** antes de crear UI nueva para un panel de historial, revisar si el otro panel ya resolvió el mismo patrón.
- **2026-08-07 — Verificación de UI sin credenciales reales:** Para probar cambios visuales (colores por estado, KPIs) sin tener login real de Supabase, sirve levantar `python -m http.server`, abrir en el navegador, y en la consola forzar `loginScreen.classList.add('hidden')` + `appContent.classList.add('visible')`, luego asignar un `data` de prueba a mano y llamar `render()`. Las funciones globales del `<script>` son accesibles aunque el login no haya ocurrido — solo la visibilidad del DOM depende de la sesión. **Por qué importa:** permite verificar cambios de CSS/JS reales (vía `getComputedStyle`) en vez de solo razonar sobre el código, sin tocar la base de datos ni pedir credenciales al usuario.
- **2026-08-07 — KPI "Palets en Recepción" tenía la fórmula equivocada:** Sumaba `palets` (el total original de la factura) en vez de `p_ubicar` (lo que de verdad queda pendiente). Como en Recepción todo está bloqueado, en la práctica casi siempre `p_ubicar ≈ palets` en filas recién llegadas, así que el error no era obvio a simple vista salvo cuando una fila entraba a Recepción con `ubicados` ya mayor a 0. **Por qué importa:** al tocar cualquier KPI, verificar contra qué columna se agrega (`palets` = total original inmutable, `p_ubicar` = lo pendiente real) — son fáciles de confundir porque ambos son "el número grande" en la mayoría de filas.
- **2026-08-07 — Colores de estado eran una rotación arbitraria, no semántica:** `en_preparacion` (Reponer) usaba azul, `completado` usaba verde, `recepcion` usaba cyan — ninguno con relación intuitiva al significado. El usuario pidió mapeo semántico: amarillo=tránsito, azul=recepción, verde=reponer, rojo=completado/factura finalizada. Las variables CSS ya existían (`--warn`, `--accent2`, `--accent`, `--danger`) — solo hubo que reasignarlas, sin inventar colores nuevos. **Por qué importa:** hay 3 lugares que deben mantenerse sincronizados al tocar colores de estado: `ESTADO_COLOR`/`ESTADO_TEXT` (JS, usado en tarjetas móviles), `select.ci[data-v="..."]` (CSS, dropdown desktop/mobile), y `.estado-*` (CSS, badges del historial).
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

UI labels differ from the DB values: `en_preparacion` displays as **"Reponer"** and `completado` as **"Factura finalizada"**. `normEstado()` maps legacy values (`pendiente`/`ok`/`tarde`) onto the current set, so old `historial_cierres` snapshots still render. Each estado also has a fixed semantic color (`ESTADO_COLOR` in the script, mirrored in the `select.ci[data-v]` and `.estado-*` CSS rules): `en_transito` amber/`--warn`, `recepcion` blue/`--accent2`, `en_preparacion` green/`--accent`, `completado` red/`--danger`.

| Estado | Total Palets | Ubicados / P. por ubicar |
|--------|--------------|--------------------------|
| En tránsito | locked (pencil unlocks) | locked |
| Recepción | locked (pencil unlocks) | locked |
| Reponer | locked (pencil unlocks) | **editable** |
| Factura finalizada | — archives the invoice immediately | — |

Reaching `p_ubicar = 0` in Reponer auto-archives the invoice: it moves to `historial_cierres` and disappears from the board.

**`historial_cierres`** — snapshots created when the board is "cleared" (or auto-archived at zero):
- `id` uuid, `cerrado_at` timestamptz, `total_facturas`, `total_palets`, `total_pendientes` int, `expediciones` jsonb (full snapshot), `nota` text (free-text annotation on the whole cierre)
- The three `total_*` columns are **display-only aggregates**: written once when archiving, then only read to paint the cierre header. No KPI or export depends on them (the historial Excel export reads `expediciones`, not these). All four non-snapshot fields are editable from the panel, with `total_pendientes` clamped to `[0, total_palets]`; editing them does **not** rewrite the `expediciones` snapshot.

**`historial_ubicados_dia`** — daily located-pallet count:
- `id` uuid, `fecha` date UNIQUE, `palets_ubicados` int, `nota` text

All tables have RLS enabled. Realtime is enabled on `expediciones` for cross-tab sync.

### Key JavaScript conventions

- **XSS prevention**: all user-generated content rendered through `esc()` (HTML-escapes `&`, `<`, `>`, `"`, `'`).
- **Pencil-edit mode**: gated fields (fecha, dest, factura, **palets**, calle, obs) are `disabled` by default; clicking the pencil icon calls `toggleEditRow(i)` to enable them and show a save button. `palets` is only ever editable through the pencil (in any estado) or at registration — never inline. Saving routes through `guardarFila()`, which rewrites `p_ubicar` from the new total while preserving `ubicados`.
- **Coupled editing of ubicados / p_ubicar**: blur on either input calls `editarReposicion(i, campo, val)`. It clamps the value to `[0, palets]`, derives the other field, persists both in one update, applies the difference to today's `historial_ubicados_dia` row, and auto-archives when `p_ubicar` hits 0. Editing is only enabled in `en_preparacion`.
- **KPIs**: the six cards are **generated by `renderKpis()`** from the `KPI_DEFS` array (single source of truth: key, label, element ids, subtitle, default colour) — the `.kpi-grid` in the HTML is an empty container. Order, colour and visibility live in `kpiCfg` and persist to `localStorage` under `expediciones.kpiConfig.v1`; `loadKpiConfig()` merges the saved order with `KPI_DEFS` so a newly added KPI is appended instead of disappearing. **Colour is per-KPI (inline `--kc` on each card), never positional** — `.kpi-card:nth-child(N)` only carries the entry `animation-delay`, so reordering doesn't shuffle colours. Cards reorder by drag (Pointer Events, `enableKpiDrag`/`startKpiDrag`: hold ~220 ms on touch so page scroll still works, 5 px threshold with a mouse).
  Values are computed on the fly by `updateKPIs()` from the in-memory `data` array after every load. `kpiHoy` reads today's row from `historial_ubicados_dia`. `Total Palets` sums `palets` across **all** rows regardless of estado; `Pendientes Ubicar` and `Ubicados` are scoped to `en_preparacion` only; `Palets en Tránsito` sums `palets` across `en_transito` rows; `Palets en Recepción` sums `p_ubicar` (not `palets`) across `recepcion` rows, since that's what's actually still pending inside those invoices.
- **A hidden KPI is absent from the DOM**, so every write to a KPI element goes through `setKpiText()`/`setKpiHtml()`, which no-op when the element doesn't exist. Never call `document.getElementById('kpi…').textContent = …` directly — with the KPI hidden that throws and takes the whole render down with it.
- **Historial panels**: data loaded once into `histAllCierres` / `histAllUbicados`; client-side `filterByDate()` re-renders the filtered accordion without extra DB calls. Both panels share the same per-item edit pattern: the editable inputs start `disabled`, a pencil `.edit-btn` enables them and reveals a hidden `.save-btn`, and a `.del-btn` ("✕") removes the row. Canceling edit (clicking the pencil again) restores `data-orig` instead of persisting. **The edit controls live inside `.cierre-detail`, which is `max-height:0` until the card is expanded** — they are unreachable until the user clicks `.cierre-head`. **Facturas Anteriores has exactly one pencil/save pair per cierre** (`toggleEditCierre`/`saveCierre`, scoped to `#cierre-{id}`) that unlocks the cierre's `nota` **and** every expedición's `factura`/`palets`/`ubicados`/`p_ubicar` fields at once, even when a cierre holds several expediciones (from "Limpiar Pizarra"); saving recomputes `total_facturas`/`total_palets`/`total_pendientes` from the edited `expediciones` array (so the header never goes stale relative to what was just saved) and fires a single `historial_cierres` update with `{ nota, expediciones, total_facturas, total_palets, total_pendientes }`. Header `<b>` values update in place via `hc-fact-{id}`/`hc-pal-{id}`/`hc-pend-{id}` ids, no full re-render. `destino` and `estado` stay read-only. Ubicados por Día edits two fields (`.ci-palets`, `.ci-nota`) with its own pencil, unrelated to this one.
- **Mobile vs desktop**: `renderMobile()` generates card-based HTML (shown below 700 px); `renderTable()` builds `<tr>` rows (shown above 700 px). Both are called on every `loadData()`.

### CSS conventions

- CSS custom properties (variables) defined on `:root` for the entire dark theme.
- Accent colors: `--accent` `#00e5a0` (cyan), `--blue` `#0099ff`.
- Animations (`fade-up`, `pulse`, `spin`) are defined as `@keyframes` and applied with utility classes.
- No CSS preprocessor — plain CSS only.

## Recent changes (context)

- **KPI colours now mirror the Estado column, and KPIs are reorderable + configurable** — the KPI palette was a leftover rotation with no relation to the board (Tránsito came out green, Recepción cyan). Every KPI that represents an estado now uses that estado's exact colour (Tránsito amber, Recepción blue, Pendientes Ubicar green); the two that aggregate across all estados (Facturas, Total Palets) use purple and cyan, colours **no estado uses**, so they can't imply a false correspondence. This required moving colour off `.kpi-card:nth-child(N)` and onto each card, otherwise dragging cards around would shuffle the colours. Cards can now be dragged to reorder, and a gear button beside "Salir" opens a Configuración panel (reusing the `.historial-panel` + `.hist-overlay` pattern) to recolour, show/hide and reset KPIs; all of it persists in `localStorage`.
- **`Total Palets` now sums every estado** — it previously only counted `en_preparacion`, which made it a near-duplicate of the Reponer figures rather than the board's real pallet total. Subtitle changed to "Suma de Total palets". Two derived stats had to be kept coherent: the pendientes percentage still divides by the *reponer* pallets (relabelled "% sobre palets en reponer" — dividing by the new global total would dilute it into a meaningless number), and "Media por factura" now divides the global total by all invoices instead of only the reponer ones.
- **New `recepcion` estado + `Reponer`/`Completo` labels** — the flow is now `en_transito → recepcion → en_preparacion → completado`. Recepción behaves exactly like tránsito (everything locked); it only records that the goods arrived. DB values were left untouched apart from adding `recepcion`, so no historical data had to be migrated.
- **New `Ubicados` column** — coupled to `P. por ubicar` so that `ubicados + p_ubicar = palets` always holds. Entering either one derives the other, which makes states like "8 located + 5 pending on a 10-pallet invoice" unrepresentable.
- **`Total Palets` is now read-only on the board** — it holds the original invoice total and is only editable at registration or through the pencil. It no longer counts down, which keeps it distinct from `P. por ubicar`.
- **Auto-archive at zero** — when `p_ubicar` reaches 0 the invoice is snapshotted to `historial_cierres` and removed from the board without any extra click.
- **New KPI "Palets en Recepción"** — sums `p_ubicar` across `recepcion` rows (originally summed `palets` by mistake, which double-counted the invoice total instead of what's actually still pending; fixed 2026-08-07). The KPI grid switched to `auto-fit`/`minmax` to absorb the sixth card.
- **KPI "Ubicados Hoy" bidirectional** — `editarReposicion` computes `delta = nuevoUbicados - ubicadosPrevios`; applies positive (more located) or negative (un-located) delta to today's `historial_ubicados_dia` row; result clamped to ≥ 0.
- **Accordion + ⚙ filter in both historial panels** — each item collapses to date + key stat, expands on click; gear button opens date filter bar (Todo / 3 meses / Este mes / Última semana); filtering is client-side from in-memory cache.
- **Paginación en ambos historiales** — `.cierre-item` llevaba el `flex-shrink: 1` por defecto dentro del `.hist-list` flex-column, así que con muchos registros las tarjetas se aplastaban unas contra otras en vez de hacer scroll; se fijó `flex-shrink: 0`. Además ambos paneles paginan de 10 en 10 (`HIST_PAGE_SIZE`) con una barra `.hist-pager` («‹ 2/5 · 47 reg. ›») anclada al pie del panel; el paginado es client-side sobre la caché en memoria y se reinicia a la página 1 al cambiar de filtro.
- **Historial facturas detail redesigned as cards** — each expedición inside a cierre shows as a 2-line card (destino + factura number on line 1, palets + estado badge on line 2) instead of a 5-column table; fits the 440 px panel without squishing. Detail scrolls vertically if many rows.
- **Estado colors made semantic + `completado` relabeled** — estado text/badges now use a fixed, distinguishable color per stage instead of all reading as similar blue/cyan tones: `en_transito` amber, `recepcion` blue, `en_preparacion` (Reponer) green, `completado` red. `completado`'s display label changed from "Completo" to "Factura finalizada" (DB value `completado` unchanged). Applied in three places kept in sync: `ESTADO_COLOR`/`ESTADO_TEXT` (JS), `select.ci[data-v]` (desktop/mobile dropdown), `.estado-*` (historial badges).
- **Historial de Facturas Anteriores gained edit/save/nota, matching Historial Ubicados por Día** — each cierre's detail now opens with an editable `.ci-nota` row (pencil to unlock, save to persist, `✕` to delete) instead of the old always-visible `🗑 Eliminar` text button in the header. The delete action moved from `.hist-del-btn` (now removed, dead CSS deleted) into that same nota row as a `.del-btn`, reusing the icon already used everywhere else. Needs the `nota` column added via `add_nota_historial_cierres.sql` (applied 2026-08-07 — see Database migrations).
- **Facturas Anteriores: each expedición inside a cierre is now editable (factura/palets/ubicados/pendientes)** — first attempt at this made the cierre-level totals (`N facturas · N palets · N pendientes`) editable, but those are display-only aggregates and "facturas" there means *count*, not the invoice number; the user corrected this: editing should target the actual per-invoice fields shown in each expedición card below (número de factura, palets, ubicados, pendientes), since a cierre is practically always one invoice. Reverted the cierre-level fields back to read-only; each `exp-row` now gets its own pencil/save that rewrites its entry inside the `expediciones` jsonb array (`ubicados`/`pendientes` each clamped to `[0, palets]` independently — no forced `ubicados+pendientes=palets` since this is a historical correction tool, not the live board). `destino` and `estado` stay read-only.
- **Fixed historial panels overflowing off-screen on mobile** — `.historial-panel` had a hardcoded `width: 440px; right: -440px` with no mobile override, so on phones narrower than 440px the panel's left edge sat off-viewport, clipping the left side of every title, date, and stat. Added `.historial-panel { width:100%; right:-100% }` inside the existing `@media (max-width:700px)` block; desktop keeps the 440px panel unchanged.

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
| `add_nota_historial_cierres.sql` | Adds the `nota` column to `historial_cierres`, used by the new edit/save UI in the Facturas Anteriores panel |

`add_recepcion_ubicados.sql` is idempotent and safe to re-run. Its last statement adds `expediciones_coherencia_check`; skip that block if you would rather validate the invariant only in the app.

`add_nota_historial_cierres.sql` is a one-line idempotent `ADD COLUMN IF NOT EXISTS`, same pattern as `add_nota_historial_ubicados.sql`. Applied directly via the connected Supabase MCP on 2026-08-07 (verified: `nota text` now present on `historial_cierres`).
