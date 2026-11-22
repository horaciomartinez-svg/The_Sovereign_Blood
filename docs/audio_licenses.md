# Licencias y procedencia de la banda sonora — The Sovereign's Blood (MVP-1337)

| Campo | Valor |
|---|---|
| **Documento** | `docs/audio_licenses.md` |
| **Tramo** | Fase 3.3 — MVP-1337, directiva v2 (D-066/D-067) |
| **Autor** | AG-1 (Historian / Data), a partir del manifiesto de AG-5 `assets/audio/music/manifest.json` (schema 2) |
| **Fecha** | 2026-11-22 |
| **Alcance** | 6 pistas OGG de música de fondo + 3 SFX generados del MVP |
| **Estado** | **6/6 pistas verificadas**; todas las pistas y arreglos son **originales de TSB (CC0)**; sin transcripciones, grabaciones ni samples de terceros |
| **Regla legal** | GDD §3 / §10 y prompt v2 §2.5: prohibido material con copyright o licencias que excluyan obra derivada; sin solicitudes a Kimi ni descargas de música |

## 1. Principio de licencia (revisión schema 2)

1. **Melodía original de TSB**: las 6 pistas han sido compuestas por el equipo (AG-5) y
   sintetizadas con `tools/generate_audio_tracks.py` (numpy → WAV 44,1 kHz mono 16 bits → OGG
   Vorbis con ffmpeg). **No se transcribe ninguna melodía de terceros** (ni CSM 12, ni Estampie
   Reale, ni material ABC de ninguna web).
2. **Formas históricas de dominio público**: cada pista se inspira en una **forma/danza histórica**
   (cantiga/consort, estampie, saltarello, ductia, fanfarria de trompetería). Las formas y géneros
   musicales históricos no son objeto de copyright; se citan como referencia estilística, no como
   fuente melódica. Los `source_url` del manifiesto son solo citas de la forma (`form_reference`),
   no enlaces de descarga.
3. **Grabación/arreglo**: instrumentación, contrapunto, percusión, mezcla, normalización y bucle
   son originales de TSB. Los arreglos se declaran **CC0** en el manifiesto. No se usa ninguna
   grabación, sample, soundfont ni librería de audio de terceros.
4. **Atribución**: al ser obra original de TSB no hay autoría externa que acreditar; se citan las
   formas históricas por rigor documental (GDD §10) y se acredita al equipo TSB como autor.

## 2. Tabla de las 6 pistas (manifiesto schema 2 de AG-5)

Contextos y rutas según `data/audio_tracks.json` (D-067). Composiciones, duraciones y licencias
según `assets/audio/music/manifest.json` schema 2.

| # | Contexto | Fichero OGG | Composición (original TSB) | Forma histórica citada (PD) | Licencia | Arreglo / síntesis | Duración | Loop |
|---|---|---|---|---|---|---|---|---|
| 1 | Menú principal | `assets/audio/music/menu_consort.ogg` | **Original TSB — «Consort de menú»** | Cantiga/consort s. XIII-XV — https://es.wikipedia.org/wiki/Cantigas_de_Santa_Mar%C3%ADa | **Original TSB (CC0)** | Síntesis propia TSB (flauta, vielle, laúd, bordón, campana) | 80,0 s | sí |
| 2 | Mapa estratégico | `assets/audio/music/map_estampie.ogg` | **Original TSB — «Estampie del mapa»** | Estampie s. XIII — https://en.wikipedia.org/wiki/Estampie | **Original TSB (CC0)** | Síntesis propia TSB (flauta dulce, laúd, bordón, campana) | 72,0 s | sí |
| 3 | Batalla N2 (táctica) | `assets/audio/music/battle_n2_march.ogg` | **Original TSB — «Saltarello de TSB»** | Saltarello s. XIV — https://en.wikipedia.org/wiki/Saltarello | **Original TSB (CC0)** | Síntesis propia TSB (chirimía, vielle, bordón, tambor de marco, tabal) | 64,286 s | sí |
| 4 | Batalla N3 (combate cerrado) | `assets/audio/music/battle_n3_combat.ogg` | **Original TSB — «Ductia de TSB»** | Ductia s. XIII — https://en.wikipedia.org/wiki/Ductia | **Original TSB (CC0)** | Síntesis propia TSB (chirimía, vielle, bordón, tambores, nakers, palmas) | 65,455 s | sí |
| 5 | Fin de año / informes | `assets/audio/music/year_end.ogg` | **Original TSB — «Campana de fin de año»** (cadencia en forma de cantiga) | Cantiga s. XIII-XV — https://es.wikipedia.org/wiki/Cantigas_de_Santa_Mar%C3%ADa | **Original TSB (CC0)** | Síntesis propia TSB (flauta dulce, campana, bordón) | 43,636 s | no |
| 6 | Victoria / derrota | `assets/audio/music/end_fanfare.ogg` | **Original TSB — «Fanfarria final»** (trompetería s. XV) | Fanfarria/trompetería s. XV — https://en.wikipedia.org/wiki/Fanfare | **Original TSB (CC0)** | Síntesis propia TSB (trompeta/brass sintético, chirimía, tambores); sin loop | 36,0 s | no |

