# GDD — The Sovereign's Blood
## Game Design Document y Especificación de Ingeniería para Desarrollo Multi-Agente (DSH + DeepSeek-V4.1-Flash + Godot 4)

| Campo | Valor |
|---|---|
| **Título** | The Sovereign's Blood |
| **Género** | Gran estrategia por turnos (estilo clásico Koei, inspiración estructural: Genghis Khan II, 1992) |
| **Motor** | Godot 4.x (GDScript) |
| **Plataforma** | Desktop: Windows 11 x64 (primario), macOS y Linux (exportables) |
| **Fines** | Proyecto personal, sin fines comerciales. Contenido 100% original (datos, nombres, arte). |
| **Modelo IA** | DeepSeek-V4.1-Flash (deepseek-flash) vía DeepSeek Harness (DSH) |
| **Workspace DSH** | `C:\Proyectos\TSB` (Creator Mode, Full Access) |
| **Versión del documento** | 1.2 |
| **Estado** | Aprobado para Fase 0 — entorno verificado + flujo GitHub |

---

## 1. Visión del juego

**The Sovereign's Blood** es un juego de gran estrategia por turnos ambientado en Europa, el Mediterráneo y Oriente Próximo entre 1337 y 1453 (la era de la Guerra de los Cien Años y el ascenso de los estados dinásticos). El jugador gobierna una casa reinante: administra economía, contrata matrimonios dinásticos, negocia alianzas y comanda ejércitos en tres niveles de resolución de batalla (delegada, mapa táctico de ejércitos y combate cerrado unidad contra unidad).

**Pilar de diseño:** cada mecánica del diseño de referencia (Genghis Khan II) se reimplementa como original — sistemas propios, datos propios, arte propio — tomando de GK2 solo las *ideas de diseño* (loops, jerarquías de batalla, economía por regiones), documentadas en el Anexo A mediante ingeniería inversa limitada a los formatos de datos, nunca del código ejecutable.

**Fantasía de jugador:** no eres un ejército; eres una *dinastía*. Ganas por prestigio, herederos y coronas, no solo por territorio.

### 1.1 Objetivos de diseño
1. **Fidelidad estructural, originalidad de contenido:** mismas capas de decisión que un clásico de Koei, mundo y datos 100% nuevos.
2. **Historial jugable:** escenarios con personajes, fronteras y unidades correctos para 1337, 1402 y 1453, validados contra fuentes abiertas (Wikidata/Wikipedia, mapas históricos de dominio público).
3. **Ágil:** MVP jugable en semanas, no meses. Batallas delegadas primero (ya es una resolución completa por diseño).
4. **Mantenible por agentes IA:** código GDScript modular, datos en JSON, contratos de API explícitos entre sistemas (ver Sección 8).

### 1.2 Lo que el juego NO es (anti-objetivos)
- No es un wargame hexagonal puro: el mapa táctico es una capa, no el núcleo.
- No es un sandbox: los 3 escenarios son partidas cerradas con condiciones de victoria.
- No usa ningún asset, nombre, dato o texto de Koei/Nintendo/terceros.

---

## 2. Alcance y definición del MVP

### 2.1 Vertical slice mínimo (Fase 1 — aceptación)
- 1 escenario completo (Escenario 1: 1337), 8 facciones jugables de las 14 presentes.
- Loop de turno completo: gobernanza → economía → familia → diplomacia → militar → IA de rivales → avance de año.
- Resolución de batalla **delegada** (automática con informe) — suficiente para ganar/perder guerras.
- Guardar/cargar partida (JSON).
- UI funcional: mapa principal de regiones, menú de consejo, panel de región, panel de familia, pantalla de diplomacia, informe de batalla, pantalla de fin de año.

### 2.2 Fuera de alcance del MVP
- Batalla táctica en mapa y combate cerrado unidad a unidad (Fase 2).
- Escenarios 2 y 3 (Fase 3).
- Arte final, música, localización (Fase 3 usa placeholders mejorados).

---

## 3. Uso limitado de Reverse Engineering (REA) sobre Genghis Khan II

**Autorización explícita del usuario:** REA se usa *solo* para obtener información fundamental de GK2, conforme a lo siguiente:

| Permitido (REA) | Prohibido (REA) |
|---|---|
| Documentar estructura de los archivos de datos `GENDATA*.DAT`, `ZNAME.DAT`, `MAPDATA.DAT`, `SCENARIO.GK2`, `SAVEDATA.GK2` (tipos de campos, tamaños, orden) | Decompilar/desensamblar `MAIN.EXE`/`OPEN.EXE`/`END.EXE` para reutilizar lógica |
| Extraer lecciones de diseño: qué datos necesita un motor de este género (stats de generales, estructura de región, formato de escenario) | Copiar fórmulas literales del binario o transcribir texto del juego |
| Producir un informe de 1-2 páginas: "lecciones de modelado de datos para un clon estructural" | Producir una especificación de reimplementación 1:1 del juego |

**Entregable REA (Fase 0):** `docs/rea/gk2_data_lessons.md` — tabla de equivalencias conceptuales (ej. "GK2 modela generales con nombre/4 stats/lealtad → nuestro modelo de personajes tiene X campos"). Nada más. El equipo de desarrollo **no** lee los binarios ni los datos de Koei; consume solo este informe y el GDD.

**Motivo legal:** uso personal y de estudio; el producto final no contiene material derivado medible de Koei.

### 3.1 Entorno de ejecución (máquina de desarrollo, Windows 11 x64)

| Elemento | Ruta / valor |
|---|---|
| **Workspace DSH** | `C:\Proyectos\TSB` (DSH abierto aquí en Creator Mode, Full Access) |
| **Referencia GK2** (solo lectura, solo AG-REA) | `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf` |
| **Repo del juego** | `C:\Proyectos\TSB\sovereigns-blood` |
| **Definiciones de agentes** | `C:\Proyectos\TSB\agents\AG-*.md` — DSH crea y lee los MD de agentes aquí |
| **GDD maestro** | `C:\Proyectos\TSB\GDD_The_Sovereign's_Blood.md` |
| **Godot 4 (verificado)** | Editor: `C:\Godot\Godot_v4.7.2-stable_win64.exe` · Consola/CI: `C:\Godot\Godot_v4.7.2-stable_win64_console.exe` |
| **MCP disponibles en DSH** | `godot-mcp` y `rea-mcp` ya instalados; más fs/shell nativo del harness |
| **Repo GitHub (público)** | `https://github.com/horaciomartinez-svg/The_Sovereign_Blood` — remoto `origin`, rama principal `main` |
| **Comando headless (CI/QA)** | `"C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path C:\Proyectos\TSB\sovereigns-blood --script tests/run_all.gd` |

