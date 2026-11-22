# Economía, mercancías y menús de GK2 — REA preliminar (Fase 4)

**The Sovereign's Blood · Fase 4 · GDD §3/§3.2 · AG-REA · 2026-11-22**

Alcance: estructuras de datos del directorio GK2 (solo lectura) y lecciones de UX para Mercado, Ejércitos y
Familia. Sin `.EXE`, sin texto del juego y sin copiar assets. Método completo, evidencias y detalle del
addendum D-074/D-075/D-076: `docs/rea/notes_economy.md`.

## 1. Método y limitación

- **DOSBox ausente** (PATH, `C:\Tools`, Program Files ×2, scoop/choco, Downloads y workspace; D-038): menús
  **no observados**; todo lo inferido va marcado *[no observado]* y no se inventan comportamientos.
- Datos: inventario y clasificación por tamaño/entropía/periodicidad de todos los `.DAT`/`.GK2`/`.MOB`;
  revisión de los REA previos; búsquedas dirigidas de tablas de economía (§2) y de límites/costes (§8).
- Lo no determinable por hex se declara **no concluyente**; el diseño se apoya en el GDD y en
  D-069/D-070/D-071, no en una supuesta copia del original.

## 2. Estructuras `.DAT`/`.GK2` de economía

### 2.1 Inventario clasificado

| Grupo | Archivos | Contenido identificado | ¿Economía? |
|---|---|---|---|
| Estado de mundo | `SCENARIO.GK2`, `SAVEDATA.GK2`, `GENDATA1-4.DAT`, `ZNAME.DAT` | roster 99×27 B, tablas de mundo, 66 nombres de región | **Sí, integrada** |
| Mapa/terreno | `MAPDATA`, `HEXKG`, `HEXSG` | celdas/teselas | No |
| Gráficos | `KGRP`, `SGRP`, `GRPDATA`, `OPENGRP`, `ENDGRP`, `KAODATA`, `QKAODATA`, `PACKDATA`, `KOEI.DAT` | bancos gráficos/UI | No |
| Sprites/patrones | `SUNIT.DAT`, `KPAT.DAT` | 96 cuadros de 512 B; máscaras | No |
| Personajes extra | `USDATA1-4.DAT` | nombre `char[16]` + datos | No |
| Audio | `DA_LENCH.MOB` | módulo musical | No |

### 2.2 Búsqueda de tablas de precios/inventarios/mercaderes

- **No existe archivo dedicado** a precios, mercancías o mercaderes; ningún `.DAT` con estructura de
  catálogo corto de bienes.
- En `SCENARIO`/`SAVEDATA` no se aisló tabla de precios ni bloque de inventario: la economía parece
  integrada como **variables por región/facción** del estado de mundo (mismo esquema escenario↔save).
- Hipótesis: (a) archivo independiente = **descartada**; (b) tabla de precios en el estado = **no
  concluyente**; (c) inventario de facción/mercaderes = **no concluyente**; (d) textos de menú en los
  `.EXE` = fuera de alcance legal. No se pudo confirmar campo a campo población/riqueza/tesoro.

**Consecuencia:** nuestro sistema de mercancías y comerciantes (D-069) es una **extensión propia, no un
port 1:1**; esto libera el diseño y obliga a definirlo con criterios históricos y de jugabilidad.

## 3. Lecciones de UX *[no observado]*

### 3.1 Mercado
1. Una pantalla responde "qué tengo, qué produzco, a cuánto lo vendo y qué me falta": columnas bien,
   existencias, producción/consumo, precio y tendencia, con botones Comprar/Vender y cantidad.
2. Precio como **base × factor** visible (oferta/demanda comprensible); requisitos deshabilitados con
   motivo (sin comerciantes, sin ruta/pacto, sin oro).
3. Cabecera con tesoro, PG y balance proyectado; filtros por categoría y cantidades ×10/máx.
4. Confirmación sólo en operaciones grandes; feedback inmediato y registro en el informe trimestral.

### 3.2 Ejércitos
1. Filas por tipo de unidad con sprite `march_1`, conteo, fuerza, moral y experiencia medias; totales.
2. Reclutar/Entrenar/Disolver con coste completo (oro+PG+mercancías) y requisitos; el botón deshabilitado
   explica qué falta.
3. Efecto antes/después (hombres, moral, consumo) y lista de ejércitos por región navegable.
4. Sin negativos ni reclutamiento sobre el pool; errores explícitos; la IA usa las mismas reglas.

### 3.3 Familia
1. Árbol/lista con gobernante, consorte, hijos y parientes (edad, heredero ★, enfermo, cautivo, stats).
2. Acciones educar/matrimonio/pasar tiempo (D-071: 1/trimestre, 2–3 PG, consorte válida) con coste y
   cooldown visibles; bonus de fertilidad como modificador temporal.
3. Sucesión explicada en tooltip y rechazos claros ("sin consorte válida", "sin PG", "menor de edad").

## 4. Checklist verificable (QA Fase 4)

| Pantalla | Criterios |
|---|---|
| Mercado | 10 mercancías con `base_price`/producción/uso; columnas completas; precio base×factor determinista; sin comerciantes → deshabilitado con motivo; volumen según comerciantes; tesoro/balance visibles; sin negativos; grano/sal afectan apoyo, armas/caballos se consumen al reclutar; persistencia con `save_version` |
| Ejércitos | fila por tipo con sprite/conteo/fuerza/moral/experiencia; coste oro+PG+mercancías y bloqueo explicado; Entrenar/Disolver con sus costes; totales coherentes; errores explícitos; IA sin trampas |
| Familia | gobernante/consorte/hijos con edad/estado/heredero/stats; acciones con coste y requisitos; pasar tiempo 1/trimestre con bonus visible; sucesión en tooltip; sin slots vacíos |
| Común | coste visible antes de confirmar; sin texto libre; i18n ES/EN; estados vacíos legibles; sin crashes; 1920×1080 escalable |