**Nota sobre la directiva inicial:** el encargo mencionaba melodías PD de CSM 100/166 y del
*Chansonnier du Roy*. AG-5 ha optado por **no transcribir ninguna de ellas** (no había partituras
sin descargar material) y ha regenerado esas pistas como **melodías originales TSB** en las
mismas formas históricas. Esto elimina el riesgo de licencia de transcripciones y es compatible con
D-067 («síntesis propia del equipo»); las formas citadas son de dominio público.

### 2.1 Criterios musicales (D-067, prompt v2 §2.5)

- Set **reducido**: exactamente 6 pistas, una por contexto (menú, mapa, batalla N2, batalla N3,
  fin de año, cierre); no se amplía en este tramo.
- Estética «manuscrito iluminado / época» (GDD §10): consort medieval, estampie/cantiga
  instrumental, danzas medievales con percusión; nada de fantasía ni música con copyright.
- Formato OGG Vorbis mono 44,1 kHz, pico normalizado a ~−6 dBFS, bucle limpio (fade circular de
  5 ms, colas de reverberación envueltas); 0 muestras recortadas en las 6 pistas.
- `data/audio_tracks.json` define contexto → ruta/loop/`volume_db` (sin rutas hardcodeadas);
  el volumen por defecto de música es −6 dB relativa a Master (D-067).

## 3. Verificación del manifiesto (6/6)

`assets/audio/music/manifest.json` (schema 2, generado por AG-5) contiene **6/6 pistas** y coincide
con los 6 contextos de `data/audio_tracks.json`; todas las rutas
`res://assets/audio/music/<fichero>.ogg` existen en disco. En las 6: `license = "Original TSB
(CC0)"`, `source_url = null`, y `form`/`form_reference` solo citan la forma histórica PD.

| Fichero | Contexto | Bytes | Duración | Pico dBFS | Clipped | Loop (manifiesto / data) |
|---|---|---:|---:|---:|---:|---|
| `menu_consort.ogg` | menu | 744.564 | 80,0 s | −5,96 | 0 | sí / sí |
| `map_estampie.ogg` | map | 620.796 | 72,0 s | −5,92 | 0 | sí / sí |
| `battle_n2_march.ogg` | battle_n2 | 715.905 | 64,286 s | −5,90 | 0 | sí / sí |
| `battle_n3_combat.ogg` | battle_n3 | 763.060 | 65,455 s | −6,02 | 0 | sí / sí |
| `year_end.ogg` | year_end | 377.047 | 43,636 s | −6,02 | 0 | **no / no (corregido)** |
| `end_fanfare.ogg` | end | 382.227 | 36,0 s | −6,04 | 0 | no / no |

- **Total del set: 3.603.599 bytes**.
- Los OGG son Vorbis mono 44,1 kHz; el manifiesto incluye `codec`, `loop_jump`, `loop_deriv` y
  `sha256` por pista. Verificación de bucle: saltos de frontera ≤0,0037 (−48 dBFS), extremos a cero,
  0 muestras clipeadas. AG-5 confirma que **no descargó ninguna grabación** y que
  arreglos/instrumentación/mezcla/bucle son originales de TSB.
- `year_end.ogg` y `end_fanfare.ogg` están marcados `loop=false` tanto en el manifiesto como en
  `data/audio_tracks.json` (discrepancia anterior resuelta).

## 4. SFX generados (síntesis propia de TSB)

No hay ficheros de audio externos: `scripts/autoload/audio_manager.gd` genera PCM 16 bits mono a
22.050 Hz de forma determinista en tiempo de ejecución (LCG local con semilla fija; no consume
`GameState.rng`). Son **código y síntesis propios**; no requieren licencia de terceros.

| SFX | API | Generación | Duración aprox. | Licencia |
|---|---|---|---|---|
| Click de UI | `AudioManager.play_ui_click()` | Senoides 1.200/2.400 Hz con envolvente exponencial | ~45 ms | Propia TSB (código) |
| Campana de fin de año | `AudioManager.play_year_bell()` | Parciales 440/660/880/1.320 Hz con ataque y decaimiento | ~900 ms | Propia TSB (código) |
| Espada (N3) | `AudioManager.play_sword()` | Ruido determinista + parciales metálicos 1.700/2.600 Hz + cuerpo 120 Hz | ~180 ms | Propia TSB (código) |

Misma declaración que la música: **síntesis propia, sin samples ni grabaciones de terceros**.

