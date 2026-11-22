# Notas técnicas — REA ampliado de batalla y gráficos de unidad (GK2)

**AG-REA · Fase 2 · GDD v1.5 §3.2 · 2026-11-21.** Anexo de método y medidas de
`docs/rea/gk2_battle_mechanics.md`. Solo archivos de datos; ningún `.EXE` abierto. No se conserva
ninguna imagen derivada ni copia de píxeles/paletas.

## 1. Verificación del entorno (DOSBox)

Consultas realizadas y resultado:

| Comprobación | Resultado |
|---|---|
| `Get-Command dosbox*` (PATH) | sin coincidencias |
| `C:\Tools` | contiene `ghidra`, `rea`, `stripe`; 0 entradas `dosbox*` |
| `C:\Program Files` y `C:\Program Files (x86)` (dirs con `dos`, `emul`, `retro`, `scumm`, `box`) | sin coincidencias |
| `C:\Users\horac\Downloads`, `AppData\Local\Programs`, `scoop`, `ProgramData\chocolatey`, `C:\Games`, `C:\Emulators` (profundidad 3, `dosbox*.exe`) | sin coincidencias |
| Búsqueda recursiva en `C:\Proyectos\TSB` por `*dosbox*` | sin coincidencias |
| Gestores disponibles | `winget` y `scoop` presentes |
| Red | `HEAD https://www.dosbox.com/` → HTTP 200 (red disponible) |
| Capturas de GK2 en el workspace | ninguna: `docs/screenshots/` son renders de **TSB** |

**Decisión:** no se instaló DOSBox. Motivos: (1) una instalación con `winget`/`scoop` escribiría fuera
de `C:\Proyectos\TSB` (prohibido por §3.1); (2) una instalación portable dentro del workspace es
técnicamente posible con la red disponible, pero **la observación no sería viable en esta sesión**:
llegar a una batalla de Nivel 2/3 exige jugar de forma interactiva (elegir escenario, declarar guerra,
mover ejércitos) con menús del juego, sin interfaz headless ni automatización fiable disponible, y no hay
material de captura previo que sirva de base. Se documenta la limitación y se solicita captura al usuario
(§4). *No* se inventaron observaciones.

## 2. `SUNIT.DAT` — medidas

- Tamaño 49.152 B; 49.152 = 2^12 · 3 · 4 = 96 · 512.
- Entropía 4,74 bit/B; 41,5 % `0x00`; 5,6 % `0xFF`; 3,1 % `0x80`; 2,7 % `0x01`; 1,9 % `0x40`;
  1,7 % `0xC0`; 1,6 % `0x03`; 1,6 % `0x08`; 255 valores distintos.
- Autocorrelación (lags 2–600), top: p=6 43,5 %; p=2 37,2 %; **p=512 36,8 %**; p=12 34,8 %; p=4 33,0 %;
  p=5 29,6 %; p=18 29,5 %; p=506 29,3 %; p=8 29,1 %; p=7 29,1 %. Esperado por azar ≈ 19 %
  (`Σp² ≈ 0,19`). El pico en 512 (y 506, vecino) es el único paso grande; p=6 y p=2 se explican por los
  tramos largos de ceros.
- Barrido 2D (comparación de filas a distancia W, 30 filas): W=16 12,5 %; W=32 12,0 %; W=64 11,8 %;
  W=128 19,0 %; W=256 24,0 %; W=512 37,9 %.
- Perfil de bloques de 512 B: ceros 33–51 %; `0xFF` 2–7 %; densidad variable ⇒ cuadros con distinta
  ocupación (compatible con animaciones).
- Paleta: 0 ventanas de 768 B con todos los bytes ≤ 63 (no hay paleta VGA 6-bit embebida). Las ventanas
  de 48 B que cumplen ≤63 son coincidencias locales (p. ej. en 767, 1093…) y no forman paletas.
- Pruebas de layout (solo internas, artefactos eliminados):
  - 4 bpp empaquetado 32×32 (2 px/byte): sin figuras reconocibles.
  - 4 bpp planar EGA 32×32 fila a fila y plano a plano: sin figuras reconocibles.
  - 8 bpp 32×16, 16×32, 16×64: sin figuras reconocibles.
  - 4 bpp empaquetado 64×16: sin figuras reconocibles.
- Conclusión: **96 cuadros de 512 B** es firme (periodicidad + divisibilidad exacta); la geometría de
  píxeles, profundidad de color y disposición de cuadros **no son concluyentes** con solo hex. Posible
  compresión propia de KOEI, orden de planos distinto o registro con cabecera. No se copió nada.

## 3. `KPAT.DAT` y `GRPDATA.DAT` — medidas

### 3.1 `KPAT.DAT`
- 45.450 B = 2 · 3² · 5² · 101. Entropía 2,22; 49,8 % `0x00`; 33,5 % `0xFF` (83,3 % binario).
- Cola de valores: `0xC0` 1,2 %, `0x03` 1,2 %, `0xFC` 1,1 %, `0x3F` 1,1 %, `0xF8` 1,1 %, `0x7F` 1,1 %
  (patrones de semibyte: valores casi-binarios con máscaras de 2/4 bits).
- Cabecera: bytes 0–7 = `37 00 5A 00 13 00 39 00` → cuatro `u16 LE` (0x0037, 0x005A, 0x0013, 0x0039);
  después campo de ceros extenso. No se interpreta como contador (valores pequeños y sin relación
  aparente con el tamaño).
