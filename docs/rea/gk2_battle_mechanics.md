# Mecánicas de batalla y gráficos de unidades GK2 — lecciones para §10.3

**The Sovereign's Blood · Fase 2 · GDD v1.5 §3.2 (REA ampliado) · AG-REA · 2026-11-21**

Alcance: análisis estructural de `SUNIT.DAT`, `KPAT.DAT` y `GRPDATA.DAT` (solo lectura) + lecciones de
diseño para §10.3. **No** se desensambló ningún `.EXE`, **no** se copiaron píxeles, paletas ni assets y
**no** se transcribió texto del juego. Detalle técnico y protocolo de capturas: `docs/rea/notes_battle.md`.

## 1. Método y estado de la observación

1. **Comprobación de entorno (DOSBox):** no instalado. Verificado en `PATH`, `C:\Tools`, `Program
   Files`/`Program Files (x86)`, `ProgramData\chocolatey`, `scoop`, `Downloads` y búsqueda recursiva en
   el workspace: 0 ejecutables `dosbox*`. La red sí responde (HTTP 200), por lo que una instalación
   portable dentro de `C:\Proyectos\TSB` sería técnicamente posible, pero **no se ejecutó**: llegar a una
   batalla de Nivel 2/3 exige una sesión jugada interactiva (selección de escenario → guerra → batalla)
   sin ruta headless ni automatización fiable, y no existe material de captura de GK2 en el workspace
   (las imágenes de `docs/screenshots/` son renders de TSB).
2. **Consecuencia:** las mecánicas de Nivel 2/3 **no están observadas**. Este informe **no inventa**
   observaciones: §2 declara qué falta y §3–§5 documentan lo que sí es determinable desde los datos.
3. **Método sobre datos:** lectura binaria con PowerShell, entropía de Shannon, autocorrelación de bytes
   (lags 2–600) para detectar paso de registro, perfiles por bloque (1–4 KB), correlación 2D por anchos
   candidatos (W = 2–300) y pruebas de hipótesis de layout gráfico (4 bpp empaquetado, 4 bpp planar EGA,
   8 bpp) renderizando candidatos **solo para análisis interno**; los artefactos de previsualización se
   eliminaron y no se conserva ninguna imagen derivada.

## 2. Observación de batalla (Nivel 2/3): estado

| Aspecto solicitado | Estado | Evidencia necesaria (capturas del usuario vía lead) |
|---|---|---|
| Orden de fases del turno táctico (movimiento/disparo/choque/moral) | **No observado** | 2–3 turnos completos del Nivel 2 con la barra de estado visible |
| Iniciativa y orden de activación de grupos | **No observado** | Inicio de turno con varios grupos y quién actúa primero |
| Movimiento: coste por hex/tipo de unidad, zonas de control | **No observado** | Mover infantería y caballería por llano/bosque/río |
| Resolución de choque (Nivel 3 o autocomputo) | **No observado** | Choque de dos grupos + pantalla de resultado |
| Efectos de terreno (llanura, bosque, ciudad, río) | **No observado** | Mismo combate en dos terrenos distintos |
| Moral y fatiga (indicadores, recuperación) | **No observado** | Varios asaltos seguidos mostrando la barra de moral |
| Cadencias del combate cerrado (rondas, cartas de orden) | **No observado** | 1 combate cerrado completo, ronda a ronda |
| Proyectiles visibles y trayectoria | **No observado** | Ataque de ballesteros/arqueros/bombarda en Nivel 3 |

**Lo que los datos sí permiten inferir** (inferencia, no observación): `SUNIT.DAT` está organizado en 96
bloques de 512 B y los otros dos archivos son bancos de patrones con estructura 2D — compatible con un
sistema de batalla de **mapa 2D por teselas + unidades representadas por cuadros pequeños**, no con
sprites grandes ni con un motor 3D. Es una hipótesis de arquitectura, no una descripción de reglas.

**Protocolo solicitado al usuario** (a través de lead): 3–5 capturas o un vídeo corto por punto de la
tabla, con la barra de estado/moral visible y el nivel de batalla indicado; bastan 1920×1080 (o la
resolución nativa de DOSBox escalada ×2). Con ese material se puede completar §2 en una reactivación
posterior sin tocar los `.EXE`.

## 3. `SUNIT.DAT` — banco de cuadros de unidad

