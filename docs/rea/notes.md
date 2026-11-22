# Notas técnicas REA — GK2 (anexo de `gk2_data_lessons.md`)

**AG-REA · Fase 0 · 2026-11-21.** Este anexo contiene el detalle de método, medidas y preguntas
abiertas. No forma parte del entregable de 2 páginas. Sólo archivos `.DAT`/`.GK2`/`.MOB`; ningún
ejecutable fue abierto.

## 1. Método y reproducibilidad

Herramientas: PowerShell (`[System.IO.File]::ReadAllBytes`), estadística propia y, opcionalmente,
`rea-mcp` (no fue necesario: la inspección hex/estadística bastó). Directorio de referencia (sólo
lectura): `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf`.

Procedimiento aplicado a cada archivo:

1. Tamaño exacto y factorización (para descartar/anclar tamaños de registro y rejillas).
2. Entropía de Shannon: `H = -Σ p·log2(p)` sobre 256 valores; además `%0x00`, `%0xFF` y `%0xC8`.
3. Perfil por bloques de 256 B (ceros / imprimibles / relleno) para localizar secciones.
4. Autocorrelación de bytes para lags 2–700: `match(p) = #{i : b[i]=b[i+p]} / (n-p)`; baseline =
   probabilidad de coincidencia por azar (`Σ pᵢ²`). Picos en múltiplos de un valor ⇒ tamaño de registro.
5. Estadísticas por columna para candidatos de registro: `%` imprimible, `%` cero, nº de valores
   distintos, mín./máx. Un candidato válido debe mostrar columnas de texto coherentes y columnas
   numéricas con rangos estables.
6. Búsqueda de cadenas ASCII de longitud fija (runs ≥4 imprimibles) y de posiciones de nombre:
   diferencia entre posiciones consecutivas ⇒ paso de registro.
7. Comparación entre archivos: igualdad byte a byte por bloque de 256 B; alineación por anclas de 16 B
   (claves `BitConverter.ToString`) para estimar desplazamientos.

Comandos representativos (PowerShell, sin dependencias):

```powershell
$b=[IO.File]::ReadAllBytes($f)
$c=New-Object 'int[]' 256; foreach($x in $b){$c[$x]++}
$h=0.0; foreach($k in $c){ if($k -gt 0){ $p=$k/$b.Length; $h-=$p*[Math]::Log($p,2) } }
for($p=2;$p -le 700;$p++){ $eq=0; for($i=0;$i -lt $b.Length-$p;$i++){ if($b[$i] -eq $b[$i+$p]){$eq++} } }
```

## 2. Inventario completo (archivos de datos)

Entropía en bits/byte. Se excluyen `MAIN.EXE`, `OPEN.EXE`, `END.EXE`, `FMDRV.COM`, `KOEI.COM`
(prohibidos o irrelevantes).

