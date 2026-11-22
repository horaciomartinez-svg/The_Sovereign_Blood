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
| **Versión del documento** | 1.9 |
| **Estado** | Aprobado — v1.9: Fase 4 (mercancías y comercio, pantalla de ejércitos, acción de consorte, Manual del Jugador, tutorial con Consejero y dificultad); hereda v1.8.1 (animación de combate), v1.8/v1.7 (sprites/tiles), v1.6 (17 unidades) |

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

### 3.2 REA ampliado — batallas Nivel 2/3 y gráficos de unidades (autorización expresa del usuario, Fase 2)

Además del alcance §3, AG-REA (reactivable solo para esto) producirá `docs/rea/gk2_battle_mechanics.md` con:

| Permitido (REA ampliado) | Prohibido (sigue en vigor) |
|---|---|
| **Observación de comportamiento:** documentar jugando en DOSBox las batallas de Nivel 2 (mapa táctico) y Nivel 3 (combate cerrado): orden de fases, movimiento, iniciativa, resolución de choques, efectos de terreno, moral — *qué reglas se observan*, con capturas y notas de sesión | Decompilar/desensamblar ejecutables para reutilizar código o fórmulas literales |
| **Estructura de datos gráficos:** documentar `SUNIT.DAT` (sprites de unidades: dimensiones, número de cuadros, paleta, disposición), `KPAT.DAT`, `GRPDATA.DAT` — formato y convenciones de animación como *referencia de legibilidad* | Copiar pixel data, paletas o assets de Koei al juego; transcribir texto del juego |
| **Lecciones de diseño:** qué hace legible una unidad en batalla (silueta, arma visible, animación de ataque reconocible) | Especificación de reimplementación 1:1 con valores copiados |

El informe alimenta el diseño de §10.3 (sprites) y el balance §6.2/§6.3, que se implementan con arte y código 100% originales.

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

**Mercancías y comercio (v1.9 — D-069):** cada facción mantiene un **inventario de mercancías** agregado de sus regiones. Hay 8-12 bienes (`data/trade_goods.json`, schema + fuentes): especias, pieles, lana, vino, sal, grano, armas, caballos, hierro y madera. Cada bien define `base_price`, `produced_by` (terreno/edificio: costa→sal; llanura extensa/pastos→caballos/pieles; taller→armas; bosque→madera; etc.) y `used_by` (reclutamiento/consumo). La producción llega al inventario de facción cada trimestre.
- **Comerciantes obligatorios:** el volumen de compra/venta de una facción depende de los **Comerciantes** asignados (clase trabajadora de §5.2). Sin comerciantes asignados no se puede operar el mercado; más comerciantes = mayor volumen máximo por trimestre.
- **Mercado:** comprar/vender al precio `base_price × factor_oferta_demanda`, donde el factor se deriva del inventario local/regional y de eventos (determinista con el RNG de la partida). Comercio exterior con facciones con pacto comercial, o mediante **expedición de mercaderes** (2 PG) que retorna tras N trimestres.
- **Riqueza con propósito:** el oro del comercio financia reclutamiento y entrenamiento (§5.5); el comercio es significativo pero **menor que la economía base**, sin inflación desbocada (mismas métricas de D-068).
- **Consumo:** grano/sal sostienen el apoyo poblacional; armas y caballos se consumen al reclutar las unidades que los requieren (§6.4).

### 5.3 Dinastía y familia (eje central)
Cada facción tiene un árbol familiar: gobernante, consorte, hijos (edad, sexo, stats), hermanos, tíos (candidatos alternos).

**Atributos de personaje (1-100):** Mando, Astucia, Carisma, Lealtad, Educación. Los hijos ganan stats con la educación (asignar tutor: PG/turno).

**Matrimonios:** casar hijos/os genera alianzas y *pretensiones dinásticas*. Si un cónyuge tiene derecho a una corona extranjera, se desbloquea el Casus Belli "Reclamación". Matrimonio de Estado con facción menor absorbe sus regiones por sucesión pacífica (si hay heredero común).

