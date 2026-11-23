# Plan de QA — Fase 5B: guerra, guardado y control del jugador (C1-C10)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-23 |
| **Directiva** | GDD v1.9.3; contrato `docs/architecture_contracts_fase5b.md`; D-084…D-090 |
| **Alcance** | Ataque/guerra desde Militar, guardado multislot/autoguardado, propiedad de regiones, expedición de mercaderes, tutorial Principiante, Manual, **legibilidad tipográfica +2 pt (C10)**, no regresión, congelación y UX/capturas |
| **Harness** | `tests/qa_acceptance_fase5b.gd` (C1-C10; `extends SceneTree`; compila siempre; SKIP justificado; exit 0 solo con 10/10) |
| **Baseline** | HEAD `22152ed5` (GDD v1.9.3 + D-084…D-090; módulos AG-1/AG-2/AG-3 en curso) |
| **Verificación final** | task-86 (bloqueada por task-82/83/84) |

> **Semántica:** PASS = criterio cumplido; SKIP = pendiente de módulo en curso (no es rechazo); FAIL = incumplimiento. Baseline con SKIP sale 1 «PENDIENTE». **Exit 0 solo con C1-C10 PASS.**

---

## 1. Matriz C1-C10 → test → comando → evidencia

| # | Criterio (contrato 5B §7) | Test | Evidencia |
|---|---|---|---|
| C1 | Ataque desde Militar: objetivo, multi-ejército, guerra automática/directa, resultado/batalla, captura | `_criterion_1_attack()` | `MilitarySystem.attack_region`, `begin_hostilities`, UI/capturas |
| C2 | Guardado manual 3 ranuras + autosave por turno + carga/hash | `_criterion_2_saves()` | `list_saves`, slots/autosave, `load_game`, captura |
| C3 | Región ajena sin reasignación (UI+engine `not_owner`); propia OK | `_criterion_3_ownership()` | `EconomySystem.allocate(actor_faction)`, panel |
| C4 | Expedición clara/funcional + tutorial/ayuda | `_criterion_4_expedition()` | mercado/condición `expedition_sent`, textos/captura |
| C5 | Tutorial Principiante con ataque/guardado/expedición/propiedad | `_criterion_5_tutorial()` | `tutorial_script.json` pasos/condiciones, `TutorialSystem` |
| C6 | Manual actualizado | `_criterion_6_manual()` | `docs/MANUAL_DEL_JUGADOR.md` + coherencia |
| C7 | No regresión | `_criterion_7_regression()` | run_all, validate, editor, F1/F2/F3/MVP/anim/tiles |
| C8 | diff 0 1402/1453, sin arte, GDD v1.9.3+D-084…089+STATUS | `_criterion_8_governance()` | hashes/diff/docs |
| C9 | Capturas 1920×1080 y 0 botones muertos | `_criterion_9_ux()` | capturas nuevas + `ui_smoke` |
| C10 | Fuentes +2 pt en pantallas de juego; `main_menu` intacto | `_criterion_10_fonts()` | tema/constantes, capturas comparativas y hash del menú principal |

---

## 2. Detalle de checks

### C1 — Ataque/guerra
- `MilitarySystem.attack_region(faction_id, target_region, army_ids)` → `{ok, reason, declared_war, results:[{army_id,moved,battle}], pg_spent}`; valida propiedad/adyacencia/PG/guerra aliada; multi-selección; declara guerra automática si no había (`begin_hostilities`), no si ya; mueve en orden y resuelve batalla delegada.
- UI Militar → Atacar con objetivo/ejércitos/coste/aviso; resultado por ejército/informe; capturas.

### C2 — Guardado
- `save_game(slot)`/`load_game(slot)`/`has_save(slot)`/`list_saves()` con `autosave` + `slot_1..3`; metadatos (year/quarter/faction/saved_at/chronicle_size); autosave tras cierre de turno; no sobrescribe manuales; hash exacto; capturas de pantalla.

### C3 — Propiedad
- `EconomySystem.allocate(region_id, worker_class, amount, actor_faction="")`: actor distinto del owner → `false` con `not_owner`; sin actor mantiene compatibilidad; panel de región ajena deshabilitado con aviso, propia OK.

### C4 — Expedición
- Sección «Expedición de mercaderes» con instrucciones, bien/cantidad, coste 2 PG, retorno 2 trimestres, expediciones activas; deshabilitada con motivo si faltan comerciantes/bienes/PG; paso tutorial `expedition_sent` y ayuda/Manual.

### C5 — Tutorial Principiante
- `tutorial_script.json`: pasos de ataque, expedición, guardado y «solo reinos propios»; condiciones `attack_launched`/`expedition_sent`; `TutorialSystem.advance_tutorial` desde acciones; Principiante activo, Normal con conmutador; highlight `attack_button/save_button/expedition_button`.

### C6 — Manual
- `docs/MANUAL_DEL_JUGADOR.md` documenta ataque/declaración automática, multi-selección, guardado multislot/autoguardado, expedición, propiedad de reinos; coherente con `context_help.json` y capturas; sin texto de Koei.

### C7 — No regresión
- `run_all` verde (≥2019/0), validate 0 WARN, editor/headless 0; F1/F2/F3/MVP/anim/tiles verdes; IA<2 s, mapa<8 ms.