| Archivo | Bytes | H | %0x00 | %0xFF | Tipo inferido |
|---|---:|---:|---:|---:|---|
| `GENDATA1.DAT` | 7.827 | 2,67 | 71,0 | 3,4 | Plantilla personajes escenario 1 |
| `GENDATA2.DAT` | 7.827 | 4,02 | 54,9 | 2,0 | Ídem escenario 2 |
| `GENDATA3.DAT` | 7.827 | 3,86 | 57,0 | 2,0 | Ídem escenario 3 |
| `GENDATA4.DAT` | 7.827 | 4,02 | 54,7 | 2,1 | Ídem escenario 4 |
| `ZNAME.DAT` | 1.122 | 2,60 | 64,4 | 0,0 | 66 nombres de región (17 B) |
| `SCENARIO.GK2` | 49.841 | 2,70 | 70,8 | 2,8 | Mundo del escenario 1 |
| `SAVEDATA.GK2` | 47.137 | 3,00 | 67,4 | 3,1 | Partida guardada (mismo esquema) |
| `MAPDATA.DAT` | 177.031 | 6,52 | 0,9 | 4,2 | Mapa; no concluyente |
| `HEXKG.DAT` | 46.624 | 5,44 | 8,1 | 0,0 | 1.457 × 32 B; no concluyente |
| `HEXSG.DAT` | 43.332 | 3,63 | 3,8 | 0,0 | Celdas 1 B, relleno 0xC8 |
| `GRPDATA.DAT` | 45.475 | 4,95 | 39,1 | 6,8 | No analizado en profundidad |
| `KGRP.DAT` | 58.656 | 6,19 | 16,5 | 8,2 | No analizado |
| `SGRP.DAT` | 144.576 | 5,13 | 38,7 | 6,6 | No analizado |
| `ENDGRP.DAT` | 638.436 | 6,63 | 4,1 | 0,8 | No analizado |
| `OPENGRP.DAT` | 306.342 | 6,63 | 0,5 | 1,3 | No analizado |
| `SUNIT.DAT` | 49.152 | 4,74 | 41,5 | 5,6 | No analizado |
| `KPAT.DAT` | 45.450 | 2,22 | 49,8 | 33,5 | No analizado |
| `PACKDATA.DAT` | 461.898 | 6,37 | 9,8 | 0,7 | No analizado |
| `KAODATA.DAT` | 730.368 | 5,86 | 20,0 | 9,2 | No analizado |
| `QKAODATA.DAT` | 262.944 | 5,70 | 20,7 | 13,0 | No analizado |
| `KOEI.DAT` | 8.839 | 5,64 | 6,3 | 3,0 | No analizado |
| `USDATA1.DAT` | 1.456 | 2,50 | 72,2 | 0,1 | No analizado |
| `USDATA2..4.DAT` | 2.184 c/u | 2,36–2,65 | 71,5–74,6 | 0–1,3 | No analizado |
| `DA_LENCH.MOB` | 490 | 3,23 | 0,0 | 0,0 | No analizado |

## 3. `GENDATA1..4.DAT` — detalle

- Tamaño idéntico en los 4: 7.827 B. Autocorrelación de GENDATA1: picos en 27 (63,3 %), 54 (63,6 %),
  81 (60,8 %), 108 (61,9 %) frente a un baseline ~5,4 %; confirma registro de 27 B.
- Cabecera de 2 B `FF 00`; después, nombres en `0x0002 + 27·k`. Ejemplos de posiciones de nombre:
  `0x0002, 0x001D (+27), 0x0038 (+27), 0x0053, 0x006E, 0x00A4 (k=6), …` hasta `0x0A58` (k=98).
  Para `k ≥ 99` (offset ≥ `0x0A73`) el patrón de columnas cambia: fin de la tabla.
- Layout de ranura de 27 B, confirmado por columnas:

| Offset interno | Bytes | Contenido |
|---|---:|---|
| 0–16 | 17 | Nombre ASCII relleno de `0x00`; longitud utilizada 1–12 |
| 17–18 | 2 | Campo A: `00 00`/`FF FF` y pares pequeños que se repiten por grupos |
| 19–26 | 8 | Campo B: 16 semibytes; rangos por byte observados: máx. alto = 15,4,4,3,8,0,15,9; máx. bajo = 15,3,4,15,13,3,14,15 |

- Ranuras con nombre por archivo (k=0..98): GENDATA1 = 47, GENDATA2 = 72, GENDATA3 = 69,
  GENDATA4 = 70. El resto son ceros o marcadores (`FF FF`).
- En el campo B, el primer byte aparece con semibytes iguales (`FF`, `CC`, `AA`, `77`, `88`, `99`…),
  lo que sugiere un valor de 4 bits replicado (posible convención de lectura de 4 bits como byte);
  el resto de bytes presenta semibytes de 0–15 pero no siempre iguales. Interpretación pendiente.
- Subtablas posteriores (offsets referidos a GENDATA2, idénticos en estructura a los otros):