**Sucesión:** al morir el gobernante, el heredero legal sube al trono. Si el heredero es menor de 14 → regencia (astucia reducida, riesgo de usurpación por parientes). Si no hay heredero → **crisis sucesoria**: facción cae a interregno 2 años; los parientes de otras casas pueden declarar guerra por la corona. Tercera facción extinción → derrota.

**Eventos vitales trimestrales (probabilidades):** nacimiento (base 12% por consorte fértil < 40 años), enfermedad (base 2% por personaje > 50, +epidemias: Peste Negra evento global 1347-1353), muerte en batalla (si lidera un ejército derrotado: 15%).

**Acción «Pasar tiempo con la consorte» (v1.9 — D-071):** en el árbol familiar, una vez por trimestre y con coste de **2-3 PG**, el gobernante pasa tiempo con su consorte: otorga un **bonus de fertilidad** (probabilidad de nacimiento aumentada durante los **siguientes 2-4 trimestres**) y un pequeño bonus de prestigio/relación. Sin consorte válida (viuda/enferma/ausente) la acción se rechaza con mensaje claro; no deja estados rotos. La educación automática de menores (D-020) se mantiene y se muestra en la ficha del hijo.

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
Ejércitos = grupos de unidades dentro de una región; límite por región según edificios. Movimiento por adyacencia regional (1 PG por ejército movido + coste de terreno). **Reclutamiento con mercancías (v1.9 — D-070):** además de oro y pool regional, ciertas unidades consumen mercancías del inventario de facción — caballería exige **caballos**; infantería pesada/hombres de armas exigen **armas** (tabla §6.4 ampliada). La **pantalla de ejércitos** muestra por tipo de unidad su imagen (sprite `march_1` existente), número, fuerza y moral/experiencia medias, y permite **Reclutar / Entrenar** (sube experiencia; oro + 1 PG) / **Disolver** (libera reclutas y devuelve parte del oro) desde una vista global de facción.

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

**Reclutamiento con mercancías y entrenamiento (v1.9 — D-070):** además de oro y pool regional, el reclutamiento consume mercancías del inventario de facción: unidades de **caballería** (sargentos a caballo, hombres de armas, caballería ligera, caballería de estepa, mamelucos, caballeros teutónicos) requieren **caballos**; **infantería pesada/hombres de armas a pie** requieren **armas**. La tabla concreta de coste por unidad queda en `data/units.json` (`recruit_goods`) y se valida con el pipeline. **Entrenar** una unidad sube su experiencia/media (coste de oro + 1 PG) desde la pantalla de ejércitos; **Disolver** libera el pool de reclutas y devuelve parte del oro. La IA usa las mismas reglas (sin trampas de recursos).

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
3. **Mapa principal:** mapa geográfico profesional de Europa, Norte de África y Oriente Próximo (especificación completa en §10.1): terreno de época estilizado, fronteras de los reinos por año, regiones clickeables que resaltan al pasar el cursor, iconos de ejército (bandera + número), panel lateral con resumen (año/trimestre, PG, tesoro, alertas) y **retrato del soberano jugador** (§10.2) en la esquina del mapa, al estilo de la referencia. Zoom/pan con cámara 2D. Click = panel de región (asignar mano de obra, edificios, reclutar).
4. **Menú de Consejo (barra lateral clásica):** órdenes con coste PG visible: Consejo, Familia, Diplomacia, Militar, Economía, Terminar turno. Estilo visual: pergaminos/azul profundo/dorado, tipografía serif legible (Cinzel títulos, EB Garamond cuerpo — Google Fonts, OFL).
5. **Árbol familiar:** diagrama con retratos placeholder, líneas de parentesco, estado (edad, heredero ★, enfermo, cautivo). Acciones: educar, concertar matrimonio, nombrar regente.
6. **Diplomacia:** lista de facciones con barras de relación; modales de propuesta con éxito estimado.
7. **Informe de batalla (Nivel 1):** resumen por asaltos, bajas, capturas, botín; botones "Rechazar/revisar" no aplican (no hay undo — decisión final, como el diseño de referencia).
8. **Fin de año:** informe anual (cosecha, nacimientos, muertes, eventos, cambios de frontera) con avance a siguiente año.
9. **Pantalla de victoria/derrota** con estadísticas de la partida.
10. **Mercado / comercio (v1.9 — D-069):** inventario de facción por mercancía, precios y factor oferta/demanda, comerciantes disponibles, comprar/vender y panel de comercio exterior (pactos/expedición), con feedback de oro y volumen.
11. **Ejércitos (v1.9 — D-070):** rejilla global por tipo de unidad con sprite `march_1`, número, fuerza y moral/experiencia medias; acciones Reclutar (oro+pool+mercancías), Entrenar (oro+1 PG) y Disolver con confirmación.
12. **Manual del Jugador (v1.9 — D-072):** botón «Manual» en el menú principal (abre `docs/MANUAL_DEL_JUGADOR.md`) y entrada «Ayuda» en el menú de consejo con resumen rápido.
13. **Dificultad y tutorial (v1.9 — D-073):** selección Principiante/Normal al iniciar; en Principiante, panel del **Consejero** con guion del primer año, texto breve, resaltado de UI y opción de saltar; guion en `data/tutorial_script.json`, estado serializable. Normal = sin Consejero y IA algo más agresiva.

