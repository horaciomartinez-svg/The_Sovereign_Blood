# GDD â€” The Sovereign's Blood
## Game Design Document y EspecificaciÃ³n de IngenierÃ­a para Desarrollo Multi-Agente (DSH + DeepSeek-V4.1-Flash + Godot 4)

| Campo | Valor |
|---|---|
| **TÃ­tulo** | The Sovereign's Blood |
| **GÃ©nero** | Gran estrategia por turnos (estilo clÃ¡sico Koei, inspiraciÃ³n estructural: Genghis Khan II, 1992) |
| **Motor** | Godot 4.x (GDScript) |
| **Plataforma** | Desktop: Windows 11 x64 (primario), macOS y Linux (exportables) |
| **Fines** | Proyecto personal, sin fines comerciales. Contenido 100% original (datos, nombres, arte). |
| **Modelo IA** | DeepSeek-V4.1-Flash (deepseek-flash) vÃ­a DeepSeek Harness (DSH) |
| **Workspace DSH** | `C:\Proyectos\TSB` (Creator Mode, Full Access) |
| **Versión del documento** | 1.9.3 |
| **Estado** | Aprobado — v1.9.3: Fase 5B (ataque desde Militar con selección de ejércitos y guerra automática, guardado multislot/autoguardado, solo el propietario decide en su región, expedición de mercaderes clara y tutorial Principiante ampliado); hereda v1.9.2 (legibilidad), v1.9.1/v1.9 (Fase 4), v1.8.x (arte/animación) |

---

## 1. VisiÃ³n del juego

**The Sovereign's Blood** es un juego de gran estrategia por turnos ambientado en Europa, el MediterrÃ¡neo y Oriente PrÃ³ximo entre 1337 y 1453 (la era de la Guerra de los Cien AÃ±os y el ascenso de los estados dinÃ¡sticos). El jugador gobierna una casa reinante: administra economÃ­a, contrata matrimonios dinÃ¡sticos, negocia alianzas y comanda ejÃ©rcitos en tres niveles de resoluciÃ³n de batalla (delegada, mapa tÃ¡ctico de ejÃ©rcitos y combate cerrado unidad contra unidad).

**Pilar de diseÃ±o:** cada mecÃ¡nica del diseÃ±o de referencia (Genghis Khan II) se reimplementa como original â€” sistemas propios, datos propios, arte propio â€” tomando de GK2 solo las *ideas de diseÃ±o* (loops, jerarquÃ­as de batalla, economÃ­a por regiones), documentadas en el Anexo A mediante ingenierÃ­a inversa limitada a los formatos de datos, nunca del cÃ³digo ejecutable.

**FantasÃ­a de jugador:** no eres un ejÃ©rcito; eres una *dinastÃ­a*. Ganas por prestigio, herederos y coronas, no solo por territorio.

### 1.1 Objetivos de diseÃ±o
1. **Fidelidad estructural, originalidad de contenido:** mismas capas de decisiÃ³n que un clÃ¡sico de Koei, mundo y datos 100% nuevos.
2. **Historial jugable:** escenarios con personajes, fronteras y unidades correctos para 1337, 1402 y 1453, validados contra fuentes abiertas (Wikidata/Wikipedia, mapas histÃ³ricos de dominio pÃºblico).
3. **Ãgil:** MVP jugable en semanas, no meses. Batallas delegadas primero (ya es una resoluciÃ³n completa por diseÃ±o).
4. **Mantenible por agentes IA:** cÃ³digo GDScript modular, datos en JSON, contratos de API explÃ­citos entre sistemas (ver SecciÃ³n 8).

### 1.2 Lo que el juego NO es (anti-objetivos)
- No es un wargame hexagonal puro: el mapa tÃ¡ctico es una capa, no el nÃºcleo.
- No es un sandbox: los 3 escenarios son partidas cerradas con condiciones de victoria.
- No usa ningÃºn asset, nombre, dato o texto de Koei/Nintendo/terceros.

---

## 2. Alcance y definiciÃ³n del MVP

### 2.1 Vertical slice mÃ­nimo (Fase 1 â€” aceptaciÃ³n)
- 1 escenario completo (Escenario 1: 1337), 8 facciones jugables de las 14 presentes.
- Loop de turno completo: gobernanza â†’ economÃ­a â†’ familia â†’ diplomacia â†’ militar â†’ IA de rivales â†’ avance de aÃ±o.
- ResoluciÃ³n de batalla **delegada** (automÃ¡tica con informe) â€” suficiente para ganar/perder guerras.
- Guardar/cargar partida (JSON).
- UI funcional: mapa principal de regiones, menÃº de consejo, panel de regiÃ³n, panel de familia, pantalla de diplomacia, informe de batalla, pantalla de fin de aÃ±o.

### 2.2 Fuera de alcance del MVP
- Batalla tÃ¡ctica en mapa y combate cerrado unidad a unidad (Fase 2).
- Escenarios 2 y 3 (Fase 3).
- Arte final, mÃºsica, localizaciÃ³n (Fase 3 usa placeholders mejorados).

---

## 3. Uso limitado de Reverse Engineering (REA) sobre Genghis Khan II

**AutorizaciÃ³n explÃ­cita del usuario:** REA se usa *solo* para obtener informaciÃ³n fundamental de GK2, conforme a lo siguiente:

| Permitido (REA) | Prohibido (REA) |
|---|---|
| Documentar estructura de los archivos de datos `GENDATA*.DAT`, `ZNAME.DAT`, `MAPDATA.DAT`, `SCENARIO.GK2`, `SAVEDATA.GK2` (tipos de campos, tamaÃ±os, orden) | Decompilar/desensamblar `MAIN.EXE`/`OPEN.EXE`/`END.EXE` para reutilizar lÃ³gica |
| Extraer lecciones de diseÃ±o: quÃ© datos necesita un motor de este gÃ©nero (stats de generales, estructura de regiÃ³n, formato de escenario) | Copiar fÃ³rmulas literales del binario o transcribir texto del juego |
| Producir un informe de 1-2 pÃ¡ginas: "lecciones de modelado de datos para un clon estructural" | Producir una especificaciÃ³n de reimplementaciÃ³n 1:1 del juego |

**Entregable REA (Fase 0):** `docs/rea/gk2_data_lessons.md` â€” tabla de equivalencias conceptuales (ej. "GK2 modela generales con nombre/4 stats/lealtad â†’ nuestro modelo de personajes tiene X campos"). Nada mÃ¡s. El equipo de desarrollo **no** lee los binarios ni los datos de Koei; consume solo este informe y el GDD.

**Motivo legal:** uso personal y de estudio; el producto final no contiene material derivado medible de Koei.

### 3.2 REA ampliado â€” batallas Nivel 2/3 y grÃ¡ficos de unidades (autorizaciÃ³n expresa del usuario, Fase 2)

AdemÃ¡s del alcance Â§3, AG-REA (reactivable solo para esto) producirÃ¡ `docs/rea/gk2_battle_mechanics.md` con:

| Permitido (REA ampliado) | Prohibido (sigue en vigor) |
|---|---|
| **ObservaciÃ³n de comportamiento:** documentar jugando en DOSBox las batallas de Nivel 2 (mapa tÃ¡ctico) y Nivel 3 (combate cerrado): orden de fases, movimiento, iniciativa, resoluciÃ³n de choques, efectos de terreno, moral â€” *quÃ© reglas se observan*, con capturas y notas de sesiÃ³n | Decompilar/desensamblar ejecutables para reutilizar cÃ³digo o fÃ³rmulas literales |
| **Estructura de datos grÃ¡ficos:** documentar `SUNIT.DAT` (sprites de unidades: dimensiones, nÃºmero de cuadros, paleta, disposiciÃ³n), `KPAT.DAT`, `GRPDATA.DAT` â€” formato y convenciones de animaciÃ³n como *referencia de legibilidad* | Copiar pixel data, paletas o assets de Koei al juego; transcribir texto del juego |
| **Lecciones de diseÃ±o:** quÃ© hace legible una unidad en batalla (silueta, arma visible, animaciÃ³n de ataque reconocible) | EspecificaciÃ³n de reimplementaciÃ³n 1:1 con valores copiados |

El informe alimenta el diseÃ±o de Â§10.3 (sprites) y el balance Â§6.2/Â§6.3, que se implementan con arte y cÃ³digo 100% originales.

### 3.1 Entorno de ejecuciÃ³n (mÃ¡quina de desarrollo, Windows 11 x64)

| Elemento | Ruta / valor |
|---|---|
| **Workspace DSH** | `C:\Proyectos\TSB` (DSH abierto aquÃ­ en Creator Mode, Full Access) |
| **Referencia GK2** (solo lectura, solo AG-REA) | `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf` |
| **Repo del juego** | `C:\Proyectos\TSB\sovereigns-blood` |
| **Definiciones de agentes** | `C:\Proyectos\TSB\agents\AG-*.md` â€” DSH crea y lee los MD de agentes aquÃ­ |
| **GDD maestro** | `C:\Proyectos\TSB\GDD_The_Sovereign's_Blood.md` |
| **Godot 4 (verificado)** | Editor: `C:\Godot\Godot_v4.7.2-stable_win64.exe` Â· Consola/CI: `C:\Godot\Godot_v4.7.2-stable_win64_console.exe` |
| **MCP disponibles en DSH** | `godot-mcp` y `rea-mcp` ya instalados; mÃ¡s fs/shell nativo del harness |
| **Repo GitHub (pÃºblico)** | `https://github.com/horaciomartinez-svg/The_Sovereign_Blood` â€” remoto `origin`, rama principal `main` |
| **Comando headless (CI/QA)** | `"C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path C:\Proyectos\TSB\sovereigns-blood --script tests/run_all.gd` |

