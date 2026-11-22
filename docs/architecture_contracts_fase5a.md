# Contrato de integración — Fase 5A: «El juego te explica» (legibilidad UX)

| Campo | Valor |
|---|---|
| **Versión** | 1.0 — 2026-11-23 |
| **Autoridad** | AG-0; directiva `prompt_DSH_fase5a_legibilidad_v1.md` + GDD v1.9.2 |
| **Partes** | AG-1 (textos), AG-2 (estado/cálculo), AG-3 (UI), AG-4 (QA) |
| **Restricciones** | 1402/1453 congelados (D-066, diff 0); sin arte externo; sin cambios de simulación/balance/IA; determinismo intacto; REA completo (D-077/D-078) solo referencia local no publicada |

## 1. Estado y APIs (AG-2)

### 1.1 `turn_actions` (D-081) — transitorio
`GameState.state.turn_actions`: `[{action, target, pg}]`; se registra con `GameState.record_turn_action(action, target, pg)`; se resetea en `begin_turn` y al empezar año; **no se serializa** (estado de presentación, documentado en D-081). API `get_turn_actions()`, `clear_turn_actions()`.
Los sistemas que gastan PG (diplomacia, familia, economía/construcción, espionaje, expedición) registran la acción; las acciones militares/trabajadores/mercado también pueden registrarse informativamente (sin coste PG) sin bloquear.

### 1.2 `chronicle` (D-080) — persistido
`GameState.state.chronicle`: lista de `{year:int, season_or_year:String, kind:String, text:String}`. API `append_chronicle(entry)`, `get_chronicle(year?)`, `get_chronicle_text()`. Serializado en `to_dict/from_dict`; saves antiguos sin la clave reciben `[]` (defaults, sin romper). El año se cierra con una entrada `kind:"year"` y cada trimestre puede añadir `kind:"quarter"`.
Migración: no se sube `save_version`; `from_dict` rellena defaults para `chronicle`, `turn_actions` (vacío) y `advisor_enabled`.

### 1.3 Estaciones (D-079)
`GameState.get_season_name(quarter_override=-1)`/`get_season_index()`: trimestre 1→Primavera, 2→Verano, 3→Otoño, 4→Invierno (se deriva del reloj; sin estado nuevo). `get_season_label()` → «Primavera 1337».

### 1.4 Consejero comercial y conmutador (D-082)
`TradeSystem.get_trade_advice(faction_id, region_id="")` → `{ok, good_id, kind:"sell"|"buy"|"hold", price, base, margin, text}` determinista (sin RNG): entre el inventario disponible elige el mayor margen `price/base − 1` (venta) o el menor (compra si procede); incluye retorno de expediciones si aplica. `GameState.state.advisor_enabled` (bool; default `difficulty=="beginner"`; conmutable en partida, persistido en save). API `set_advisor_enabled/is_advisor_enabled`.
`data/context_help.json` y `data/legibility_texts.json` (AG-1) se cargan por DataLoader; validate reconoce/excluye sin WARN.

## 2. Datos y textos (AG-1)

- `data/context_help.json`: `{screen: {title, lines:[3-5]}}` para las pantallas §9: `main_menu`, `scenario_select`, `world_map`, `region_panel`, `council`, `family`, `diplomacy`, `military`, `economy`, `market`, `army_management`, `battle_n1`, `battle_n2`, `battle_n3`, `year_end`, `chronicle`, `options`, `victory`. Texto 100 % propio en español, coherente con el Manual (D-072).
- `data/legibility_texts.json`: plantillas de boletín/crónica (`bulletin` y `chronicle`), etiquetas de estaciones, formatos de líneas (ingresos/gastos/apoyo/acciones/corte/mercaderes/eventos/ranking). Sin nombres/tokens de Koei; sin RNG.
- Esquemas opcionales; AG-2 reconoce ambos datasets en `validator_core`/DataLoader (0 WARN). No se tocan datos 1402/1453.

## 3. UI (AG-3)

1. **HUD** persistente: `{Estación} {Año} — Tesoro: X · PG: Y`; tinte de mapa por estación con `CanvasModulate`/overlay generado por código (parámetros en constantes; sutil, opción de desactivar si existe pantalla de opciones).
2. **Boletín trimestral** al cerrar trimestre (momento actual de fin de año/pista): modal 4-6 líneas con ≥5 categorías (ingresos/gastos, apoyo, acciones, corte, mercaderes, eventos), botón Continuar; sin controles muertos.
3. **Crónica anual** al cerrar año: desglose económico (oro, bienes), eventos, guerras, ranking de prestigio de las 8 jugables; pestaña **Crónica** consultable en cualquier momento (histórico persistido).
4. **Confirmar órdenes**: al pulsar Terminar turno, modal «Tus órdenes este trimestre» con la lista (`turn_actions`) o «No has dado órdenes este trimestre»; Corregir/Confirmar; aviso de exenciones libres.
5. **Consejero**: conmutador en el menú de consejo (activo por defecto en Principiante); panel existente reutilizado; consejo comercial en Mercado.
6. **Ayuda contextual**: botón «?» en cada pantalla §9 que muestra 3-5 líneas de `context_help.json` (overlay sin salir del juego); capturas ≥4 pantallas.
7. **Panel de unidad N2/N3**: por unidad seleccionada hombres, armamento (armas), apoyo, moral, entrenamiento (experiencia); comandante con estado sano/herido y stat Mando; solo lectura, sin tocar simulación/animación.
Capturas 1920×1080 en `.ui_check_f3`: temporadas ×4, boletín, crónica, confirmación (con y sin órdenes), consejo mercado, ayuda ×4+, paneles N2/N3.

## 4. QA (AG-4) — C1-C10
C1 HUD estación+año, tinte, capturas ×4; C2 boletín ≥5 categorías/texto propio/0 botones muertos; C3 crónica + histórico persistido (hash) y consultable; C4 confirmación (lista con y sin órdenes, Corregir/Confirmar, test log determinista); C5 consejero comercial correcto (precio alto/bajo, sin RNG, captura); C6 «?» en todas las pantallas §9 (capturas ≥4); C7 paneles N2/N3 (hombres/armas/apoyo/moral/entrenamiento + comandante); C8 save/load con chronicle (3 puntos) y partidas antiguas con defaults; C9 no regresión (run_all, validate 0 WARN, editor 0, IA<2 s, mapa<8 ms); C10 congelamientos (diff 0 1402/1453, sin arte externo, GDD v1.9.2 + D-079…D-083 + STATUS + tag fase-5a). Informe `docs/qa/fase5a_report.md`.

## 5. Propiedad
| Owner | Scopes |
|---|---|
| **AG-1** | `data/context_help.json`, `data/legibility_texts.json` (+ esquemas si aplica) |
| **AG-2** | `scripts/autoload/**`, `scripts/utils/**`, `tools/validator_core.gd`, `tests/test_*.gd`, `tests/run_all.gd` |
| **AG-3** | `scenes/**`, `scripts/ui/**` |
| **AG-4** | `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd` |
| **AG-0** | `GDD_The_Sovereign's_Blood.md`, `docs/decisions.md`, `docs/STATUS.md`, `docs/architecture_contracts_fase5a.md`, git |

## 6. Cierre
Commits por agente + `[AG-0]`, push a `origin/main`, tag **`fase-5a`**, aviso a Kimi contra GDD v1.9.2 + directiva. No se publica nada del REA completo (D-078).