**MVP de interacción:** todo con mouse; atajos opcionales (Enter = terminar turno). Resolución objetivo 1920×1080, escalable.

---

## 10. Arte, audio y dirección visual

- **Dirección:** "manuscrito iluminado + mapa de época". Paleta: azul tinta, ocre pergamino, dorado, rojo grana. Evitar estética medieval genérica de fantasía: es historia, no fantasía.
- **Assets MVP (Fase 1-2):** placeholders generados proceduralmente (Godot Shaders simples o formas vectoriales): regiones planas con borde tinta, banderas por facción, retratos = escudos heráldicos generados por código a partir de datos de casa (colores + divisa). Esto elimina la dependencia de arte para jugar.
- **Fase 3:** retratos ilustrados (generación IA + retoque manual), tiles de batalla táctica, mapa con relieve, banda sonora (música renacentista de dominio público interpretada/fuentes libres, ej. música de consort CC), efectos (espadas, campanas, murmullo de corte).
- **Heraldica generativa:** cada casa define `colors[2] + charge` en datos → escudo único automático. Sin assets raster por facción.

### 10.1 Mapa geográfico profesional (v1.3 — solicitud del usuario)

**Objetivo.** Sustituir el tablero de hexágonos coloreados (placeholder `map_layout.json`, D-017) por un mapa estilo *atlas histórico*: el terreno real de **Europa, Norte de África y Oriente Próximo** con la división política de los reinos de la época. Referencia: el mapa de GK2 (geografía real + bordes de territorio superpuestos); el objetivo lo supera con fronteras vectoriales nítidas, relieve sutil y legibilidad total a 1920×1080.

**Arquitectura por capas (datos y render separados):**
1. **Capa base de terreno (imagen única):** terreno estilizado "pergamino/acuarela de época", generado una vez: costas detalladas, relieve sutil, ríos principales, indicación de bosques y montañas. **Prohibido** estilo satélite o fantasía. Técnica: heightmap + materiales/shaders de Godot, o textura pintada a partir de fuentes libres; 4096×3072 px mínimo, versionada en `assets/art/map/`.
2. **Capa de fronteras (vectorial, por año):** polígonos de cada región para **1337, 1402 y 1453**, dibujados como líneas de tinta sobre el terreno. Datos en nuevo dataset `data/map_borders.json` (AG-1): por `region_id`, `year` y anillo de puntos normalizados [0..1] sobre el lienzo del mapa; simplificación Douglas-Peucker con tolerancia fija; presupuesto ≤ 400 puntos por región, ≤ 150 KB el JSON.
3. **Capa interactiva:** polígonos invisibles clickeables conectados a `region_id`; hover resalta la región (tinta dorada ~18% opacidad) y muestra tooltip; cobertura completa 47/47 contra `regions.json`.
4. **Capa de entidades:** banderas de facción, ejércitos, iconos de ciudad, nombres de región con **elisión anti-solape por nivel de zoom** (3 niveles: región / país / mar); etiquetas de mar estilo carta náutica ("MARE SEPTENTRIONALE", "LEGUES"…).