**Reglas del workspace (vinculantes para todos los agentes):**
1. **Nada se crea ni guarda fuera de `C:\Proyectos\TSB`** â€” ni MD de agentes, ni docs, ni cÃ³digo, ni datos.
2. `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf` es **solo lectura** y solo AG-REA puede leerla (resto del equipo: prohibido).
3. AG-2/AG-3 usan `godot-mcp` como vÃ­a principal (crear escenas, ejecutar el editor) y el comando headless como respaldo obligatorio. AG-REA usa `rea-mcp` cuando aplique y fs/shell para inspecciÃ³n hexadecimal de los `.DAT`.
4. Todo documento de trabajo (`docs/STATUS.md`, `docs/decisions.md`, `docs/issues.md`, `docs/rea/â€¦`) vive dentro de `C:\Proyectos\TSB\sovereigns-blood\docs\` (o `C:\Proyectos\TSB\docs\` para lo que sea del workspace, no del juego).

### 3.2 Flujo Git y protocolo de verificaciÃ³n (repo GitHub)

El repo `The_Sovereign_Blood` es la fuente de verdad compartida entre el equipo DSH (que escribe) y Kimi (que verifica). Reglas vinculantes:

1. **Push al cerrar cada mÃ³dulo:** el Coordinator hace `git push origin main` al completar cada mÃ³dulo o hito de una fase, con el `docs/STATUS.md` actualizado en el mismo push. Mensajes de commit con prefijo `[AG-N]` + resumen.
2. **Etiquetas por fase:** tag `fase-0`, `fase-1`, `fase-2`, `fase-3` en el commit donde se cumplen los criterios de aceptaciÃ³n de la SecciÃ³n 12.
3. **Nada de force-push ni reescritura de historia** en `main`; si algo falla, commit revertido encima.
4. **El usuario no toca el cÃ³digo** salvo peticiÃ³n expresa; su rol es revisar `STATUS.md` y dar luz verde de fase.
5. **Protocolo de verificaciÃ³n Kimi (al final de cada mÃ³dulo):** Kimi revisa el repo remoto y verifica contra este GDD:
   - Â¿Los entregables del mÃ³dulo existen y cumplen los criterios de aceptaciÃ³n de la fase?
   - Â¿`validate_data.gd` y los tests headless pasan (logs adjuntos en `docs/STATUS.md`)?
   - Â¿Los contratos de la SecciÃ³n 8.2 se respetan (la UI no muta estado)?
   - Â¿Cumplimiento legal: ningÃºn dato/texto/asset de Koei ni de terceros?
   - Resultado: **APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO** con lista de hallazgos, que el Coordinator corrige antes de continuar.
6. **El GDD vive tambiÃ©n en el repo** (raÃ­z). Cualquier cambio de alcance aprobado se versiona ahÃ­ (commit `[GDD]`).

---

## 4. Mundo, Ã©poca y escenarios

### 4.1 Marco histÃ³rico (fuente de verdad para datos)
PerÃ­odo: 1337â€“1453. Mundo jugable: Europa occidental y central, penÃ­nsula ibÃ©rica, Italia, Balcanes, Anatolia, Levante y Norte de Ãfrica costero. Fuente primaria de datos: **Wikidata** (gobernantes, fechas, casas dinÃ¡sticas), **Wikipedia** (eventos, batallas), catÃ¡logos de mapas histÃ³ricos de dominio pÃºblico (bibliotecas digitales) para fronteras aproximadas por aÃ±o.

### 4.2 Escenario 1 â€” "Dos Coronas" (aÃ±o 1337)
**Tema:** estallido de la Guerra de los Cien AÃ±os. Eduardo III de Inglaterra reivindica la corona francesa por lÃ­nea materna; los Valois resisten.

| FacciÃ³n | Gobernante (1337) | Casa | Capital | Rasgo distintivo |
|---|---|---|---|---|
| Inglaterra | Eduardo III | Plantagenet | Londres | Arqueros largos, flota |
| Francia | Felipe VI | Valois | ParÃ­s | CaballerÃ­a pesada, poblaciÃ³n |
| Sacro Imperio | Luis IV | Wittelsbach | Praga | Electores, mercenarios |
| Bohemia | Juan de Luxemburgo | Luxemburgo | Praga | CaballerÃ­a, oro de KutnÃ¡ Hora |
| HungrÃ­a | Carlos Roberto | Anjou | Buda | Frontera antiturca |
| Castilla | Alfonso XI | TrastÃ¡mara/BorgoÃ±a | Burgos | Jinetes, flota atlÃ¡ntica |
| AragÃ³n | Pedro IV | Barcelona-AragÃ³n | Barcelona | Mercenarios almogÃ¡vares, MediterrÃ¡neo |
| Polonia | Casimiro III | Piast | Cracovia | ExpansiÃ³n, caballerÃ­a ligera |
| Escocia | David II | Bruce | Edimburgo | Schiltrons, guerra vs Inglaterra |
| Papado (AviÃ±Ã³n) | Benedicto XII | â€” | AviÃ±Ã³n | Influencia, tesoro |
| Granada | Yusuf I | NazarÃ­ | Granada | Fortalezas, tributo |
| Sultanato Mameluco | An-Nasir Muhammad | Bahri | El Cairo | Riqueza, mamelucos |
| Horda de Oro | Ã–zbeg | Borjigin | Sarai | CaballerÃ­a de estepa |
| Bizancio | AndrÃ³nico III | PaleÃ³logo | Constantinopla | Supervivencia, mercenarios |

### 4.3 Escenario 2 â€” "El Choque de Imperios" (aÃ±o 1402)
**Tema:** tras la batalla de Ankara, TamerlÃ¡n desplaza al sultÃ¡n otomano; Occidente fragmentado (locura de Carlos VI, guerras civiles italianas).

| FacciÃ³n | Gobernante (1402) | Nota de diseÃ±o |
|---|---|---|
| Imperio de TamerlÃ¡n | TamerlÃ¡n | EjÃ©rcito de Ã©lite temprano, decadencia tras 1405 |
| Otomanos (Interregno) | Mehmed I vs. prÃ­ncipes rivales | FacciÃ³n frÃ¡gil con gran potencial |
| Inglaterra | Enrique IV | Guerra civil reciente, recursos escasos |
| Francia | Carlos VI | FacciÃ³n inestable: eventos de locura regia |
| HungrÃ­a / Sacro Imperio | Segismundo | Corona dual, presiÃ³n otomana |
| Venecia | Dogo Michele Steno | RepÃºblicas: comercio naval, sin dinastÃ­a (reglas especiales) |
| GÃ©nova | â€” | Mar y mercenarios |
| Florencia | â€” | Banca, influencia |
| MilÃ¡n | Gian Galeazzo Visconti (muere 1402) | Evento de sucesiÃ³n inmediato |
| Castilla | Enrique III | Menor de edad de su hijo â†’ regencia |
| AragÃ³n | Fernando I (regente) | UniÃ³n dinÃ¡stica con Castilla prÃ³xima |
| Mamelucos | Al-Faray | Estable, rico |
| Bizancio | Manuel II | Constantino XI como heredero |

### 4.4 Escenario 3 â€” "El Ocaso y el Alba" (aÃ±o 1453)
**Tema:** caÃ­da de Constantinopla, final de la Guerra de los Cien AÃ±os, Renacimiento, preludio de las guerras dinÃ¡sticas inglesas.

| FacciÃ³n | Gobernante (1453) | Nota de diseÃ±o |
|---|---|---|
| Otomanos | Mehmed II | Bombardas, jenÃ­zaros; objetivo: Constantinopla |
| Bizancio | Constantino XI | Partida de supervivencia |
| Inglaterra | Enrique VI | Inestable; evento de Guerra de las Dos Rosas |
| Francia | Carlos VII | CompaÃ±Ã­as libres, artillerÃ­a real |
| BorgoÃ±a | Felipe el Bueno | Riqueza, caballerÃ­a; decisiÃ³n histÃ³rica 1435 |
| AragÃ³n/NÃ¡poles | Alfonso V | Corona dual mediterrÃ¡nea |
| Sacro Imperio | Federico III | Pasivo pero estable |
| HungrÃ­a | MatÃ­as Corvino (desde 1458) / regencia previa | El Hunyadi: hÃ©roe militar |
| Escocia | Jacobo II | Oportunista |
| Castilla | Enrique IV | Tensiones nobiliarias |
| Venecia / GÃ©nova | â€” | Colonias y mar |
| Papado | NicolÃ¡s V | Patrono del Renacimiento |
| Mamelucos | Qaitbay (desde 1468; usar regente previo) | Estable |
| Valaquia | Vlad III (DrÃ¡cula) | HÃ©roe temÃ¡tico, difÃ­cil |

### 4.5 Condiciones de victoria (todas las escenarios)
1. **Coronas:** acumular N coronas sostenidas (propia + reclamadas) segÃºn escenario.
2. **Prestigio dinÃ¡stico:** alcanzar umbral de Prestigio Real mantenido 10 aÃ±os.
3. **Supervivencia (facciones menores):** sobrevivir hasta fin de escenario (1453/1460/1480 segÃºn caso) con umbral mÃ­nimo de territorio.
4. **Conquista total:** controlar â‰¥70% de regiones del mapa.

**Derrota:** extinciÃ³n de la casa gobernante (sin herederos vivos) o pÃ©rdida de la Ãºltima regiÃ³n.

---

## 5. MecÃ¡nicas nÃºcleo

### 5.1 Estructura del turno y recurso de acciÃ³n
El turno = **trimestre** (4 turnos/aÃ±o). Cada facciÃ³n dispone por trimestre de **Puntos de Gobernanza (PG)**, equivalente funcional al recurso de acciÃ³n del diseÃ±o de referencia:

```
PG_trimestre = 30 + (Prestigio_Real / 10) + bonus_lÃ­der - penalizaciÃ³n_descontento
```

Cada orden (mover ejÃ©rcito, negociar, edificar, intervenciÃ³n familiar, ceremonia) cuesta PG. Las Ã³rdenes no gastadas se pierden. La interfaz muestra PG restantes en todo momento (barra superior, estilo clÃ¡sico).

### 5.2 EconomÃ­a por regiones
El mapa estÃ¡ dividido en **regiones** (provincias), cada una con: poblaciÃ³n, riqueza base, terreno (llanura/bosque/montaÃ±a/costa/ciudad), edificios y asignaciÃ³n de mano de obra.

```
PoblaciÃ³n trabajadora = PoblaciÃ³n_total Ã— (1 - tasa_reclutamiento)
Manos de obra asignables a: Granjeros / Artesanos / Comerciantes / Reclutas (pool)
ProducciÃ³n_alimento  = Granjeros Ã— factor_terreno Ã— clima_trimestre
ProducciÃ³n_bienes    = Artesanos Ã— talleres Ã— tecnologÃ­a
Oro_comercio         = Comerciantes Ã— rutas_abiertas Ã— (1 + prosperidad/100)
Tesoro               += impuestos(oro_total Ã— tasa) + comercio âˆ’ mantenimiento
```

**Apoyo popular (0-100):** sube con alimentos sobrantes, baja con impuestos altos y reclutamiento forzoso. Apoyo < 20 â†’ riesgo de revuelta (evento). Apoyo > 80 â†’ bonus de crecimiento poblacional.

**Cosecha anual** (turno 1): clima aleatorio sesgado por latitud y eventos (pequeÃ±a Edad de Hielo: inviernos duros probables hacia 1400+).

**Edificios** (costo PG + oro, cola por regiÃ³n): Graneros, Talleres, Mercados, Murallas, Castillos, Astilleros, Universidad (Fase 3).

**MercancÃ­as y comercio (v1.9 â€” D-069):** cada facciÃ³n mantiene un **inventario de mercancÃ­as** agregado de sus regiones. Hay 8-12 bienes (`data/trade_goods.json`, schema + fuentes): especias, pieles, lana, vino, sal, grano, armas, caballos, hierro y madera. Cada bien define `base_price`, `produced_by` (terreno/edificio: costaâ†’sal; llanura extensa/pastosâ†’caballos/pieles; tallerâ†’armas; bosqueâ†’madera; etc.) y `used_by` (reclutamiento/consumo). La producciÃ³n llega al inventario de facciÃ³n cada trimestre.
- **Comerciantes obligatorios:** el volumen de compra/venta de una facciÃ³n depende de los **Comerciantes** asignados (clase trabajadora de Â§5.2). Sin comerciantes asignados no se puede operar el mercado; mÃ¡s comerciantes = mayor volumen mÃ¡ximo por trimestre.
- **Mercado:** comprar/vender al precio `base_price Ã— factor_oferta_demanda`, donde el factor se deriva del inventario local/regional y de eventos (determinista con el RNG de la partida). Comercio exterior con facciones con pacto comercial, o mediante **expediciÃ³n de mercaderes** (2 PG) que retorna tras N trimestres.
- **Riqueza con propÃ³sito:** el oro del comercio financia reclutamiento y entrenamiento (Â§5.5); el comercio es significativo pero **menor que la economÃ­a base**, sin inflaciÃ³n desbocada (mismas mÃ©tricas de D-068).
- **Consumo:** grano/sal sostienen el apoyo poblacional; armas y caballos se consumen al reclutar las unidades que los requieren (Â§6.4).

### 5.3 DinastÃ­a y familia (eje central)
Cada facciÃ³n tiene un Ã¡rbol familiar: gobernante, consorte, hijos (edad, sexo, stats), hermanos, tÃ­os (candidatos alternos).

**Atributos de personaje (1-100):** Mando, Astucia, Carisma, Lealtad, EducaciÃ³n. Los hijos ganan stats con la educaciÃ³n (asignar tutor: PG/turno).

**Matrimonios:** casar hijos/os genera alianzas y *pretensiones dinÃ¡sticas*. Si un cÃ³nyuge tiene derecho a una corona extranjera, se desbloquea el Casus Belli "ReclamaciÃ³n". Matrimonio de Estado con facciÃ³n menor absorbe sus regiones por sucesiÃ³n pacÃ­fica (si hay heredero comÃºn).

**SucesiÃ³n:** al morir el gobernante, el heredero legal sube al trono. Si el heredero es menor de 14 â†’ regencia (astucia reducida, riesgo de usurpaciÃ³n por parientes). Si no hay heredero â†’ **crisis sucesoria**: facciÃ³n cae a interregno 2 aÃ±os; los parientes de otras casas pueden declarar guerra por la corona. Tercera facciÃ³n extinciÃ³n â†’ derrota.

**Eventos vitales trimestrales (probabilidades):** nacimiento (base 12% por consorte fÃ©rtil < 40 aÃ±os), enfermedad (base 2% por personaje > 50, +epidemias: Peste Negra evento global 1347-1353), muerte en batalla (si lidera un ejÃ©rcito derrotado: 15%).

**AcciÃ³n Â«Pasar tiempo con la consorteÂ» (v1.9 â€” D-071):** en el Ã¡rbol familiar, una vez por trimestre y con coste de **2-3 PG**, el gobernante pasa tiempo con su consorte: otorga un **bonus de fertilidad** (probabilidad de nacimiento aumentada durante los **siguientes 2-4 trimestres**) y un pequeÃ±o bonus de prestigio/relaciÃ³n. Sin consorte vÃ¡lida (viuda/enferma/ausente) la acciÃ³n se rechaza con mensaje claro; no deja estados rotos. La educaciÃ³n automÃ¡tica de menores (D-020) se mantiene y se muestra en la ficha del hijo.

### 5.4 Diplomacia
RelaciÃ³n bilateral âˆ’100..100, derivada de: casus belli activos, tratados, religion, fronteras, personalidad del lÃ­der.

Acciones (todas cuestan PG; Ã©xito = tirada modificada por Astucia del enviado y relaciÃ³n):

| AcciÃ³n | Coste PG | Efecto |
|---|---|---|
| Propuesta de alianza | 8 | Defensa mutua 3 aÃ±os |
| Matrimonio dinÃ¡stico | 10 | +relaciÃ³n, posible pretensiÃ³n |
| Pacto comercial | 6 | +25% comercio bilateral |
| Exigir tributo | 5 | oro; guerra si rechazo y relaciÃ³n baja |
| Ofrecer tributo | 3 | +relaciÃ³n |
| Declarar guerra | 0 | requiere Casus Belli o âˆ’prestigio |
| Proponer paz | 4 | tÃ©rminos: oro/regiones/casamiento |
| Enviar espÃ­a (Fase 2) | 6 | revelar ejÃ©rcitos/tesoro/regente |

**PuntuaciÃ³n de IA rival (ver 5.7)** decida aceptaciÃ³n.

### 5.5 Militar (visiÃ³n general; detalle en SecciÃ³n 6)
EjÃ©rcitos = grupos de unidades dentro de una regiÃ³n; lÃ­mite por regiÃ³n segÃºn edificios. Movimiento por adyacencia regional (1 PG por ejÃ©rcito movido + coste de terreno). **Reclutamiento con mercancÃ­as (v1.9 â€” D-070):** ademÃ¡s de oro y pool regional, ciertas unidades consumen mercancÃ­as del inventario de facciÃ³n â€” caballerÃ­a exige **caballos**; infanterÃ­a pesada/hombres de armas exigen **armas** (tabla Â§6.4 ampliada). La **pantalla de ejÃ©rcitos** muestra por tipo de unidad su imagen (sprite `march_1` existente), nÃºmero, fuerza y moral/experiencia medias, y permite **Reclutar / Entrenar** (sube experiencia; oro + 1 PG) / **Disolver** (libera reclutas y devuelve parte del oro) desde una vista global de facciÃ³n.

### 5.6 Legibilidad y ayuda (v1.9.2 — Fase 5A)
El juego **narra** el estado y acompaña al jugador sin alterar la simulación:
- **Estaciones y HUD:** el trimestre se muestra como estación (Primavera, Verano, Otoño, Invierno) y año en el HUD persistente; un tinte de mapa sutil por estación se genera por código (sin assets) y la estación se deriva del turno (D-079).
- **Boletín y Crónica:** al cerrar cada trimestre, un boletín de 4-6 líneas resume ingresos/gastos, apoyo, acciones usadas, nacimientos/muertes, mercaderes y eventos; al cerrar el año, la Crónica presenta el desglose económico, eventos y ranking de prestigio. Las entradas se guardan en `state.chronicle` (persistido en save/load, con defaults para partidas antiguas) y hay pestaña «Crónica» (D-080).
- **Confirmar órdenes:** antes de resolver el turno se muestra «Tus órdenes este trimestre» con las acciones registradas (`turn_actions`, estado transitorio de presentación), botones Corregir/Confirmar y aviso de acciones libres (reclutar/entrenar/disolver, trabajadores, mercado) (D-081).
- **Consejero y ayuda contextual:** el Consejero puede activarse en cualquier dificultad; en el Mercado da un consejo determinista (mejor margen de venta/compra y retorno de expediciones); cada pantalla §9 tiene un botón «?» con 3-5 líneas de ayuda propias desde datos (D-082).
- **Panel de unidad N2/N3:** cada unidad muestra hombres, armamento, apoyo, moral y entrenamiento; el comandante muestra estado sano/herido y su stat de Mando. Solo lectura (D-083).

### 5.7 IA de facciones rivales

Motor por **utilidad esperada**, modular y reemplazable (un solo script `ai_brain.gd` por facciÃ³n con perfiles):

```
Utilidad(acciÃ³n) = Î£ peso_perfil Ã— (ganancia_oro, ganancia_territorio, seguridad_dinÃ¡stica, prestigio) âˆ’ coste_PG âˆ’ riesgo_estimado
Perfiles: Agresor / Comerciante / DinÃ¡stico / Superviviente / Equilibrado
```

DecisiÃ³n trimestral en 3 pasos: (1) evaluar amenazas (facciones mÃ¡s fuertes adyacentes), (2) priorizar PG (economÃ­a si pobre, ejÃ©rcito si amenazado, familia si heredero ausente), (3) ejecutar 2-4 Ã³rdenes por turno. Toda la IA se ejecuta tras el jugador, en <2 s para 14 facciones (presupuesto de rendimiento).

### 5.8 Guerra, guardado y control del jugador (v1.9.3 — Fase 5B)
- **Atacar (D-084):** Militar → Atacar abre objetivo adyacente y **selección múltiple de ejércitos**; resumen de PG; si no hay guerra se **declara automáticamente** al confirmar (con casus belli/pérdida de prestigio vigente), si ya hay guerra solo ataca; batalla delegada con informe. Aliados bloqueados con aviso.
- **Guardado (D-085):** botón Guardar/Cargar visible, **3 ranuras manuales + autoguardado** con metadatos; autoguardado después de cada turno resuelto, sin sobrescribir las manuales; save_version 1.
- **Propiedad (D-086):** solo el propietario puede reasignar trabajadores de una región; en regiones ajenas los controles están deshabilitados con aviso (`not_owner` en motor).
- **Expedición (D-087):** sección clara en Mercado (bien, cantidad, 2 PG, retorno a 2 trimestres, activas) y paso de tutorial.
- **Tutorial (D-088):** Principiante incluye atacar, expedición, guardado y límites de propiedad; condiciones `attack_launched`/`expedition_sent`; Manual actualizado (D-089).

---

## 6. Batallas â€” resoluciÃ³n en tres niveles

Como en el diseÃ±o de referencia, al entrar en combate el jugador elige el nivel de control:

### 6.1 Nivel 1 â€” Combate delegado (MVP)
Se selecciona general y postura (Ofensiva / Equilibrada / Defensiva) y se resuelve automÃ¡ticamente:

```
Poder_ejÃ©rcito = Î£ (fuerza_unidad Ã— morale Ã— veterania Ã— bono_terreno Ã— bono_comandante)
Comandante: bono = 1 + (Mando âˆ’ 50)/200   â†’ rango 0.75 â€“ 1.25
Morale = 0.5 + apoyo/200  (rango 0.5-1.0, modificado por racha y hambre)
Terreno: defensor segÃºn terreno_regiÃ³n (llanura 1.0 / bosque 1.15 / ciudad 1.4 / rÃ­o+0.2)
Tirada: factor aleatorio gaussiano Î¼=1, Ïƒ=0.15

