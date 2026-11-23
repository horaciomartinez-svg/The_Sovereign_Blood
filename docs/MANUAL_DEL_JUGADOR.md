# Manual del Jugador — The Sovereign's Blood

**Versión:** MVP-1337, Fases 4-5B (D-069…D-073, D-079…D-089) · **Escenario:** «Dos Coronas», 1337-1399
**Cómo abrir este manual en el juego:** botón **Manual** del menú principal (abre este archivo con
`OS.shell_open`) y entrada **Ayuda** del menú del Consejo, que muestra un resumen rápido. Además,
cada pantalla tiene un botón **?** con ayuda contextual breve (Fase 5A).

> Este manual explica las reglas que afectan al jugador. Si algo cambia en una versión posterior,
> manda el GDD v1.9.3 y las notas de la versión. Las cifras son las del MVP-1337 y pueden ajustarse
> por balance sin cambiar la filosofía del juego.

**Novedades de la Fase 5B «Guerra, guardado y control»:** (1) **Militar → Atacar** con objetivo,
selección múltiple de ejércitos y **guerra automática** si no había; (2) **guardado multislot**
(3 ranuras + autoguardado por turno); (3) **expedición de mercaderes** explicada; (4) **solo el
propietario decide en su reino**; (5) tutorial y ayuda actualizados con estos flujos.

**Novedades de la Fase 5A «El juego te explica»:** (1) HUD con estación y año; (2) boletín
trimestral, Crónica anual y pestaña de histórico; (3) repaso «¿Confirmas tus órdenes?» con
Corregir/Confirmar; (4) Consejero comercial en el Mercado y botón «?» de ayuda en cada pantalla;
(5) panel de unidad completo en batallas N2/N3.

## Índice