**Fuentes de fronteras (abiertas y citables):** atlas históricos de dominio público — William R. Shepherd, *Historical Atlas* (1923-26, PD); mapas anuales de Wikimedia Commons (licencia verificada una a una); catálogos de bibliotecas digitales europeas. Regla §7.8: toda frontera lleva `source` con URL en `data/sources.md`. Las fronteras son **aproximaciones jugables**, no cartografía catastral: la regla de validación es coherencia con las adyacencias de `regions.json`, no precisión métrica.

**Plan de implementación (módulo "Mapa" dentro de la Fase 2):**
- **AG-1:** produce `data/map_borders.json` (3 años × 47 regiones) + entradas en `sources.md`.
- **AG-3:** integra las 4 capas en `scenes/map/world_map.tscn` con cámara 2D (zoom rueda/pinch, pan con límites del mundo); al completarse, `map_layout.json` queda **deprecado** (decisión D-024 a registrar).
- **Criterios de aceptación del módulo:** 47/47 polígonos por año con `region_id` válido; 0 regiones huérfanas; hover/click correctos en las 3 vistas de año; coste de render del mapa < 8 ms CPU por frame (medido en CI); capturas comparativas 1920×1080 en `docs/screenshots/`, incluida una **comparativa lado a lado con el mapa de GK2** como referencia de calidad.

### 10.2 Retratos de soberanos (v1.4 — solicitud del usuario)

**Objetivo.** Como en la referencia (retratos del gobernante y su lugarteniente en la esquina del mapa), el juego muestra siempre **quién eres**: un retrato tipo avatar del soberano que se está jugando, con calidad superior a los sprites de 16 bits de GK2. Referencia visual: las miniaturas de la captura del usuario (Genghis Khan / Mugali); estética objetivo: **miniatura de manuscrito iluminado / óleo plano de época**, coherente con la dirección §10 (pergamino, tinta, dorado) — nada de fantasía.

**Dónde aparece:** (1) esquina del mapa principal, junto al escudo de armas (jugador); (2) árbol familiar (cada miembro vivo); (3) pantalla de diplomacia (gobernante rival); (4) informe de batalla (líderes de ambos bandos); (5) pantalla de corte. Mismo asset en todos lados: un solo retrato por personaje.

**Especificación técnica:**
- `characters.json` añade campo opcional `"portrait": "<asset_id>"`. Resolución de trabajo: **256×256 px** (se muestra a 96-128 px; margen para zoom en detalle del personaje). Formato PNG con fondo plano color pergamino, marco dorado fino generado por código (no parte del asset).
- **Fase 2 (placeholder funcional):** AG-3 implementa el *slot* de retrato en las 5 ubicaciones con fallback automático: si `portrait` no existe, se renderiza la heráldica generativa del personaje (escudo de su `house`) + silueta genérica por sexo/edad. Nunca un hueco vacío.
- **Retratos finales (v1.5):** los 14 gobernantes iniciales de 1337 los diseña **Kimi** con investigación histórica (parecido a retratos/efigies reales cuando existen: Eduardo III según su efigie de Westminster, Casimiro III según su efigie de Cracovia, etc.; cuando no hay retrato, indumentaria, corona y rasgos correctos por región y década) + **escudo de armas heráldico exacto del reino** integrado en la imagen. Archivos: `assets/art/portraits/<character_id>.png` (256×256). Entregado como asset final, no placeholder. AG-5 (Fase 3) se encarga solo de los retratos restantes (herederos, escenarios 1402/1453) siguiendo la hoja de estilo fijada por el set de Kimi (paleta §10, rasgos por región, indumentaria por década), con hoja de contacto para auditar consistencia (`docs/screenshots/portraits_contact_sheet.png`).
- El retrato del soberano **cambia con la sucesión**: al morir el gobernante, el slot muestra al heredero (dinámica ya disponible en `DynastySystem`).

**Criterios de aceptación:** slot presente en las 5 ubicaciones con fallback heráldico 100% funcional (Fase 2); los 14 retratos de Kimi integrados y referenciados por `portrait` en `characters.json` (Fase 2); set completo sin personaje roto/faltante (Fase 3); cambio de retrato tras sucesión verificado en test; captura del mapa con retrato + escudo en `docs/screenshots/`.

