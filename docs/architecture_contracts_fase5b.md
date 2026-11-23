# Contrato de integración — Fase 5B: guerra, guardado y control del jugador

| Campo | Valor |
|---|---|
| **Versión** | 1.0 — 2026-11-23 |
| **Autoridad** | AG-0; directiva del usuario (2026-11-23) + GDD v1.9.3 |
| **Partes** | AG-1 (textos/tutorial/Manual), AG-2 (motor/estado), AG-3 (UI), AG-4 (QA) |
| **Restricciones** | 1402/1453 congelados (D-066, diff 0); sin arte externo; sin cambios de balance/economía/IA; REA completo solo referencia local no publicada (D-078); producción original |

## 1. Ataque y guerra (D-084)
- **Militar → «Atacar»** abre pantalla de ataque: objetivo (región adyacente no propia; si es aliada se informa y no se permite sin romper alianza), lista de **ejércitos propios elegibles** (en región adyacente, con movimiento) con **selección múltiple**, coste PG total y aviso.
- Al confirmar: si no hay guerra con el propietario, se **declara automáticamente** (`DiplomacySystem.begin_hostilities`, con la pérdida de prestigio/casus belli vigente); si ya hay guerra, solo ataca. El modal muestra el aviso de guerra automática y el coste de prestigio si procede.
- API `MilitarySystem.attack_region(faction_id, target_region, army_ids)` → `{ok, reason, declared_war, results:[{army_id, moved, battle}], pg_spent}`; valida propiedad/adyacencia/PG/guerra aliada y mueve los ejércitos seleccionados en orden; cada movimiento usa `move_army` (batalla delegada si hay defensores). Determinista respecto al estado; no cambia fórmulas de combate.
- La UI muestra el resultado por ejército y enlaza al informe de batalla si lo hay. Acciones militares siguen siendo repetibles (D-074).

## 2. Guardado (D-085)
- `GameState`: `save_game(slot)`, `load_game(slot)`, `has_save(slot)`, `list_saves()` (slots `autosave`, `slot_1..slot_3`) con metadatos (`year, quarter, faction, saved_at`, opcional `chronicle` size); `autosave()` explícito; no cambia `save_version` ni el formato.
- **Autoguardado después de cada turno resuelto** (en el cierre de trimestre/año, tras resoluciones; no antes de confirmar). Nunca sobrescribe `slot_1..slot_3`.
- **Guardar/Cargar** accesible desde HUD/mapa y menú principal: 3 ranuras manuales + autoguardado, con fecha/año/facción y botón Guardar/Cargar por ranura; feedback y confirmación de sobrescritura; capturas.

## 3. Decisiones solo en reinos propios (D-086)
- `EconomySystem.allocate(region_id, worker_class, amount, actor_faction="")`: si `actor_faction` no está vacío y no es el propietario, devuelve `false` con motivo `not_owner`; sin actor mantiene compatibilidad (IA/tests antiguos).
- `region_panel`: si `region.owner != player_faction`, los controles de trabajadores se muestran deshabilitados (o solo lectura) con aviso «Solo el reino propietario puede asignar trabajadores»; nunca se llama a allocate. El resto de datos sigue visible.
- Sin cambios de simulación para la IA.

## 4. Expedición de mercaderes clara (D-087)
- Mercado: sección «Expedición de mercaderes» con instrucciones de 2-3 líneas, selección de bien/cantidad, coste PG (2), retorno a 2 trimestres y estado de expediciones activas; deshabilitada con motivo si faltan comerciantes, bienes o PG; feedback claro y captura.
- Tutorial: paso que explica asignar comerciantes + enviar expedición; condición `expedition_sent`; `TutorialSystem.advance_tutorial` desde el envío.
- Manual/context help actualizados.

## 5. Tutorial Principiante (D-088)
- `data/tutorial_script.json`: añadir/pulir pasos de **atacar** (Militar → Atacar → seleccionar ejércitos → objetivo → confirmar; guerra automática), **expedición de mercaderes**, **guardado multislot** y **solo decidir en reinos propios**; mantener los 9 pasos existentes y el orden coherente; español propio.
- Condiciones nuevas `attack_launched`, `expedition_sent` (además de `open_military`, `saved`, `assign_workers`, etc.). `TutorialSystem` avanza esas condiciones desde las acciones (ataque confirmado, expedición enviada); UI resalta los botones `attack_button`, `save_button`, `expedition_button`.
- En Principiante activo por defecto; en Normal disponible el conmutador (D-082). Estado serializable sin cambios de save_version.

## 6. Textos y Manual (AG-1)
- `data/context_help.json`: entradas para `military` (ataque/guerra), `world_map` (guardado), `market` (expedición) y `region_panel` (solo propietario).
- `docs/MANUAL_DEL_JUGADOR.md`: secciones de guerra/ataque, guardado multislot/autoguardado, expedición de mercaderes y límites de decisión en reinos ajenos; coherente con la UI y capturas.

## 7. QA C1-C9
C1 ataque desde Militar con multi-selección y objetivo; guerra automática si no había y ataque directo si ya había; resultado/batalla; captura. C2 guardado manual 3 ranuras + autoguardado tras cada turno + carga; captura; hash. C3 reino ajeno sin reasignación (UI+engine `not_owner`), propio sí. C4 expedición clara y funcional, tutorial/ayuda. C5 tutorial Principiante con ataque/guardado/expedición/propiedad y condiciones. C6 manual actualizado. C7 no regresión (run_all, validate 0 WARN, editor, F1...). C8 1402/1453 diff 0, sin arte, GDD v1.9.3+D-084…D-089+STATUS. C9 coherencia de capturas 1920×1080 y 0 botones muertos.

## 8. Propiedad
| Owner | Scopes |
|---|---|
| AG-1 | `data/tutorial_script.json`, `data/context_help.json`, `docs/MANUAL_DEL_JUGADOR.md` |
| AG-2 | `scripts/autoload/**`, `scripts/utils/**`, `tests/test_*.gd`, `tests/run_all.gd` |
| AG-3 | `scenes/**`, `scripts/ui/**`, capturas |
| AG-4 | `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd` |
| AG-0 | GDD, decisiones, STATUS, contrato, git |

## 9. Addendum 5B.1 — Tipografía (D-090)
Todas las pantallas de juego suben su tipografía **≥2 pt** respecto de Fase 5A (mínimos por rol: Tiny 12→14, Ink 14→16, títulos +2 o más), mediante tema/constantes compartidas y revisión de layout/scroll. **Excepción explícita:** el menú principal (`main_menu`) conserva exactamente sus tamaños actuales. QA C10: capturas de mapa/región/mercado/militar/batalla/boletín/crónica/guardado/ayuda y comparación de que `main_menu` no cambió.