## 5. Cadena de producción y evidencia para AG-4 (C11)

1. AG-5 compone una melodía original TSB para cada contexto en una forma histórica PD citada.
2. `tools/generate_audio_tracks.py` sintetiza cada pista (numpy) sin samples ni descargas; admite
   `--only` y semilla estable para regeneraciones reproducibles.
3. Codificación OGG Vorbis con `ffmpeg -c:a libvorbis`; normalización de pico a −6 dBFS y bucle
   circular con fade de 5 ms.
4. `assets/audio/music/manifest.json` (schema 2) registra composición original, forma citada,
   licencia, duración, métricas y sha256 de cada pista.
5. `data/audio_tracks.json` mapea los 6 contextos a `res://assets/audio/music/*.ogg`; el motor
   (`audio_manager.gd`, buses Master/Music/SFX) reproduce con loop y crossfade 1,5-2 s.

**Verificación C11 por AG-4**: comprobar que los 6 OGG existen y cargan como
`AudioStreamOggVorbis` en headless, que los 6 contextos están cubiertos, que esta tabla coincide
con el manifiesto (schema 2, `source_url=null`, licencia Original TSB CC0), que el generador no
descarga ni carga samples de terceros y que los loops de `year_end`/`end` son `false` en datos.
Con esta revisión, **la verificación legal C11 queda limpia: no queda material de terceros en la
banda sonora**.

## 6. Atribuciones

- **Música**: equipo TSB (AG-5), melodías y arreglos originales, declarados CC0. Las formas
  históricas citadas (cantiga, estampie, saltarello, ductia, fanfarria) son de dominio público y se
  acreditan por rigor documental, sin que se haya copiado su melodía.
- **Síntesis, mezcla y máster**: equipo TSB (AG-5), obra propia del proyecto, sin grabaciones de
  terceros.
- **Motor de audio y SFX**: código propio de TSB (`audio_manager.gd`), sin librerías de audio de
  terceros.

No se usa material de Koei, Kimi ni de ningún tercero; no se ha descargado música ni sample packs.
Las URLs de §2 son referencias documentales de la forma/danza, no enlaces de descarga de
grabaciones.

## 7. Riesgos de copyright y estado

| # | Riesgo | Estado / mitigación |
|---|---|---|
| R1 | **Transcripción/edición ABC de terceros** para melodías PD (CSM 12, Estampie Reale). | **CERRADO**: AG-5 regeneró las 3 pistas afectadas como melodías 100 % originales TSB; no queda ninguna transcripción de terceros. |
| R2 | **Samples/soundfonts/librerías de audio** de terceros en la síntesis. | **Sin riesgo detectado**: el generador sintetiza con numpy (ondas/ruido/percusión por código) y no carga samples; verificar en C11 que no se añadan después. |
| R3 | **Grabación comercial** usada como referencia o sample. | **Prohibido y no usada**: el generador no descarga audio; todas las pistas son originales TSB. |
| R4 | **Sustitución de CSM 100/166** por otras fuentes. | **Resuelto**: no se transcribe ninguna cantiga; se usan solo formas históricas PD como inspiración, no melodías ajenas. |
| R5 | **Discrepancia de loop** en `year_end.ogg`/`end_fanfare.ogg`. | **Resuelto**: manifiesto schema 2 y `data/audio_tracks.json` coinciden (`loop=false` en ambos). |
| R6 | **Atribución incompleta** en créditos del juego. | Incluir esta tabla o un resumen en los créditos; AG-3 puede enlazar `docs/audio_licenses.md`. |
| R7 | **Dedicación CC0 de las pistas originales**: debe ser una decisión consciente del proyecto. | AG-5 la declara en el manifiesto; si AG-0 prefiere otra licencia para el audio original, actualizar manifiesto y este documento antes del tag. |
| R8 | **Similitud con una melodía protegida** por coincidencia estilística (formas históricas). | Muy bajo: las melodías son originales y las formas históricas no son copyrightables; AG-4 puede comparar contra fuentes conocidas si lo considera necesario. |

**Declaración de cumplimiento:** las 6 pistas son obra original de TSB (melodía + arreglo +
síntesis), declaradas CC0; no contienen transcripciones, grabaciones, samples ni material con
copyright de terceros. Las únicas referencias externas son citas documentales de formas musicales
históricas de dominio público. Sin riesgos de licencia abiertos; R7 es una decisión de licencia del
proyecto, no una restricción de terceros.

---

*Documento de licencias del MVP-1337 (D-067). Mantener sincronizado con
`tools/generate_audio_tracks.py`, `assets/audio/music/manifest.json` (schema 2),
`assets/audio/music/*.ogg` y `data/audio_tracks.json`. Cualquier cambio de pista requiere
actualizar esta tabla y avisar a AG-4 para C11.*