Batalla en hasta 5 asaltos:
  daÃ±o_asalto_a = Poder_a Ã— aleatorio Ã— coef_asalto(postura_a)
  unidades pierden efectivos proporcionalmente; ejÃ©rcito con <25% o moral rota retira
  lÃ­der derrotado en retirada: 15% muerte/cautiverio
```

Salida: informe con bajas por bando, unidades perdidas, capturas, oro/regiÃ³n conquistada si captura de capital regional.

### 6.2 Nivel 2 â€” Mapa tÃ¡ctico de ejÃ©rcitos (Fase 2)
Mapa hexagonal local de la regiÃ³n (rÃ­o, colinas, ciudad). Las legiones se mueven por turnos de iniciativa; choque â†’ se resuelve ese hex en Nivel 3 o por autocomputo local. Puntos de victoria por objetivos (puente, ciudad, retaguardia).

### 6.3 Nivel 3 â€” Combate cerrado unidad contra unidad (Fase 2)
Como el nivel 2 pero con grupos unidad-a-unidad y cartas de orden: Carga, Disparo, FormaciÃ³n (piqueros), Finta, Retirada ordenada. El comandante con mayor Mando roba +1 orden/turno.

### 6.4 Tabla de unidades y evoluciÃ³n tecnolÃ³gica

| Unidad | Ã‰poca | Tipo | Fuerza | Mov. | Coste | Notas |
|---|---|---|---|---|---|---|
| Milicia de lanza | I-III | Inf. | 4 | 2 | bajo | Leva masiva |
| Piquero escocÃ©s (schiltron) | I-II | Inf. | 7 | 1 | bajo | Anti-caballerÃ­a Ã—1.5 |
| Ballesteros | I-III | Dis. | 8 | 2 | medio | GÃ©nova/Italia; dispara antes del choque |
| Arquero largo | I-III | Dis. | 9 | 2 | medio | Inglaterra/Gales; lluvia de flechas |
| Sargentos a caballo | I-II | Cab. | 9 | 4 | medio | CaballerÃ­a media |
| Hombres de armas | I-III | Cab. | 12 | 3 | alto | NÃºcleo feudal |
| Jinete (cab. ligera) | I-III | Cab.L | 7 | 5 | bajo | Castilla, hÃºngaros; hostigamiento |
| Cab. de estepa | I-II | Cab.L | 8 | 6 | medio | Horda de Oro; treta |
| AlmogÃ¡var | I | Inf. | 8 | 3 | medio | AragÃ³n; terreno difÃ­cil Ã—1.3 |
| Mameluco | I-III | Cab. | 12 | 4 | alto | El Cairo; disciplina (morale+0.1) |
| Pikero suizo/alemÃ¡n | II-III | Inf. | 11 | 2 | medio | Desde ~1386; anti-carga Ã—1.5 |
| Hombre de armas a pie | II-III | Inf. | 11 | 2 | alto | Moda pos-CrÃ©cy |
| Bombarda | II-III | Art. | 16 | 1 | muy alto | Asedio; ruido (morale enemigo âˆ’0.1 asalto 1) |
| Arcabucero | III | Dis. | 12 | 2 | alto | Desde ~1440; penetra armadura |
| Carro bÃ©lico hÃºsita | III | Esp. | 9 | 2 | medio | Defensa mÃ³vil Ã—1.3 |
| JenÃ­zaro | III | Inf. | 13 | 3 | alto | Otomanos; reclutamiento devshirme (pool especial) |
| Caballeros teutÃ³nicos | I-II | Cab. | 13 | 3 | alto | Balcano/BÃ¡ltico; cruzada |

**Reglas de interacciÃ³n:** Disparo inflige daÃ±o previo al asalto; CaballerÃ­a pesada Ã—1.4 vs InfanterÃ­a en llanura pero Ã—0.6 vs Schiltron/Piqueros; ArtillerÃ­a solo efectiva en asedio; Cab. ligera puede retirarse sin asalto final (finta).

**Reclutamiento con mercancÃ­as y entrenamiento (v1.9 â€” D-070):** ademÃ¡s de oro y pool regional, el reclutamiento consume mercancÃ­as del inventario de facciÃ³n: unidades de **caballerÃ­a** (sargentos a caballo, hombres de armas, caballerÃ­a ligera, caballerÃ­a de estepa, mamelucos, caballeros teutÃ³nicos) requieren **caballos**; **infanterÃ­a pesada/hombres de armas a pie** requieren **armas**. La tabla concreta de coste por unidad queda en `data/units.json` (`recruit_goods`) y se valida con el pipeline. **Entrenar** una unidad sube su experiencia/media (coste de oro + 1 PG) desde la pantalla de ejÃ©rcitos; **Disolver** libera el pool de reclutas y devuelve parte del oro. La IA usa las mismas reglas (sin trampas de recursos).

---

## 7. Arquitectura de datos

Todo contenido vive en JSON en `res://data/` (versionado en Git). NingÃºn dato estÃ¡ hardcodeado en GDScript. ValidaciÃ³n: `data/schema/*.json` (JSON Schema draft 2020-12) + script `tools/validate_data.gd` ejecutado en CI y al arrancar en modo debug.

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
  "name": "NormandÃ­a",
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
Snapshot serializable de todos los sistemas: `turn`, `year`, `quarter`, `factions[]` (tesoro, PG, relaciones, Ã¡rboles familiares vivos), `regions[]` (dueÃ±o, asignaciÃ³n, edificios, pool), `armies[]` (composiciÃ³n, moral, posiciÃ³n), `event_log`. VersiÃ³n con `save_version` para migraciones.