### 10.3 Sprites de unidades y animación de combate (v1.5 — solicitud del usuario)

**Objetivo.** En los Niveles 2/3 de batalla, cada tipo de unidad se reconoce **a simple vista por su arma y silueta**, con calidad de ilustración a pesar de su baja resolución (referencia de legibilidad: informe REA `gk2_battle_mechanics.md`, §3.2). Ejemplos exigidos: la milicia de lanza se ve con su lanza o alabarda de la época; los ballesteros se ven con su ballesta y, al atacar, **se ve volar el virote**; arqueros largos con arco y flecha visible.

**Especificación técnica:**
- **Tamaño:** sprites base 64×64 px (unidad a pie) y 64×80 (caballería); escalables ×2/×3 en pantalla. Estilo "miniatura pintada" coherente con los retratos §10.2 (trazo de ilustración, no pixel art digital genérico), fondo transparente PNG.
- **Hojas de animación por unidad:** idle (2 cuadros), marcha (4), ataque (4-6), impacto/herida (2), muerte (2), con versión por dirección (S, SE, E como mínimo — espejo para el resto). Proyectiles separados: virote (ballesta), flecha (arco), piedra (bombarda), con trayectoria balística visible.
- **Armas por época (§6.4):** las siluetas deben distinguir pica/lanza de alabarda (aparece hacia 1380) y de arcabuz (post-1440); la ballesta con gafa y cinturín de recarga; el arco largo inglés; escudo heater vs. pavés; caballería con lanza en ristre vs. cab. ligera con jabalina.
- **Asignación:** `units.json` añade campo opcional `"sprite_sheet": "res://assets/art/units/<unit_id>.png"`; fallback = marcador heráldico por facción (ya existente) si falta el sprite.
- **Producción:** AG-5 (Fase 3) con guía de estilo; la lista de hojas requeridas se deriva de `units.json` (17 tipos × variantes por época según aplique). Prioridad: las 6-8 unidades más comunes del Escenario 1.