**Reglas del workspace (vinculantes para todos los agentes):**
1. **Nada se crea ni guarda fuera de `C:\Proyectos\TSB`** — ni MD de agentes, ni docs, ni código, ni datos.
2. `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf` es **solo lectura** y solo AG-REA puede leerla (resto del equipo: prohibido).
3. AG-2/AG-3 usan `godot-mcp` como vía principal (crear escenas, ejecutar el editor) y el comando headless como respaldo obligatorio. AG-REA usa `rea-mcp` cuando aplique y fs/shell para inspección hexadecimal de los `.DAT`.
4. Todo documento de trabajo (`docs/STATUS.md`, `docs/decisions.md`, `docs/issues.md`, `docs/rea/…`) vive dentro de `C:\Proyectos\TSB\sovereigns-blood\docs\` (o `C:\Proyectos\TSB\docs\` para lo que sea del workspace, no del juego).

### 3.2 Flujo Git y protocolo de verificación (repo GitHub)

El repo `The_Sovereign_Blood` es la fuente de verdad compartida entre el equipo DSH (que escribe) y Kimi (que verifica). Reglas vinculantes:

1. **Push al cerrar cada módulo:** el Coordinator hace `git push origin main` al completar cada módulo o hito de una fase, con el `docs/STATUS.md` actualizado en el mismo push. Mensajes de commit con prefijo `[AG-N]` + resumen.
2. **Etiquetas por fase:** tag `fase-0`, `fase-1`, `fase-2`, `fase-3` en el commit donde se cumplen los criterios de aceptación de la Sección 12.
3. **Nada de force-push ni reescritura de historia** en `main`; si algo falla, commit revertido encima.
4. **El usuario no toca el código** salvo petición expresa; su rol es revisar `STATUS.md` y dar luz verde de fase.
5. **Protocolo de verificación Kimi (al final de cada módulo):** Kimi revisa el repo remoto y verifica contra este GDD:
   - ¿Los entregables del módulo existen y cumplen los criterios de aceptación de la fase?
   - ¿`validate_data.gd` y los tests headless pasan (logs adjuntos en `docs/STATUS.md`)?
   - ¿Los contratos de la Sección 8.2 se respetan (la UI no muta estado)?
   - ¿Cumplimiento legal: ningún dato/texto/asset de Koei ni de terceros?
   - Resultado: **APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO** con lista de hallazgos, que el Coordinator corrige antes de continuar.
6. **El GDD vive también en el repo** (raíz). Cualquier cambio de alcance aprobado se versiona ahí (commit `[GDD]`).

---

## 4. Mundo, época y escenarios

### 4.1 Marco histórico (fuente de verdad para datos)
Período: 1337–1453. Mundo jugable: Europa occidental y central, península ibérica, Italia, Balcanes, Anatolia, Levante y Norte de África costero. Fuente primaria de datos: **Wikidata** (gobernantes, fechas, casas dinásticas), **Wikipedia** (eventos, batallas), catálogos de mapas históricos de dominio público (bibliotecas digitales) para fronteras aproximadas por año.

### 4.2 Escenario 1 — "Dos Coronas" (año 1337)
**Tema:** estallido de la Guerra de los Cien Años. Eduardo III de Inglaterra reivindica la corona francesa por línea materna; los Valois resisten.

| Facción | Gobernante (1337) | Casa | Capital | Rasgo distintivo |
|---|---|---|---|---|
| Inglaterra | Eduardo III | Plantagenet | Londres | Arqueros largos, flota |
| Francia | Felipe VI | Valois | París | Caballería pesada, población |
| Sacro Imperio | Luis IV | Wittelsbach | Praga | Electores, mercenarios |
| Bohemia | Juan de Luxemburgo | Luxemburgo | Praga | Caballería, oro de Kutná Hora |
| Hungría | Carlos Roberto | Anjou | Buda | Frontera antiturca |
| Castilla | Alfonso XI | Trastámara/Borgoña | Burgos | Jinetes, flota atlántica |
| Aragón | Pedro IV | Barcelona-Aragón | Barcelona | Mercenarios almogávares, Mediterráneo |
| Polonia | Casimiro III | Piast | Cracovia | Expansión, caballería ligera |
| Escocia | David II | Bruce | Edimburgo | Schiltrons, guerra vs Inglaterra |
| Papado (Aviñón) | Benedicto XII | — | Aviñón | Influencia, tesoro |
| Granada | Yusuf I | Nazarí | Granada | Fortalezas, tributo |
| Sultanato Mameluco | An-Nasir Muhammad | Bahri | El Cairo | Riqueza, mamelucos |
| Horda de Oro | Özbeg | Borjigin | Sarai | Caballería de estepa |
| Bizancio | Andrónico III | Paleólogo | Constantinopla | Supervivencia, mercenarios |

### 4.3 Escenario 2 — "El Choque de Imperios" (año 1402)
**Tema:** tras la batalla de Ankara, Tamerlán desplaza al sultán otomano; Occidente fragmentado (locura de Carlos VI, guerras civiles italianas).

| Facción | Gobernante (1402) | Nota de diseño |
|---|---|---|
| Imperio de Tamerlán | Tamerlán | Ejército de élite temprano, decadencia tras 1405 |
| Otomanos (Interregno) | Mehmed I vs. príncipes rivales | Facción frágil con gran potencial |
| Inglaterra | Enrique IV | Guerra civil reciente, recursos escasos |
| Francia | Carlos VI | Facción inestable: eventos de locura regia |
| Hungría / Sacro Imperio | Segismundo | Corona dual, presión otomana |
| Venecia | Dogo Michele Steno | Repúblicas: comercio naval, sin dinastía (reglas especiales) |
| Génova | — | Mar y mercenarios |
| Florencia | — | Banca, influencia |
| Milán | Gian Galeazzo Visconti (muere 1402) | Evento de sucesión inmediato |
| Castilla | Enrique III | Menor de edad de su hijo → regencia |
| Aragón | Fernando I (regente) | Unión dinástica con Castilla próxima |
| Mamelucos | Al-Faray | Estable, rico |
| Bizancio | Manuel II | Constantino XI como heredero |

### 4.4 Escenario 3 — "El Ocaso y el Alba" (año 1453)
**Tema:** caída de Constantinopla, final de la Guerra de los Cien Años, Renacimiento, preludio de las guerras dinásticas inglesas.

| Facción | Gobernante (1453) | Nota de diseño |
|---|---|---|
| Otomanos | Mehmed II | Bombardas, jenízaros; objetivo: Constantinopla |
| Bizancio | Constantino XI | Partida de supervivencia |
| Inglaterra | Enrique VI | Inestable; evento de Guerra de las Dos Rosas |
| Francia | Carlos VII | Compañías libres, artillería real |
| Borgoña | Felipe el Bueno | Riqueza, caballería; decisión histórica 1435 |
| Aragón/Nápoles | Alfonso V | Corona dual mediterránea |
| Sacro Imperio | Federico III | Pasivo pero estable |
| Hungría | Matías Corvino (desde 1458) / regencia previa | El Hunyadi: héroe militar |
| Escocia | Jacobo II | Oportunista |
| Castilla | Enrique IV | Tensiones nobiliarias |
| Venecia / Génova | — | Colonias y mar |
| Papado | Nicolás V | Patrono del Renacimiento |
| Mamelucos | Qaitbay (desde 1468; usar regente previo) | Estable |
| Valaquia | Vlad III (Drácula) | Héroe temático, difícil |

### 4.5 Condiciones de victoria (todas las escenarios)
1. **Coronas:** acumular N coronas sostenidas (propia + reclamadas) según escenario.
2. **Prestigio dinástico:** alcanzar umbral de Prestigio Real mantenido 10 años.
3. **Supervivencia (facciones menores):** sobrevivir hasta fin de escenario (1453/1460/1480 según caso) con umbral mínimo de territorio.
4. **Conquista total:** controlar ≥70% de regiones del mapa.

**Derrota:** extinción de la casa gobernante (sin herederos vivos) o pérdida de la última región.

---

## 5. Mecánicas núcleo

### 5.1 Estructura del turno y recurso de acción
El turno = **trimestre** (4 turnos/año). Cada facción dispone por trimestre de **Puntos de Gobernanza (PG)**, equivalente funcional al recurso de acción del diseño de referencia:

```
PG_trimestre = 30 + (Prestigio_Real / 10) + bonus_líder - penalización_descontento
```

Cada orden (mover ejército, negociar, edificar, intervención familiar, ceremonia) cuesta PG. Las órdenes no gastadas se pierden. La interfaz muestra PG restantes en todo momento (barra superior, estilo clásico).

### 5.2 Economía por regiones
El mapa está dividido en **regiones** (provincias), cada una con: población, riqueza base, terreno (llanura/bosque/montaña/costa/ciudad), edificios y asignación de mano de obra.

```
Población trabajadora = Población_total × (1 - tasa_reclutamiento)
Manos de obra asignables a: Granjeros / Artesanos / Comerciantes / Reclutas (pool)
Producción_alimento  = Granjeros × factor_terreno × clima_trimestre
Producción_bienes    = Artesanos × talleres × tecnología
Oro_comercio         = Comerciantes × rutas_abiertas × (1 + prosperidad/100)
Tesoro               += impuestos(oro_total × tasa) + comercio − mantenimiento
```

**Apoyo popular (0-100):** sube con alimentos sobrantes, baja con impuestos altos y reclutamiento forzoso. Apoyo < 20 → riesgo de revuelta (evento). Apoyo > 80 → bonus de crecimiento poblacional.

**Cosecha anual** (turno 1): clima aleatorio sesgado por latitud y eventos (pequeña Edad de Hielo: inviernos duros probables hacia 1400+).

**Edificios** (costo PG + oro, cola por región): Graneros, Talleres, Mercados, Murallas, Castillos, Astilleros, Universidad (Fase 3).

### 5.3 Dinastía y familia (eje central)
Cada facción tiene un árbol familiar: gobernante, consorte, hijos (edad, sexo, stats), hermanos, tíos (candidatos alternos).

**Atributos de personaje (1-100):** Mando, Astucia, Carisma, Lealtad, Educación. Los hijos ganan stats con la educación (asignar tutor: PG/turno).

**Matrimonios:** casar hijos/os genera alianzas y *pretensiones dinásticas*. Si un cónyuge tiene derecho a una corona extranjera, se desbloquea el Casus Belli "Reclamación". Matrimonio de Estado con facción menor absorbe sus regiones por sucesión pacífica (si hay heredero común).

**Sucesión:** al morir el gobernante, el heredero legal sube al trono. Si el heredero es menor de 14 → regencia (astucia reducida, riesgo de usurpación por parientes). Si no hay heredero → **crisis sucesoria**: facción cae a interregno 2 años; los parientes de otras casas pueden declarar guerra por la corona. Tercera facción extinción → derrota.

**Eventos vitales trimestrales (probabilidades):** nacimiento (base 12% por consorte fértil < 40 años), enfermedad (base 2% por personaje > 50, +epidemias: Peste Negra evento global 1347-1353), muerte en batalla (si lidera un ejército derrotado: 15%).

### 5.4 Diplomacia
Relación bilateral −100..100, derivada de: casus belli activos, tratados, religion, fronteras, personalidad del líder.

Acciones (todas cuestan PG; éxito = tirada modificada por Astucia del enviado y relación):

| Acción | Coste PG | Efecto |
|---|---|---|
| Propuesta de alianza | 8 | Defensa mutua 3 años |
| Matrimonio dinástico | 10 | +relación, posible pretensión |
| Pacto comercial | 6 | +25% comercio bilateral |
| Exigir tributo | 5 | oro; guerra si rechazo y relación baja |
| Ofrecer tributo | 3 | +relación |
| Declarar guerra | 0 | requiere Casus Belli o −prestigio |
| Proponer paz | 4 | términos: oro/regiones/casamiento |
| Enviar espía (Fase 2) | 6 | revelar ejércitos/tesoro/regente |

**Puntuación de IA rival (ver 5.6)** decida aceptación.

### 5.5 Militar (visión general; detalle en Sección 6)
Ejércitos = grupos de unidades dentro de una región; límite por región según edificios. Movimiento por adyacencia regional (1 PG por ejército movido + coste de terreno). Reclutamiento consume pool regional y oro.

### 5.6 IA de facciones rivales
Motor por **utilidad esperada**, modular y reemplazable (un solo script `ai_brain.gd` por facción con perfiles):

```
Utilidad(acción) = Σ peso_perfil × (ganancia_oro, ganancia_territorio, seguridad_dinástica, prestigio) − coste_PG − riesgo_estimado
Perfiles: Agresor / Comerciante / Dinástico / Superviviente / Equilibrado
```

Decisión trimestral en 3 pasos: (1) evaluar amenazas (facciones más fuertes adyacentes), (2) priorizar PG (economía si pobre, ejército si amenazado, familia si heredero ausente), (3) ejecutar 2-4 órdenes por turno. Toda la IA se ejecuta tras el jugador, en <2 s para 14 facciones (presupuesto de rendimiento).

---

## 6. Batallas — resolución en tres niveles

Como en el diseño de referencia, al entrar en combate el jugador elige el nivel de control:

### 6.1 Nivel 1 — Combate delegado (MVP)
Se selecciona general y postura (Ofensiva / Equilibrada / Defensiva) y se resuelve automáticamente:

```
Poder_ejército = Σ (fuerza_unidad × morale × veterania × bono_terreno × bono_comandante)
Comandante: bono = 1 + (Mando − 50)/200   → rango 0.75 – 1.25
Morale = 0.5 + apoyo/200  (rango 0.5-1.0, modificado por racha y hambre)
Terreno: defensor según terreno_región (llanura 1.0 / bosque 1.15 / ciudad 1.4 / río+0.2)
Tirada: factor aleatorio gaussiano μ=1, σ=0.15