### 7.8 Fuentes abiertas de datos (para el agente Historia)
- **Wikidata SPARQL:** gobernantes por paÃ­s/aÃ±o, fechas de nacimiento/muerte, casas dinÃ¡sticas (P39 cargo, P6 jefe de gobierno, P53 familia).
- **Wikipedia (EN/ES/FR):** batallas y sus fechas para eventos; unidades por naciÃ³n.
- **Mapas histÃ³ricos de dominio pÃºblico** (Perry-CastaÃ±eda, bibliotecas digitales europeas): fronteras aproximadas por aÃ±o â†’ vectorizar a mano sobre plantilla.
- Regla de oro del agente Historia: **toda cifra histÃ³rica citada en datos debe tener `source` con URL** en `data/sources.md`.

---

## 8. Arquitectura de software (Godot 4)

### 8.1 Estructura de proyecto

```
sovereigns-blood/
â”œâ”€â”€ project.godot
â”œâ”€â”€ scenes/
â”‚   â”œâ”€â”€ main/main_menu.tscn
â”‚   â”œâ”€â”€ main/scenario_select.tscn
â”‚   â”œâ”€â”€ map/world_map.tscn          # mapa principal por regiones
â”‚   â”œâ”€â”€ map/region_node.tscn        # nodo clickeable de regiÃ³n
â”‚   â”œâ”€â”€ council/council_menu.tscn   # menÃº de Ã³rdenes estilo clÃ¡sico
â”‚   â”œâ”€â”€ family/family_tree.tscn
â”‚   â”œâ”€â”€ diplomacy/diplomacy_screen.tscn
â”‚   â”œâ”€â”€ battle/battle_report.tscn   # Nivel 1
â”‚   â”œâ”€â”€ battle/tactical_map.tscn    # Nivel 2 (Fase 2)
â”‚   â”œâ”€â”€ battle/close_combat.tscn    # Nivel 3 (Fase 2)
â”‚   â””â”€â”€ ui/components/              # barras, tooltips, cuadros de diÃ¡logo
â”œâ”€â”€ scripts/
â”‚   â”œâ”€â”€ autoload/
â”‚   â”‚   â”œâ”€â”€ game_state.gd          # estado global + save/load
â”‚   â”‚   â”œâ”€â”€ data_loader.gd         # JSON â†’ objetos tipados
â”‚   â”‚   â”œâ”€â”€ turn_manager.gd        # secuencia de turno, PG
â”‚   â”‚   â”œâ”€â”€ economy_system.gd
â”‚   â”‚   â”œâ”€â”€ dynasty_system.gd      # nacimientos, muertes, sucesiÃ³n
â”‚   â”‚   â”œâ”€â”€ diplomacy_system.gd
â”‚   â”‚   â”œâ”€â”€ military_system.gd     # ejÃ©rcitos, movimiento, reclutamiento
â”‚   â”‚   â”œâ”€â”€ battle_manager.gd      # 3 niveles de resoluciÃ³n
â”‚   â”‚   â”œâ”€â”€ ai_manager.gd          # orquesta facciones IA
â”‚   â”‚   â”œâ”€â”€ event_bus.gd           # seÃ±ales globales tipadas
â”‚   â”‚   â””â”€â”€ audio_manager.gd
â”‚   â”œâ”€â”€ ai/
â”‚   â”‚   â”œâ”€â”€ ai_brain.gd            # interfaz; un nodo por facciÃ³n IA
â”‚   â”‚   â””â”€â”€ profiles/*.gd          # agresor, comerciante, dinÃ¡stico...
â”‚   â”œâ”€â”€ model/                     # dataclasses en GDScript
â”‚   â”‚   â”œâ”€â”€ character.gd
â”‚   â”‚   â”œâ”€â”€ region_state.gd
â”‚   â”‚   â”œâ”€â”€ army.gd
â”‚   â”‚   â””â”€â”€ unit_instance.gd
â”‚   â””â”€â”€ utils/rng.gd               # RNG sembrado (reproducibilidad de tests)
â”œâ”€â”€ data/                          # ver SecciÃ³n 7
â”œâ”€â”€ assets/art/, assets/audio/     # placeholders hasta Fase 3
â”œâ”€â”€ tests/                         # GUT (Godot Unit Test)
â””â”€â”€ tools/validate_data.gd
```

### 8.2 Contratos entre sistemas (API pÃºblica mÃ­nima)

```gdscript
# turn_manager.gd â€” el orquestador del turno; la UI solo habla con Ã©l
signal turn_started(quarter: int, year: int)
signal pg_changed(remaining: int)
func begin_turn(faction_id: String) -> void
func end_turn() -> void            # ejecuta IA de rivales + fin de aÃ±o si toca

# economy_system.gd
func recalculate(faction_id: String) -> void
func allocate(region_id: String, worker_class: String, amount: int) -> bool  # valida PG

# dynasty_system.gd
func marry(character_id: String, target_character_id: String) -> Dictionary  # {ok, alliance?, claim?}
func advance_year() -> Array[Dictionary]   # eventos vitales generados

# diplomacy_system.gd
func propose(actor: String, target: String, action: Dictionary) -> Dictionary

# battle_manager.gd â€” fachada Ãºnica para los 3 niveles
func resolve_delegated(attacker_army: Army, defender_army: Army, region: RegionState, stance: int) -> BattleReport
func launch_tactical(attacker_army: Army, defender_army: Army, region: RegionState) -> Node  # (Fase 2)
```

Regla de oro para los agentes programadores: **las escenas de UI nunca mutan estado directamente**; llaman a los sistemas vÃ­a `EventBus` o autoloads. Esto mantiene el cÃ³digo reemplazable por IA sin efectos colaterales.

### 8.3 Patrones
- **Autoload + seÃ±ales tipadas** para desacoplar; nada de singletons "a lo bruto".
- **Estado puro serializable:** todos los datos de partida en diccionarios/arrays listos para `to_json` (guardado y tests deterministas).
- **RNG centralizado** (`utils/rng.gd`) con semilla guardada en partida â†’ replays y tests reproducibles.
- **Modo headless** (`godot --headless`) para CI de tests; el agente QA ejecuta `godot --headless --script tests/run_all.gd`.

### 8.4 Guardado
`user://saves/<slot>.json` con `save_version: 1`. BotÃ³n guardar/cargar en menÃº principal y esc. Autoguardado cada fin de aÃ±o en `user://saves/autosave.json`.

---

## 9. UI/UX â€” pantallas y flujo