**Sprites de TODAS las unidades ENTREGADOS (v1.6 — Kimi, 2026-11-22).** Paquete `Sprites_Unidades_TSB.zip`: las **17 unidades** de `units.json` × 3 cuadros de marcha (51 sprites) + 3 proyectiles (`proyectil_virote.png`, `proyectil_flecha.png`, `proyectil_piedra.png`). Contrato del asset:
- **Archivos:** `<unit_id>_march_{1,2,3}.png`; infantería 512×512, caballería 512×640 (proporción 64×80), artillería/especiales (`bombard`, `hussite_war_wagon`) 512×341 panorámico. RGBA transparente, figura aislada sin sombra de suelo. Originales 1024/1536 incluidos. Ancla: borde inferior, centro horizontal.
- **Animación de marcha (ciclo 3):** `march_1` extremidad izquierda adelante → `march_2` reunión/paso → `march_3` derecha adelante (equivalente en el paso del caballo / giro de ruedas). Todos miran a E; para N/NW/O espejar en el motor (convención GK2); S/SE usan la versión actual.
- **Reescalado:** LANCZOS a 64×64 / 64×80 (64×43 artillería) en importación; validar legibilidad del arma a 64 px (QA visual).
- **Proyectiles:** capa separada con trayectoria balística; virote→`crossbowmen`, flecha→`longbowman`/`janissary`/`steppe_cavalry`, piedra→`bombard`.
- **Campo `units.json` (D-037):** `"sprite_sheet": {"frames": ["res://assets/art/sprites/units/<unit_id>_march_1.png", "..._2", "..._3"], "anim": {"march": [0,1,2], "fps": 6, "loop": true}, "size": [64,64], "anchor": "bottom_center", "facing": "E"}` (64×80 caballería, 64×43 artillería). Fallback heráldico si falta.
- **Cuadros de animación de combate ENTREGADOS (v1.8 — Kimi, 2026-11-22, D-049).** Paquete `Anim_Combate_TSB.zip`: las **17 unidades** × 10 cuadros (idle×2, ataque×4, impacto×2, muerte×2) = **170 sprites**, mismas convenciones que el set de marcha (512-wide RGBA, ancla `bottom_center`, facing E con espejo, reescalado 64×64/64×80/64×43 LANCZOS). Secuencia de ataque: preparación → golpe/disparo (`attack_2` = cuadro de impacto, sincronizar con D-048) → follow-through → recuperación. Secuencias especiales: unidades a distancia (apuntar→disparar→bajar→recargar; proyectil sigue en capa separada), `bombarda` (dotación de 2 artilleros; `attack_2` = disparo con nube de pólvora y retroceso), `hussite_war_wagon` (dotilla disparando desde las pavesas). QA visual cuadro a cuadro en `_hoja_contacto_anim.png`.
- **Contrato de integración (D-049):** los 10 cuadros se añaden a `frames` tras los 3 de marcha (índices 3-12) y el `anim` se extiende: `{"march":[0,1,2], "idle":[3,4], "attack":[5,6,7,8], "hit":[9,10], "death":[11,12], "fps":6, "loop":true, "fps_attack":9, "fps_hit":8, "fps_death":6, "death_hold":true}`. `loop` aplica a marcha/idle; ataque/impacto/muerte se reproducen una vez; `death_hold` = el cuadro final de muerte persiste hasta que la unidad desaparece del campo. Ver detalle en el README del paquete.
- **Addendum v1.8.1 (2026-11-23) — alineación con `docs/art/requests/kimi_phase3_assets.md` v1.1 (AG-5):** las 7 unidades a distancia/artillería (`janissary`, `arquebusier`, `crossbowmen`, `longbowman`, `steppe_cavalry`, `bombarda`, `hussite_war_wagon`) llevan **ataque de 6 cuadros** (Paquete B = 184 PNG totales: 34 idle + 82 attack + 34 impact + 34 death), entregado en `Anim_Combate_Rango_Artilleria_TSB.zip` (42 `attack_1..6` + 34 `impact_1..2`; nomenclatura `impact` en lugar de `hit`). Índices por unidad: 10 unidades de choque → `idle [3,4]`, `attack [5..8]`, `impact [9,10]`, `death [11,12]`; 7 a distancia/artillería → `idle [3,4]`, `attack [5..10]`, `impact [11,12]`, `death [13,14]`. `attack_4` = cuadro de disparo/impacto (sincronizar proyectil, D-048).

**Criterios de aceptación:** cada tipo de unidad del Escenario 1 identificable en silueta a 64 px; animación de ataque con proyectil visible para ballesteros/arqueros/bombardas; todas las hojas referenciadas en `units.json` cargan sin error en CI; capturas de las 3 unidades de ejemplo (milicia, ballesteros, arqueros) en `docs/screenshots/`.

### 10.4 Tiles del campo de batalla táctica (v1.7 — solicitud del usuario)

**Objetivo.** En el **Nivel 3 de batalla** (vista cercana), el terreno se dibuja con mosaicos texturizados realistas estilo "miniatura pintada" (coherente §10.2/§10.3), vista cenital a 45°. El terreno es **tácticamente relevante**: el río es obstáculo natural intransitable que obliga a rodearlo o a forzar el cruce por **puente** (como en GK2); colinas y bosques dan defensa y penalizan caballería; villa/aldea es posición defendible; camino da bonus de movimiento.

**Set ENTREGADO (v1.7 — Kimi, 2026-11-22).** Paquete `Tiles_Batalla_TSB.zip`: 12 tiles 512×512 (originales 1024 en `src/`), hoja de contacto `_hoja_contacto_tiles.png` (nombre único, no colisiona con la de unidades §10.3):
- **Terreno base:** `tile_pastizal`, `tile_pastizal_arbustos`, `tile_pradera` (libres, sin bonus).
- **Río y cruces:** `tile_rio` (intransitable; banda horizontal, el motor rota 90° para el sentido vertical), `tile_puente` (cruce), `tile_puente_villa` (cruce + villa murada defensiva). Los tres comparten la misma geometría de agua/orillas (generados por referencia): el generador de campos sustituye casillas de río por puentes en los puntos de cruce.
- **Elevación y cobertura:** `tile_colina` (coste 2, defensa +1), `tile_bosque` (coste 2, defensa +1, penaliza caballería §6.4), `tile_montana` (intransitable).
- **Asentamiento:** `tile_villa` (defensa +1), `tile_villa_calle`, `tile_camino` (bonus movimiento).
- **Contrato de datos:** tabla `battle_tiles` (JSON) con `tile`, `move_cost`, `defense`, `passable`, flags `cavalry_penalty`/`move_bonus` — valores exactos según balance §6.4 (AG-2), formato en el README del paquete.
- **Composición de campos:** el terreno se deriva de la región del mapa estratégico §10.1 (llanura/bosque/colinas/montaña/costa); el río corta el campo de orilla a orilla con 1-2 puentes; la villa se coloca en el asentamiento sitiado.