Batalla en hasta 5 asaltos:
  daño_asalto_a = Poder_a × aleatorio × coef_asalto(postura_a)
  unidades pierden efectivos proporcionalmente; ejército con <25% o moral rota retira
  líder derrotado en retirada: 15% muerte/cautiverio
```

Salida: informe con bajas por bando, unidades perdidas, capturas, oro/región conquistada si captura de capital regional.

### 6.2 Nivel 2 — Mapa táctico de ejércitos (Fase 2)
Mapa hexagonal local de la región (río, colinas, ciudad). Las legiones se mueven por turnos de iniciativa; choque → se resuelve ese hex en Nivel 3 o por autocomputo local. Puntos de victoria por objetivos (puente, ciudad, retaguardia).

### 6.3 Nivel 3 — Combate cerrado unidad contra unidad (Fase 2)
Como el nivel 2 pero con grupos unidad-a-unidad y cartas de orden: Carga, Disparo, Formación (piqueros), Finta, Retirada ordenada. El comandante con mayor Mando roba +1 orden/turno.

### 6.4 Tabla de unidades y evolución tecnológica

| Unidad | Época | Tipo | Fuerza | Mov. | Coste | Notas |
|---|---|---|---|---|---|---|
| Milicia de lanza | I-III | Inf. | 4 | 2 | bajo | Leva masiva |
| Piquero escocés (schiltron) | I-II | Inf. | 7 | 1 | bajo | Anti-caballería ×1.5 |
| Ballesteros | I-III | Dis. | 8 | 2 | medio | Génova/Italia; dispara antes del choque |
| Arquero largo | I-III | Dis. | 9 | 2 | medio | Inglaterra/Gales; lluvia de flechas |
| Sargentos a caballo | I-II | Cab. | 9 | 4 | medio | Caballería media |
| Hombres de armas | I-III | Cab. | 12 | 3 | alto | Núcleo feudal |
| Jinete (cab. ligera) | I-III | Cab.L | 7 | 5 | bajo | Castilla, húngaros; hostigamiento |
| Cab. de estepa | I-II | Cab.L | 8 | 6 | medio | Horda de Oro; treta |
| Almogávar | I | Inf. | 8 | 3 | medio | Aragón; terreno difícil ×1.3 |
| Mameluco | I-III | Cab. | 12 | 4 | alto | El Cairo; disciplina (morale+0.1) |
| Pikero suizo/alemán | II-III | Inf. | 11 | 2 | medio | Desde ~1386; anti-carga ×1.5 |
| Hombre de armas a pie | II-III | Inf. | 11 | 2 | alto | Moda pos-Crécy |
| Bombarda | II-III | Art. | 16 | 1 | muy alto | Asedio; ruido (morale enemigo −0.1 asalto 1) |
| Arcabucero | III | Dis. | 12 | 2 | alto | Desde ~1440; penetra armadura |
| Carro bélico húsita | III | Esp. | 9 | 2 | medio | Defensa móvil ×1.3 |
| Jenízaro | III | Inf. | 13 | 3 | alto | Otomanos; reclutamiento devshirme (pool especial) |
| Caballeros teutónicos | I-II | Cab. | 13 | 3 | alto | Balcano/Báltico; cruzada |

**Reglas de interacción:** Disparo inflige daño previo al asalto; Caballería pesada ×1.4 vs Infantería en llanura pero ×0.6 vs Schiltron/Piqueros; Artillería solo efectiva en asedio; Cab. ligera puede retirarse sin asalto final (finta).

---

## 7. Arquitectura de datos

Todo contenido vive en JSON en `res://data/` (versionado en Git). Ningún dato está hardcodeado en GDScript. Validación: `data/schema/*.json` (JSON Schema draft 2020-12) + script `tools/validate_data.gd` ejecutado en CI y al arrancar en modo debug.