1. **MenÃº principal:** Nuevo juego / Cargar / Opciones / Salir. Arte placeholder (fondo mapa viejo estilizado).
2. **SelecciÃ³n de escenario:** 3 tarjetas con aÃ±o, mapa miniatura y lista de facciones jugables.
3. **Mapa principal:** mapa geogrÃ¡fico profesional de Europa, Norte de Ãfrica y Oriente PrÃ³ximo (especificaciÃ³n completa en Â§10.1): terreno de Ã©poca estilizado, fronteras de los reinos por aÃ±o, regiones clickeables que resaltan al pasar el cursor, iconos de ejÃ©rcito (bandera + nÃºmero), panel lateral con resumen (aÃ±o/trimestre, PG, tesoro, alertas) y **retrato del soberano jugador** (Â§10.2) en la esquina del mapa, al estilo de la referencia. Zoom/pan con cÃ¡mara 2D. Click = panel de regiÃ³n (asignar mano de obra, edificios, reclutar).
4. **MenÃº de Consejo (barra lateral clÃ¡sica):** Ã³rdenes con coste PG visible: Consejo, Familia, Diplomacia, Militar, EconomÃ­a, Terminar turno. Estilo visual: pergaminos/azul profundo/dorado, tipografÃ­a serif legible (Cinzel tÃ­tulos, EB Garamond cuerpo â€” Google Fonts, OFL).
5. **Ãrbol familiar:** diagrama con retratos placeholder, lÃ­neas de parentesco, estado (edad, heredero â˜…, enfermo, cautivo). Acciones: educar, concertar matrimonio, nombrar regente.
6. **Diplomacia:** lista de facciones con barras de relaciÃ³n; modales de propuesta con Ã©xito estimado.
7. **Informe de batalla (Nivel 1):** resumen por asaltos, bajas, capturas, botÃ­n; botones "Rechazar/revisar" no aplican (no hay undo â€” decisiÃ³n final, como el diseÃ±o de referencia).
8. **Fin de aÃ±o:** informe anual (cosecha, nacimientos, muertes, eventos, cambios de frontera) con avance a siguiente aÃ±o.
9. **Pantalla de victoria/derrota** con estadÃ­sticas de la partida.
10. **Mercado / comercio (v1.9 â€” D-069):** inventario de facciÃ³n por mercancÃ­a, precios y factor oferta/demanda, comerciantes disponibles, comprar/vender y panel de comercio exterior (pactos/expediciÃ³n), con feedback de oro y volumen.
11. **EjÃ©rcitos (v1.9 â€” D-070):** rejilla global por tipo de unidad con sprite `march_1`, nÃºmero, fuerza y moral/experiencia medias; acciones Reclutar (oro+pool+mercancÃ­as), Entrenar (oro+1 PG) y Disolver con confirmaciÃ³n.
12. **Manual del Jugador (v1.9 â€” D-072):** botÃ³n Â«ManualÂ» en el menÃº principal (abre `docs/MANUAL_DEL_JUGADOR.md`) y entrada Â«AyudaÂ» en el menÃº de consejo con resumen rÃ¡pido.
13. **Dificultad y tutorial (v1.9 â€” D-073):** selecciÃ³n Principiante/Normal al iniciar; en Principiante, panel del **Consejero** con guion del primer aÃ±o, texto breve, resaltado de UI y opciÃ³n de saltar; guion en `data/tutorial_script.json`, estado serializable. Normal = sin Consejero y IA algo mÃ¡s agresiva.

**MVP de interacciÃ³n:** todo con mouse; atajos opcionales (Enter = terminar turno). ResoluciÃ³n objetivo 1920Ã—1080, escalable.

14. **Estaciones + HUD (v1.9.2 — D-079):** HUD «{Estación} {Año} — Tesoro/PG» y tinte de mapa por estación generado por código.
15. **Boletín trimestral (v1.9.2 — D-080):** modal de cierre de trimestre con resumen informativo y «Continuar».
16. **Crónica anual + histórico (v1.9.2 — D-080):** pantalla de cierre de año con desglose/ranking y pestaña «Crónica» consultable; sus entradas persisten en `state.chronicle`.
17. **Confirmación de órdenes (v1.9.2 — D-081):** resumen «Tus órdenes este trimestre» con Corregir/Confirmar y lista de exenciones libres.
18. **Consejero y ayuda contextual (v1.9.2 — D-082):** consejero comercial determinista en Mercado, conmutador del Consejero en partida y botón «?» en cada pantalla §9 con texto desde datos.
19. **Panel de unidad completo N2/N3 (v1.9.2 — D-083):** hombres, armas, apoyo, moral, entrenamiento y comandante (estado + Mando) por selección.

20. **Atacar desde Militar (v1.9.3 — D-084):** objetivo adyacente, selección múltiple de ejércitos, confirmación con guerra automática si no había y batalla delegada.
21. **Guardado multislot + autoguardado (v1.9.3 — D-085):** 3 ranuras manuales + autosave por turno, con metadatos y carga.
22. **Propiedad de región (v1.9.3 — D-086):** solo el propietario reasigna trabajadores; regiones ajenas en solo lectura.
23. **Expedición de mercaderes (v1.9.3 — D-087):** sección guiada en Mercado y paso de tutorial.
24. **Tutorial Principiante ampliado (v1.9.3 — D-088):** ataque, guardado, expedición y propiedad; Manual D-089.

---

## 10. Arte, audio y direcciÃ³n visual

- **DirecciÃ³n:** "manuscrito iluminado + mapa de Ã©poca". Paleta: azul tinta, ocre pergamino, dorado, rojo grana. Evitar estÃ©tica medieval genÃ©rica de fantasÃ­a: es historia, no fantasÃ­a.
- **Assets MVP (Fase 1-2):** placeholders generados proceduralmente (Godot Shaders simples o formas vectoriales): regiones planas con borde tinta, banderas por facciÃ³n, retratos = escudos herÃ¡ldicos generados por cÃ³digo a partir de datos de casa (colores + divisa). Esto elimina la dependencia de arte para jugar.
- **Fase 3:** retratos ilustrados (generaciÃ³n IA + retoque manual), tiles de batalla tÃ¡ctica, mapa con relieve, banda sonora (mÃºsica renacentista de dominio pÃºblico interpretada/fuentes libres, ej. mÃºsica de consort CC), efectos (espadas, campanas, murmullo de corte).
- **Heraldica generativa:** cada casa define `colors[2] + charge` en datos â†’ escudo Ãºnico automÃ¡tico. Sin assets raster por facciÃ³n.

### 10.1 Mapa geogrÃ¡fico profesional (v1.3 â€” solicitud del usuario)

**Objetivo.** Sustituir el tablero de hexÃ¡gonos coloreados (placeholder `map_layout.json`, D-017) por un mapa estilo *atlas histÃ³rico*: el terreno real de **Europa, Norte de Ãfrica y Oriente PrÃ³ximo** con la divisiÃ³n polÃ­tica de los reinos de la Ã©poca. Referencia: el mapa de GK2 (geografÃ­a real + bordes de territorio superpuestos); el objetivo lo supera con fronteras vectoriales nÃ­tidas, relieve sutil y legibilidad total a 1920Ã—1080.

**Arquitectura por capas (datos y render separados):**
1. **Capa base de terreno (imagen Ãºnica):** terreno estilizado "pergamino/acuarela de Ã©poca", generado una vez: costas detalladas, relieve sutil, rÃ­os principales, indicaciÃ³n de bosques y montaÃ±as. **Prohibido** estilo satÃ©lite o fantasÃ­a. TÃ©cnica: heightmap + materiales/shaders de Godot, o textura pintada a partir de fuentes libres; 4096Ã—3072 px mÃ­nimo, versionada en `assets/art/map/`.
2. **Capa de fronteras (vectorial, por aÃ±o):** polÃ­gonos de cada regiÃ³n para **1337, 1402 y 1453**, dibujados como lÃ­neas de tinta sobre el terreno. Datos en nuevo dataset `data/map_borders.json` (AG-1): por `region_id`, `year` y anillo de puntos normalizados [0..1] sobre el lienzo del mapa; simplificaciÃ³n Douglas-Peucker con tolerancia fija; presupuesto â‰¤ 400 puntos por regiÃ³n, â‰¤ 150 KB el JSON.
3. **Capa interactiva:** polÃ­gonos invisibles clickeables conectados a `region_id`; hover resalta la regiÃ³n (tinta dorada ~18% opacidad) y muestra tooltip; cobertura completa 47/47 contra `regions.json`.
4. **Capa de entidades:** banderas de facciÃ³n, ejÃ©rcitos, iconos de ciudad, nombres de regiÃ³n con **elisiÃ³n anti-solape por nivel de zoom** (3 niveles: regiÃ³n / paÃ­s / mar); etiquetas de mar estilo carta nÃ¡utica ("MARE SEPTENTRIONALE", "LEGUES"â€¦).

**Fuentes de fronteras (abiertas y citables):** atlas histÃ³ricos de dominio pÃºblico â€” William R. Shepherd, *Historical Atlas* (1923-26, PD); mapas anuales de Wikimedia Commons (licencia verificada una a una); catÃ¡logos de bibliotecas digitales europeas. Regla Â§7.8: toda frontera lleva `source` con URL en `data/sources.md`. Las fronteras son **aproximaciones jugables**, no cartografÃ­a catastral: la regla de validaciÃ³n es coherencia con las adyacencias de `regions.json`, no precisiÃ³n mÃ©trica.

**Plan de implementaciÃ³n (mÃ³dulo "Mapa" dentro de la Fase 2):**
- **AG-1:** produce `data/map_borders.json` (3 aÃ±os Ã— 47 regiones) + entradas en `sources.md`.
- **AG-3:** integra las 4 capas en `scenes/map/world_map.tscn` con cÃ¡mara 2D (zoom rueda/pinch, pan con lÃ­mites del mundo); al completarse, `map_layout.json` queda **deprecado** (decisiÃ³n D-024 a registrar).
- **Criterios de aceptaciÃ³n del mÃ³dulo:** 47/47 polÃ­gonos por aÃ±o con `region_id` vÃ¡lido; 0 regiones huÃ©rfanas; hover/click correctos en las 3 vistas de aÃ±o; coste de render del mapa < 8 ms CPU por frame (medido en CI); capturas comparativas 1920Ã—1080 en `docs/screenshots/`, incluida una **comparativa lado a lado con el mapa de GK2** como referencia de calidad.

### 10.2 Retratos de soberanos (v1.4 â€” solicitud del usuario)

**Objetivo.** Como en la referencia (retratos del gobernante y su lugarteniente en la esquina del mapa), el juego muestra siempre **quiÃ©n eres**: un retrato tipo avatar del soberano que se estÃ¡ jugando, con calidad superior a los sprites de 16 bits de GK2. Referencia visual: las miniaturas de la captura del usuario (Genghis Khan / Mugali); estÃ©tica objetivo: **miniatura de manuscrito iluminado / Ã³leo plano de Ã©poca**, coherente con la direcciÃ³n Â§10 (pergamino, tinta, dorado) â€” nada de fantasÃ­a.

**DÃ³nde aparece:** (1) esquina del mapa principal, junto al escudo de armas (jugador); (2) Ã¡rbol familiar (cada miembro vivo); (3) pantalla de diplomacia (gobernante rival); (4) informe de batalla (lÃ­deres de ambos bandos); (5) pantalla de corte. Mismo asset en todos lados: un solo retrato por personaje.

**EspecificaciÃ³n tÃ©cnica:**
- `characters.json` aÃ±ade campo opcional `"portrait": "<asset_id>"`. ResoluciÃ³n de trabajo: **256Ã—256 px** (se muestra a 96-128 px; margen para zoom en detalle del personaje). Formato PNG con fondo plano color pergamino, marco dorado fino generado por cÃ³digo (no parte del asset).
- **Fase 2 (placeholder funcional):** AG-3 implementa el *slot* de retrato en las 5 ubicaciones con fallback automÃ¡tico: si `portrait` no existe, se renderiza la herÃ¡ldica generativa del personaje (escudo de su `house`) + silueta genÃ©rica por sexo/edad. Nunca un hueco vacÃ­o.
- **Retratos finales (v1.5):** los 14 gobernantes iniciales de 1337 los diseÃ±a **Kimi** con investigaciÃ³n histÃ³rica (parecido a retratos/efigies reales cuando existen: Eduardo III segÃºn su efigie de Westminster, Casimiro III segÃºn su efigie de Cracovia, etc.; cuando no hay retrato, indumentaria, corona y rasgos correctos por regiÃ³n y dÃ©cada) + **escudo de armas herÃ¡ldico exacto del reino** integrado en la imagen. Archivos: `assets/art/portraits/<character_id>.png` (256Ã—256). Entregado como asset final, no placeholder. AG-5 (Fase 3) se encarga solo de los retratos restantes (herederos, escenarios 1402/1453) siguiendo la hoja de estilo fijada por el set de Kimi (paleta Â§10, rasgos por regiÃ³n, indumentaria por dÃ©cada), con hoja de contacto para auditar consistencia (`docs/screenshots/portraits_contact_sheet.png`).
- El retrato del soberano **cambia con la sucesiÃ³n**: al morir el gobernante, el slot muestra al heredero (dinÃ¡mica ya disponible en `DynastySystem`).