| Propiedad | Valor observado | Evidencia |
|---|---|---|
| Tamaño | 49.152 B = **96 × 512 B** exactos | divisibilidad; sin resto |
| Entropía / nulos | 4,74 bits/B; 41,5 % `0x00`; 5,6 % `0xFF`; 255 valores distintos | histograma |
| Periodicidad | pico fuerte en **512** (36,8 % de coincidencia frente a ~19 % esperado por azar) | autocorrelación, lags 2–600 |
| Coherencia vertical | máx. en **W = 512** (37,9 %); muy superior a W = 32/64/128/256 | barrido 2D de anchos |
| Inicio del contenido | primer tramo a cero hasta `0x18`; el primer patrón denso aparece hacia `0x18`–`0x60` | dump y perfil por bloques |
| Densidad por bloque | 33–51 % de ceros y 2–7 % de `0xFF` por bloque de 512 B (varía) | estadística por bloque |
| Paleta embebida | **no detectada**: 0 ventanas de 768 B con todos los bytes ≤ 63 | búsqueda de paleta VGA 6-bit |
| Interpretación | 96 cuadros de 512 B; 512 B equivalen a 32×32 px a 4 bpp (1.024 px) o 32×16 a 8 bpp (512 px) | aritmética + pruebas de render |

**Estado: parcialmente concluyente.** El paso de 512 B y la existencia de 96 cuadros son firmes. Las
pruebas de render de candidatos (4 bpp empaquetado 32×32, 4 bpp planar EGA fila a fila y plano a plano,
8 bpp 32×16/16×32/16×64) **no produjeron figuras reconocibles**, por lo que la disposición exacta de
píxeles y la profundidad de color **no son concluyentes** (posible compresión propia de KOEI, orden de
planos distinto o formato de cuadro con cabecera). No se copió ningún píxel ni paleta.

**Lección de diseño (§10.3):** la referencia resuelve una unidad en **~512 B por cuadro** (unas 32 veces
menos datos que una hoja 64×64 en RGBA). Su legibilidad no viene del detalle, sino de la **pose clave** y
de la silueta con el arma extendida. Imitar la *economía* (pocos cuadros, poses muy marcadas, contraste
alto), nunca los píxeles.

## 4. `KPAT.DAT` — banco de patrones/máscaras

| Propiedad | Valor observado | Evidencia |
|---|---|---|
| Tamaño | 45.450 B = 2·3²·5²·101 (candidatos 450×101, 202×225, 150×303) | factorización |
| Entropía / nulos | 2,22 bits/B; 49,8 % `0x00` + 33,5 % `0xFF` = **83,3 % binario** | histograma |
| Valores no binarios | `0xC0`, `0x03`, `0xFC`, `0x3F`, `0xF8`, `0x7F`… (~1 % cada uno) | histograma: patrones de semibyte |
| Cabecera | primeros 8 B = cuatro `u16 LE` pequeños y luego campo de ceros; el resto del archivo domina lo binario | dump de cabecera |
| Estructura 2D | coherencia de fila alta en **W = 21** (61,8 %), **W = 42** (62,7 %) y **W = 101** (60,8 %), frente a ~36 % esperado | barrido de anchos 2–300 |
| Interpretación | banco de **máscaras/patrones binarios** (terreno, plantillas o siluetas) con algunos campos de valores | hipótesis, no confirmada |

**Estado: hipótesis.** La naturaleza mayoritariamente binaria y la coherencia por filas son sólidas; el
uso concreto (¿máscaras de terreno de batalla?, ¿plantillas de formaciones?) **no es determinable** por
hex. Se documenta como banco de patrones binarios de referencia, sin copiar contenido.

**Lección de diseño:** la referencia separa **máscara** (binaria, barata) de **color/detalle**. Para
§10.3/§6.2 conviene el mismo desacople: silueta/máscara de 1 bit para colisión, selección y sombra;
capa pintada encima para el estilo "miniatura".

## 5. `GRPDATA.DAT` — banco de teselas/patrones con estructura raster

| Propiedad | Valor observado | Evidencia |
|---|---|---|
| Tamaño | 45.475 B = 5²·17·107 | factorización |
| Entropía / nulos | 4,95 bits/B; 39,1 % `0x00`; 6,8 % `0xFF` | histograma |
| Secciones | `0x0000`–`0x0FFF` casi vacía (77 % ceros); `0x1000`–`0x1FFF` mixta (38 % ceros, 27 % `0xFF`); **`0x2000`–`0x2FFF` densa (4 % ceros)**; `0x5000`–`0x6FFF` también densa | perfil por bloques de 4 KB |
| Cabecera/patrones | tras 40 B iniciales aparecen patrones de tramado clásicos (`55 AA`, `54 7E 2A`) | dump |
| Coherencia 2D | **W = 80** (70,6 %), W = 40 (63,4 %), W = 100 (64,3 %) frente a ~17 % esperado | barrido de anchos 2–300 |
| Relación con `KPAT` | sin correlación por desplazamiento (máx. ~0,233 ≈ azar ~0,24) | correlación cruzada −60..+60 |
| Paleta embebida | no detectada (0 ventanas VGA de 768 B) | búsqueda de paleta |
| Interpretación | banco **gráfico** con secciones y filas de ~40/80 B (teselas o texturas de terreno); no es estado numérico de partida | hipótesis, no confirmada |