### C8 — Gobernanza
- `git diff fase-5a..HEAD` en datos 1402/1453 = 0; sin arte externo; GDD v1.9.3; D-084…D-089; STATUS §22 (Fase 5B); REA completo fuera del repo.

### C9 — UX/capturas
- Capturas 1920×1080 de ataque, guardado/slots, expedición, tutorial/ayuda, panel propia/ajena; `ui_smoke` sin errores; 0 botones muertos.

### C10 — Legibilidad tipográfica +2 pt (D-090)
- Todas las pantallas de juego (mapa, región, consejo, familia, diplomacia, mercado, militar, batallas N1/N2/N3, boletín, crónica, guardado, ayuda, tutorial, opciones, victoria/derrota) suben **al menos +2 pt** respecto al baseline; `main_menu` y selector de escenario conservan **exactamente** su tamaño (excepción).
- Evidencia: tema/constantes de UI, capturas comparativas 1920×1080 y hash/estado del menú principal; sin romper layout/scroll.

---

## 3. Comandos

```powershell
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$repo = "C:\Proyectos\TSB\sovereigns-blood"
& $g --headless --path $repo --script tests/qa_acceptance_fase5b.gd
& $g --headless --path $repo --script tests/qa_acceptance_fase5a.gd
& $g --headless --path $repo --script tests/qa_acceptance_fase4.gd
& $g --headless --path $repo --script tests/qa_acceptance_mvp_1337.gd
& $g --headless --path $repo --script tests/qa_acceptance_fase3_anim.gd
& $g --headless --path $repo --script tests/qa_acceptance_fase3.gd
& $g --headless --path $repo --script tests/qa_acceptance_tiles.gd
& $g --headless --path $repo --script tests/qa_acceptance_fase3_final.gd
& $g --headless --path $repo --script tests/qa_acceptance.gd
& $g --headless --path $repo --script tests/qa_acceptance_fase2.gd
& $g --headless --path $repo --script tests/run_all.gd
& $g --headless --path $repo --script tools/validate_data.gd
& $g --headless --path $repo --script scripts/ui/dev/ui_smoke.gd
& $g --headless --path $repo --editor --quit
& $g --headless --path $repo --quit
```

**Baseline esperado:** C7 PASS; C1-C6/C8/C9 SKIP hasta AG-1/AG-2/AG-3 y STATUS. Salida 1 «PENDIENTE» (no rechazo). Detalle en `docs/issues.md` §24.

---

## 4. Riesgos R-F5B

| ID | Riesgo | Mitigación |
|---|---|---|
| R-F5B-01 | Ataque no declara guerra o ataca aliados/multi-ejército incorrecto | C1 API + UI/captura |
| R-F5B-02 | Slots/autosave sobrescriben manuales o no cargan hash | C2 4 slots + hash/captura |
| R-F5B-03 | Reasignación en región ajena (UI o motor) | C3 `not_owner` + panel |
| R-F5B-04 | Expedición confusa/no funcional o sin tutorial | C4 UI/condición/textos |
| R-F5B-05 | Tutorial sin pasos/condiciones nuevos | C5 JSON/API/highlights |
| R-F5B-06 | Manual desactualizado | C6 términos/coherencia/capturas |
| R-F5B-07 | Regresión simulación/IA/mapa | C7 batería |
| R-F5B-08 | Se toca 1402/1453 o se publica arte/REA | C8 diff/art/REA local |
| R-F5B-09 | Botones muertos/capturas faltantes | C9 ui_smoke/capturas |
| R-F5B-10 | Concurrencia AG-1/AG-2/AG-3 durante baseline | snapshot HEAD; final sobre commits |
| R-F5B-11 | Fuentes no suben ≥2 pt o menú principal cambia | C10 tema/capturas/hash menú |

### 4.1 Baseline ejecutado (HEAD `22152ed5`; módulos en curso) — **2 PASS / 0 FAIL / 8 SKIP**

- **PASS C6** Manual actualizado (ataque/guerra, guardado, expedición, propiedad); **PASS C8** GDD v1.9.3 + D-084…D-089 + STATUS, 1402/1453 hashes intactos y `git diff fase-5a..HEAD` = 0.
- **SKIP:** C1 (API `attack_region` existe; faltan capturas/UI), C2 (`list_saves` solo autosave, sin 3 ranuras), C3 (guard/panel parcial; capturas), C4 (UI/textos parciales; captura), C5 (tutorial sin condiciones `owner`), C7 (run_all **2008/11 transitorio** por módulos 5B; no se certifica), C9/C10 (capturas y D-090 pendientes).
- `validate_data` **16/12, 12.221 comprobaciones, 0 WARN**, editor 0. No es rechazo de QA: módulos AG-1/AG-2/AG-3 en curso; se repetirá en task-86.

---

## 5. Verificación final (task-86)

Harness C1-C10 ×2 exit 0; batería completa; capturas 1920×1080; diff 0/sin arte/REA fuera del repo; veredicto **«QA Fase 5B: APROBADO/RECHAZADO»** en `docs/qa/fase5b_report.md` + `docs/issues.md` §24.