### 7.1 Esquema `characters.json` (fragmento)

```json
{
  "id": "edward_iii_plantagenet",
  "name": "Eduardo III",
  "house": "plantagenet",
  "faction": "england",
  "born": 1312, "died": null,
  "role": "ruler",
  "stats": { "command": 85, "intrigue": 70, "charisma": 82, "loyalty": 90, "education": 78 },
  "traits": ["warrior_king", "claimant_france"],
  "family": { "father": "edward_ii", "mother": "isabella_france", "spouse": "philippa_hainault", "children": ["black_prince", "lionel_antwerp", "john_ghent"] },
  "claims": [ { "target": "france", "strength": 0.8 } ]
}
```

### 7.2 Esquema `regions.json` (fragmento)

```json
{
  "id": "region_normandy",
  "name": "Normandía",
  "terrain": "plains",
  "has_city": true,
  "adjacency": ["region_brittany", "region_ile_de_france", "region_maine"],
  "year_data": {
    "1337": { "owner": "france", "population": 520000, "base_wealth": 60, "buildings": ["castle"] },
    "1402": { "owner": "england", "population": 480000, "base_wealth": 55, "buildings": ["castle", "market"] },
    "1453": { "owner": "france", "population": 610000, "base_wealth": 70, "buildings": ["castle", "market", "workshops"] }
  }
}
```

