# Economía, mercancías y menús de GK2 — REA preliminar (Fase 4)

**The Sovereign's Blood · Fase 4 · GDD §3/§3.2 · AG-REA · 2026-11-22**

Alcance: estructuras de datos del directorio GK2 (solo lectura) y lecciones de UX para las pantallas
Economía/Mercado, Militar/Ejércitos y Familia. **No** se abrió ningún `.EXE`, **no** se transcribió texto
del juego y **no** se copiaron assets. Método y límites detallados: `docs/rea/notes_economy.md`.

## 1. Método y limitación de observación

- **DOSBox no disponible** (verificado en PATH, `C:\Tools`, Program Files ×2, scoop/choco, Downloads y
  workspace: 0 ejecutables; ver D-038). La observación de menús **no se realizó** y aquí **no se inventa**:
  todo comportamiento inferido va marcado como *[no observado]*.
- Método sobre datos: inventario y clasificación por tamaño/entropía/periodicidad de todos los `.DAT`/
  `.GK2`/`.MOB`; revisión de los resultados de fases anteriores (`gk2_data_lessons.md`, `notes.md`,
  `gk2_battle_mechanics.md`); comprobaciones dirigidas de tablas candidatas de economía (ver §2).
- Lo que no es determinable por hex se declara **no concluyente**; la propuesta de diseño se apoya en el
  GDD y en las decisiones D-069/D-070/D-071, no en una supuesta copia del original.

## 2. Estructuras `.DAT`/`.GK2` de economía

### 2.1 Inventario clasificado (todo el directorio de datos)

| Grupo | Archivos | Contenido identificado | ¿Economía? |
|---|---|---|---|
| Estado de mundo | `SCENARIO.GK2` (49.841 B), `SAVEDATA.GK2` (47.137 B), `GENDATA1-4.DAT` (7.827 c/u), `ZNAME.DAT` (1.122) | prólogo+roster 99×27 B, tablas de mundo, 66 nombres de región | **Sí, integrada** por región/facción |
| Mapa/terreno | `MAPDATA.DAT`, `HEXKG.DAT`, `HEXSG.DAT` | celdas/teselas; sin tablas de precios | No |
| Gráficos de grupo | `KGRP`, `SGRP`, `GRPDATA`, `OPENGRP`, `ENDGRP` | bancos gráficos (ver Fase 2) | No |
| Sprites/patrones | `SUNIT.DAT`, `KPAT.DAT` | 96 cuadros de 512 B; máscaras/patrones | No |
| Retratos/ilustración | `KAODATA.DAT`, `QKAODATA.DAT` | imágenes | No |
| Empaquetado/UI | `PACKDATA.DAT`, `KOEI.DAT` | gráficos comprimidos/tiles | No |
| Personajes extra | `USDATA1-4.DAT` (1.456–2.184 B) | nombres de 16 B + datos (patrón de roster) | No (personajes) |
| Audio | `DA_LENCH.MOB` | módulo musical | No |

**Hallazgo principal:** no existe un archivo dedicado a precios, mercancías o mercaderes, ni se localizó
dentro del estado de mundo una tabla de 10–30 registros con estructura de precios. La economía de GK2 se
resuelve, por lo que los datos permiten inferir, con **variables por región y por facción** integradas en
`SCENARIO.GK2`/`SAVEDATA.GK2` (mismo esquema, campos mutables sobrescritos; ver informe de Fase 0).
No se pudo confirmar campo a campo qué bytes son población, riqueza o tesoro: **no concluyente**.

### 2.2 Tabla de hipótesis (qué se buscó y qué se puede afirmar)

| Hipótesis | Evidencia | Estado |
|---|---|---|
| Archivo de precios/mercancías independiente | inventario completo: ningún `.DAT` con tamaño/estructura de catálogo corto de bienes | **Descartada** (no hay evidencia) |
| Tabla de precios dentro de `SCENARIO`/`SAVEDATA` | secciones numéricas existen, pero sin anclas de texto ni periodicidad de 10–30 registros que la aíslen | **No concluyente** |
| Inventario de mercancías por facción en el save | el save sobrescribe campos mutables de las mismas tablas; no se identificó bloque de inventario | **No concluyente** |
| Mercaderes como entidad con registro propio | no hay tabla de entidades de ~8–32 B con contadores asociados | **No concluyente / sin evidencia** |
| Menús y textos de economía | residen previsiblemente en los `.EXE` (no analizables) | **Fuera de alcance legal** |