**Criterios de aceptaciÃ³n:** slot presente en las 5 ubicaciones con fallback herÃ¡ldico 100% funcional (Fase 2); los 14 retratos de Kimi integrados y referenciados por `portrait` en `characters.json` (Fase 2); set completo sin personaje roto/faltante (Fase 3); cambio de retrato tras sucesiÃ³n verificado en test; captura del mapa con retrato + escudo en `docs/screenshots/`.

### 10.3 Sprites de unidades y animaciÃ³n de combate (v1.5 â€” solicitud del usuario)

**Objetivo.** En los Niveles 2/3 de batalla, cada tipo de unidad se reconoce **a simple vista por su arma y silueta**, con calidad de ilustraciÃ³n a pesar de su baja resoluciÃ³n (referencia de legibilidad: informe REA `gk2_battle_mechanics.md`, Â§3.2). Ejemplos exigidos: la milicia de lanza se ve con su lanza o alabarda de la Ã©poca; los ballesteros se ven con su ballesta y, al atacar, **se ve volar el virote**; arqueros largos con arco y flecha visible.

**EspecificaciÃ³n tÃ©cnica:**
- **TamaÃ±o:** sprites base 64Ã—64 px (unidad a pie) y 64Ã—80 (caballerÃ­a); escalables Ã—2/Ã—3 en pantalla. Estilo "miniatura pintada" coherente con los retratos Â§10.2 (trazo de ilustraciÃ³n, no pixel art digital genÃ©rico), fondo transparente PNG.
- **Hojas de animaciÃ³n por unidad:** idle (2 cuadros), marcha (4), ataque (4-6), impacto/herida (2), muerte (2), con versiÃ³n por direcciÃ³n (S, SE, E como mÃ­nimo â€” espejo para el resto). Proyectiles separados: virote (ballesta), flecha (arco), piedra (bombarda), con trayectoria balÃ­stica visible.
- **Armas por Ã©poca (Â§6.4):** las siluetas deben distinguir pica/lanza de alabarda (aparece hacia 1380) y de arcabuz (post-1440); la ballesta con gafa y cinturÃ­n de recarga; el arco largo inglÃ©s; escudo heater vs. pavÃ©s; caballerÃ­a con lanza en ristre vs. cab. ligera con jabalina.
- **AsignaciÃ³n:** `units.json` aÃ±ade campo opcional `"sprite_sheet": "res://assets/art/units/<unit_id>.png"`; fallback = marcador herÃ¡ldico por facciÃ³n (ya existente) si falta el sprite.
- **ProducciÃ³n:** AG-5 (Fase 3) con guÃ­a de estilo; la lista de hojas requeridas se deriva de `units.json` (17 tipos Ã— variantes por Ã©poca segÃºn aplique). Prioridad: las 6-8 unidades mÃ¡s comunes del Escenario 1.

**Sprites de TODAS las unidades ENTREGADOS (v1.6 â€” Kimi, 2026-11-22).** Paquete `Sprites_Unidades_TSB.zip`: las **17 unidades** de `units.json` Ã— 3 cuadros de marcha (51 sprites) + 3 proyectiles (`proyectil_virote.png`, `proyectil_flecha.png`, `proyectil_piedra.png`). Contrato del asset:
- **Archivos:** `<unit_id>_march_{1,2,3}.png`; infanterÃ­a 512Ã—512, caballerÃ­a 512Ã—640 (proporciÃ³n 64Ã—80), artillerÃ­a/especiales (`bombard`, `hussite_war_wagon`) 512Ã—341 panorÃ¡mico. RGBA transparente, figura aislada sin sombra de suelo. Originales 1024/1536 incluidos. Ancla: borde inferior, centro horizontal.
- **AnimaciÃ³n de marcha (ciclo 3):** `march_1` extremidad izquierda adelante â†’ `march_2` reuniÃ³n/paso â†’ `march_3` derecha adelante (equivalente en el paso del caballo / giro de ruedas). Todos miran a E; para N/NW/O espejar en el motor (convenciÃ³n GK2); S/SE usan la versiÃ³n actual.
- **Reescalado:** LANCZOS a 64Ã—64 / 64Ã—80 (64Ã—43 artillerÃ­a) en importaciÃ³n; validar legibilidad del arma a 64 px (QA visual).
- **Proyectiles:** capa separada con trayectoria balÃ­stica; viroteâ†’`crossbowmen`, flechaâ†’`longbowman`/`janissary`/`steppe_cavalry`, piedraâ†’`bombard`.
- **Campo `units.json` (D-037):** `"sprite_sheet": {"frames": ["res://assets/art/sprites/units/<unit_id>_march_1.png", "..._2", "..._3"], "anim": {"march": [0,1,2], "fps": 6, "loop": true}, "size": [64,64], "anchor": "bottom_center", "facing": "E"}` (64Ã—80 caballerÃ­a, 64Ã—43 artillerÃ­a). Fallback herÃ¡ldico si falta.
- **Cuadros de animaciÃ³n de combate ENTREGADOS (v1.8 â€” Kimi, 2026-11-22, D-049).** Paquete `Anim_Combate_TSB.zip`: las **17 unidades** Ã— 10 cuadros (idleÃ—2, ataqueÃ—4, impactoÃ—2, muerteÃ—2) = **170 sprites**, mismas convenciones que el set de marcha (512-wide RGBA, ancla `bottom_center`, facing E con espejo, reescalado 64Ã—64/64Ã—80/64Ã—43 LANCZOS). Secuencia de ataque: preparaciÃ³n â†’ golpe/disparo (`attack_2` = cuadro de impacto, sincronizar con D-048) â†’ follow-through â†’ recuperaciÃ³n. Secuencias especiales: unidades a distancia (apuntarâ†’dispararâ†’bajarâ†’recargar; proyectil sigue en capa separada), `bombarda` (dotaciÃ³n de 2 artilleros; `attack_2` = disparo con nube de pÃ³lvora y retroceso), `hussite_war_wagon` (dotilla disparando desde las pavesas). QA visual cuadro a cuadro en `_hoja_contacto_anim.png`.
- **Contrato de integraciÃ³n (D-049):** los 10 cuadros se aÃ±aden a `frames` tras los 3 de marcha (Ã­ndices 3-12) y el `anim` se extiende: `{"march":[0,1,2], "idle":[3,4], "attack":[5,6,7,8], "hit":[9,10], "death":[11,12], "fps":6, "loop":true, "fps_attack":9, "fps_hit":8, "fps_death":6, "death_hold":true}`. `loop` aplica a marcha/idle; ataque/impacto/muerte se reproducen una vez; `death_hold` = el cuadro final de muerte persiste hasta que la unidad desaparece del campo. Ver detalle en el README del paquete.
- **Addendum v1.8.1 (2026-11-23) â€” alineaciÃ³n con `docs/art/requests/kimi_phase3_assets.md` v1.1 (AG-5):** las 7 unidades a distancia/artillerÃ­a (`janissary`, `arquebusier`, `crossbowmen`, `longbowman`, `steppe_cavalry`, `bombarda`, `hussite_war_wagon`) llevan **ataque de 6 cuadros** (Paquete B = 184 PNG totales: 34 idle + 82 attack + 34 impact + 34 death), entregado en `Anim_Combate_Rango_Artilleria_TSB.zip` (42 `attack_1..6` + 34 `impact_1..2`; nomenclatura `impact` en lugar de `hit`). Ãndices por unidad: 10 unidades de choque â†’ `idle [3,4]`, `attack [5..8]`, `impact [9,10]`, `death [11,12]`; 7 a distancia/artillerÃ­a â†’ `idle [3,4]`, `attack [5..10]`, `impact [11,12]`, `death [13,14]`. `attack_4` = cuadro de disparo/impacto (sincronizar proyectil, D-048).

**Criterios de aceptaciÃ³n:** cada tipo de unidad del Escenario 1 identificable en silueta a 64 px; animaciÃ³n de ataque con proyectil visible para ballesteros/arqueros/bombardas; todas las hojas referenciadas en `units.json` cargan sin error en CI; capturas de las 3 unidades de ejemplo (milicia, ballesteros, arqueros) en `docs/screenshots/`.

### 10.4 Tiles del campo de batalla tÃ¡ctica (v1.7 â€” solicitud del usuario)

**Objetivo.** En el **Nivel 3 de batalla** (vista cercana), el terreno se dibuja con mosaicos texturizados realistas estilo "miniatura pintada" (coherente Â§10.2/Â§10.3), vista cenital a 45Â°. El terreno es **tÃ¡cticamente relevante**: el rÃ­o es obstÃ¡culo natural intransitable que obliga a rodearlo o a forzar el cruce por **puente** (como en GK2); colinas y bosques dan defensa y penalizan caballerÃ­a; villa/aldea es posiciÃ³n defendible; camino da bonus de movimiento.

**Set ENTREGADO (v1.7 â€” Kimi, 2026-11-22).** Paquete `Tiles_Batalla_TSB.zip`: 12 tiles 512Ã—512 (originales 1024 en `src/`), hoja de contacto `_hoja_contacto_tiles.png` (nombre Ãºnico, no colisiona con la de unidades Â§10.3):
- **Terreno base:** `tile_pastizal`, `tile_pastizal_arbustos`, `tile_pradera` (libres, sin bonus).
- **RÃ­o y cruces:** `tile_rio` (intransitable; banda horizontal, el motor rota 90Â° para el sentido vertical), `tile_puente` (cruce), `tile_puente_villa` (cruce + villa murada defensiva). Los tres comparten la misma geometrÃ­a de agua/orillas (generados por referencia): el generador de campos sustituye casillas de rÃ­o por puentes en los puntos de cruce.
- **ElevaciÃ³n y cobertura:** `tile_colina` (coste 2, defensa +1), `tile_bosque` (coste 2, defensa +1, penaliza caballerÃ­a Â§6.4), `tile_montana` (intransitable).
- **Asentamiento:** `tile_villa` (defensa +1), `tile_villa_calle`, `tile_camino` (bonus movimiento).
- **Contrato de datos:** tabla `battle_tiles` (JSON) con `tile`, `move_cost`, `defense`, `passable`, flags `cavalry_penalty`/`move_bonus` â€” valores exactos segÃºn balance Â§6.4 (AG-2), formato en el README del paquete.
- **ComposiciÃ³n de campos:** el terreno se deriva de la regiÃ³n del mapa estratÃ©gico Â§10.1 (llanura/bosque/colinas/montaÃ±a/costa); el rÃ­o corta el campo de orilla a orilla con 1-2 puentes; la villa se coloca en el asentamiento sitiado.

**Criterios de aceptaciÃ³n:** campo de batalla N3 renderizado con los 12 tiles sin errores de carga; unidad no puede entrar a rÃ­o/montaÃ±a (test); bonus de colina/camino aplicados en las fÃ³rmulas Â§6.4; capturas de un campo con rÃ­o+puente+villa y uno de llanura en `docs/screenshots/`; generador de campos deriva el terreno de la regiÃ³n estratÃ©gica.

---

## 11. Equipo de agentes DSH

