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

- **2026-08-10 — Los `total_*` de `historial_cierres` son agregados de solo visualización:** `total_facturas`, `total_palets` y `total_pendientes` se escriben una única vez al archivar (`archivarYEliminar`, `limpiarPizarra`) y a partir de ahí solo se leen para pintar la cabecera del cierre — ningún KPI, export ni cálculo depende de ellos (el export de historial lee `expediciones` jsonb, no estas columnas). **Por qué importa:** hacerlos editables no puede romper la lógica del tablero; pero por lo mismo, editarlos **no** reescribe el snapshot `expediciones`, así que cabecera y detalle pueden divergir a propósito si el usuario corrige solo el total.
- **2026-08-10 — En los paneles de historial hay que expandir la tarjeta antes de poder editar:** los controles de edición viven dentro de `.cierre-detail`, que arranca con `max-height:0; overflow:hidden`; hasta que no se hace clic en `.cierre-head` no son alcanzables (Playwright falla con "intercepts pointer events" si se intenta clicar antes). **Por qué importa:** si el usuario reporta "no me aparece la opción de editar", la primera pregunta es si desplegó la tarjeta; y cualquier test de estos paneles debe hacer `click('.cierre-head')` + esperar la transición de 300 ms antes de tocar los botones.
- **2026-08-10 — Rama `claude/claude-md-docs-0by7ke` había quedado desactualizada respecto a `main`:** Los paneles de historial en el móvil del usuario ya mostraban paginación y colores semánticos (features de las PR #5-#9, ya fusionadas en `main`), pero esta rama seguía basada en un commit anterior a esas fusiones — el código local no coincidía con lo que el usuario realmente veía en producción. **Por qué importa:** antes de depurar un bug reportado por el usuario sobre la app en vivo, verificar primero que la rama de trabajo esté al día con `main` (`git log --oneline origin/main -5` vs `git rev-list --left-right --count origin/main...HEAD`); si no lo está, hacer merge antes de tocar nada, o el fix se aplicaría sobre código que ya no representa lo desplegado.
- **2026-08-10 — Los paneles `.historial-panel` no tenían override de ancho para móvil:** `width: 440px; right: -440px` es fijo sin media query, así que en pantallas angostas (<440px, la mayoría de celulares) el panel se abre con su borde izquierdo fuera de la pantalla, cortando el texto del lado izquierdo (títulos, fechas, labels) — visible en capturas como columnas de texto truncadas. **Por qué importa:** cualquier panel/modal con ancho fijo en px debe revisarse contra el breakpoint móvil existente (`@media (max-width:700px)`); el fix fue `width:100%; right:-100%` dentro de ese media query, verificado sin overflow horizontal en 360/375/390/412px con Playwright (`getBoundingClientRect` de todos los hijos del panel, colapsado y expandido).
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