| Offset aprox. | Estructura | Evidencia |
|---|---|---|
| `0x0A80`–`0x0B7F` | byte `0x80` cada 27 B (10 marcas) | función no determinada; sólo un byte no nulo por registro |
| `0x102C` | ASCII `GNG2` (4 B) | única aparición; marca de subsección |
| `0x11D0`–`0x14CF` | 32 registros de 24 B = 4 B + `char[16]` + 4 B | 16/32/22/29 nombres en GENDATA1/2/3/4; nombres de hasta 16 B |
| `0x14EC`… | ~24 entradas con nombre, paso 22 B | nombres ≤11 B; no coinciden con `ZNAME` |
| `0x16BF`–`0x1B99` | ~19 entradas con nombre, paso 27 B | nombres ≤12 B; no coinciden con `ZNAME` |
| `0x1E93` | fin de archivo | |

- No se encontró campo contador de personajes; la capacidad de 99 se deduce del cambio de estructura
  en `0x0A73` y de la coherencia de columnas (margen ±1).

## 4. `ZNAME.DAT` — detalle

- 1.122 = 66 × 17 exactos; sin cabecera.
- 66 ranuras; 47 con nombre; longitud 1–14; todo ASCII imprimible; relleno `0x00`.
- Distribución de longitudes: 5→11, 6→7, 7→6, 8→2, 9→4, 10→3, 11→4, 12→1, 13→4, 14→5, vacías→19.
- No hay campos numéricos por fila: el índice (0–65) es la referencia.

## 5. `SCENARIO.GK2` y `SAVEDATA.GK2` — detalle

- Tamaños: 49.841 vs 47.137 (Δ = 2.704 B).
- Prólogo de 181 B en ambos: 6 B de cabecera + 5 filas de 35 B. En SCENARIO la cabecera es `00×6` y
  cada fila es 34 caracteres de relleno `0x2D` + terminador `0x00`; en SAVEDATA la cabecera es
  `FF 01 00 00 00 00` y la fila 1 contiene una cadena ASCII de 29 B (fecha/partida) + relleno `0x2D`.
- Roster en `0x00B5`: marca `FF 00` + 99 × 27 B desde `0x00B7`. En SCENARIO, comparado con
  `GENDATA1[0x0002..]`, resultado: **2.673/2.673 bytes iguales (100 %)**.
- Comparación por bloques de 256 B entre SCENARIO y SAVEDATA (desde 181): 7 bloques idénticos al
  ≥97,7 %, en `0x15B5, 0x18B5, 0x19B5, 0x1AB5, 0x1BB5, 0x1CB5, 0x1DB5`; ningún bloque resultó ≤2,3 %
  de igualdad. La diferencia de 2.704 B se reparte en los campos mutables (contadores, dueños,
  posiciones) y en los bloques de texto del prólogo.
- Conclusión: escenario y guardado son la misma base de datos; el guardado sobrescribe estado. No hay
  sección nueva de "partida".
- No se determinó qué tabla almacena dueños de región, tesoros o asignaciones; están entre las tablas
  posteriores al roster, cuya semántica no se descifró sin ejecutable.

## 6. `MAPDATA.DAT` — pruebas realizadas (todas no concluyentes)

- Tamaño 177.031 = 1 + 177.030; 177.030 = 2·3²·5·7·281. Descomposiciones "bonitas": 281×630,
  315×562, 2×88.515 (= 2 celdas de 1 B por celda lógica de 281×315).
- Entropía 6,52; sólo 0,9 % de ceros; el byte `0x38` aparece 15,2 %, `0xFF` 4,2 %, `0x0F` 3,8 %,
  `0x20` 2,7 %, `0xF0` 2,5 %, `0xC0` 2,4 %.
- Autocorrelación: máximo 10,6 % en p=3 (vs 5,4 % base), 7,1 % en p=6, 6,2 % en p=4, 6,1 % en p=9;
  no hay pico en 281/630/315/562.