### 11.1 RecomendaciÃ³n: equipo nativo de DSH (sin plugin de terceros)

Usa los **subagentes nativos de DSH** (`/agents` o el mecanismo de agentes del harness) con `deepseek-flash` como modelo. Razones:
- DSH es gratuito/open source y corre local; los plugins aÃ±aden una capa de fallo y mantenimiento que no necesitas.
- `deepseek-flash` soporta hasta 2.500 peticiones concurrentes â†’ puedes correr los 5 agentes en paralelo cuando las tareas lo permitan (la fase de desarrollo de sistemas, no la de datos).
- El contexto de 1M tokens permite dar a cada agente el GDD completo + los archivos relevantes sin fragmentaciÃ³n.

### 11.2 DefiniciÃ³n del equipo (plantillas de agente)

Cada agente se define con: nombre, modelo (`deepseek-flash`), prompt de sistema, herramientas (fs, godot-mcp, rea-mcp, shell), y carpeta de trabajo. El Coordinator debe **guardar cada definiciÃ³n como un MD en `C:\Proyectos\TSB\agents\`** (ej. `C:\Proyectos\TSB\agents\AG-2-systems-dev.md`) la primera vez que activa al agente, y reusar ese MD en sesiones posteriores. Rutas de trabajo relativas al repo `C:\Proyectos\TSB\sovereigns-blood\`.

**AG-0 Â· Coordinator (orquestador â€” corre en el chat principal de DSH)**
> Eres el coordinador del desarrollo de The Sovereign's Blood (GDD v1.0). No escribes cÃ³digo de producciÃ³n. Descompones tareas, las asignas a AG-1..AG-5 segÃºn la SecciÃ³n 11.3, revisas sus diffs contra los criterios de aceptaciÃ³n (SecciÃ³n 12) y decides siguiente paso. Mantienes `docs/STATUS.md` actualizado. Ante ambigÃ¼edad del GDD, decides lo mÃ¡s simple que cumpla el alcance del MVP y lo registras en `docs/decisions.md`.

**AG-1 Â· Historian/Data** (herramientas: fs, web search si estÃ¡ disponible; *sin* godot-mcp)
> Eres el agente de datos histÃ³ricos. Produces y mantienes `data/*.json` conforme a la SecciÃ³n 7 y `data/sources.md`. Cada dato histÃ³rico lleva `source` con URL (Wikidata/Wikipedia/mapa). Prioridad de trabajo: (1) `factions.json`, `characters.json`, `regions.json` del Escenario 1 (1337); (2) `units.json`; (3) `scenario_1337.json` y `events_1337.json`. Nunca inventes cifras: si no hay fuente, usa estimaciÃ³n marcada `"estimate": true`. En la Fase 0 tambiÃ©n redactas `docs/rea/gk2_data_lessons.md` a partir del informe de AG-REA.

**AG-REA Â· Reverse Engineer** (herramientas: fs, shell, rea-mcp; alcance limitado por SecciÃ³n 3)
> Tu Ãºnica misiÃ³n es analizar los formatos de datos del juego de referencia Genghis Khan II. Los archivos estÃ¡n en `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf` (solo lectura). Usa rea-mcp o inspecciÃ³n hexadecimal para documentar los `.DAT`/`.GK2` y produce `docs/rea/gk2_data_lessons.md`: tablas de campos, tamaÃ±os, lecciones de modelado de datos (checklist completo en Anexo A). EstÃ¡ terminantemente prohibido analizar ejecutables (.EXE) ni transcribir texto del juego. Al terminar el informe, tu tarea concluye y no vuelves a activarte salvo peticiÃ³n expresa del Coordinator.

**AG-2 Â· Systems Dev** (herramientas: fs, shell, godot-mcp)
> Implementas los sistemas de juego en GDScript segÃºn las Secciones 5, 6 y 8: turn_manager, economy_system, dynasty_system, diplomacy_system, military_system, battle_manager (Nivel 1), ai_manager, data_loader, model/. Contratos: usa exactamente las firmas de la SecciÃ³n 8.2. Cada PR debe incluir test GUT del sistema tocado. No tocas escenas de UI ni assets.

**AG-3 Â· UI Dev** (herramientas: fs, shell, godot-mcp)
> Implementas las escenas de la SecciÃ³n 9 consumiendo SOLO los contratos pÃºblicos de la SecciÃ³n 8.2 (nunca mutas estado directamente). UI funcional primero, estilo despuÃ©s (la direcciÃ³n visual estÃ¡ en SecciÃ³n 10). Cada pantalla debe funcionar a 1920Ã—1080 y con placeholders de arte.

**AG-4 Â· QA** (herramientas: fs, shell)
> Ejecutas `godot --headless --script tests/run_all.gd` tras cada cambio de AG-2/AG-3. Redactas tests de regresiÃ³n para cada bug encontrado (`tests/`). Verificas: criterios de aceptaciÃ³n de la SecciÃ³n 12, validaciÃ³n de datos (`tools/validate_data.gd`), determinismo (misma semilla â†’ mismo resultado). No arreglas cÃ³digo: reportas issues con pasos de reproducciÃ³n en `docs/issues.md` y el Coordinator los asigna.

**AG-5 Â· Art Pipeline** (se activa en Fase 3)
> Produces assets finales segÃºn SecciÃ³n 10: prompts de generaciÃ³n de retratos/tiles, integraciÃ³n en `assets/`, bandera sonora CC.

### 11.3 Flujo de trabajo del equipo

```
FASE 0 (secuencial)
  AG-REA â†’ gk2_data_lessons.md â†’ AG-1 â†’ datasets Escenario 1 + schemas
                                     â†˜ AG-2 scaffold del proyecto Godot (vacÃ­o pero compilando) en paralelo

FASE 1 (paralelo controlado)
  AG-2 sistemas nÃºcleo (economÃ­a, dinastÃ­a, diplomacia, batalla delegada, IA, save/load)
  AG-3 UI (consumiendo contratos; puede usar stubs hasta que AG-2 entregue)
  AG-4 QA continuo + tests
  Coordinator revisa diffs, mantiene STATUS.md, resuelve conflictos de integraciÃ³n

FASE 2 / 3
  Mismo esquema; AG-5 se une en Fase 3. Escenarios 2-3 = AG-1 datos + AG-2 activaciÃ³n por aÃ±o.
```

**Reglas de coordinaciÃ³n:** (1) un solo agente toca un archivo a la vez (el Coordinator asigna archivos, no carpetas); (2) commits pequeÃ±os y frecuentes, mensaje con prefijo `[AG-N]`; (3) cada fase cierra con revisiÃ³n del Coordinator contra los criterios de aceptaciÃ³n antes de pasar a la siguiente.

### 11.4 Prompt maestro sugerido (para iniciar DSH)

```text
ActÃºa como AG-0 Coordinator del proyecto The Sovereign's Blood.

ENTORNO (inamovible):
- Workspace raÃ­z: C:\Proyectos\TSB â€” NADA se crea fuera de esta carpeta.
- GDD maestro: C:\Proyectos\TSB\GDD_The_Sovereign's_Blood.md â€” lÃ©elo completo antes de
  actuar; ante cualquier duda, este documento manda.
- Referencia GK2 (SOLO LECTURA, solo para AG-REA): C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf
- Repo del juego a crear: C:\Proyectos\TSB\sovereigns-blood
- Definiciones de agentes: guarda cada prompt de la SecciÃ³n 11.2 como MD en
  C:\Proyectos\TSB\agents\ (ej. agents\AG-REA.md) la primera vez que actives a cada agente.
- Godot: C:\Godot\<ejecutable>.exe â€” verifica el nombre exacto antes de usarlo;
  godot-mcp y rea-mcp ya estÃ¡n instalados en este DSH.

TU PRIMERA TAREA (Fase 0):
1. Verifica que este workspace contiene el GDD y la carpeta de referencia GK2; reporta lo que encuentres.
2. Crea la estructura: C:\Proyectos\TSB\agents\, C:\Proyectos\TSB\sovereigns-blood\ con
   project.godot vacÃ­o que compile y docs\STATUS.md inicial.
3. Activa AG-REA (guarda su MD en agents\) para producir docs\rea\gk2_data_lessons.md
   segÃºn la SecciÃ³n 3 y el Anexo A.
4. Activa AG-1 para producir los datasets del Escenario 1 (1337) segÃºn la SecciÃ³n 7,
   con fuentes en data\sources.md.
5. Crea el agente AG-4 (QA) y hazle pasar tools\validate_data.gd cuando AG-1 termine.
6. MantÃ©n docs\STATUS.md y docs\decisions.md actualizados en cada paso.

REGLAS: commits pequeÃ±os con prefijo [AG-N]; un solo agente por archivo a la vez;
no avances a la Fase 1 hasta cumplir los criterios de aceptaciÃ³n de la Fase 0
(SecciÃ³n 12). Trabaja en horario off-peak cuando sea posible.

GIT (SecciÃ³n 3.2): al crear el repo local, aÃ±ade el remoto
https://github.com/horaciomartinez-svg/The_Sovereign_Blood.git como origin (main).
Tu PRIMER push debe incluir el GDD en la raÃ­z del repo (commit [AG-0] init).
Haz push al cerrar cada mÃ³dulo con docs\STATUS.md actualizado; crea el tag de fase
al cumplir los criterios de aceptaciÃ³n. Nunca force-pushees. Godot headless:
"C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path
C:\Proyectos\TSB\sovereigns-blood --script tests/run_all.gd
```

---

## 12. Plan Ã¡gil por fases (con criterios de aceptaciÃ³n)

### Fase 0 â€” Cimientos (objetivo: 3-5 dÃ­as)
- AG-REA: informe `gk2_data_lessons.md`.
- AG-1: schemas + `factions/characters/regions/units/scenario_1337/events_1337` validados.
- AG-2: repo Godot compilando, autoloads vacÃ­os, CI headless corriendo.
- **AceptaciÃ³n:** `validate_data.gd` 0 errores; `godot --headless` arranca sin warnings crÃ­ticos; informe REA â‰¤ 2 pÃ¡ginas.

### Fase 1 â€” MVP jugable (objetivo: 2-3 semanas)
- Loop completo de trimestre + aÃ±o; economÃ­a con asignaciÃ³n por regiÃ³n; apoyo/revueltas; familia (nacimientos, educaciÃ³n, sucesiÃ³n, matrimonios y pretensiones); diplomacia (las 7 acciones); batallas delegadas; IA de 13 facciones rivales; guardar/cargar; UI completa de la SecciÃ³n 9.
- **AceptaciÃ³n jugable:** se puede jugar Inglaterra 1337 de principio a fin de aÃ±o sin crash; la IA completa sus turnos <2 s; guardar/cargar preserva el estado exacto (test automatizado); batalla delegada produce informe coherente y captura regiones; evento de Peste Negra dispara en 1348.

### Fase 2 â€” Profundidad militar (objetivo: 2-3 semanas)
- Mapa tÃ¡ctico Nivel 2 (hex local) y combate cerrado Nivel 3 (Ã³rdenes/cartas); espionaje; fin de partidas por extinciÃ³n dinÃ¡stica.
- **AG-REA ampliado (Â§3.2):** informe `docs/rea/gk2_battle_mechanics.md` (mecÃ¡rmicas observadas de batalla Nivel 2/3 + estructura de `SUNIT.DAT`).
- **MÃ³dulo Mapa (Â§10.1):** mapa geogrÃ¡fico profesional con fronteras por aÃ±o; depreca `map_layout.json`.
- **MÃ³dulo Retratos (Â§10.2):** integrar los 14 retratos finales entregados por Kimi (`assets/art/portraits/`) y referenciarlos en `characters.json`.
- **AceptaciÃ³n:** CrÃ©cy puede jugarse en los 3 niveles con resultados coherentes; pÃ©rdida de lÃ­der sin herederos termina la partida correctamente; mÃ³dulos Mapa y Retratos cumplen Â§10.1/Â§10.2; informe REA ampliado entregado.

### Fase 3 â€” Contenido y remaster (objetivo: 2-3 semanas)
- **IntegraciÃ³n de sprites Kimi (primero):** AG-5 copia el paquete `Sprites_Unidades_TSB.zip` a `assets/art/sprites/units/` (51 PNG, 17 unidades), reescala a 64Ã—64 / 64Ã—80 / 64Ã—43 (LANCZOS), aÃ±ade `sprite_sheet` a las 17 unidades en `units.json` (formato Â§10.3) y valida carga en CI headless. Niveles 2/3 de batalla usan estos sprites con el ciclo de marcha; proyectiles en capa separada con trayectoria balÃ­stica. **ActualizaciÃ³n v1.8 (D-049):** integrar tambiÃ©n `Anim_Combate_TSB.zip` (170 PNG de idle/ataque/impacto/muerte) extendiendo `frames` y `anim` segÃºn el contrato Â§10.3; en batalla N3 la unidad en guardia usa `idle`, al atacar `attack` (impacto en `attack_2`), al recibir daÃ±o `hit`, al morir `death` con `death_hold`.
- Escenarios 1402 y 1453 completos (datos + eventos: Ankara, locura de Carlos VI, caÃ­da de Constantinopla, Dos Rosas); evoluciÃ³n tecnolÃ³gica por aÃ±o; arte final (retratos Â§10.2 de herederos y nuevos escenarios siguiendo la hoja de estilo Kimi, **tiles de batalla Â§10.4 ya entregados por Kimi â€” solo integrar**, mÃºsica CC); balance general.
- **AceptaciÃ³n:** los 3 escenarios empiezan y llegan a su aÃ±o final; victoria/derrota segÃºn SecciÃ³n 4.5; partida completa de test automatizada de 10 aÃ±os sin errores; set de retratos completo y slot de retrato funcional en las 5 ubicaciones Â§10.2.

### Fase 4 â€” Profundidad (objetivo: 2-3 semanas)
- **REA preliminar:** `docs/rea/gk2_economy_military_family.md` (â‰¤2 pÃ¡ginas + `notes_economy.md`): estructuras de datos de economÃ­a/mercancÃ­as/mercaderes y lecciones de UX de los menÃºs EconomÃ­a/Militar/Familia (sin transcribir texto ni copiar assets; sin `.EXE`).
- **MercancÃ­as y comercio (D-069):** 8-12 bienes en `data/trade_goods.json` + schema/fuentes; producciÃ³n por terreno/edificios; inventario de facciÃ³n; comerciantes obligatorios; mercado con precios oferta/demanda; comercio exterior/expediciÃ³n; consumo (grano/sal) y uso en reclutamiento (armas/caballos); pantalla Mercado.
- **EjÃ©rcitos (D-070):** pantalla global con imagen por tipo, conteos, fuerza/moral/experiencia; Reclutar/Entrenar/Disolver; reclutamiento con mercancÃ­as.
- **Familia (D-071):** acciÃ³n Â«Pasar tiempo con la consorteÂ» (2-3 PG/trimestre; bonus de fertilidad 2-4 trimestres; sin consorte vÃ¡lida â†’ rechazo claro).
- **Manual (D-072):** `docs/MANUAL_DEL_JUGADOR.md` con 10 secciones, accesible desde el juego.
- **Tutorial y dificultad (D-073):** Principiante (Consejero + IA menos agresiva) / Normal; guion en `data/tutorial_script.json`; panel del Consejero con resaltado y salto; estado serializable.
- **AceptaciÃ³n:** QA C1-C12 del prompt de Fase 4 â€” REA legal; `trade_goods` validado con fuentes; comercio operativo solo con comerciantes y simulaciÃ³n 10 aÃ±os sin inflaciÃ³n; pantalla de ejÃ©rcitos con acciones efectivas; reclutamiento consume mercancÃ­as; consorte con bonus/cooldown; Manual completo y accesible; tutorial con guion/resaltes/salto y dificultad; save/load con inventario y tutorial; sin regresiÃ³n (run_all â‰¥1742/0, validate 0, editor 0 warnings, F1/F2/F3/MVP/anim/tiles); 1402/1453 intactos y sin arte externo; UX sin botones muertos y capturas 1920Ã—1080.

**Total estimado: 7-10 semanas de trabajo del equipo de agentes, revisado por ti en sesiones cortas.**

---

## 13. QA y pruebas

- **Unitarias (GUT):** cada sistema nÃºcleo con tests de sus fÃ³rmulas (economÃ­a, batalla delegada, sucesiÃ³n) usando RNG sembrado.
- **IntegraciÃ³n:** partida-simulaciÃ³n headless: Inglaterra en piloto automÃ¡tico 20 aÃ±os sin crash y con estado serializable en cada aÃ±o.
- **Datos:** validaciÃ³n JSON Schema + reglas cruzadas (adyacencias simÃ©tricas, toda facciÃ³n tiene capital, toda regiÃ³n tiene dueÃ±o en aÃ±o de escenario).
- **Determinismo:** misma semilla + mismas acciones = mismo hash de save.
- **Manual:** checklist por fase del Coordinator; capturas de cada pantalla en `docs/screenshots/`.

## 14. Riesgos y mitigaciÃ³n

| Riesgo | Prob. | MitigaciÃ³n |
|---|---|---|
| Godot MCP inestable en Windows | Media | Shell directo (`godot --headless`) como vÃ­a alternativa obligatoria en scripts |
| Datos histÃ³ricos incompletos (poblaciÃ³n medieval) | Alta | Estimaciones marcadas; redondeos por magnitud; foco en jugabilidad |
| Scope creep (Batallas Nivel 2/3) | Alta | Bloqueados hasta Fase 2; Nivel 1 ya permite ganar la campaÃ±a |
| Agentes pisando archivos | Media | AsignaciÃ³n por archivo del Coordinator; commits pequeÃ±os `[AG-N]` |
| IA lenta con 14 facciones | Baja | Perfiles simples; presupuesto 2 s medido en CI |
| Costo API | Baja | Trabajar off-peak; cachÃ© de contexto; GLM-4.7-Flash gratis para AG-1 si conviene |

## 15. Anexos

### Anexo A â€” Checklist REA (GK2, alcance limitado SecciÃ³n 3)
Ruta de los archivos: `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf` (solo lectura). Herramientas: `rea-mcp` o inspecciÃ³n hexadecimal con fs/shell.
- [ ] Header y tamaÃ±os de `GENDATA1.DAT` (campos de generales por escenario)
- [ ] Estructura de `ZNAME.DAT` (nombres de regiÃ³n, longitud fija)
- [ ] Estructura de `SCENARIO.GK2` y `SAVEDATA.GK2` (quÃ© guarda el estado)
- [ ] `MAPDATA.DAT` / `HEXKG.DAT` / `HEXSG.DAT`: dimensiones del mapa y codificaciÃ³n
- [ ] Redactar `docs/rea/gk2_data_lessons.md` con tabla de equivalencias para nuestros JSON
- [ ] Prohibido: abrir `MAIN.EXE`/`OPEN.EXE`/`END.EXE` con desensamblador

### Anexo B â€” DefiniciÃ³n de terminado (DoD)
1. Compila y corre en Godot 4 headless y con UI.
2. Tests GUT pasan; nuevo sistema = nuevo test.
3. Sin referencias a propiedad intelectual de terceros en cÃ³digo/datos/arte.
4. `validate_data.gd` sin errores.
5. Revisado por Coordinator contra el criterio de aceptaciÃ³n de su fase.

### Anexo C â€” Glosario
PG: Puntos de Gobernanza Â· Casus Belli: justificaciÃ³n de guerra Â· Devshirme: reclutamiento otomano Â· Schiltron: formaciÃ³n escocesa anti-caballerÃ­a Â· DS(DSH): DeepSeek Harness Â· REA: Reverse Engineer Anything (uso limitado, SecciÃ³n 3).

---

*Fin del GDD v1.3 â€” The Sovereign's Blood. Documento de trabajo para el equipo de agentes DSH; ante conflicto entre este documento y el cÃ³digo, este documento manda hasta que el Coordinator apruebe un cambio registrado en `docs/decisions.md`. v1.1: entorno Windows real (SecciÃ³n 3.1), carpeta `agents\`, godot-mcp y rea-mcp. v1.2: ejecutables Godot 4.7.2 verificados, repo GitHub pÃºblico y protocolo de verificaciÃ³n (SecciÃ³n 3.2). v1.3: especificaciÃ³n de mapa geogrÃ¡fico profesional (SecciÃ³n 10.1, mÃ³dulo Mapa en Fase 2), solicitud del usuario tras comparar con el mapa de GK2. v1.4: especificaciÃ³n de retratos de soberanos (SecciÃ³n 10.2) â€” avatar del soberano en mapa y pantallas clave, placeholders herÃ¡ldicos en Fase 2 y retratos ilustrados en Fase 3. v1.5: REA ampliado a mecÃ¡rmicas de batalla Nivel 2/3 y estructura de sprites (SecciÃ³n 3.2, autorizaciÃ³n del usuario); retratos finales de los 14 soberanos diseÃ±ados por Kimi con herÃ¡ldica real (SecciÃ³n 10.2); sprites de unidades con armas de Ã©poca y proyectiles visibles (SecciÃ³n 10.3). v1.6: sprites de las 17 unidades del dataset entregados por Kimi (contrato de asset, ciclo de marcha de 3 cuadros, proyectiles) con integraciÃ³n AG-5 como primera tarea de Fase 3 (SecciÃ³n 10.3 y plan de fases). v1.7: tiles del campo de batalla del Nivel 3 entregados por Kimi (SecciÃ³n 10.4) â€” 12 mosaicos con rÃ­o/puente/villa, obstÃ¡culos naturales al estilo GK2, contrato battle_tiles y guÃ­a de composiciÃ³n de campos. v1.8: cuadros de animaciÃ³n de combate de las 17 unidades entregados por Kimi (SecciÃ³n 10.3, D-049) â€” 170 sprites idle/ataque/impacto/muerte con contrato de integraciÃ³n en `units.json` (Ã­ndices 3-12, `death_hold`); sprites Â§10.3 y tiles Â§10.4 verificados APROBADO contra el repo (HEAD 854b5dc). v1.8.1: addendum de animaciÃ³n alineado con la peticiÃ³n formal de AG-5 `kimi_phase3_assets.md` v1.1 â€” ataque de 6 cuadros para las 7 unidades a distancia/artillerÃ­a, nomenclatura `impact`, cÃ³mputo completo de 184 PNG (`Anim_Combate_Rango_Artilleria_TSB.zip`, 2026-11-23). Fase 3 cerrada por DSH con tag `fase-3` (HEAD ce487179, QA final 7/7 APROBADO CON OBSERVACIONES; arte externo Kimi pendiente de integraciÃ³n).*

