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

- **2026-08-11 — Relabel de "Fecha Prevista" a "Fecha de Registro": buscar por clase CSS, no por el texto de la etiqueta:** El input `.ci-fecha` (columna original) tenía la etiqueta "Fecha prevista" repetida en 3 sitios (`<th>` de la tabla, `<label>` del modal, `<label>` de la tarjeta móvil) que no comparten ninguna constante JS como `ESTADO_TEXT` — son texto suelto en el HTML. Al agregar la columna `fecha_prevista` de verdad, hubo que renombrar los 3 textos viejos a mano para no terminar con dos campos llamados igual. **Por qué importa:** cuando una etiqueta de columna no pasa por una función central de traducción (a diferencia de los estados), un rename seguro empieza por `grep` del texto exacto en todo el archivo, no solo del nombre de la clase CSS que la contiene.
- **2026-08-11 — Un valor "nunca vacío" calculado a partir de otro campo necesita recalcularse en los 3 caminos de guardado, no solo en la creación:** `fecha_prevista` debía quedar en blanco = "calcular a +8 días", pero la app tiene 3 sitios donde se persiste una fila (`saveNew()`, y el guardado por lápiz en escritorio/móvil, ambos vía `guardarFila()`). Bastó centralizar el cálculo dentro de `guardarFila()` (que ya es el punto de paso común de escritorio y móvil) más una llamada aparte en `saveNew()` para insertar. **Por qué importa:** antes de decidir "dónde" añadir una regla de negocio nueva, ubicar todos los caminos de escritura que existen (aquí 3, no 1) y verificar si alguno de ellos comparte ya una función común — evita implementar la regla dos veces con el riesgo de que diverjan.
- **2026-08-11 — Un color de dos niveles de indirección vía custom properties permite "ligar" ajustes sin re-renderizar, PERO cada elemento visual relacionado necesita su propia referencia a la misma variable:** Al hacer configurable el color de Total Palets, solo se actualizó el `<input>` (`.ci-palets` → `var(--col-palets)`); la barrita de progreso al lado (`.pb-bar`) se quedó apuntando al `var(--warn)` hardcodeado de siempre, así que cambiar el color de la columna recoloreaba el número pero no la barra. **Por qué importa:** al conectar una propiedad visual a una variable configurable, buscar TODOS los elementos que hoy comparten ese mismo color hardcodeado (no solo el más obvio) — aquí bastaba un `grep` de `var(--warn)` para encontrar la barra que se había quedado atrás.
- **2026-08-11 — Un interruptor para "desligar" un vínculo debe congelar el valor actual, no reiniciarlo:** Al apagar "Vincular colores con Estado", los 4 KPIs que hasta entonces seguían el color de su estado necesitaban un color propio para poder seguir mostrando algo — usar el default de `KPI_DEFS` habría dado un salto visual si el usuario ya había personalizado el color del estado. `toggleKpiEstadoLink()` en cambio copia el color ACTUAL del estado (`estadoCfg[mirrorsEstado]`) al `kpiCfg.colors[key]` del KPI en el momento exacto de desvincular, así el usuario ve el mismo color antes y después de mover el interruptor — solo cambia que a partir de ahí puede editarlo aparte. **Por qué importa:** cualquier interruptor que rompe una relación derivada (A sigue a B) debe fijar el valor heredado como punto de partida del ítem que se independiza, no resetearlo a un default genérico; si no, "desactivar X" se siente como "randomizar X".
- **2026-08-11 — Un color de dos niveles de indirección vía custom properties permite "ligar" ajustes sin re-renderizar:** Para que el color de un KPI siga automáticamente al color de su estado, el `--kc` de la tarjeta no apunta a un color final sino a otra variable (`var(--estado-en_transito)`), y esa variable a su vez es una custom property en `:root` que `applyEstadoColors()` reasigna con `setProperty`. Cambiar el estado no toca el DOM del KPI en absoluto — el navegador resuelve la cascada solo. **Por qué importa:** cuando dos partes de la UI deben "significar lo mismo" y una tercera cosa (aquí: Configuración) controla ambas a la vez, meter un nivel extra de indirección en las custom properties evita tener que sincronizar manualmente re-renderizados de sitios no relacionados en el DOM.
- **2026-08-11 — Las pruebas que leen `getComputedStyle(...).color` justo tras un cambio pueden capturar una transición CSS a medio terminar:** `.ci`/`select.ci` ya tenían `transition:all .15s` (para hover/focus); al hacer los colores de estado configurables, cambiar de color ahora también anima suavemente vía esa misma regla. Una prueba que esperaba exactamente 150 ms tras el clic leía un color intermedio y fallaba por ±1 en el RGB, no por un bug real. **Por qué importa:** al probar un cambio de color en un elemento que ya tiene `transition` en esa propiedad, esperar bastante más que la duración de la transición (aquí subir de 150 a 350 ms) antes de leer `getComputedStyle`, o el fallo parecerá un bug de redondeo cuando en realidad es la animación captada a mitad de camino.
- **2026-08-11 — Una clase CSS compartida entre dos features no relacionadas se vuelve una fuga cuando una se hace configurable:** `.ci-palets` la usaban tanto la columna Total Palets de la tabla como el campo "Palés" del panel Historial Ubicados por Día — visualmente coincidía (mismo ámbar), pero conceptualmente eran cosas distintas. Al hacer editable el color de la columna Total Palets, hacerlo sobre `.ci-palets` habría recoloreado también ese campo del historial sin que el usuario lo pidiera. Se creó `.ci-diapalets` como clase gemela desacoplada (mismo CSS por defecto, sin variable configurable). **Por qué importa:** antes de conectar una clase existente a un ajuste configurable, `grep` de esa clase en todo el archivo para confirmar que no la reutiliza otra sección no relacionada.
- **2026-08-11 — Relabel de "Reponer" a "Ubicar": buscar por `ESTADO_TEXT`, no por el nombre del estado:** El valor `en_preparacion` en `ESTADO_TEXT` fue el cambio principal, pero el texto "Reponer"/"reponer" también aparecía suelto en 4 sitios más que no derivan de esa constante: el `<option>` hardcodeado del modal "Nueva entrada", el emoji del desglose del KPI Facturas, y dos subtítulos de KPI extra ("% sobre palets en reponer", "En reponer", "Recibidos sin reponer"). **Por qué importa:** al renombrar una etiqueta de estado, un `grep -i "reponer"` sobre el HTML+JS antes de dar por terminado evita dejar texto viejo en sitios que no pasan por la función central de traducción; los nombres internos (`esReponer`, `enPrep`) no hace falta tocarlos si el usuario solo pidió cambiar lo visible.
- **2026-08-11 — Un color asignado por posición CSS es incompatible con reordenar elementos:** Los 6 KPI tomaban su color de `.kpi-card:nth-child(N){--kc:...}`, así que al añadir arrastrar-para-reordenar los colores se habrían barajado (la tarjeta movida adoptaba el color de su nueva posición). Hubo que mover el color a un dato por KPI (`KPI_DEFS[].color` → `style="--kc:..."` en cada tarjeta) y dejar en `nth-child` solo el `animation-delay`. **Por qué importa:** antes de hacer reordenable cualquier lista, revisar si algún estilo depende de `nth-child`/`:first-child`/`:last-child`; ese estilo debe pasar a ser un atributo del elemento, no de su posición.
- **2026-08-11 — Al permitir ocultar elementos, todo `getElementById(...).textContent = x` se vuelve una bomba:** Con los KPI ocultables, sus nodos dejan de existir y los ~11 accesos directos que había en `updateKPIs`, `renderKpiExtraUbicados`, `registrarUbicadosHoy`, `saveHistUbic` y `deleteHistUbic` lanzarían `TypeError` tumbando el render entero. Se centralizó en `setKpiText()`/`setKpiHtml()`, que comprueban existencia. **Por qué importa:** cualquier función de visibilidad opcional obliga a auditar TODOS los accesos al DOM de esos elementos, no solo el sitio obvio donde se pintan.
- **2026-08-11 — Cambiar el significado de un KPI obliga a revisar sus estadísticas derivadas:** Al pasar `Total Palets` de "solo Reponer" a "todos los estados", dos números del desplegable quedaban incoherentes sin tocarlos: el `%` de pendientes se diluía al dividir por el total global, y "Media por factura" dividía palets de todos los estados entre solo las facturas en Reponer. **Por qué importa:** un cambio de fórmula en un KPI rara vez es una línea; hay que rastrear qué otros cálculos reutilizan esa variable (aquí `totalPalets` alimentaba `pctPend` y `avg`) y decidir explícitamente si siguen el cambio o conservan el ámbito antiguo.
- **2026-08-10 — "Facturas" en la cabecera de un cierre es un contador, no el número de factura:** Primer intento hice editables `total_facturas`/`total_palets`/`total_pendientes` (los 3 agregados de la cabecera), pero el usuario aclaró que casi siempre hay una sola factura por cierre y lo que realmente quiere corregir es el **número de factura** de esa factura puntual — un dato que vive dentro de `expediciones[i].factura`, no en `total_facturas` (que es solo un conteo). **Por qué importa:** cuando un campo se llama igual a nivel de agregado y a nivel de detalle ("facturas" = cantidad vs. "factura" = identificador), preguntar explícitamente cuál de los dos quiere editar el usuario antes de implementar, en vez de asumir por la etiqueta visible más prominente (la cabecera, en este caso, era la equivocada).
- **2026-08-10 — El usuario prefirió un único lápiz/disquete por cierre en vez de uno por campo/fila:** Primer diseño le dio a cada expedición su propio lápiz (y otro aparte para la nota), lo cual exigía escopar cada control a un wrapper con id único para que no se pisaran entre sí. El usuario pidió simplificarlo: un solo lápiz que desbloquee nota + todas las expediciones del cierre a la vez, y un solo disquete que las guarde todas juntas en una llamada. **Por qué importa:** con un único par edit/save por cierre, escopar a `card.querySelector` vuelve a ser seguro (ya no hay ambigüedad de "cuál .edit-btn"); `saveCierre` recorre `card.querySelectorAll('.exp-row')` en orden para reconstruir el array `expediciones` completo y lo persiste junto con `nota` en un solo `update`.
- **2026-08-10 — La cabecera de un cierre debe recalcularse al guardar, no quedar congelada:** Primer diseño de `saveCierre` solo persistía `{ nota, expediciones }`, dejando `total_facturas`/`total_palets`/`total_pendientes` (escritos una vez al archivar) sin tocar — el usuario editaba "pendientes" de la única factura de un cierre y la cabecera seguía mostrando el valor viejo, porque son columnas separadas que nadie recalculaba. **Por qué importa:** aunque técnicamente son agregados de solo visualización que ningún KPI consulta, mostrarle al usuario un número que no refleja lo que acaba de guardar es confuso — no basta con que "no rompa nada", tiene que quedar coherente. Fix: `saveCierre` recalcula los 3 totales sumando el array `expediciones` ya editado (`exps.length`, `Σpalets`, `Σp_ubicar`) y los manda en el mismo `update`; el DOM se actualiza in-place vía `hc-fact-{id}`/`hc-pal-{id}`/`hc-pend-{id}` sin re-renderizar todo el panel (evita colapsar el acordeón o perder el scroll).
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