**Estado: parcialmente concluyente.** La estructura raster (filas de 80 B, secciones de densidad muy
distinta, tramados ordenados) es sólida; el tamaño exacto de tesela y su mapeo a la rejilla táctica **no
son concluyentes**. No se conserva ninguna imagen derivada.

**Lección de diseño:** el terreno de la referencia está **teselado y tramado** para ahorrar memoria con
paletas cortas. A 64 px y con arte pintado no necesitamos tramado, sino **familias de teselas
contrastadas** (llanura/bosque/ciudad/río) y transiciones suaves; la *lección* es la separación
terreno/unidad en capas y el uso de patrones repetibles, no su estética.

## 6. Lecciones de diseño para sprites 64×64 (§10.3)

1. **Silueta primero.** Contorno de tinta de 2–3 px y 3 valores de luminancia por unidad; prohibido el
   tramado a 64 px (a este tamaño ensucia). Prueba de aceptación: reconocer la unidad en silueta negra al
   25 %, 50 % y 100 % de escala.
2. **El arma define la unidad.** Lanza/pica: asta de 72–88 px en diagonal que **rompe el recuadro** de
   64 px (la pica puede salir de la caja); alabarda: cabeza de hacha inconfundible a 4 px; ballesta:
   ballesta horizontal con gafa y cinturín; arco largo: arco vertical de 56–64 px con cuerda visible;
   escudo heater vs. pavés por proporción.
3. **Poses clave, no cuadros de relleno.** Con 4–6 cuadros de ataque basta: 2 de anticipación (arma
   atrás), 1–2 de golpe (arma extendida, contacto), 1–2 de recuperación. Cadencia sugerida: marcha
   6–8 fps; ataque 10–12 fps con el contacto en el cuadro 3. Coincide con la economía de la referencia
   (512 B por cuadro) y con la hoja de §10.3 (idle 2, marcha 4, ataque 4–6, impacto 2, muerte 2).
4. **Direcciones por espejo.** Modelar S, SE y E; el resto por espejo horizontal/vertical, como ya prevé
   §10.3. Mantener el arma en el mismo lado para no romper la lectura.
5. **Proyectiles en capa aparte.** Virote 8–16 px, flecha 12–20 px, piedra de bombarda 8–12 px, con
   trayectoria balística visible: virote casi tenso (3–5 cuadros), flecha en arco (6–8), piedra en lob
   (8–12) + impacto con polvo. Regla de legibilidad: el proyectil debe medir ≥ 4 px en pantalla al 100 %.
6. **Contraste con el terreno.** Teselas desaturadas y unidades con acento de facción (penacho/escudo)
   en el color de §10 (azul tinta, ocre, dorado, rojo grana); sombra de contacto de 1–2 px para separar
   la unidad del hex.
7. **Escala y consistencia.** Mantener proporciones entre infantería (64×64) y caballería (64×80) con una
   misma línea de horizonte; el mismo estilo que los retratos §10.2 (trazo de ilustración, no pixel art).
8. **Datos y QA.** Hoja como grilla regular (p. ej. 8 columnas) + mapa de animación en `units.json`
   (`sprite_sheet`, `frame_size`, `animations{idle:[..], attack:[..]}`); validación en CI: cada hoja
   referenciada existe, cuadros exactos, y captura de las 3 unidades de ejemplo de §10.3.

## 7. Límites y declaración legal

**Límites:** (a) mecánicas de Nivel 2/3 **no observadas** (DOSBox no instalado; sin capturas de GK2;
no se instaló emulador por no ser viable completar la observación en esta sesión); (b) `SUNIT.DAT`:
paso de 96×512 B firme, pero dimensiones/frames/profundidad de color **no concluyentes**; (c) `KPAT.DAT`:
banco binario de patrones confirmado como estructura, uso no; (d) `GRPDATA.DAT`: estructura raster con
filas de ~40/80 B, tamaño de tesela y mapeo no concluyentes; (e) no se detectó paleta embebida en ninguno
de los tres; (f) no se analizaron ejecutables (prohibido). Lo no determinable se declara, no se estima
como si fuera observación.

**Declaración legal:** análisis estructural limitado con fines personales de estudio (GDD §3.2). No se
descompiló ni desensambló ningún ejecutable, no se copiaron píxeles, paletas ni assets de Koei, y no se
transcribió texto del juego. Las previsualizaciones internas usadas para probar hipótesis de layout se
eliminaron y no forman parte del repositorio ni del producto. Las lecciones de §6 son criterios de diseño
propios inspirados en la *legibilidad* de la referencia, no una reimplementación de su arte.