**Criterios de aceptación:** campo de batalla N3 renderizado con los 12 tiles sin errores de carga; unidad no puede entrar a río/montaña (test); bonus de colina/camino aplicados en las fórmulas §6.4; capturas de un campo con río+puente+villa y uno de llanura en `docs/screenshots/`; generador de campos deriva el terreno de la región estratégica.

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

### Fase 2 — Profundidad militar (objetivo: 2-3 semanas)
- Mapa táctico Nivel 2 (hex local) y combate cerrado Nivel 3 (órdenes/cartas); espionaje; fin de partidas por extinción dinástica.
- **AG-REA ampliado (§3.2):** informe `docs/rea/gk2_battle_mechanics.md` (mecármicas observadas de batalla Nivel 2/3 + estructura de `SUNIT.DAT`).
- **Módulo Mapa (§10.1):** mapa geográfico profesional con fronteras por año; depreca `map_layout.json`.
- **Módulo Retratos (§10.2):** integrar los 14 retratos finales entregados por Kimi (`assets/art/portraits/`) y referenciarlos en `characters.json`.
- **Aceptación:** Crécy puede jugarse en los 3 niveles con resultados coherentes; pérdida de líder sin herederos termina la partida correctamente; módulos Mapa y Retratos cumplen §10.1/§10.2; informe REA ampliado entregado.

### Fase 3 — Contenido y remaster (objetivo: 2-3 semanas)
- **Integración de sprites Kimi (primero):** AG-5 copia el paquete `Sprites_Unidades_TSB.zip` a `assets/art/sprites/units/` (51 PNG, 17 unidades), reescala a 64×64 / 64×80 / 64×43 (LANCZOS), añade `sprite_sheet` a las 17 unidades en `units.json` (formato §10.3) y valida carga en CI headless. Niveles 2/3 de batalla usan estos sprites con el ciclo de marcha; proyectiles en capa separada con trayectoria balística. **Actualización v1.8 (D-049):** integrar también `Anim_Combate_TSB.zip` (170 PNG de idle/ataque/impacto/muerte) extendiendo `frames` y `anim` según el contrato §10.3; en batalla N3 la unidad en guardia usa `idle`, al atacar `attack` (impacto en `attack_2`), al recibir daño `hit`, al morir `death` con `death_hold`.
- Escenarios 1402 y 1453 completos (datos + eventos: Ankara, locura de Carlos VI, caída de Constantinopla, Dos Rosas); evolución tecnológica por año; arte final (retratos §10.2 de herederos y nuevos escenarios siguiendo la hoja de estilo Kimi, **tiles de batalla §10.4 ya entregados por Kimi — solo integrar**, música CC); balance general.
- **Aceptación:** los 3 escenarios empiezan y llegan a su año final; victoria/derrota según Sección 4.5; partida completa de test automatizada de 10 años sin errores; set de retratos completo y slot de retrato funcional en las 5 ubicaciones §10.2.