**Consecuencia de diseño:** nuestro sistema de mercancías y comerciantes (D-069) **no es un port** de GK2:
es una extensión propia. Esto libera el diseño (no hay formato que imitar) y obliga a definir el modelo,
los precios y la UX desde cero con criterios históricos y de jugabilidad; por eso el resto del informe es
la parte consumible.

## 3. Lecciones de UX para los tres menús *[no observado]*

La observación directa no fue posible; estas lecciones son **inferidas del género y de nuestro GDD/UI**, y
están formuladas como criterios verificables para AG-1/AG-2/AG-3 y para el QA C1.

### 3.1 Economía / Mercado
1. Una sola pantalla debe responder "¿qué tengo, qué produzco, a cuánto lo vendo y qué me falta?".
   Columnas por bien: icono+nombre, existencias, producción/consumo del trimestre, precio actual, flecha
   de tendencia, botones Comprar/Vender con selector de cantidad.
2. El precio debe mostrarse como **base y factor** (p. ej. "60 × 1,15") para que el jugador entienda la
   oferta/demanda; sin números mágicos.
3. Requisitos visibles y deshabilitados con motivo: sin comerciantes → "sin comerciantes asignados";
   sin ruta/pacto → "sin ruta comercial"; sin oro → coste en rojo.
4. Cabecera permanente con tesoro, PG e ingresos/gastos proyectados del trimestre; el jugador debe poder
   evaluar una compra sin salir de la pantalla.
5. Ordenar/filtrar por categoría (básicos/lujo/estrategia) y buscar; teclado para cantidades (×10, máx.).
6. Confirmación sólo en operaciones grandes; feedback inmediato y registro en el informe trimestral.

### 3.2 Militar / Ejércitos
1. Panel global por facción: filas por tipo de unidad con sprite `march_1`, conteo, fuerza, moral y
   experiencia medias; totales agregados de hombres y poder.
2. Acciones Reclutar/Entrenar/Disolver con coste completo (oro + PG + mercancías) y requisitos: pool
   regional, edificios, caballos/armas en inventario. El botón deshabilitado explica **qué falta**.
3. Debe verse el efecto: antes/después de hombres, moral y consumo de mercancías (D-070).
4. Lista de ejércitos por región con composición y ubicación; desde ahí se pueda ir a la región.
5. Nunca permitir números negativos ni reclutamiento por encima del pool; mensajes de error explícitos.
6. La IA usa las mismas reglas (sin trampas) y la pantalla lo declara.

### 3.3 Familia
1. Árbol/lista con gobernante, consorte, hijos y parientes: edad, estado (heredero ★, enfermo, cautivo),
   stats y educación en curso; sin huecos vacíos.
2. Acciones: educar (tutor), matrimonio, pasar tiempo con la consorte (D-071: 1/trimestre, 2–3 PG,
   requiere consorte viva/fértil) con coste y cooldown visibles.
3. Estado de fertilidad/bonus mostrado como modificador temporal ("+fertilidad, 2 trimestres").
4. Sucesión legible: quién es heredero, por qué, y qué pasa si muere (regencia/crisis) en tooltip.
5. Rechazos claros: "sin consorte válida", "sin PG", "menor de edad" — sin estados rotos.

## 4. Checklist por pantalla (verificable por QA C1)