### 7.3 Esquema `factions.json`

```json
{ "id": "france", "name": "Reino de Francia", "capital": "region_ile_de_france",
  "government": "monarchy", "color": "#2a4d8f", "playable": true,
  "profile": "balanced", "start_year": 1337 }
```

### 7.4 Esquema `units.json`

```json
{ "id": "longbowman", "name": "Arquero largo", "era": [1,3], "type": "ranged",
  "strength": 9, "move": 2, "cost": { "gold": 60, "recruits": 200 },
  "multipliers": { "vs_cavalry": 1.2 }, "requires": [], "faction_tags": ["england", "wales"] }
```

### 7.5 Esquema `scenarios/scenario_1337.json`

```json
{
  "id": "scenario_1337", "title": "Dos Coronas", "start_year": 1337, "end_year": 1399,
  "factions": ["england","france","hre",...],
  "initial_state": { "characters": "characters_1337.json", "regions": "1337", "treasuries": {...}, "armies": {...} },
  "victory": { "crowns": 2, "prestige": 500, "years_held": 10 },
  "events_script": "events_1337.json"
}
```

### 7.6 Esquema `events_YYYY.json` (sistema de eventos)

```json
{ "id": "black_death_1348", "year": 1348, "trigger": { "type": "year_reached" },
  "effects": [ { "type": "population_modifier", "scope": "europe_west", "value": -0.35 } ],
  "news": "La Peste Negra recorre Europa..." }
```

### 7.7 Estado de partida guardada (`user://saves/*.json`)
Snapshot serializable de todos los sistemas: `turn`, `year`, `quarter`, `factions[]` (tesoro, PG, relaciones, árboles familiares vivos), `regions[]` (dueño, asignación, edificios, pool), `armies[]` (composición, moral, posición), `event_log`. Versión con `save_version` para migraciones.

### 7.8 Fuentes abiertas de datos (para el agente Historia)
- **Wikidata SPARQL:** gobernantes por país/año, fechas de nacimiento/muerte, casas dinásticas (P39 cargo, P6 jefe de gobierno, P53 familia).
- **Wikipedia (EN/ES/FR):** batallas y sus fechas para eventos; unidades por nación.
- **Mapas históricos de dominio público** (Perry-Castañeda, bibliotecas digitales europeas): fronteras aproximadas por año → vectorizar a mano sobre plantilla.
- Regla de oro del agente Historia: **toda cifra histórica citada en datos debe tener `source` con URL** en `data/sources.md`.

---

## 8. Arquitectura de software (Godot 4)

### 8.1 Estructura de proyecto

```
sovereigns-blood/
├── project.godot
├── scenes/
│   ├── main/main_menu.tscn
│   ├── main/scenario_select.tscn
│   ├── map/world_map.tscn          # mapa principal por regiones
│   ├── map/region_node.tscn        # nodo clickeable de región
│   ├── council/council_menu.tscn   # menú de órdenes estilo clásico
│   ├── family/family_tree.tscn
│   ├── diplomacy/diplomacy_screen.tscn
│   ├── battle/battle_report.tscn   # Nivel 1
│   ├── battle/tactical_map.tscn    # Nivel 2 (Fase 2)
│   ├── battle/close_combat.tscn    # Nivel 3 (Fase 2)
│   └── ui/components/              # barras, tooltips, cuadros de diálogo
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd          # estado global + save/load
│   │   ├── data_loader.gd         # JSON → objetos tipados
│   │   ├── turn_manager.gd        # secuencia de turno, PG
│   │   ├── economy_system.gd
│   │   ├── dynasty_system.gd      # nacimientos, muertes, sucesión
│   │   ├── diplomacy_system.gd
│   │   ├── military_system.gd     # ejércitos, movimiento, reclutamiento
│   │   ├── battle_manager.gd      # 3 niveles de resolución
│   │   ├── ai_manager.gd          # orquesta facciones IA
│   │   ├── event_bus.gd           # señales globales tipadas
│   │   └── audio_manager.gd
│   ├── ai/
│   │   ├── ai_brain.gd            # interfaz; un nodo por facción IA
│   │   └── profiles/*.gd          # agresor, comerciante, dinástico...
│   ├── model/                     # dataclasses en GDScript
│   │   ├── character.gd
│   │   ├── region_state.gd
│   │   ├── army.gd
│   │   └── unit_instance.gd
│   └── utils/rng.gd               # RNG sembrado (reproducibilidad de tests)
├── data/                          # ver Sección 7
├── assets/art/, assets/audio/     # placeholders hasta Fase 3
├── tests/                         # GUT (Godot Unit Test)
└── tools/validate_data.gd
```

### 8.2 Contratos entre sistemas (API pública mínima)

