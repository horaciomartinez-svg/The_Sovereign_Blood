# Lecciones de modelado de datos de GK2

**The Sovereign's Blood · Fase 0 · criterios A1/A6 (GDD §12) · AG-REA · 2026-11-21**

Alcance: inspección estructural *solo* de archivos de datos (`.DAT`/`.GK2`) del ejemplar de referencia
Genghis Khan II, en modo lectura. No se abrió ningún ejecutable (`MAIN.EXE`, `OPEN.EXE`, `END.EXE`).
Detalle técnico y reproducibilidad: `docs/rea/notes.md`.

## 1. Inventario

Entropía de Shannon (H) en bits/byte; `%0` = fracción de bytes `0x00`.

| Archivo | Bytes | H | %0 | Tipo de contenido inferido |
|---|---:|---:|---:|---|
| `GENDATA1..4.DAT` | 7.827 c/u | 2,67–4,02 | 54,7–71,0 | Plantilla de personajes por escenario: 99 ranuras de 27 B + subtablas |
| `ZNAME.DAT` | 1.122 | 2,60 | 64,4 | 66 nombres de región de 17 B, ASCII, relleno `0x00` |
| `SCENARIO.GK2` | 49.841 | 2,70 | 70,8 | Base de mundo del escenario 1 (prólogo + roster + tablas) |
| `SAVEDATA.GK2` | 47.137 | 3,00 | 67,4 | Partida guardada con el mismo esquema que el escenario |
| `MAPDATA.DAT` | 177.031 | 6,52 | 0,9 | Mapa; codificación no concluyente (§2.4) |
| `HEXKG.DAT` | 46.624 | 5,44 | 8,1 | 1.457 registros de 32 B; semántica no concluyente |
| `HEXSG.DAT` | 43.332 | 3,63 | 3,8 | Mapa de celdas de 1 B con relleno `0xC8` (53,6 %) |

Resto de `.DAT`/`.MOB` presentes (no prioritarios, sin análisis profundo): `GRPDATA`, `KGRP`, `SGRP`,
`ENDGRP`, `OPENGRP`, `SUNIT`, `KPAT`, `PACKDATA`, `KAODATA`, `QKAODATA`, `KOEI.DAT`, `USDATA1..4`,
`DA_LENCH.MOB`. Los `.EXE` y `.COM` no se abrieron (prohibición §3 del GDD).

## 2. Estructuras observadas

### 2.1 `GENDATA1..4.DAT` — plantilla de personajes

Los cuatro pesan exactamente lo mismo y comparten arquitectura: cambia el contenido, no el esquema.
Tamaños de registro detectados por autocorrelación (picos en 27, 54, 81, 108…) y por columnas.

| Offset | Campo | Tipo / tamaño | Observado | Notas |
|---|---|---|---|---|
| `0x0000` | Cabecera | 2 B `FF 00` | igual en los 4 | Separador, no contador |
| `0x0002`–`0x0A72` | Ranura de personaje ×99 | 27 B | 47/72/69/70 con nombre (1/2/3/4) | Capacidad fija deducida del cambio de tabla posterior; sin contador |
| +0x00 | Nombre | `char[17]` ASCII, relleno `0x00` | 1–12 caracteres usados | El relleno hace de terminador |
| +0x11 | Campo A | `u8[2]` | `00 00`, `FF FF` y pares pequeños por grupos (`1A 01`, `0D 02`…) | Candidato a máscara/índice; función no confirmada |
| +0x13 | Campo B | `u8[8]` = 16 semibytes | semibytes 0–15; primer byte suele ser valor de 4 bits replicado (`FF`, `CC`, `AA`…) | Probables 16 atributos empaquetados 2×4 bits; no confirmado |
| `0x0A80`–`0x0B7F` | Indicadores | byte `0x80` a paso 27 B | 10 marcas | Función no determinada |
| `0x102C` | Marca | ASCII 4 B `GNG2` | única en el archivo | Identificador de subsección |
| `0x11D0`–`0x14CF` | Facciones ×32 | 24 B = 4+16+4 | 16/32/22/29 nombres en GENDATA1/2/3/4; nombre ≤16 B | Campos laterales de 4 B sin identificar |
| `0x14EC`… y `0x16BF`–`0x1B99` | Tablas de nombres | paso 22 B y 27 B | ~24 y ~19 entradas; nombres ≤12 B | Semántica no determinada; no coinciden con `ZNAME` |

### 2.2 `ZNAME.DAT` — nombres de región