| Pantalla | # | Criterio verificable |
|---|---:|---|
| Mercado | 1 | Existen las 10 mercancías de D-069 con `base_price`, producción y uso |
| Mercado | 2 | Columnas: bien, stock, producción/consumo, precio, tendencia, acciones |
| Mercado | 3 | Precio = base × factor oferta/demanda visible y determinista (misma semilla → mismo precio) |
| Mercado | 4 | Sin comerciantes asignados → comprar/vender deshabilitado con motivo textual |
| Mercado | 5 | Volumen comerciado depende del nº de comerciantes; tope por trimestre |
| Mercado | 6 | Tesoro y balance proyectado visibles; ninguna operación deja stock o oro negativos |
| Mercado | 7 | Grano/sal afectan apoyo; armas/caballos se consumen al reclutar (D-069/D-070) |
| Mercado | 8 | Persistencia: inventario, comerciantes y precios sobreviven a save/load (save_version) |
| Ejércitos | 1 | Una fila por tipo de unidad con sprite, conteo, fuerza, moral, experiencia |
| Ejércitos | 2 | Reclutar muestra coste oro+PG+mercancías y bloquea si falta pool/edificio/bien |
| Ejércitos | 3 | Entrenar sube experiencia y descuenta oro+PG; Disolver devuelve 50 % de oro |
| Ejércitos | 4 | Totales de facción correctos y coherentes con las regiones |
| Ejércitos | 5 | Errores explícitos; sin doble gasto ni negativos; IA con mismas reglas |
| Familia | 1 | Gobernante/consorte/hijos visibles con edad, estado, heredero y stats |
| Familia | 2 | Educar/matrimonio/pasar tiempo con coste y requisitos visibles |
| Familia | 3 | Pasar tiempo: 1/trimestre, coste PG, requiere consorte válida, bonus temporal visible |
| Familia | 4 | Herencia/sucesión explicada en tooltip; ningún slot vacío |
| Común | 1 | Coste en PG/oro visible antes de confirmar; sin texto libre; i18n ES/EN |
| Común | 2 | Estados vacíos legibles y sin crashes; teclado/mouse; 1920×1080 escalable |

## 5. Diez mercancías históricas plausibles (s. XIV) — propuesta para `trade_goods.json`