```gdscript
# turn_manager.gd — el orquestador del turno; la UI solo habla con él
signal turn_started(quarter: int, year: int)
signal pg_changed(remaining: int)
func begin_turn(faction_id: String) -> void
func end_turn() -> void            # ejecuta IA de rivales + fin de año si toca

# economy_system.gd
func recalculate(faction_id: String) -> void
func allocate(region_id: String, worker_class: String, amount: int) -> bool  # valida PG

# dynasty_system.gd
func marry(character_id: String, target_character_id: String) -> Dictionary  # {ok, alliance?, claim?}
func advance_year() -> Array[Dictionary]   # eventos vitales generados

# diplomacy_system.gd
func propose(actor: String, target: String, action: Dictionary) -> Dictionary

# battle_manager.gd — fachada única para los 3 niveles
func resolve_delegated(attacker_army: Army, defender_army: Army, region: RegionState, stance: int) -> BattleReport
func launch_tactical(attacker_army: Army, defender_army: Army, region: RegionState) -> Node  # (Fase 2)
```

Regla de oro para los agentes programadores: **las escenas de UI nunca mutan estado directamente**; llaman a los sistemas vía `EventBus` o autoloads. Esto mantiene el código reemplazable por IA sin efectos colaterales.

### 8.3 Patrones
- **Autoload + señales tipadas** para desacoplar; nada de singletons "a lo bruto".
- **Estado puro serializable:** todos los datos de partida en diccionarios/arrays listos para `to_json` (guardado y tests deterministas).
- **RNG centralizado** (`utils/rng.gd`) con semilla guardada en partida → replays y tests reproducibles.
- **Modo headless** (`godot --headless`) para CI de tests; el agente QA ejecuta `godot --headless --script tests/run_all.gd`.

### 8.4 Guardado
`user://saves/<slot>.json` con `save_version: 1`. Botón guardar/cargar en menú principal y esc. Autoguardado cada fin de año en `user://saves/autosave.json`.

---

## 9. UI/UX — pantallas y flujo

1. **Menú principal:** Nuevo juego / Cargar / Opciones / Salir. Arte placeholder (fondo mapa viejo estilizado).
2. **Selección de escenario:** 3 tarjetas con año, mapa miniatura y lista de facciones jugables.
3. **Mapa principal:** regiones poligonales coloreadas por facción; iconos de ejército (bandera + número); ciudad destacada; panel lateral con resumen (año/trimestre, PG, tesoro, alertas). Hover = tooltip de región. Click = panel de región (asignar mano de obra, edificios, reclutar).
4. **Menú de Consejo (barra lateral clásica):** órdenes con coste PG visible: Consejo, Familia, Diplomacia, Militar, Economía, Terminar turno. Estilo visual: pergaminos/azul profundo/dorado, tipografía serif legible (Cinzel títulos, EB Garamond cuerpo — Google Fonts, OFL).
5. **Árbol familiar:** diagrama con retratos placeholder, líneas de parentesco, estado (edad, heredero ★, enfermo, cautivo). Acciones: educar, concertar matrimonio, nombrar regente.
6. **Diplomacia:** lista de facciones con barras de relación; modales de propuesta con éxito estimado.
7. **Informe de batalla (Nivel 1):** resumen por asaltos, bajas, capturas, botín; botones "Rechazar/revisar" no aplican (no hay undo — decisión final, como el diseño de referencia).
8. **Fin de año:** informe anual (cosecha, nacimientos, muertes, eventos, cambios de frontera) con avance a siguiente año.
9. **Pantalla de victoria/derrota** con estadísticas de la partida.

**MVP de interacción:** todo con mouse; atajos opcionales (Enter = terminar turno). Resolución objetivo 1920×1080, escalable.

---

## 10. Arte, audio y dirección visual

- **Dirección:** "manuscrito iluminado + mapa de época". Paleta: azul tinta, ocre pergamino, dorado, rojo grana. Evitar estética medieval genérica de fantasía: es historia, no fantasía.
- **Assets MVP (Fase 1-2):** placeholders generados proceduralmente (Godot Shaders simples o formas vectoriales): regiones planas con borde tinta, banderas por facción, retratos = escudos heráldicos generados por código a partir de datos de casa (colores + divisa). Esto elimina la dependencia de arte para jugar.
- **Fase 3:** retratos ilustrados (generación IA + retoque manual), tiles de batalla táctica, mapa con relieve, banda sonora (música renacentista de dominio público interpretada/fuentes libres, ej. música de consort CC), efectos (espadas, campanas, murmullo de corte).
- **Heraldica generativa:** cada casa define `colors[2] + charge` en datos → escudo único automático. Sin assets raster por facción.

---

## 11. Equipo de agentes DSH

### 11.1 Recomendación: equipo nativo de DSH (sin plugin de terceros)

Usa los **subagentes nativos de DSH** (`/agents` o el mecanismo de agentes del harness) con `deepseek-flash` como modelo. Razones:
- DSH es gratuito/open source y corre local; los plugins añaden una capa de fallo y mantenimiento que no necesitas.
- `deepseek-flash` soporta hasta 2.500 peticiones concurrentes → puedes correr los 5 agentes en paralelo cuando las tareas lo permitan (la fase de desarrollo de sistemas, no la de datos).
- El contexto de 1M tokens permite dar a cada agente el GDD completo + los archivos relevantes sin fragmentación.

### 11.2 Definición del equipo (plantillas de agente)