| Offset | Campo | Tipo / tamaño | Observado |
|---|---|---|---|
| `0x0000`–`0x0461` | Nombre ×66 | `char[17]` ASCII, relleno `0x00` | 66 ranuras, 47 con nombre, longitud 1–14; sin cabecera ni contador |

Es una tabla de nombres pura: los archivos de mundo referencian la ranura por índice (0–65), sin repetir
el texto.

### 2.3 `SCENARIO.GK2` y `SAVEDATA.GK2` — escenario frente a guardado

| Offset | Campo | Tipo / tamaño | Observado | Notas |
|---|---|---|---|---|
| `0x0000` | Cabecera | 6 B | `00×6` en escenario; `FF 01 00 00 00 00` en guardado | Marca partida iniciada |
| `0x0006`–`0x00B4` | Prólogo | 5 filas × 35 B = 175 B | relleno `0x2D`; en guardado la fila 1 lleva fecha/partida ASCII de 29 B | Prólogo total 181 B |
| `0x00B5` | Marca de roster | 2 B `FF 00` | igual que en `GENDATA*` | |
| `0x00B7`–`0x0B27` | Roster ×99 | 27 B por ranura | en escenario es **byte a byte idéntico** al roster de `GENDATA1.DAT` (2.673 B, 100 %) | Mismo layout que §2.1 |
| resto | Tablas de mundo | replican la familia de `GENDATA*` (+181 B) y añaden tablas propias | 49.841 B (escenario) vs 47.137 B (guardado): Δ 2.704 B | Diferencias en bloques concretos, no en secciones nuevas |
| `0x15B5`–`0x1DB5` | Tablas estáticas | 7 bloques de 256 B idénticos (≥97,7 %) escenario↔guardado | contenido compartido (nombres/definiciones) | Ningún bloque bajó del 2,3 % de igualdad |

Estructuralmente no hay un "formato de guardado" aparte: el motor escribe el estado de partida **sobre
las mismas tablas** del escenario.

### 2.4 `MAPDATA.DAT`

| Offset | Campo | Tipo / tamaño | Observado |
|---|---|---|---|
| `0x0000` | Posible cabecera | 1 B (`0x80`) | tamaño impar: `177.031 = 1 + 177.030` |
| `0x0001`… | Datos de mapa | por determinar | 177.030 = 281×630 = 315×562 = 2×88.515; sin periodicidad de fila (anchos 2–700) |

Compatible con 281×630 celdas de 1 B (o 281×315 de `u16`), pero sin correlación que confirme el orden;
entropía 6,52 y ausencia de periodicidad apuntan a datos empaquetados/comprimidos.

### 2.5 `HEXKG.DAT` y `HEXSG.DAT`

| Archivo | Estructura | Observado | Notas |
|---|---|---|---|
| `HEXKG.DAT` | 1.457 registros de 32 B exactos | bytes ≤ `0x7B`; 8,1 % nulos; perfiles por columna homogéneos | Layout confirmado; binario no textual; semántica no concluyente |
| `HEXSG.DAT` | 43.332 celdas de 1 B | relleno `0xC8` 53,6 %; 116 valores distintos; primer no-relleno en `0x30` | Autocorrelación fuerte a 24 B (57 % vs ~31 % base) sin rejilla 2D coherente; orden/codificación no concluyentes |

## 3. Equivalencias GK2 → JSON del GDD §7

| GK2 (evidencia) | Nuestro destino | Nota de diseño |
|---|---|---|
| Personaje: nombre 17 B + 16 atributos de 4 bits + 2 B de agrupación | `characters.json`: `id`, `name`, `stats{command,intrigue,charisma,loyalty,education}`, `house`, `faction` | Escala 0–15 → 0–100: documentar conversión, no copiarla |
| Roster fijo de 99 ranuras con huecos y byte `0x80` | `characters.json` + `initial_state` del escenario | Sin capacidad fija: IDs estables y listas dispersas |
| Facciones: nombre 16 B + dos campos de 4 B | `factions.json`: `name`, `capital`, `government`, `color`, `playable` | Índice de ranura → tabla `index → id` |
| `ZNAME.DAT`: 66 nombres ordenados | `regions.json`: `name`, `adjacency` | El orden GK2 es índice implícito; nosotros IDs explícitos |
| `SCENARIO.GK2`: prólogo + roster + tablas | `scenarios/scenario_1337.json`: `initial_state`, `factions`, `victory`, `events_script` | Escenario = datos inmutables + estado inicial |
| `SAVEDATA.GK2`: mismos offsets, campos mutables cambiados | `user://saves/*.json`: `turn`, `year`, `quarter`, `factions[]`, `regions[]`, `armies[]`, `event_log`, `save_version` | El guardado es snapshot completo y versionado |
| Cabecera de guardado con fecha/partida de 29 B | `save_version` + metadatos (`year`, `quarter`, `faction`, `scenario_id`) | Añadir resumen legible para la UI |
| `HEXSG`: celda con `0xC8` = sin región | `regions.json`: `owner`/`region_id` anulables + `terrain` | Sin centinelas numéricos: `null` y enums validados |