| id | Bien | Producción plausible | Demanda / uso | Fuente abierta |
|---|---|---|---|---|
| `spices` | Especias | Levante/Egipto/Italia (Venecia, Génova); lujo | Cortes, ciudades ricas; margen alto | [Spice trade](https://en.wikipedia.org/wiki/Spice_trade) |
| `furs` | Pieles | Rusia/Báltico/Escandinavia (Hansa, Nóvgorod) | Cortes y ejércitos del norte; lujo | [Fur trade](https://en.wikipedia.org/wiki/Fur_trade) |
| `wool` | Lana | Inglaterra, Flandes, Castilla | Paños flamencos/italianos; exportación | [Wool trade](https://en.wikipedia.org/wiki/Wool_trade) |
| `wine` | Vino | Francia (Burdeos, Borgoña), Iberia, Rin | Ciudades del norte, Inglaterra, corte | [History of wine](https://en.wikipedia.org/wiki/History_of_wine) |
| `salt` | Sal | Brouage (Francia), Setúbal (Portugal), Lüneburg | Conservación de alimentos: consumo masivo | [Salt](https://en.wikipedia.org/wiki/Salt) |
| `grain` | Grano | Sicilia, Egipto, Prusia, Báltico | Alimentar ciudades y ejércitos; base del apoyo | [Hanseatic League](https://en.wikipedia.org/wiki/Hanseatic_League) |
| `arms` | Armas | Milán/Brescia, Toledo, centros del Rin | Reclutamiento de infantería pesada (D-070) | [Blacksmith](https://en.wikipedia.org/wiki/Blacksmith) |
| `horses` | Caballos | Estepas, Hungría, Iberia, Flandes | Caballería; consumo al reclutar (D-070) | [Horses in the Middle Ages](https://en.wikipedia.org/wiki/Horses_in_the_Middle_Ages) |
| `iron` | Hierro | Suecia, Estiria, Vizcaya | Herramientas, armas, construcción | [Blast furnace](https://en.wikipedia.org/wiki/Blast_furnace) |
| `timber` | Madera | Báltico, Escandinavia, Polonia | Construcción naval/edilicia; ligada a mercados | [Hanseatic League](https://en.wikipedia.org/wiki/Hanseatic_League) |

Nota de método: son asignaciones **plausibles** para el s. XIV, no cifras definitivas; AG-1 debe fijar los
valores finales con `source` (URL) y `"estimate": true` cuando proceda (GDD §7.8). No se ha transcrito
texto de GK2 ni se han usado sus nombres.

## 6. Modelo de precios y oferta/demanda sugerido

- **Producción**: `supply_r(g) = Σ mano_de_obra(asignada) × factor_terreno(r,g) × factor_edificio(r,g)`
  por región y trimestre; los bienes de lujo requieren edificio (Mercado/Taller) y ruta.
- **Consumo**: población + ejército + edificios; grano/sal sostienen apoyo; armas/caballos se consumen al
  reclutar (D-069/D-070).
- **Precio**: `P(g) = base(g) × clamp(1 + k·(D−S)/max(S,1), 0.5, 2.0)`, con `k≈0.6`, suavizado
  trimestral `P_t = 0.7·P_{t−1} + 0.3·P_target` y ruido determinista ±5 % con `GameState.rng`. Sin
  comerciantes no hay comercio; cada comerciante aporta capacidad (p. ej. 40 unidades/trimestre) y reduce
  margen por competencia. Pacto comercial: +25 % de volumen (GDD §5.4); expedición de mercaderes: 2 PG,
  retorno a 2 trimestres, riesgo de pérdida.
- **Cota económica**: el comercio aporta ≤ ~20–25 % de la economía base (D-069) para no romper el balance
  D-068; el gasto de corte y el upkeep de ejércitos siguen siendo los sumideros principales.
- **Estado serializable** (GDD §7.7): `factions[].inventory{g:qty}`, `factions[].merchants`,
  `market.prices{g}`, `trade_routes[]`, `expeditions[]`; incremento de `save_version` con migración
  (inventario vacío, comerciantes 0, precios base).
- **Datos propuestos** (`data/trade_goods.json`): `id`, `name_es/name_en`, `category`
  (bulk/luxury/strategic), `base_price` (oro/unidad), `unit`, `produced_by{terrain[],buildings[]}`,
  `used_by{recruit[],consume[]}`, `weight` (capacidad de comerciante). Validación: 10 registros, ids
  únicos, precios >0, referencias a terrenos/edificios/unidades existentes.

## 7. Límites y declaración legal

- **No observado** (D-038): menús Economía/Militar/Familia y cualquier comportamiento del original. La
  checklist de §4 es un contrato de UX propio, no una descripción del original.
- **No concluyente**: campos concretos de economía en `SCENARIO`/`SAVEDATA` (población/riqueza/tesoro) y
  existencia de un sistema de mercancías/mercaderes en GK2; no hay archivo dedicado ni tabla aislable con
  la evidencia disponible. Se entrega como hipótesis y se recomienda no perseguir un port 1:1.
- **Prohibiciones respetadas**: sin desensamblado de ejecutables, sin texto literal, sin copia de
  píxeles/paletas/assets. Fuentes históricas abiertas citadas en §5; valores finales a cargo de AG-1 con
  `source` en `data/sources.md`.

---

## 8. Addendum D-074/D-075/D-076 — límites de acciones y costes de reclutamiento

### 8.1 Búsqueda estructural (resultado)

Se amplió la búsqueda a los dos aspectos detectados en la prueba del usuario:

| Qué se buscó | Método | Resultado |
|---|---|---|
| Tabla de límites de acciones por turno | Inventario completo de `.DAT`/`.GK2`; búsqueda de tablas de 8–24 registros con campos constantes de límite y patrones de banderas por facción | **No identificada**: el límite es lógica de estado de turno (runtime), no tabla fija; en `SAVEDATA` solo cabría el estado `actions_used`, no su definición |
| Tabla de costes de reclutamiento por tipo de unidad | Barrido de secuencias ascendentes `u8`/`u16` (ids/costes) en `SCENARIO`, `SAVEDATA`, `GENDATA`, `KGRP`, `GRPDATA` y `KOEI.DAT`, pasos 4–32 y 8–24 registros | **0 candidatos**: no hay tabla de costes aislable en los datos; los parámetros por unidad residen previsiblemente en los `.EXE` (prohibidos) |
| Secuencia de menús Economía/Militar/Familia | Búsqueda de texto/estructura de menú en datos | **No determinable**: el texto de UI está en los ejecutables; los datos no contienen guiones ni etiquetas de menú |
| Observación (D-038) | DOSBox verificado ausente | **No observado**: lo siguiente es diseño propio verificable, no descripción del original |

Conclusión: para D-074/D-075 **no hay referencia binaria utilizable**; son decisiones de diseño propias
(extensión, no port). `actions_used` y la tabla de costes viven en nuestro código y en `units.json`, no en
datos de GK2.

### 8.2 Lecciones UX — acciones 1/turno frente a repetibles

- **Clasificar por naturaleza, no por pantalla:** órdenes de corte (diplomacia, familia, construcción,
  espionaje, expedición) = **1/turno**; logística (reclutar/entrenar/disolver, asignar trabajadores,
  comprar/vender) = **repetible**. La UI debe hacer visible la distinción sin que el jugador memorice reglas.
- **Marca persistente:** píldora "1/turno" en acciones gateadas; tras usarlas, botón deshabilitado con
  check y tooltip "Usado este turno" (y "para este objetivo" cuando aplique). Las repetibles no llevan
  píldora: muestran contador/cantidad.
- **Motivos de deshabilitado diferenciados:** usado vs sin PG vs requisito no cumplido vs objetivo ya
  usado. Un botón gris sin motivo es un bug de UX.
- **Diplomacia/espionaje por objetivo:** el gate es por acción **y** objetivo; la lista debe marcar cuáles
  se usaron este turno, no deshabilitar la pantalla entera.
- **Doble clic y carreras:** el motor rechaza el duplicado (`action_used`) aunque la UI falle, sin doble
  gasto de PG/oro; la UI puede ser optimista pero la autoridad es el estado.
- **Reinicio y persistencia:** al terminar turno los botones se rehabilitan; `actions_used` viaja en el
  save y las partidas antiguas migran a conjunto vacío.
- **Repetibles con control:** reclutar varias veces exige coste acumulado y límites (pool, oro, mercancías)
  visibles; "repetible" no debe significar "sin freno".

### 8.3 Lecciones UX — costes relativos por tipo de unidad

- **Tier visible:** infantería < arqueros < caballería ligera < caballería pesada < artillería. La
  caballería ligera no debe ser más barata que un arquero largo y la artillería debe superar a cualquier
  caballería (D-075).
- **Coste completo por tarjeta:** oro + hombres del pool + mercancías (`caballos`/`armas`) + PG si aplica;
  total para la cantidad seleccionada y tesoro proyectado. Comparación sin abrir fichas.
- **Comparación:** ordenar/filtrar por coste, secundario "oro por hombre" y etiquetas de tier con tooltip
  que explique el porqué (caballo + armadura + entrenamiento), no solo el número.
- **Nada oculto:** si la unidad consume caballos, se ve antes de reclutar; si falta el bien, botón
  deshabilitado con motivo. La IA paga la misma tabla (sin descuentos).
- **Validación de datos:** test que afirme `cost(caballería) > cost(arqueros/infantería ligera)` y
  `cost(artillería) > cost(caballería)`; los valores se cambian solo en `units.json` + `sources.md §13`.

### 8.4 Checklist verificable para D-074/D-075 (C13/C14)

| # | Criterio verificable |
|---:|---|
| 1 | El motor rechaza una segunda diplomacia (misma acción+objetivo) con motivo `action_used`; PG/estado intactos |
| 2 | Rechaza 2.º matrimonio/acción familiar, 2.ª construcción, 2.º espionaje por objetivo y 2.ª expedición en el turno |
| 3 | Reclutar/entrenar/disolver, asignar trabajadores y comprar/vender permiten **varias** operaciones por turno |
| 4 | `actions_used` se resetea al empezar turno, se conserva en save/load y migra en partidas antiguas |
| 5 | La UI deshabilita la acción usada con tooltip y distingue usado / sin PG / requisito no cumplido |
| 6 | Doble clic o reintento no produce doble gasto; el feedback explica el rechazo |
| 7 | Cada tarjeta de unidad muestra oro + hombres + mercancías, total para la cantidad y tesoro resultante |
| 8 | Los 17 tipos tienen coste diferenciado por tier (caballería > arqueros/infantería; artillería > caballería) |
| 9 | Reclutar deduce exactamente `cost.gold` y `recruit_goods`; si falta algo no hay deducción parcial y hay motivo |
| 10 | Se puede comparar/ordenar por coste; el tier se explica con tooltip; sin costes ocultos |
| 11 | Test automático de la regla de tiers y de costes distintos; `sources.md §13` documenta los valores |
| 12 | Sin regresión: `validate_data` 0 WARN/0 errores y C1–C14 del QA de Fase 4 en verde |