Cada agente se define con: nombre, modelo (`deepseek-flash`), prompt de sistema, herramientas (fs, godot-mcp, rea-mcp, shell), y carpeta de trabajo. El Coordinator debe **guardar cada definición como un MD en `C:\Proyectos\TSB\agents\`** (ej. `C:\Proyectos\TSB\agents\AG-2-systems-dev.md`) la primera vez que activa al agente, y reusar ese MD en sesiones posteriores. Rutas de trabajo relativas al repo `C:\Proyectos\TSB\sovereigns-blood\`.

**AG-0 · Coordinator (orquestador — corre en el chat principal de DSH)**
> Eres el coordinador del desarrollo de The Sovereign's Blood (GDD v1.0). No escribes código de producción. Descompones tareas, las asignas a AG-1..AG-5 según la Sección 11.3, revisas sus diffs contra los criterios de aceptación (Sección 12) y decides siguiente paso. Mantienes `docs/STATUS.md` actualizado. Ante ambigüedad del GDD, decides lo más simple que cumpla el alcance del MVP y lo registras en `docs/decisions.md`.

**AG-1 · Historian/Data** (herramientas: fs, web search si está disponible; *sin* godot-mcp)
> Eres el agente de datos históricos. Produces y mantienes `data/*.json` conforme a la Sección 7 y `data/sources.md`. Cada dato histórico lleva `source` con URL (Wikidata/Wikipedia/mapa). Prioridad de trabajo: (1) `factions.json`, `characters.json`, `regions.json` del Escenario 1 (1337); (2) `units.json`; (3) `scenario_1337.json` y `events_1337.json`. Nunca inventes cifras: si no hay fuente, usa estimación marcada `"estimate": true`. En la Fase 0 también redactas `docs/rea/gk2_data_lessons.md` a partir del informe de AG-REA.

**AG-REA · Reverse Engineer** (herramientas: fs, shell, rea-mcp; alcance limitado por Sección 3)
> Tu única misión es analizar los formatos de datos del juego de referencia Genghis Khan II. Los archivos están en `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf` (solo lectura). Usa rea-mcp o inspección hexadecimal para documentar los `.DAT`/`.GK2` y produce `docs/rea/gk2_data_lessons.md`: tablas de campos, tamaños, lecciones de modelado de datos (checklist completo en Anexo A). Está terminantemente prohibido analizar ejecutables (.EXE) ni transcribir texto del juego. Al terminar el informe, tu tarea concluye y no vuelves a activarte salvo petición expresa del Coordinator.

**AG-2 · Systems Dev** (herramientas: fs, shell, godot-mcp)
> Implementas los sistemas de juego en GDScript según las Secciones 5, 6 y 8: turn_manager, economy_system, dynasty_system, diplomacy_system, military_system, battle_manager (Nivel 1), ai_manager, data_loader, model/. Contratos: usa exactamente las firmas de la Sección 8.2. Cada PR debe incluir test GUT del sistema tocado. No tocas escenas de UI ni assets.

**AG-3 · UI Dev** (herramientas: fs, shell, godot-mcp)
> Implementas las escenas de la Sección 9 consumiendo SOLO los contratos públicos de la Sección 8.2 (nunca mutas estado directamente). UI funcional primero, estilo después (la dirección visual está en Sección 10). Cada pantalla debe funcionar a 1920×1080 y con placeholders de arte.

**AG-4 · QA** (herramientas: fs, shell)
> Ejecutas `godot --headless --script tests/run_all.gd` tras cada cambio de AG-2/AG-3. Redactas tests de regresión para cada bug encontrado (`tests/`). Verificas: criterios de aceptación de la Sección 12, validación de datos (`tools/validate_data.gd`), determinismo (misma semilla → mismo resultado). No arreglas código: reportas issues con pasos de reproducción en `docs/issues.md` y el Coordinator los asigna.

**AG-5 · Art Pipeline** (se activa en Fase 3)
> Produces assets finales según Sección 10: prompts de generación de retratos/tiles, integración en `assets/`, bandera sonora CC.

### 11.3 Flujo de trabajo del equipo

```
FASE 0 (secuencial)
  AG-REA → gk2_data_lessons.md → AG-1 → datasets Escenario 1 + schemas
                                     ↘ AG-2 scaffold del proyecto Godot (vacío pero compilando) en paralelo

FASE 1 (paralelo controlado)
  AG-2 sistemas núcleo (economía, dinastía, diplomacia, batalla delegada, IA, save/load)
  AG-3 UI (consumiendo contratos; puede usar stubs hasta que AG-2 entregue)
  AG-4 QA continuo + tests
  Coordinator revisa diffs, mantiene STATUS.md, resuelve conflictos de integración

FASE 2 / 3
  Mismo esquema; AG-5 se une en Fase 3. Escenarios 2-3 = AG-1 datos + AG-2 activación por año.
```

**Reglas de coordinación:** (1) un solo agente toca un archivo a la vez (el Coordinator asigna archivos, no carpetas); (2) commits pequeños y frecuentes, mensaje con prefijo `[AG-N]`; (3) cada fase cierra con revisión del Coordinator contra los criterios de aceptación antes de pasar a la siguiente.

### 11.4 Prompt maestro sugerido (para iniciar DSH)

```text
Actúa como AG-0 Coordinator del proyecto The Sovereign's Blood.

ENTORNO (inamovible):
- Workspace raíz: C:\Proyectos\TSB — NADA se crea fuera de esta carpeta.
- GDD maestro: C:\Proyectos\TSB\GDD_The_Sovereign's_Blood.md — léelo completo antes de
  actuar; ante cualquier duda, este documento manda.
- Referencia GK2 (SOLO LECTURA, solo para AG-REA): C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf
- Repo del juego a crear: C:\Proyectos\TSB\sovereigns-blood
- Definiciones de agentes: guarda cada prompt de la Sección 11.2 como MD en
  C:\Proyectos\TSB\agents\ (ej. agents\AG-REA.md) la primera vez que actives a cada agente.
- Godot: C:\Godot\<ejecutable>.exe — verifica el nombre exacto antes de usarlo;
  godot-mcp y rea-mcp ya están instalados en este DSH.

TU PRIMERA TAREA (Fase 0):
1. Verifica que este workspace contiene el GDD y la carpeta de referencia GK2; reporta lo que encuentres.
2. Crea la estructura: C:\Proyectos\TSB\agents\, C:\Proyectos\TSB\sovereigns-blood\ con
   project.godot vacío que compile y docs\STATUS.md inicial.
3. Activa AG-REA (guarda su MD en agents\) para producir docs\rea\gk2_data_lessons.md
   según la Sección 3 y el Anexo A.
4. Activa AG-1 para producir los datasets del Escenario 1 (1337) según la Sección 7,
   con fuentes en data\sources.md.
5. Crea el agente AG-4 (QA) y hazle pasar tools\validate_data.gd cuando AG-1 termine.
6. Mantén docs\STATUS.md y docs\decisions.md actualizados en cada paso.

REGLAS: commits pequeños con prefijo [AG-N]; un solo agente por archivo a la vez;
no avances a la Fase 1 hasta cumplir los criterios de aceptación de la Fase 0
(Sección 12). Trabaja en horario off-peak cuando sea posible.

GIT (Sección 3.2): al crear el repo local, añade el remoto
https://github.com/horaciomartinez-svg/The_Sovereign_Blood.git como origin (main).
Tu PRIMER push debe incluir el GDD en la raíz del repo (commit [AG-0] init).
Haz push al cerrar cada módulo con docs\STATUS.md actualizado; crea el tag de fase
al cumplir los criterios de aceptación. Nunca force-pushees. Godot headless:
"C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path
C:\Proyectos\TSB\sovereigns-blood --script tests/run_all.gd
```

---

## 12. Plan ágil por fases (con criterios de aceptación)

### Fase 0 — Cimientos (objetivo: 3-5 días)
- AG-REA: informe `gk2_data_lessons.md`.
- AG-1: schemas + `factions/characters/regions/units/scenario_1337/events_1337` validados.
- AG-2: repo Godot compilando, autoloads vacíos, CI headless corriendo.
- **Aceptación:** `validate_data.gd` 0 errores; `godot --headless` arranca sin warnings críticos; informe REA ≤ 2 páginas.

### Fase 1 — MVP jugable (objetivo: 2-3 semanas)
- Loop completo de trimestre + año; economía con asignación por región; apoyo/revueltas; familia (nacimientos, educación, sucesión, matrimonios y pretensiones); diplomacia (las 7 acciones); batallas delegadas; IA de 13 facciones rivales; guardar/cargar; UI completa de la Sección 9.
- **Aceptación jugable:** se puede jugar Inglaterra 1337 de principio a fin de año sin crash; la IA completa sus turnos <2 s; guardar/cargar preserva el estado exacto (test automatizado); batalla delegada produce informe coherente y captura regiones; evento de Peste Negra dispara en 1348.

### Fase 2 — Profundidad militar (objetivo: 2 semanas)
- Mapa táctico Nivel 2 (hex local) y combate cerrado Nivel 3 (órdenes/cartas); espionaje; fin de partidas por extinción dinástica.
- **Aceptación:** Crécy puede jugarse en los 3 niveles con resultados coherentes; pérdida de líder sin herederos termina la partida correctamente.

### Fase 3 — Contenido y remaster (objetivo: 2-3 semanas)
- Escenarios 1402 y 1453 completos (datos + eventos: Ankara, locura de Carlos VI, caída de Constantinopla, Dos Rosas); evolución tecnológica por año; arte final (retratos, tiles, música CC); balance general.
- **Aceptación:** los 3 escenarios empiezan y llegan a su año final; victoria/derrota según Sección 4.5; partida completa de test automatizada de 10 años sin errores.

**Total estimado: 7-10 semanas de trabajo del equipo de agentes, revisado por ti en sesiones cortas.**

---

## 13. QA y pruebas

- **Unitarias (GUT):** cada sistema núcleo con tests de sus fórmulas (economía, batalla delegada, sucesión) usando RNG sembrado.
- **Integración:** partida-simulación headless: Inglaterra en piloto automático 20 años sin crash y con estado serializable en cada año.
- **Datos:** validación JSON Schema + reglas cruzadas (adyacencias simétricas, toda facción tiene capital, toda región tiene dueño en año de escenario).
- **Determinismo:** misma semilla + mismas acciones = mismo hash de save.
- **Manual:** checklist por fase del Coordinator; capturas de cada pantalla en `docs/screenshots/`.

## 14. Riesgos y mitigación

| Riesgo | Prob. | Mitigación |
|---|---|---|
| Godot MCP inestable en Windows | Media | Shell directo (`godot --headless`) como vía alternativa obligatoria en scripts |
| Datos históricos incompletos (población medieval) | Alta | Estimaciones marcadas; redondeos por magnitud; foco en jugabilidad |
| Scope creep (Batallas Nivel 2/3) | Alta | Bloqueados hasta Fase 2; Nivel 1 ya permite ganar la campaña |
| Agentes pisando archivos | Media | Asignación por archivo del Coordinator; commits pequeños `[AG-N]` |
| IA lenta con 14 facciones | Baja | Perfiles simples; presupuesto 2 s medido en CI |
| Costo API | Baja | Trabajar off-peak; caché de contexto; GLM-4.7-Flash gratis para AG-1 si conviene |

## 15. Anexos

### Anexo A — Checklist REA (GK2, alcance limitado Sección 3)
Ruta de los archivos: `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf` (solo lectura). Herramientas: `rea-mcp` o inspección hexadecimal con fs/shell.
- [ ] Header y tamaños de `GENDATA1.DAT` (campos de generales por escenario)
- [ ] Estructura de `ZNAME.DAT` (nombres de región, longitud fija)
- [ ] Estructura de `SCENARIO.GK2` y `SAVEDATA.GK2` (qué guarda el estado)
- [ ] `MAPDATA.DAT` / `HEXKG.DAT` / `HEXSG.DAT`: dimensiones del mapa y codificación
- [ ] Redactar `docs/rea/gk2_data_lessons.md` con tabla de equivalencias para nuestros JSON
- [ ] Prohibido: abrir `MAIN.EXE`/`OPEN.EXE`/`END.EXE` con desensamblador

### Anexo B — Definición de terminado (DoD)
1. Compila y corre en Godot 4 headless y con UI.
2. Tests GUT pasan; nuevo sistema = nuevo test.
3. Sin referencias a propiedad intelectual de terceros en código/datos/arte.
4. `validate_data.gd` sin errores.
5. Revisado por Coordinator contra el criterio de aceptación de su fase.

### Anexo C — Glosario
PG: Puntos de Gobernanza · Casus Belli: justificación de guerra · Devshirme: reclutamiento otomano · Schiltron: formación escocesa anti-caballería · DS(DSH): DeepSeek Harness · REA: Reverse Engineer Anything (uso limitado, Sección 3).

---

*Fin del GDD v1.2 — The Sovereign's Blood. Documento de trabajo para el equipo de agentes DSH; ante conflicto entre este documento y el código, este documento manda hasta que el Coordinator apruebe un cambio registrado en `docs/decisions.md`. v1.1: entorno Windows real (Sección 3.1), carpeta `agents\`, godot-mcp y rea-mcp. v1.2: ejecutables Godot 4.7.2 verificados, repo GitHub público y protocolo de verificación (Sección 3.2).*