- Autocorrelación top: p=2 56,5 %; p=21 56,1 %; p=22 55,7 %; p=20 55,3 %; p=18 54,3 %; p=19 54,0 %;
  p=42 53,0 %; p=55 52,4 %; p=56 52,1 %. Esperado por azar ≈ 36 %.
- Barrido 2D: W=21 61,8 %; W=42 62,7 %; W=101 60,8 %; W=150 49,4 %; W=202 49,2 %; W=225 47,9 %;
  W=450 29,5 %. Sugiere filas de ~21/42 B (o tramas con ese paso) y posible rejilla de 101.
- Render de prueba 1 bit a anchos 101/150/225/450: bandas horizontales de textura (no figuras). Se
  elimina; no se conserva. Interpretación: **banco de máscaras/patrones**, uso concreto no concluyente.

### 3.2 `GRPDATA.DAT`
- 45.475 B = 5² · 17 · 107. Entropía 4,95; 39,1 % `0x00`; 6,8 % `0xFF`.
- Perfil por 4 KB: `0x0000` 77 % ceros / 2 % FF; `0x1000` 38 % / 27 %; **`0x2000` 4 % / 1 % (densa)**;
  `0x3000` 29 % / 4 %; `0x4000` 65 % / 16 %; `0x5000` **5 % / 0 %**; `0x6000` 18 % / 0 %; `0x7000`
  45 % / 1 %; `0x8000` 55 % / 5 %; `0x9000` 29 % / 4 %; `0xA000` 62 % / 15 %; `0xB000` 65 % / 0 %.
  ⇒ varias sub-tablas/tilesets con densidades muy distintas.
- Cabecera: 40 B iniciales casi vacíos; después patrones de tramado (`54 7E 2A`, `55 AA` alternos) y
  estructuras repetidas: típico de datos gráficos/patrones, no de estado numérico.
- Autocorrelación top: p=4 38,4 %; p=8 37,4 %; p=12 36,0 %; p=16 34,7 %; p=24 33,8 %; p=6 33,7 %;
  p=20 33,0 %; p=40 32,9 %; p=36 32,4 %; p=80 32,0 %. Esperado por azar ≈ 17 %.
- Barrido 2D: W=17 34,3 %; W=20 48,3 %; W=25 30,7 %; **W=40 63,4 %**; **W=80 70,6 %**; W=85 58,8 %;
  W=100 64,3 %; W=107 58,6 %.
- Relación `KPAT` ↔ `GRPDATA`: correlación cruzada para desplazamientos −60..+60, máximo 0,233
  (esperado por azar ≈ 0,24) ⇒ tablas independientes; la diferencia de 25 B en tamaño no es cabecera de
  una respecto de la otra.
- Paleta embebida: 0 ventanas VGA de 768 B válidas.

## 4. Protocolo de capturas solicitado (para completar §2)

Para una reactivación posterior, pedir al usuario (vía lead) 3–5 capturas o un vídeo corto por bloque:

1. **Nivel 2, inicio de turno**: barra de estado completa (turno, moral, fase) con 2+ grupos visibles.
2. **Nivel 2, movimiento**: mover infantería y caballería; capturar antes/después (coste de movimiento en
   llano, bosque, río, ciudad).
3. **Nivel 2, choque**: resolución de un choque de grupos (pantalla de resultado incluida).
4. **Nivel 3, combate cerrado**: una ronda completa (cartas/órdenes disponibles y efecto).
5. **Moral/fatiga**: 2–3 asaltos consecutivos con la barra de moral visible.
6. **Proyectiles**: ataque de ballesteros, arqueros y bombarda (cuadro de disparo y proyectil en vuelo).

Formato: PNG/MP4, resolución nativa de DOSBox escalada ×2 como mínimo, sin recortar la UI. Con eso se
puede rellenar la tabla §2 sin analizar ejecutables.

## 5. Reproducibilidad

```powershell
$b=[IO.File]::ReadAllBytes("...\SUNIT.DAT")
# entropía
$c=New-Object 'int[]' 256; foreach($x in $b){$c[$x]++}
$h=0.0; foreach($k in $c){ if($k -gt 0){ $p=$k/$b.Length; $h-=$p*[Math]::Log($p,2) } }
# autocorrelación (paso de registro)
for($p=2;$p -le 600;$p++){ $eq=0; for($i=0;$i -lt $b.Length-$p;$i++){ if($b[$i] -eq $b[$i+$p]){$eq++} } }
# barrido 2D de anchos
foreach($W in 2..300){ ... comparar $b[$i] con $b[$i+$W] ... }
```

Búsqueda de paleta VGA: ventanas de 768 B con `max(seg) -le 63`; búsqueda de paleta de 16 colores:
ventanas de 48 B (descartadas por coincidencias múltiples).

## 6. Limpieza y legalidad

- Las previsualizaciones de hipótesis se generaron en `docs/rea/_tmp/` y se **eliminaron**; el
  directorio ya no existe. No quedan imágenes derivadas de GK2 en el repo ni en el entregable.
- No se copiaron píxeles, paletas, tiles ni texto; no se analizaron ejecutables (prohibido).
- Este anexo no es especificación de reimplementación: alimenta el diseño original de §10.3 con criterios
  de legibilidad (silueta, arma visible, proyectil visible) y declara como no concluyente lo que no pudo
  determinarse por hex.