1. [Introducción: tu dinastía](#1-introducción-tu-dinastía)
2. [Cómo se gana y cómo se pierde](#2-cómo-se-gana-y-cómo-se-pierde)
3. [El turno: trimestres, PG y fases](#3-el-turno-trimestres-pg-y-fases)
4. [Economía, mercancías y comercio](#4-economía-mercancías-y-comercio)
5. [Familia, sucesión y Peste Negra](#5-familia-sucesión-y-peste-negra)
6. [Diplomacia y espionaje](#6-diplomacia-y-espionaje)
7. [Militar y los tres niveles de batalla](#7-militar-y-los-tres-niveles-de-batalla)
8. [IA, dificultades y eventos históricos](#8-ia-dificultades-y-eventos-históricos)
9. [Consejos por facción (8 jugables de 1337)](#9-consejos-por-facción-8-jugables-de-1337)
10. [Glosario](#10-glosario)
11. [Ayuda en el juego](#11-ayuda-en-el-juego)

---

## 1. Introducción: tu dinastía

*The Sovereign's Blood* es un juego de estrategia por turnos ambientado en la Europa de la Baja
Edad Media. No controlas un «país abstracto»: encarnas a una **dinastía**. Tu gobernante puede
morir, casarse, tener hijos, envejecer y ser sustituido; tus decisiones económicas, diplomáticas y
militares existen para que esa casa sobreviva y prospere.

En el escenario **«Dos Coronas»** empiezas en **1337**, en vísperas de la Guerra de los Cien Años,
y juegas hasta **1399**. Hay **8 facciones jugables** en 1337: Inglaterra, Francia, el Sacro Imperio
Romano Germánico (HRE), Bohemia, Hungría, Castilla, Aragón y Polonia. Las demás facciones existen
como vecinos, aliados, rivales o amenazas.

**El bucle básico:** mira el mapa → decide economía y trabajadores → gestiona familia y corte →
negocia o espía → recluta y mueve ejércitos → termina el turno → reacciona a eventos y batallas.
Ganar no consiste en pintar el mapa de un color: consiste en que tu casa siga en el trono con
prestigio, herederos y poder suficiente.

**Fantasía de juego:** eres un soberano medieval, no un dios. La peste, las malas cosechas, las
revueltas y las traiciones ocurren; tu trabajo es anticiparlas. El **Consejero** (modo
Principiante) te guía el primer año, pero las decisiones son tuyas.

## 2. Cómo se gana y cómo se pierde

### 2.1 Condiciones de victoria (MVP-1337)

El escenario se gana de **tres formas alternativas** (basta cumplir una):

1. **Prestigio mantenido.** Alcanzar **500 de prestigio** y **mantenerlo durante 10 años
   consecutivos**. El contador se reinicia si el prestigio baja de 500; no basta con un pico.
2. **Conquista.** Controlar **al menos el 70 % de las regiones del escenario** (33 de 47).
3. **Supervivencia.** Llegar vivo al **año final (1399)** sin haber sido derrotado. Es la vía más
   defensiva: conservar el trono y el territorio también es ganar.

El prestigio se obtiene ganando batallas, cumpliendo eventos, firmando paces ventajosas y con
edificios/decisiones de corte; se pierde al ser humillado, perder guerras o sufrir revueltas.
Las **coronas/claims** (derechos dinásticos) refuerzan la legitimidad y facilitan la vía de
prestigio, pero en el MVP la comprobación de victoria es la anterior.

**Ejemplo A (prestigio):** Inglaterra empieza con casus belli sobre Francia. Gana Crécy, evita
rebeliones y llega a 500 de prestigio en 1356; si lo mantiene hasta 1366, gana.
**Ejemplo B (conquista):** Francia sobrevive a la Peste Negra, absorbe Borgoña y Bretaña y controla
33+ regiones antes de 1399; gana por conquista.
**Ejemplo C (supervivencia):** Polonia no entra en guerras, estabiliza su economía y llega a 1399
con su dinastía en el trono; gana por supervivencia.

### 2.2 Condiciones de derrota

- **Extinción dinástica:** muere tu gobernante y tu casa no tiene heredero válido (ni tutor/regente
  posible). La partida termina.
- **Pérdida total:** pierdes tu **última región**. Aunque sobreviva un familiar, sin territorio no
  hay reino.
- **Derrota militar total:** si una guerra te deja sin ejército y sin capacidad de reclutar,
  mientras el enemigo ocupa tus regiones, estás abocado a la pérdida total.

No hay «game over» por quedarte sin oro: puedes estar en bancarrota, con revueltas y deudas, y
aun así remontar. La derrota real es dinástica o territorial.

## 3. El turno: trimestres, PG y fases

### 3.1 Un año = cuatro trimestres

Cada **turno** es un trimestre. En un año hay cuatro turnos; al cerrar el cuarto se ejecuta el
**fin de año** (cosecha, natalidad/mortalidad, eventos históricos, autoguardado).

El **HUD** muestra siempre la **estación y el año**: Primavera, Verano, Otoño e Invierno se derivan
del trimestre (1-4) y el año avanza tras el invierno. La estación no es un estado nuevo: se calcula
del reloj y no afecta a guardados ni al determinismo. El mapa recibe un tinte estacional sutil,
desactivable desde Opciones si está disponible.

En tu turno gastas **Puntos de Gobierno (PG)** en órdenes y, cuando termines, pulsas
**Terminar turno**. Antes de resolver verás el repaso **«¿Confirmas tus órdenes?»** (ver §3.4).
Después se resuelven, en orden: economía trimestral, producción de mercancías, decisiones de la IA,
eventos y comprobaciones de victoria/derrota. Al cerrar cada trimestre aparece el **boletín**, y al
cerrar el año la **Crónica** (ver §3.5). Al final del cuarto trimestre se suma el **avance de año**.

### 3.2 Puntos de Gobierno (PG)

Cada trimestre recibes:

```
PG = 30 + floor(prestigio / 10) + bonus del gobernante − penalizaciones
```

- **Máximo:** 120 PG (no se acumulan de un trimestre a otro salvo el remanente que permita el
  sistema de la partida).
- **Penalización por descontento:** −2 PG por cada región con apoyo < 30.
- **Penalización por regencia:** −3 PG si gobierna un regente (heredero menor).
- El **bonus del gobernante** depende de sus stats (administración/Diplomacia/Martial).

**Costes orientativos:** asignar trabajadores 1 PG; mover ejército 1 PG; educación de un hijo 1 PG;
matrimonio 10 PG; alianza 8 PG; pacto comercial 6 PG; exigir tributo 5 PG; ofrecer tributo 3 PG;
proponer paz 4 PG; espionaje 6 PG; expedición comercial 2 PG. Declarar guerra no consume PG, pero
sin **casus belli** cuesta prestigio.

**Límite de acciones y exenciones:** las acciones de corte y diplomacia suelen estar limitadas a
una por turno cuando el sistema lo indica. En cambio, **reclutar, entrenar y disolver**, así como
**asignar trabajadores** y **operar en el mercado**, son acciones libres: puedes repetirlas varias
veces en el mismo turno mientras tengas oro, PG, pool y mercancías. El repaso de órdenes (§3.4)
señala estas exenciones para que no las confundas con el límite general.

### 3.3 Fases del turno

1. **Gobierno/economía:** trabajadores, edificios, impuestos y mercado.
2. **Familia:** matrimonios, educación, consorte, decisiones dinásticas.
3. **Diplomacia:** relaciones, pactos, tributos, guerra/paz, espionaje.
4. **Militar:** reclutar, entrenar, disolver, mover ejércitos y resolver batallas.
5. **Fin de turno:** economía trimestral, IA, eventos y comprobaciones.
6. **Fin de año:** cosecha (modificador 0,85-1,15), natalidad/mortalidad, eventos anuales,
   Peste Negra si corresponde y autoguardado.

**Consejo:** no gastes todos los PG en la primera pantalla. Guarda 2-3 PG para reaccionar a una
batalla o a una oportunidad diplomática.

### 3.4 «¿Confirmas tus órdenes?» (Fase 5A)

Al pulsar **Terminar turno**, el juego no resuelve de inmediato: abre el repaso **«Tus órdenes este
trimestre»**, con la lista de acciones realizadas y su coste en PG. Si no has dado órdenes, verás
«No has dado órdenes este trimestre».

- **Corregir:** cierra el repaso y vuelve al mapa sin resolver nada; puedes cambiar de idea.
- **Confirmar:** resuelve el trimestre (economía, IA, eventos, etc.).
- **Exenciones visibles:** reclutar/entrenar/disolver, asignar trabajadores y operar en el mercado
  son libres y pueden repetirse; el repaso las marca como tales para que no las confundas con las
  acciones limitadas a una por turno.
- El registro de órdenes es transitorio (se reinicia al empezar turno) y **no consume RNG**; no
  altera el guardado ni el balance.

### 3.5 Boletín trimestral, Crónica anual e histórico (Fase 5A)

- **Boletín trimestral:** al cerrar cada trimestre aparece un resumen encabezado por **«Ha terminado
  el {estación} de {año}»** con seis categorías: ingresos/gastos, apoyo popular, acciones usadas,
  nacimientos/muertes, mercaderes/expediciones y eventos. Se genera del estado (sin RNG) y se cierra
  con **Continuar**.
- **Crónica anual:** al cerrar el año aparece la **«Crónica del año {año}»** con el balance
  económico (oro, ingresos y gastos), bienes producidos, eventos, guerras declaradas/terminadas y el
  **ranking de prestigio de las 8 facciones jugables**.
- **Histórico:** cada entrada se guarda en `state.chronicle` y se **persiste en save/load**; puedes
  consultarla en cualquier momento desde la pestaña **Crónica** del Consejo. Las partidas antiguas
  sin Crónica arrancan con una lista vacía, sin romper la carga. La Crónica es memoria, no una
  mecánica: no cambia el estado ni consume RNG.

### 3.6 Guardar y cargar (multislot + autoguardado, Fase 5B)

- **Guardar:** desde el mapa/HUD o el menú principal, con **3 ranuras manuales** (`slot_1` a
  `slot_3`) y el **autoguardado**. Cada ranura muestra año, trimestre, facción y fecha; si
  sobrescribes, el juego pide confirmación y da feedback.
- **Autoguardado:** se actualiza **después de cada turno resuelto** (nunca antes de confirmar) y
  **nunca sobrescribe tus ranuras manuales**. Sigue siendo cargable desde el menú principal.
- **Cargar:** elige una ranura o el autoguardado; el formato `save_version` no cambia y las partidas
  antiguas siguen cargando con defaults. Guarda antes de una guerra o una decisión irreversible.

## 4. Economía, mercancías y comercio

### 4.1 Regiones, población y riqueza

Cada región tiene **población**, **riqueza base**, **terreno** (llanura, bosque, montaña, costa,
ciudad), **edificios** y **apoyo popular** (0-100). La población determina cuánta mano de obra
tienes; la riqueza determina impuestos y comercio; el terreno determina comida y producción.

**Trabajadores:** la mano de obra total es aproximadamente `población / 200`. Se reparte por
defecto en **55 % granjeros, 20 % artesanos, 15 % comerciantes y 10 % reclutas** (pool militar).
Puedes reasignar trabajadores (1 PG). Más granjeros = más comida y apoyo; más artesanos =
más bienes; más comerciantes = más oro de comercio; más reclutas = más reemplazos militares.

**Ingresos trimestrales** (resumen):
- **Impuestos:** proporcionales a riqueza × población.
- **Bienes:** artesanos × edificios (taller/mercado).
- **Comercio:** comerciantes × rutas (mercado/ciudad) × prosperidad.
- **Mantenimiento:** 20 de oro por cada 200 hombres de ejército y trimestre, más un recargo si
  tu tesoro supera los 8.000 (35 % del exceso por trimestre). No acumules oro sin usarlo: invierte
  en edificios, reclutamiento o mercancías.

**Propiedad de la región:** solo el **reino propietario** puede asignar trabajadores, construir y
tomar decisiones internas en su territorio. En una región ajena el panel sigue mostrando población,
riqueza y edificios, pero los controles están desactivados con el aviso «Solo el reino propietario
puede asignar trabajadores»; la IA también opera solo sobre sus propias regiones. Esto evita
cambiar el rumbo de un reino que no gobiernas.

### 4.2 Apoyo, cosecha y revueltas

El **apoyo** sube con comida excedentaria y riqueza, y baja con déficit alimentario, guerra y
reclutamiento excesivo. Con apoyo bajo (< 20) hay riesgo de **revuelta**: la región puede perder
oro, prestigio y control. Las montañas reciben un bonus de apoyo (D-068) para no ser ingobernables,
pero siguen siendo frágiles.

La **cosecha** anual varía entre 0,85 y 1,15; una mala cosecha puede convertir un superávit en
hambruna. Mantén un colchón de grano y no dependas de una sola región.

### 4.3 Edificios

Los edificios se construyen en regiones y modifican producción, defensa o apoyo: **granero**
(comida), **taller** (bienes), **mercado** (comercio/precios), **murallas/castillo** (defensa),
**puerto** (comercio), **universidad** (educación/tecnología), **catedral** (prestigio/apoyo),
**mina** (hierro/sal). Construir cuesta oro y a veces PG; elige según el terreno y tu estrategia.

### 4.4 Mercancías (nuevo en Fase 4)

Hay **10 mercancías**: especias, pieles, lana, vino, sal, grano, armas, caballos, hierro y madera.
Cada una tiene un **precio base** y se produce según el terreno/edificios de tus regiones:

| Bien | Precio base | Se produce en | Uso principal |
|---|---:|---|---|
| Grano | 10 | llanura + granero | alimento/apoyo |
| Madera | 15 | bosque | comercio/artillería |
| Sal | 20 | costa + mina | alimento/apoyo |
| Lana | 25 | llanura + taller | comercio |
| Pieles | 30 | bosque + mercado | lujo/comercio |
| Vino | 35 | llanura + mercado | lujo/comercio |
| Hierro | 50 | montaña + mina | comercio/artillería |
| Armas | 60 | ciudad + taller | reclutamiento |
| Caballos | 70 | llanura | reclutamiento de caballería |
| Especias | 80 | costa/ciudad + mercado | lujo/comercio |

**Inventario:** cada facción acumula mercancías de sus regiones cada trimestre. El inventario es
serializable (se guarda en la partida).

**Mercado y comerciantes:** solo puedes comprar/vender si tienes **comerciantes asignados**
(> 0). El volumen por trimestre depende de ellos (≈5 unidades por comerciante). Los precios parten
del precio base y suben si el bien escasea; hay un pequeño factor aleatorio determinista por
semilla. **Sin comerciantes no hay comercio**, aunque tengas oro.

**Consejero comercial (Fase 5A):** el Mercado incorpora un consejo calculado del estado real, sin
RNG: compara el precio actual con el precio base y el inventario/volumen disponible, y te sugiere
la operación con mejor margen (por ejemplo, «El {bien} está caro hoy: conviene vender») o te avisa
de cuándo vuelve una expedición. Es una recomendación, no una orden: la decisión y el coste son
tuyos.

**Pactos y expediciones:** un **pacto comercial** mejora el comercio y las relaciones; una
**expedición de mercaderes** cuesta 2 PG, envía un bien y vuelve a los **2 trimestres** con
beneficio (o pérdida) según el resultado. Las expediciones son una apuesta: no envías todo tu grano.

**Consumo:** grano y sal sostienen el apoyo; **armas** y **caballos** se consumen al reclutar
(ver §7). Vender armas o caballos puede salvar una tesorería, pero te deja sin reemplazos.

### 4.5 Impuestos y tesorería

Los impuestos llegan cada trimestre. Si subes impuestos, ganas oro pero baja el apoyo; si los
bajas, ganas estabilidad pero pierdes ingresos. El tesoro por encima de 8.000 paga un recargo:
invertir el exceso en edificios, ejército o mercancías suele ser mejor que acumularlo.

### 4.6 Expedición de mercaderes (Fase 5B)

La **expedición de mercaderes** es una operación de comercio exterior de varios trimestres:

1. **Asigna comerciantes** en el Mercado (sin comerciantes no hay expedición).
2. Elige un **bien** de tu inventario y una **cantidad**; revisa el coste y el retorno estimado.
3. Paga **2 PG** y confirma. La expedición **vuelve a los 2 trimestres** con beneficio o pérdida
   según el resultado; puedes ver las expediciones activas y su trimestre de retorno en el Mercado.

El botón se deshabilita con un motivo claro si faltan comerciantes, el bien o PG. No envía todo tu
grano ni tus armas: una expedición es una apuesta comercial, no un ingreso garantizado. El envío no
consume RNG de la partida; el resultado se calcula con las reglas de comercio.

## 5. Familia, sucesión y Peste Negra

### 5.1 Matrimonio y fertilidad

Puedes casar a tu gobernante o a tus hijos con una facción vecina (coste 10 PG y relaciones). El
matrimonio mejora relaciones, puede crear claims y permite tener hijos. La fertilidad depende de la
edad y del estado de salud del consorte; los hijos nacen con stats heredadas y se educan.

### 5.2 Educación y herederos

La **educación** de un hijo cuesta 1 PG por acción y mejora sus stats (administración, diplomacia,
militar). Un heredero bien educado gobierna mejor y reduce el riesgo de regencia. Designa un
heredero claro; si no hay heredero vivo, la casa puede extinguirse.

### 5.3 Sucesión y regencia

Cuando muere el gobernante, hereda el **heredero** (hijo, pariente o designado). Si es menor de
edad, gobierna un **regente** con penalización de −3 PG y riesgo de facciones. Una sucesión
disputada puede costar prestigio y apoyo. Mantén al menos un heredero vivo y, si puedes, dos.

### 5.4 Acción «Pasar tiempo con la consorte» (nuevo)

En el árbol familiar puedes **pasar tiempo con tu consorte** una vez por trimestre:
- Requiere consorte **viva, no enferma y en edad fértil**.
- Cuesta **2-3 PG** y otorga un **bonus de fertilidad durante los siguientes 2-4 trimestres**,
  además de un pequeño prestigio/relación.
- Si no hay consorte válida, la acción se rechaza con un motivo claro y **no rompe el estado**.

Úsala cuando necesites asegurar la sucesión; no la desperdicies si ya tienes varios herederos.

### 5.5 Peste Negra y mortalidad

En **1348** llega la **Peste Negra**: las regiones de Europa occidental pierden ~35 % de población
y apoyo (−10); en **1350** hay un rebrote (~10 % adicional). La peste también puede matar parientes
(la dinastía no es inmune): `DynastySystem` aplica mortalidad y enfermedad, pero **nunca mata al
gobernante/heredero/cónyuge de forma arbitraria** en el mismo evento. Después de la peste, la mano
de obra escasea: reasigna trabajadores y no reclutes de más.

## 6. Diplomacia y espionaje

### 6.1 Relaciones

Cada pareja de facciones tiene una relación de **−100 a +100**. Las relaciones mejoran con
matrimonios, regalos, pactos y paces; empeoran con guerras, espionaje descubierto y tributos
humillantes. Una relación muy baja facilita que la IA te declare la guerra.

### 6.2 Las 7 acciones diplomáticas

| Acción | PG | Cuándo usarla | Contra quién |
|---|---:|---|---|
| **Alianza** | 8 | Buscas seguridad o un socio contra un tercero | Vecino con relación positiva |
| **Matrimonio** | 10 | Quieres mejorar relaciones, claims y fertilidad | Casa rival o aliada |
| **Pacto comercial** | 6 | Aumentar comercio y relaciones | Socio con rutas |
| **Exigir tributo** | 5 | Eres más fuerte y quieres oro/prestigio | Débil, relación baja |
| **Ofrecer tributo** | 3 | Comprar paz o tiempo | Agresor o aliado |
| **Declarar guerra** | 0 | Tienes casus belli y ventaja militar | Objetivo débil o aislado |
| **Proponer paz** | 4 | La guerra se estanca o te conviene cerrar | Enemigo agotado |

**Casus belli:** sin un motivo (claim, evento, agresión previa), declarar la guerra cuesta
prestigio y empeora relaciones. El evento de **1337** concede a Inglaterra casus belli sobre
Francia; aprovéchalo o prepárate.

### 6.3 Espionaje

El **espionaje** cuesta 6 PG y puede revelar información (ejército, tesoro, planes) o sabotear
relaciones. Si te descubren, pierdes prestigio y relaciones. Úsalo contra rivales fuertes antes de
una guerra, no contra aliados.

## 7. Militar y los tres niveles de batalla

### 7.1 Reclutar, entrenar y disolver

**Reclutar** consume:
- **Oro** (coste de la unidad × bloques de 200 hombres).
- **Pool de reclutas** de la región (población reclutable).
- **Mercancías** (`recruit_goods` por bloque): caballería → **caballos**; infantería pesada a pie
  → **armas**; artillería → **hierro/madera**. Si falta el bien, el reclutamiento falla con motivo
  `missing_goods` y **no gasta oro ni crea ejército**.

**Entrenar** sube la experiencia del ejército (hasta 100) a cambio de oro (10 por bloque) y 1 PG
por acción; más experiencia = mejor rendimiento en batalla.
**Disolver** devuelve el **50 % del oro** de la unidad y libera el pool; útil para reducir
mantenimiento, pero pierdes veteranía.

**Mantenimiento:** 20 de oro por cada 200 hombres y trimestre. Un ejército enorme puede arruinar
tu economía; entrena y concentra fuerzas en lugar de reclutar sin límite.

### 7.2 Los tres niveles de batalla

1. **Nivel 1 — resolución delegada:** la IA/automático resuelve la batalla con tus stats, terreno y
   composición. Rápido; ideal cuando tienes clara ventaja o no quieres microgestión. Genera informe.
2. **Nivel 2 — táctica:** despliegas unidades en un mapa táctico, eliges formación y objetivos.
   Más control que N1; útil en batallas igualadas.
3. **Nivel 3 — combate cerrado:** luchas ronda a ronda, unidad a unidad, con flanqueos, moral y
   ataques. Máximo control y detalle; úsalo en batallas decisivas o cuando necesites exprimir una
   victoria.

**Panel de unidad (N2/N3):** al seleccionar una unidad, la tarjeta muestra **hombres, armamento
(armas), apoyo/suministro, moral y entrenamiento (experiencia)**, además del **comandante**, su
estado (**sano/herido/muerto**) y su stat de **Mando**. En N2 lo usarás para desplegar y elegir
objetivos; en N3, para decidir flancos y ataques ronda a ronda. Es solo lectura del estado: no
cambia el balance ni la simulación.

**Cuándo elegir:** N1 para limpiar rebeldes o ventajas abrumadoras; N2 para la mayoría de guerras;
N3 para batallas que cambian la partida (Crécy, Poitiers, asedios clave) o cuando quieras aprender
el sistema. Puedes cambiar de nivel en distintas batallas; no estás obligado a uno solo.

**Contras básicas:** caballería pesada rompe infantería ligera; piqueros/schiltron frenan
caballería; arqueros castigan formaciones lentas; artillería es lenta pero devastadora contra
muros. El terreno importa: bosque/colina penalizan caballería, montaña favorece defensa.

### 7.3 Atacar y declarar la guerra (Fase 5B)

El flujo **Militar → Atacar** sustituye al viejo «mover y esperar»:

1. Elige una **región objetivo adyacente que no sea tuya**; si es de un aliado, el juego lo avisa y
   no permite atacar sin romper la alianza.
2. Selecciona **uno o varios ejércitos elegibles** (en una región adyacente y con movimiento). El
   resumen muestra el coste total en PG y el aviso de guerra.
3. Al confirmar, si **no estabas en guerra** con el propietario, el juego **declara la guerra
   automáticamente** (`begin_hostilities`), aplicando el **casus belli** o la **pérdida de
   prestigio** vigente. Si ya había guerra, simplemente ataca.
4. Los ejércitos se mueven en orden y las batallas se resuelven con las fórmulas actuales; verás el
   resultado por ejército y el enlace al **informe de batalla** si hay defensores.

Las acciones militares siguen siendo **repetibles** en el turno (D-074): puedes atacar varias
regiones o con varios grupos si tienes PG y ejércitos elegibles. Atacar sin casus belli no es
gratis: revisa la diplomacia antes de lanzar la primera ofensiva. Este flujo no cambia el balance,
las fórmulas de combate ni la IA; solo hace visible y confirmable lo que el motor ya resolvía.

## 8. IA, dificultades y eventos históricos

### 8.1 Dificultades

- **Principiante:** el **Consejero** te guía con el tutorial del primer año y la IA tiene una
  agresividad reducida (multiplicador tunable, ~0,75). Recomendado para la primera partida.
- **Normal:** sin Consejero y con agresividad de IA estándar (1,0). La IA usa las mismas reglas que
  tú: no hace trampas de recursos.

El **Consejero** aparece como panel lateral con avatar heráldico generado por código; resalta el
elemento de UI del paso actual, avanza cuando cumples la condición y puedes **saltarlo** en
cualquier momento. El estado (`active`, `step_index`, `completed`, `skipped`) se guarda con la
partida.

### 8.2 Personalidades de la IA

Cada facción tiene un perfil (agresivo, diplomático, expansionista, comerciante…). La IA prioriza
supervivencia, economía y objetivos históricos; declara guerras si detecta debilidad o tiene casus
belli. No esperes pasividad: si tu ejército desaparece y tu tesoro está vacío, serás un objetivo.

### 8.3 Eventos históricos (1337-1399)

Los eventos ocurren en su año si se cumplen las condiciones (algunos requieren guerra activa):

| Año | Evento | Efecto principal |
|---:|---|---|
| 1337 | Guerra de los Cien Años | Casus belli Inglaterra→Francia; relación −60 |
| 1340 | Batalla de Sluys | Prestigio inglés; relación −10 (requiere guerra) |
| 1346 | Crécy | Bajas francesas; prestigio inglés (requiere guerra) |
| 1347 | Sitio de Calais | Prestigio inglés; oro francés (requiere guerra) |
| **1348** | **Peste Negra** | Población −35 % en Europa occidental; apoyo −10 |
| 1350 | Rebrote de peste | Población −10 % |
| 1356 | Poitiers | Bajas francesas; prestigio inglés (requiere guerra) |
| 1358 | Jacquerie | Apoyo/población/oro francés |
| 1360 | Paz de Brétigny | Paz anglo-francesa; prestigio inglés |
| 1366 | Guerra civil castellana | Apoyo/bajas castellanas |
| 1367 | Nájera | Bajas castellanas; prestigio inglés |
| 1369 | Reanudación de la guerra | Nuevo casus belli inglés |
| 1371 | Maritsa | Apoyo balcánico; prestigio bizantino |
| 1378 | Cisma de Occidente | Prestigio papal; relación con Francia; apoyo europeo |
| 1378 | Revuelta de los Ciompi | Apoyo/oro en Toscana |
| 1381 | Revuelta campesina | Apoyo/oro inglés |
| 1389 | Kosovo | Apoyo balcánico; prestigio húngaro |
| 1396 | Nicópolis | Bajas húngaras; prestigio húngaro |

No todos los eventos se ven en todas las partidas: los de guerra dependen de que esa guerra ocurra.
El **evento de 1337** deja a Inglaterra y Francia en tensión; en 1337 el escenario ya tiene la
guerra anglo-francesa activa para que la cadena histórica pueda dispararse en una partida pasiva.

## 9. Consejos por facción (8 jugables de 1337)

### Inglaterra (Edward III)
- **Fortalezas:** arqueros largos, casus belli sobre Francia, ejército inicial veterano.
- **Estrategia:** usa Crécy/Sluys para ganar prestigio; protege Aquitania; no abras un segundo
  frente con Escocia sin paz. Invierte en arqueros y mercados; vende lana si necesitas oro.
- **Riesgo:** la Peste Negra y la revuelta de 1381 golpean apoyo y población.

### Francia (Philip VI)
- **Fortalezas:** la mayor población y economía; caballería pesada; corazón territorial.
- **Estrategia:** aguanta el primer choque inglés, evita batallas campales hasta reforzar; usa
  diplomacia para aislar a Inglaterra. Construye graneros/mercados y no desperdicies la ventaja
  económica en ejércitos sin entrenar.
- **Riesgo:** derrotas en Crécy/Poitiers y la Jacquerie; dos frentes (Flandes/Inglaterra).

### Sacro Imperio (Louis IV)
- **Fortalezas:** muchas regiones, diversidad económica, prestigio imperial.
- **Estrategia:** juega diplomático; no puedes defender todo. Prioriza Austria/Baviera, usa
  alianzas y evita guerras largas. Vende excedentes y construye minas/talleres.
- **Riesgo:** apoyo en montaña y revueltas; elecciones y divisiones internas.

### Bohemia (John of Bohemia)
- **Fortalezas:** Praga, plata/industria, posición central; caballería.
- **Estrategia:** enriquece Bohemia y evita guerras lejanas; usa matrimonios y prestigio. Es una
  facción ideal para la victoria por supervivencia/prestigio.
- **Riesgo:** vecinos fuertes (HRE, Hungría, Polonia); no sobrexpongas al gobernante.

### Hungría (Charles Robert)
- **Fortalezas:** caballería ligera, frontera balcánica, espacio de expansión.
- **Estrategia:** expansión controlada hacia los Balcanes; mantén grano y apoyo en las montañas;
  evita guerras en dos frentes. Los eventos de Maritsa/Kosovo/Nicópolis castigan al que se expone.
- **Riesgo:** apoyo en Transilvania/Croacia y presión otomana futura.

### Castilla (Alfonso XI)
- **Fortalezas:** población, jinetes, frontera con Granada; oportunidad de reconquista.
- **Estrategia:** usa caballería ligera y guerra de frontera; no te metas en la guerra anglo-
  francesa salvo por interés claro. Desarrolla comercio atlántico y consolidación interna.
- **Riesgo:** guerra civil castellana (1366) y Nájera (1367).

### Aragón (Peter IV)
- **Fortalezas:** almogávares, comercio mediterráneo, Sicilia/Cerdeña/Valencia.
- **Estrategia:** prioriza comercio y mercenarios; evita guerras terrestres largas. Los almogávares
  son excelentes infantería; protege las rutas marítimas.
- **Riesgo:** dispersión territorial y revueltas; enemigos en Italia/Mediterráneo.

### Polonia (Casimir III)
- **Fortalezas:** caballería ligera, expansión hacia el este, economía emergente.
- **Estrategia:** crece económicamente, evita HRE/Teutónicos hasta estar listo; usa matrimonios y
  diplomacia. Es fuerte en victoria por supervivencia; cuida la sucesión (no hay heredero claro en
  1337).
- **Riesgo:** Teutónicos, HRE y falta de heredero; no inicies guerras sin ejército entrenado.

## 10. Glosario

- **Apoyo popular:** 0-100; mide lealtad de una región. Bajo → revueltas.
- **Casus belli:** motivo legítimo para declarar guerra; sin él, cuesta prestigio.
- **Claim/corona:** derecho dinástico sobre un título o región; refuerza legitimidad.
- **Consorte:** cónyuge del gobernante; afecta fertilidad, relaciones y sucesión.
- **Edificio:** mejora regional (granero, taller, mercado, murallas, puerto, universidad…).
- **Era:** periodo tecnológico; en 1337 solo unidades de era I.
- **Expedición comercial:** envío de mercancías (2 PG) que vuelve a los 2 trimestres.
- **Heredero:** personaje que hereda el trono; si no hay, riesgo de extinción.
- **Inventario:** mercancías acumuladas por facción.
- **Mercancía:** bien comercializable (grano, sal, lana, vino, armas, caballos…).
- **N1/N2/N3:** niveles de batalla (delegada, táctica, combate cerrado).
- **PG (Puntos de Gobierno):** recurso para órdenes cada trimestre.
- **Prestigio:** reputación dinástica; victoria si 500 mantenido 10 años.
- **Recluta (pool):** población disponible para convertirse en soldado.
- **Regencia:** gobierno temporal de un regente si el heredero es menor.
- **Revuelta:** rebelión regional por apoyo bajo; puede costar oro/prestigio.
- **Soberanía/control:** porcentaje de regiones controladas; victoria al 70 %.
- **Turno:** un trimestre; cuatro por año.
- **Vasallo/aliado:** facción con pacto; no es un subordinado automático, hay que negociar.

## 11. Ayuda en el juego

La Fase 5A añade varias formas de consultar las reglas sin salir de la partida:

- **Manual:** botón **Manual** del menú principal; abre este documento con `OS.shell_open`. Si el
  sistema no puede abrirlo, muestra un aviso y puedes consultarlo desde `docs/`.
- **Ayuda del Consejo:** entrada **Ayuda** en el menú del Consejero, con un resumen rápido y acceso
  al manual.
- **Botón «?» contextual:** cada pantalla del juego (menú, mapa, región, consejo, familia,
  diplomacia, militar, economía, mercado, gestión de ejércitos, batallas N1/N2/N3, fin de año,
  crónica, opciones y victoria) tiene un botón **?** que abre **3-5 líneas de ayuda** adaptadas de
  este manual. El contenido vive en `data/context_help.json`; es original, está en español y no
  depende de RNG. Cerrar la ayuda no altera la partida.
- **Consejero durante la partida:** puedes activarlo o desactivarlo desde el Consejo. En
  Principiante viene activo por defecto; en Normal puedes activarlo cuando quieras. El Consejero
  comercial del Mercado (§4.4) es independiente y calcula su consejo del estado real.
- **Boletín y Crónica** (§3.5) son también ayuda de lectura: resumen lo ocurrido y guardan el
  histórico consultable.

La ayuda contextual usa las mismas claves de pantalla que la UI y el manual:
`main_menu`, `scenario_select`, `world_map`, `region_panel`, `council`, `family`, `diplomacy`,
`military`, `economy`, `market`, `army_management`, `battle_n1`, `battle_n2`, `battle_n3`,
`year_end`, `chronicle`, `options` y `victory`. Si una pantalla nueva no tiene ayuda, se muestra un
texto genérico y se puede ampliar el JSON sin tocar código.

---

*Manual del MVP-1337 (D-072, actualizado en Fase 5A por C11/D-079…D-083 y en Fase 5B por
D-084…D-089). Para el detalle técnico de sistemas, consulta `docs/architecture_contracts_fase4.md`,
`docs/architecture_contracts_fase5a.md` y `docs/architecture_contracts_fase5b.md`; para el tutorial,
`data/tutorial_script.json` (D-073/D-088); para la ayuda contextual, `data/context_help.json` y
`data/legibility_texts.json`. Si una cifra de balance cambia en un parche, se actualizará este
manual en la misma entrega.*