## 5. Diez mercancías históricas plausibles (s. XIV)

| id | Bien | Producción plausible | Demanda / uso | Fuente abierta |
|---|---|---|---|---|
| `spices` | Especias | Levante/Egipto/Italia; lujo | Cortes y ciudades ricas | [Spice trade](https://en.wikipedia.org/wiki/Spice_trade) |
| `furs` | Pieles | Rusia/Báltico/Escandinavia | Cortes del norte; lujo | [Fur trade](https://en.wikipedia.org/wiki/Fur_trade) |
| `wool` | Lana | Inglaterra, Flandes, Castilla | Paños flamencos/italianos | [Wool trade](https://en.wikipedia.org/wiki/Wool_trade) |
| `wine` | Vino | Francia, Iberia, Rin | Ciudades del norte, Inglaterra | [History of wine](https://en.wikipedia.org/wiki/History_of_wine) |
| `salt` | Sal | Brouage, Setúbal, Lüneburg | Conservación de alimentos | [Salt](https://en.wikipedia.org/wiki/Salt) |
| `grain` | Grano | Sicilia, Egipto, Prusia, Báltico | Ciudades y ejércitos; apoyo | [Hanseatic League](https://en.wikipedia.org/wiki/Hanseatic_League) |
| `arms` | Armas | Milán/Brescia, Toledo, Rin | Infantería pesada (D-070) | [Blacksmith](https://en.wikipedia.org/wiki/Blacksmith) |
| `horses` | Caballos | Estepas, Hungría, Iberia | Caballería; consumo al reclutar | [Horses in the Middle Ages](https://en.wikipedia.org/wiki/Horses_in_the_Middle_Ages) |
| `iron` | Hierro | Suecia, Estiria, Vizcaya | Herramientas, armas, construcción | [Blast furnace](https://en.wikipedia.org/wiki/Blast_furnace) |
| `timber` | Madera | Báltico, Escandinavia, Polonia | Construcción naval/edilicia | [Hanseatic League](https://en.wikipedia.org/wiki/Hanseatic_League) |

Asignaciones **plausibles**, no cifras definitivas: AG-1 fija valores con `source` y `"estimate": true`
cuando proceda (GDD §7.8). No se transcribió texto de GK2.

## 6. Modelo de precios y oferta/demanda sugerido

- **Producción**: `supply = Σ mano_de_obra × factor_terreno × factor_edificio` por región/trimestre; los
  bienes de lujo requieren Mercado/Taller y ruta. **Consumo**: población + ejército + edificios.
- **Precio**: `P = base × clamp(1 + 0,6·(D−S)/max(S,1), 0,5, 2,0)`, suavizado `P_t = 0,7·P_{t−1} +
  0,3·P_target` y ruido determinista ±5 % (`GameState.rng`). Sin comerciantes no hay comercio; cada
  comerciante aporta capacidad (≈40 ud/trimestre) y reduce margen. Pacto comercial +25 % (GDD §5.4);
  expedición 2 PG, retorno a 2 trimestres, riesgo de pérdida.
- **Cota**: comercio ≤ ~20–25 % de la economía base (D-069), con upkeep/gasto de corte como sumideros (D-068).
- **Estado** (`save_version`): `inventory{g:qty}`, `merchants`, `market.prices{g}`, `trade_routes[]`,
  `expeditions[]`, con migración (inventario vacío, precios base).
- **Datos** (`trade_goods.json`): `id`, `name_es/name_en`, `category` (bulk/luxury/strategic),
  `base_price`, `unit`, `produced_by{terrain[],buildings[]}`, `used_by{recruit[],consume[]}`, `weight`;
  10 registros, ids únicos, referencias existentes.

## 7. Límites y declaración legal

- **No observado** (D-038): menús y comportamiento del original; esta checklist es contrato de UX propio.
- **No concluyente**: campos económicos de `SCENARIO`/`SAVEDATA` y existencia de mercancías/mercaderes en
  GK2 (sin archivo dedicado ni tabla aislable); no se persigue un port 1:1.
- **Legal**: sin desensamblado, sin texto literal, sin copiar assets; fuentes abiertas citadas.

## 8. Addendum D-074/D-075/D-076 — resumen y remisión

La búsqueda estructural no encontró tablas utilizables para D-074/D-075: barridos de secuencias
ascendentes `u8`/`u16` (ids/costes) en `SCENARIO`, `SAVEDATA`, `GENDATA`, `KGRP`, `GRPDATA` y `KOEI.DAT`
dieron **0 candidatos**; no hay tabla de límites por turno (el `actions_used` es estado runtime) y los
costes/menús residen previsiblemente en los `.EXE` (prohibidos) → **no observado / no concluyente**. Por
tanto son diseño propio, no port.

Resumen de lecciones: (a) clasificar acciones por naturaleza —corte (diplomacia, familia, construcción,
espionaje, expedición) **1/turno** con píldora, tooltip de usado y motivo diferenciado; logística
(reclutar/entrenar/disolver, trabajadores, mercado) **repetible** con contador—; (b) gate por acción y
objetivo, rechazo autoritativo `action_used` (sin doble gasto), reset/persistencia/migración; (c) costes
por tier (infantería < arqueros < caballería ligera < pesada < artillería), coste completo por tarjeta
(oro+hombres+mercancías), comparación por coste y test automático de la regla de tiers.

**Remisión:** el detalle completo (UX ampliada y checklist de 12 criterios C13/C14) está en
`docs/rea/notes_economy.md` §10. Este informe mantiene el resumen y cumple el límite de 2 páginas.