### Fase 4 — Profundidad (objetivo: 2-3 semanas)
- **REA preliminar:** `docs/rea/gk2_economy_military_family.md` (≤2 páginas + `notes_economy.md`): estructuras de datos de economía/mercancías/mercaderes y lecciones de UX de los menús Economía/Militar/Familia (sin transcribir texto ni copiar assets; sin `.EXE`).
- **Mercancías y comercio (D-069):** 8-12 bienes en `data/trade_goods.json` + schema/fuentes; producción por terreno/edificios; inventario de facción; comerciantes obligatorios; mercado con precios oferta/demanda; comercio exterior/expedición; consumo (grano/sal) y uso en reclutamiento (armas/caballos); pantalla Mercado.
- **Ejércitos (D-070):** pantalla global con imagen por tipo, conteos, fuerza/moral/experiencia; Reclutar/Entrenar/Disolver; reclutamiento con mercancías.
- **Familia (D-071):** acción «Pasar tiempo con la consorte» (2-3 PG/trimestre; bonus de fertilidad 2-4 trimestres; sin consorte válida → rechazo claro).
- **Manual (D-072):** `docs/MANUAL_DEL_JUGADOR.md` con 10 secciones, accesible desde el juego.
- **Tutorial y dificultad (D-073):** Principiante (Consejero + IA menos agresiva) / Normal; guion en `data/tutorial_script.json`; panel del Consejero con resaltado y salto; estado serializable.
- **Aceptación:** QA C1-C12 del prompt de Fase 4 — REA legal; `trade_goods` validado con fuentes; comercio operativo solo con comerciantes y simulación 10 años sin inflación; pantalla de ejércitos con acciones efectivas; reclutamiento consume mercancías; consorte con bonus/cooldown; Manual completo y accesible; tutorial con guion/resaltes/salto y dificultad; save/load con inventario y tutorial; sin regresión (run_all ≥1742/0, validate 0, editor 0 warnings, F1/F2/F3/MVP/anim/tiles); 1402/1453 intactos y sin arte externo; UX sin botones muertos y capturas 1920×1080.

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

*Fin del GDD v1.3 — The Sovereign's Blood. Documento de trabajo para el equipo de agentes DSH; ante conflicto entre este documento y el código, este documento manda hasta que el Coordinator apruebe un cambio registrado en `docs/decisions.md`. v1.1: entorno Windows real (Sección 3.1), carpeta `agents\`, godot-mcp y rea-mcp. v1.2: ejecutables Godot 4.7.2 verificados, repo GitHub público y protocolo de verificación (Sección 3.2). v1.3: especificación de mapa geográfico profesional (Sección 10.1, módulo Mapa en Fase 2), solicitud del usuario tras comparar con el mapa de GK2. v1.4: especificación de retratos de soberanos (Sección 10.2) — avatar del soberano en mapa y pantallas clave, placeholders heráldicos en Fase 2 y retratos ilustrados en Fase 3. v1.5: REA ampliado a mecármicas de batalla Nivel 2/3 y estructura de sprites (Sección 3.2, autorización del usuario); retratos finales de los 14 soberanos diseñados por Kimi con heráldica real (Sección 10.2); sprites de unidades con armas de época y proyectiles visibles (Sección 10.3). v1.6: sprites de las 17 unidades del dataset entregados por Kimi (contrato de asset, ciclo de marcha de 3 cuadros, proyectiles) con integración AG-5 como primera tarea de Fase 3 (Sección 10.3 y plan de fases). v1.7: tiles del campo de batalla del Nivel 3 entregados por Kimi (Sección 10.4) — 12 mosaicos con río/puente/villa, obstáculos naturales al estilo GK2, contrato battle_tiles y guía de composición de campos. v1.8: cuadros de animación de combate de las 17 unidades entregados por Kimi (Sección 10.3, D-049) — 170 sprites idle/ataque/impacto/muerte con contrato de integración en `units.json` (índices 3-12, `death_hold`); sprites §10.3 y tiles §10.4 verificados APROBADO contra el repo (HEAD 854b5dc). v1.8.1: addendum de animación alineado con la petición formal de AG-5 `kimi_phase3_assets.md` v1.1 — ataque de 6 cuadros para las 7 unidades a distancia/artillería, nomenclatura `impact`, cómputo completo de 184 PNG (`Anim_Combate_Rango_Artilleria_TSB.zip`, 2026-11-23). Fase 3 cerrada por DSH con tag `fase-3` (HEAD ce487179, QA final 7/7 APROBADO CON OBSERVACIONES; arte externo Kimi pendiente de integración).*