## 4. Lecciones de modelado

1. **Escenario y guardado comparten esquema.** El guardado reescribe campos sobre las mismas tablas; no
   hay formato alternativo. Nuestro save debe serializar el modelo completo con `save_version` y
   migraciones (GDD §7.7).
2. **Capacidad fija + huecos.** 99 ranuras de personaje, 66 de región, 32 de facción, casi todas vacías:
   el motor tolera huecos y reutiliza índices. Nuestro JSON debe usar IDs estables y validar referencias,
   no posiciones.
3. **Duplicación deliberada.** El escenario contiene una copia exacta del roster de `GENDATA1` (2.673 B):
   lección negativa; nosotros mantenemos una única fuente y referenciamos desde el escenario.
4. **Atributos empaquetados.** 16 atributos en 8 B, escala 0–15; nuestros stats 0–100 deben documentar
   escala y conversión; el JSON no empaqueta bits (legibilidad y validación).
5. **Centinelas dispersos.** `0x00` (vacío), `0xFF`/`0xFFFF` (sin dato) y `0xC8` (sin región) conviven con
   valores válidos: preferir `null`/`""` y enums, con tabla de equivalencias si se importa el original.
6. **Nombres en tabla aparte.** `ZNAME` separa texto de entidades: replicar IDs + tabla de
   nombres/localización evita duplicar texto y facilita ES/EN.
7. **Metadatos en el guardado.** La cabecera del save guarda fecha/partida; el escenario no: nuestro save
   necesita año/trimestre/facción y `scenario_id` para validar la carga.
8. **Escenarios = mismo esquema, distinto contenido.** Los cuatro `GENDATA*` pesan igual: un solo esquema
   para `scenario_1337/1402/1453`, variando sólo datos.
9. **Registro de tamaño fijo y relleno `0x2D`** en textos: en JSON no hace falta, pero sí un validador que
   detecte registros incompletos y campos de texto acolchados.
10. **Determinismo y orden.** El roster coincide byte a byte entre `GENDATA1` y `SCENARIO.GK2`: índices y
    orden estables. Nuestros datos deben ser deterministas (mismo JSON → mismo estado inicial) para que
    simulación y tests sean reproducibles.

## 5. Método, límites y declaración legal

**Método:** lectura binaria con PowerShell (`ReadAllBytes`), entropía de Shannon por archivo y por bloque,
perfiles `%0x00`/`%0xFF`/relleno, autocorrelación de bytes (lags 2–700) para tamaño de registro,
estadísticas por columna para candidatos, detección de cadenas ASCII de longitud fija y comparación
bloque a bloque (256 B) entre escenario y guardado. Un tamaño de registro se acepta sólo si
autocorrelación y columnas son coherentes; una tabla, sólo si el paso se repite en todo el rango.

**No concluyente:** (a) semántica del campo A y de los 16 semibytes (exigiría análisis de ejecutable,
prohibido); (b) `MAPDATA`: orientación, tamaño de celda y codificación no confirmados pese al tamaño
281×630; (c) `HEXKG`/`HEXSG`: paso de 32 B y relleno `0xC8` confirmados, pero no el significado de los
valores ni el orden de celdas; (d) tablas secundarias de `GENDATA*` (pasos y longitudes determinados,
significado no); (e) recuento de ranuras sin contador explícito (margen ±1 en 99); (f) relaciones
familiares, economía, batalla e IA: fuera del alcance §3 y no analizables sin ejecutable.

**Declaración legal.** Análisis estructural limitado con fines personales de estudio (GDD §3). No contiene
código derivado del binario, fórmulas literales ni material transcrito del juego: sólo longitudes,
offsets, tamaños y recuentos, sin listar nombres de regiones, personajes ni facciones. El producto final
de The Sovereign's Blood no incorpora material derivado de Koei.