- Correlación 2D (celda vs fila siguiente) para anchos candidatos y tamaños de celda 1/2/3/4: todos
  ~5 % (baseline). Igual para 281×630, 281×315, 315×562, 157×1.127, 210×843, 630×281.
- Histogramas por fase para registros de 3 B (offsets 0–3): distribuciones idénticas ⇒ no hay registros
  de 3 B con campos fijos; el pico en p=3 puede deberse a motivos locales repetidos.
- No se intentó descompresión (se desconoce el algoritmo) ni análisis de ejecutable (prohibido). Se
  documenta como **no concluyente**.

## 7. `HEXKG.DAT` y `HEXSG.DAT` — detalle

`HEXKG.DAT`:
- 46.624 = 32 × 1.457 exactos (sin resto). 1.457 = 31 × 47.
- Todos los bytes ≤ `0x7B` (123); 0 % > 127; 8,1 % ceros; 124 valores distintos.
- Perfiles por columna (32 columnas de 1.457 valores): % de ceros 4–11 %, mín. 0, máx. 119–123 en todas
  las columnas ⇒ estructura homogénea compatible con datos de imagen/tile de 8 bits, no con una tabla
  de campos heterogéneos. Sin periodicidad 2D coherente (mejor ancho 31/32 al ~29 %, cerca del azar).
- Contenido no textual: sin cadenas ASCII de longitud fija ni terminadores NUL sistemáticos.

`HEXSG.DAT`:
- 43.332 = 276 × 157 = 12 × 3.611 = 4 × 3 × 3.611; 3.611 = 23 × 157.
- 0xC8 = 53,6 % (relleno/mar); 116 valores distintos; rango no-relleno 0–255; 3,8 % ceros.
- Primer byte no-relleno en `0x30` (los 48 B iniciales son `0xC8`).
- Autocorrelación: máximo en p=24 (57,4 %), 23 (54,8 %), 25 (53,3 %), 48 (50,7 %), 22 (50,5 %);
  baseline ~31 % (por el dominio de `0xC8`). Vertical a 24 B = 57,2 % vs horizontal 60,8 %.
- Correlación 2D para anchos 23/24/46/69/92/138/157/276/314/471/628/942/1884 y offsets 0/12/24/48:
  vertical 27–57 %, horizontal ~60 %; ninguna combinación muestra rejilla coherente ⇒ el archivo no
  está en orden de filas simple o usa otra rejilla/transformación. No concluyente.

## 8. Preguntas abiertas (para una eventual fase REA adicional, con autorización explícita)

1. ¿Qué representan los 2 B del campo A de personaje (máscara de escenarios, clan, padre, estado)?
2. ¿Los 16 semibytes del campo B son 16 atributos? ¿Qué escala y en qué orden?
3. ¿Qué tablas de `GENDATA*` posteriores al roster almacenan facciones vs regiones vs tribus?
4. ¿Cuál es el orden real de las celdas de `HEXSG`/`HEXKG` y su mapeo a la rejilla de `MAPDATA`?
5. ¿`MAPDATA` usa compresión KOEI? ¿Cuál es la cabecera real (1 B? 4 B?)?
6. ¿Qué campos del guardado cambian respecto al escenario (dueño, asignación, tesoro, moral)?

Responder 1–4 requeriría análisis del ejecutable, **prohibido** por el GDD §3; por eso el informe
principal declara esos puntos como no concluyentes y el desarrollo no depende de ellos.

## 9. Declaración legal

Análisis estructural limitado con fines personales de estudio (GDD §3). Sin código derivado del
binario, sin fórmulas literales y sin material transcrito: este anexo no contiene nombres de regiones,
personajes ni facciones, ni listas de texto del juego; sólo offsets, tamaños, recuentos, entropías y
descripciones de layout. El producto final de The Sovereign's Blood no incorpora material derivado
de Koei.
