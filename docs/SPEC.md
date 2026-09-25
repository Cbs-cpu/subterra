# SUBTERRA — Spec (clon jugable de *Magicite*)

> **Qué es:** un clon mecánicamente fiel de *Magicite* (SmashGames / Sean Young, Steam, 2014): roguelike de plataformas 2D en vista lateral, con recolección, crafteo combinando objetos de dos en dos, hambre, estadísticas RPG, elección de bioma en cada distrito, pueblos seguros entre distritos, desbloqueos permanentes y cooperativo de hasta 4 jugadores.
> **Motor:** Godot 4.6.3 · GDScript · desarrollo asistido con el MCP de Godot.
> **Título de trabajo:** *Subterra* (renombrable).
> **Regla de originalidad (innegociable):** se clonan **las mecánicas, los sistemas, la estructura y los números** (que no son protegibles), pero **todo el arte, los nombres propios, los textos, el lore, la música y el sonido son originales**. No se copia ni un sprite, texto o nombre propio del juego original. Cada elemento de esta spec indica, a título de referencia de diseño, a qué elemento del original equivale.

---

## Problem Statement

Quiero volver a jugar a algo que se sienta exactamente como *Magicite*: el bucle de "talar, minar, combinar dos cosas en el inventario para fabricar algo mejor, bajar un distrito más y elegir por qué puerta sigo", con la tensión del hambre y de los guardianes que te persiguen si te entretienes. El juego original está abandonado desde hace años, no tiene más contenido ni soporte, y no encaja con lo que quiero ahora (sprites más cuidados, movimiento más fluido y un proyecto propio que pueda ampliar). Del prototipo anterior (*La Gran Presa*) aprendí que el pixel art "correcto" y el movimiento básico no bastan: los personajes necesitan más fotogramas y el control tiene que responder con suavidad.

## Solution

**Subterra** reproduce el juego completo de *Magicite* con identidad propia:

- **Vista lateral, plataformas** con salto variable, doble salto y dash con estamina.
- **Mundo subterráneo** ("Hondura") amenazado por **la Ceniza**, una corrupción que avanza desde abajo. Los habitantes, expulsados de la Superficie, luchan por sobrevivir. *(Equivale a Deephaven y el Scourge.)*
- **20 distritos generados proceduralmente + el Nido de Ceniza** (distrito 21, jefe final). Cada distrito termina en **3 puertas de colores**, y cada una lleva a un bioma distinto. Entre distritos hay un **pueblo seguro** con tiendas, artesanos, un comprador de objetos, altares y gallinas.
- **9 biomas + el Nido**, cada uno con sus trampas ambientales, enemigos y jefes.
- **Crafteo combinando dos objetos** del inventario (Mayús + clic en ambos). Hay cadenas de materiales, calidades de objeto (normal, azul, amarilla, morada) y durabilidad.
- **Estadísticas** (Vida, Ataque, Destreza, Magia), subidas de nivel, **habilidades cada 5 niveles** (máximo 3, con teclas Z, X y C), **2 rasgos** a elegir al crear el personaje, **hambre**, estamina y maná.
- **Metaprogresión:** 15 razas, más de 20 sombreros y 9 compañeros que se desbloquean cumpliendo retos, con recompensa al terminar la partida.
- **Modos:** Normal y **Demente** (difícil). **Cooperativo** online de 1 a 4 jugadores: solo se pierde cuando cae todo el grupo y se puede revivir a los compañeros.
- **Calidad por encima del original:** personajes de 16×24 px con 6–10 fotogramas por animación, movimiento con aceleración, tiempo de coyote, búfer de salto y squash & stretch, cámara suave con mira de ratón e interpolación de física.

---

## User Stories

### Crear personaje e inicio
1. Como jugador, quiero crear un personaje eligiendo **raza, sombrero, compañero y 2 rasgos**, para planificar mi partida.
2. Como jugador, quiero ver en la pantalla de creación los efectos y el **requisito de desbloqueo** de cada raza, sombrero y compañero bloqueado, para saber qué perseguir.
3. Como jugador, quiero que mis estadísticas iniciales se generen al azar (15 puntos, Vida 4–6 y el resto 2–4) y poder **re-tirarlas** con un botón, para buscar un reparto que me guste.
4. Como jugador, quiero ver qué estadísticas tienen **crecimiento alto, normal o bajo** (verde, blanco o rojo), para anticipar cómo evolucionará mi personaje.
5. Como jugador, quiero ponerle **nombre** a mi personaje (y que ciertos nombres secretos desbloqueen cosas), para personalizarlo y descubrir secretos.
6. Como jugador, quiero cambiar los rasgos pulsándolos (clic izquierdo avanza, derecho retrocede), sin poder repetir uno, para elegir rápido.
7. Como jugador, quiero elegir modo **Normal** o **Demente**, para ajustar el reto.
8. Como jugador, quiero empezar en el **distrito 1 (Bosque Hundido)** con el equipo inicial de mi raza, para arrancar de inmediato.

### Movimiento y control (más fluido que el original)
9. Como jugador, quiero moverme con A y D con aceleración y frenada suaves, para un control preciso y agradable.
10. Como jugador, quiero un **salto variable** (más alto si mantengo Espacio) y un **doble salto** que gasta 1 de estamina, para dominar el plataformeo.
11. Como jugador, quiero **tiempo de coyote** (saltar justo después de salir de un borde) y **búfer de salto** (pulsar un poco antes de aterrizar), para que el salto nunca se "coma".
12. Como jugador, quiero hacer **dash** con Q y E (1 de estamina), más largo en el aire que en el suelo, para esquivar y cruzar huecos.
13. Como jugador, quiero una **barra de estamina** cuyo máximo depende de la Destreza y que se recupera con el tiempo, para gestionar saltos y dashes.
14. Como jugador, quiero atravesar **plataformas de un solo sentido** hacia arriba y bajar de ellas pulsando S, para moverme en vertical con libertad.
15. Como jugador, quiero que **mover el ratón desplace la cámara** en esa dirección (mira), para ver amenazas arriba y abajo.
16. Como jugador, quiero una cámara que siga con suavidad, sin temblores ni saltos de píxel, para que el juego se vea fluido.
17. Como jugador, quiero animaciones de **reposo, correr, saltar, caer, aterrizar, dash, atacar, recibir daño y morir**, con estiramiento y aplastamiento, para que el personaje se sienta vivo.
18. Como jugador, quiero que **caer encima de un enemigo me haga daño** (no es un plataformas clásico), para respetar las reglas del original.
19. Como jugador, quiero unos instantes de invulnerabilidad con parpadeo tras recibir daño, y un pequeño retroceso, para leer el impacto.

### Recolección
20. Como jugador, quiero **talar árboles** con el hacha para obtener madera y palos, para empezar a craftear.
21. Como jugador, quiero **minar rocas y vetas** con el pico: piedra, carbón y minerales según la calidad del pico, para progresar en materiales.
22. Como jugador, quiero que la calidad del pico limite qué puedo minar (madera → piedra → hierro → oro → diamante → cristal de ceniza), para tener una progresión clara.
23. Como jugador, quiero **segar matas de hierba** para encontrar hierbas, setas y raíces, para fabricar pociones.
24. Como jugador, quiero cazar **animales pasivos** (cerdos, ovejas, conejos, gallinas) para conseguir carne, monedas y experiencia gratis, para sobrevivir al hambre.
25. Como jugador, quiero **capturar bichos elementales** (fuego, hielo y rayo) de las luces flotantes con una red, para fabricar gemas y bastones.
26. Como jugador, quiero que los enemigos suelten **pieles, cueros, huesos y telarañas**, para fabricar equipo y cuerda.
27. Como jugador, quiero que cada herramienta tenga **durabilidad** y se rompa al llegar a 0, para gestionar recursos.

### Inventario y crafteo
28. Como jugador, quiero abrir el **inventario con R** y ver una rejilla de ranuras y una **barra rápida**, para organizar mis objetos.
29. Como jugador, quiero **combinar dos objetos** manteniendo Mayús y haciendo clic en ambos, para craftear el resultado.
30. Como jugador, quiero **dividir montones** y colocar de uno en uno con clic derecho, para gestionar cantidades.
31. Como jugador, quiero montones de hasta **99 unidades**, para acumular materiales.
32. Como jugador, quiero las cadenas de recetas básicas: madera + madera = tablón; tablón + tablón = hoja de madera; palo + tablón = empuñadura; palo + palo = mango de hacha; palo + mango de hacha = mango de pico; hoja + mango = hacha, pico o espada, para fabricar mis primeras herramientas.
33. Como jugador, quiero fabricar **lingotes** (material + material), **hojas** (lingote + lingote), **grandes hojas** (hoja + hoja) y **grandes hachas** (gran hoja + mango de hacha), para mejorar mis armas.
34. Como jugador, quiero fabricar **cuerda** (telaraña ×2), **red** (cuerda ×2), **red para bichos** (red + palo), **arco sin tensar** (mango de pico + palo) y **arco** (arco sin tensar + cuerda), para cazar bichos y disparar.
35. Como jugador, quiero fabricar **flechas** (lingote + palo = 5 flechas) de hueso, piedra, hierro, oro y diamante, y **recuperarlas** si fallan, para tener munición.
36. Como jugador, quiero fabricar **gemas** (dos bichos iguales) y **bastones** (gema + palo), y **espadas elementales** (espadón especial + gema), para usar magia.
37. Como jugador, quiero fabricar **pociones**: hierba ×2 = vida (2 de Vida), seta ×2 = maná (3 de maná), hierba + seta o raíz = misteriosa, y poción + poción iguales = grande (5 de Vida o 7 de maná), para curarme.
38. Como jugador, quiero **pociones misteriosas** que curan o envenenan (y se vuelven veneno tras varios usos) y que puedo **lanzar** contra enemigos, para tener una opción arriesgada.
39. Como jugador, quiero fabricar un **encendedor** (carbón + carbón o piedra) para **cocinar carne**, que quita más hambre y puede curar, para alimentarme mejor.
40. Como jugador, quiero fabricar **tambores** (cuero refinado + tablón) y **tambores de mejora** (tambor + bicho), que dan bonificaciones temporales, para prepararme ante un jefe.
41. Como jugador, quiero que al craftear armas y equipo haya probabilidad de **calidad superior** (azul, amarilla o morada) con bonificaciones extra de Vida, Ataque, Destreza o Magia, influida por la Suerte, para que craftear sea emocionante.
42. Como jugador, quiero un **libro de recetas** que registre las combinaciones que ya he descubierto, para no tener que memorizarlas.
43. Como jugador, quiero **tirar** objetos al suelo y recogerlos, para gestionar el espacio.

### Combate
44. Como jugador, quiero atacar con **clic izquierdo** usando el objeto que tenga en la mano, hacia donde apunta el ratón, para combatir con precisión.
45. Como jugador, quiero que **las espadas** sean rápidas y **las grandes hachas** lentas pero más fuertes, para elegir estilo.
46. Como jugador, quiero que el daño cuerpo a cuerpo dependa del **Ataque + el arma**, el de los arcos de la **Destreza + la flecha** y el de los bastones de la **Magia**, para que mis estadísticas definan mi estilo.
47. Como jugador, quiero **golpes críticos** (base baja, mejorable con equipo), para tener picos de daño.
48. Como jugador, quiero bastones de **Bola de fuego** (recta, atraviesa paredes), **Rayo** (cae en vertical a través del personaje) y **Esquirla de hielo** (3 copos orbitando, con la mitad de la Magia como daño), cada uno gastando maná, para tener magia variada.
49. Como jugador, quiero que el **maná** dependa de la Magia y se regenere lentamente, para dosificar hechizos.
50. Como jugador, quiero que los enemigos sufran **retroceso** al golpearlos, para controlar el espacio.
51. Como jugador, quiero ver números de daño flotantes, destellos de impacto y un breve **hit-stop**, para sentir los golpes.
52. Como jugador, quiero que el daño mínimo de cualquier ataque sea 1, para que nunca sea inútil atacar.

### Estadísticas, progresión y habilidades
53. Como jugador, quiero ganar **experiencia y monedas** al matar enemigos, con una barra de XP visible arriba a la izquierda, para ver mi progreso.
54. Como jugador, quiero que al **subir de nivel** suba al menos 1 punto aleatorio en mis estadísticas, según sus tasas de crecimiento, para hacerme más fuerte.
55. Como jugador, quiero **elegir 1 de 3 habilidades aleatorias cada 5 niveles** (Guerrero rojo, Mago azul o Explorador verde), con un máximo de 3 asignadas a Z, X y C, para personalizar la build.
56. Como jugador, quiero que las habilidades tengan **duración y tiempo de recarga**, y que la recarga se reinicie al entrar en un distrito, para usarlas con cabeza.
57. Como jugador, quiero las 14 habilidades del original con nombre y aspecto propios (ver *Contenido*), para disfrutar del mismo abanico táctico.
58. Como jugador, quiero ver mis estadísticas y rasgos en el inventario, para entender mi personaje.

### Hambre y supervivencia
59. Como jugador, quiero una **barra de hambre de 8 segmentos** (12 con el rasgo Tragón) que baja con el tiempo, para tener presión constante.
60. Como jugador, quiero perder vida periódicamente si el hambre llega a 0, para que comer importe.
61. Como jugador, quiero comer **carne cruda o de pollo** (quitan hambre) o **cocinada** (quita más y tiene un 50 % de curar 1 de Vida), para tener decisiones de comida.

### Distritos, biomas y estructura de la partida
62. Como jugador, quiero que cada **distrito se genere proceduralmente** a partir de salas de plataformas conectadas, con árboles, rocas, hierba, cofres y enemigos, para que cada partida sea distinta.
63. Como jugador, quiero entrar por la izquierda y buscar la **salida**, que siempre es alcanzable, para tener un objetivo claro.
64. Como jugador, quiero que al final de cada distrito haya **3 puertas de colores**, cada una hacia un bioma distinto, para decidir mi ruta de riesgo y recompensa.
65. Como jugador, quiero que tras elegir puerta llegue a un **pueblo con el tema del bioma elegido**, para prepararme antes de entrar.
66. Como jugador, quiero que **los guardianes de Ceniza** aparezcan en la entrada si me quedo demasiado tiempo en un distrito (unos 5 minutos) y me persigan con daño letal, aumentando en número, para que no pueda farmear sin límite.
67. Como jugador, quiero un aviso visual y sonoro antes de que lleguen los guardianes, para poder reaccionar.
68. Como jugador, quiero **trampas ambientales** propias de cada bioma, para que cada uno se juegue distinto.
69. Como jugador, quiero **cofres normales** y **cofres dorados** (que necesitan llave o el rasgo Cerrajero), y **mímicos** que se hacen pasar por cofres, para tener botín y sustos.
70. Como jugador, quiero **jefes de bioma** que aparecen en ciertos distritos, con desbloqueos al vencerlos, para tener retos memorables.
71. Como jugador, quiero que el distrito 21 sea el **Nido de Ceniza** con el **Muro de Ceniza** (el jefe final ocupa toda la altura de la pantalla y avanza de izquierda a derecha disparando proyectiles), para un clímax épico.
72. Como jugador, quiero **ganar la partida** al destruir el Muro de Ceniza y ver una pantalla de victoria con estadísticas y desbloqueos, para cerrar la aventura.

### Pueblo
73. Como jugador, quiero que el pueblo sea una **zona segura** sin guardianes ni límite de tiempo, para planificar con calma.
74. Como jugador, quiero **2 tenderos** que venden herramientas, minerales y materiales de criaturas, para comprar lo que no puedo fabricar.
75. Como jugador, quiero un **herrero** que fabrica lingotes de mineral y equipo de Ataque (cascos, armaduras y escudos) con 3 materiales iguales, para mejorar mi defensa y ataque.
76. Como jugador, quiero una **sastra** (tela y equipo de Magia: capuchas y túnicas) y un **peletero** (cuero y equipo de Destreza: gorros y capas), para especializarme.
77. Como jugador, quiero un **comprador** que paga 2–4 monedas por objeto (1 por la madera, los palos y los tablones), para convertir el exceso en dinero.
78. Como jugador, quiero **4 altares de dioses** (500 monedas) con resultados de apuesta: +5 Ataque o −1 de Vida máxima; +2 a todo o −1 de Vida; curación completa o nada; +5 Destreza o nada, para arriesgar mi dinero.
79. Como jugador, quiero **gallinas** en el pueblo que puedo matar para comer, a riesgo de invocar al **Gallo Rey**, para tener un secreto divertido.
80. Como jugador, quiero comprar una **gema espiritual** (2000 monedas) que invoca a un jefe secreto, cuya derrota desbloquea una raza, para tener un reto opcional.

### Metaprogresión y desbloqueos
81. Como jugador, quiero **desbloquear razas, sombreros y compañeros** cumpliendo retos (algunos con un 20 % de probabilidad al cumplirlos), para tener objetivos a largo plazo.
82. Como jugador, quiero que los desbloqueos **se concedan al terminar la partida** (muerte o victoria) y se guarden en disco, para conservarlos.
83. Como jugador, quiero ver en una **pantalla de fin de partida** el distrito alcanzado, el nivel, las muertes y lo desbloqueado, para sentir el progreso.
84. Como jugador, quiero **estadísticas globales** (partidas, victorias, enemigos, cofres dorados abiertos…), porque algunos desbloqueos son acumulativos.
85. Como jugador, quiero que los **compañeros** revoloteen a mi alrededor con su efecto pasivo, para tener un aliado visible.

### Cooperativo
86. Como jugador, quiero **alojar una partida online** o **unirme por IP o código** hasta 4 jugadores, para jugar con amigos.
87. Como grupo, queremos que cada jugador tenga su propio personaje, inventario y cámara, y compartir el mundo, para cooperar.
88. Como grupo, queremos que un jugador caído quede **abatido** y se le pueda **revivir**, y que la partida termine solo cuando caemos todos, para ayudarnos.
89. Como grupo, queremos que las habilidades de apoyo (velocidad, Destreza o armas mágicas para los aliados) afecten a los compañeros, para sinergias de equipo.
90. Como jugador, quiero que la partida online sea **host-autoritativa**, sin trampas triviales de los clientes, para que funcione de forma estable.

### Presentación, audio y opciones
91. Como jugador, quiero **pixel art original y cuidado**: personajes de 16×24 con contorno, tiles de 16×16 con bordes y variaciones, fondos parallax de 2–3 capas por bioma e iluminación ambiental suave, para un juego bonito.
92. Como jugador, quiero **música original** por bioma y pueblo, y efectos de sonido, para ambientar.
93. Como jugador, quiero un **HUD** con Vida, maná, estamina, hambre, XP y nivel, monedas, barra rápida, habilidades con su recarga y número de distrito, para tener toda la información.
94. Como jugador, quiero opciones de volumen, pantalla completa, escala entera, temblor de pantalla y **reasignación de controles**, además de soporte de mando, para jugar cómodo.
95. Como jugador, quiero **pausar** en solitario, para no perder la partida si me levanto.
96. Como jugador, quiero **guardar y salir** en el pueblo y continuar después, para jugar en sesiones cortas.

### Desarrollo
97. Como desarrollador, quiero que objetos, recetas, enemigos, biomas, razas, sombreros, compañeros, rasgos y habilidades sean **datos** (recursos o tablas), para añadir contenido sin tocar el motor.
98. Como desarrollador, quiero que la **generación de distritos sea determinista por semilla**, para reproducir bugs.
99. Como desarrollador, quiero **tests headless** de la lógica pura y smoke tests que recorran distritos reales, para validar sin abrir el editor.
100. Como desarrollador, quiero **atajos de depuración** (dar objeto, saltar de distrito, elegir bioma, invocar jefe, modo dios, revelar mapa), para probar rápido.

---

## Implementation Decisions

### Plataforma y presentación
- Godot 4.6.3, GDScript, renderer *Compatibility*. **Resolución interna de 480×270** (más campo de visión que el prototipo anterior), escalado entero y filtro *nearest*.
- **Física 2D a 60 Hz con interpolación de física activada** (render suave a cualquier tasa de refresco). La cámara sigue con suavizado y *snap* a píxel en el render para evitar temblores.
- PC con teclado y ratón como control principal (igual que el original). Mando opcional (el stick derecho apunta).
- Controles por defecto: A y D para moverse, Espacio para saltar, S para bajar de plataformas, Q y E para dash, clic izquierdo para usar el objeto en mano, clic derecho para usar o dividir en el inventario, R para el inventario, 1–8 o la rueda para la barra rápida, Z, X y C para las habilidades, F para interactuar, Esc para pausar y Tab para el mapa.

### Módulos (de más profundo a más superficial)

1. **ItemDB** (datos): cada objeto tiene id, nombre, categoría (material, herramienta, arma, arco, bastón, flecha, equipo, consumible, llave o bicho), tamaño de montón, durabilidad, bonificaciones (Vida, Ataque, Destreza, Magia), tipo de herramienta y nivel (hacha o pico con tier 0–5), precio de venta y compra, y sprite.
2. **Crafting** (lógica pura): `combine(a, b, luck, rng) → {result_id, count, quality}`.
   - Las recetas son **pares no ordenados** (a + b = b + a) definidos en tabla. Cada receta indica cuánto consume de cada ingrediente (p. ej. madera ×2 + madera ×2 para dos tablones, según el original).
   - Si la receta produce un arma o un equipo, se hace una **tirada de calidad**: normal, azul, amarilla o morada, con bonificaciones de estadística crecientes. La probabilidad se modifica con la Suerte (rasgo Artesano +10 %).
   - Las recetas de artesano (lingote de mineral, tela, cuero y equipo de 3 materiales) se resuelven con `craft_npc(npc, items)`.
3. **Inventory** (lógica pura): ranuras con montones hasta 99, barra rápida, equipo (casco, cuerpo, escudo y 2 anillos), dividir, mover, añadir con auto-apilado y tirar. Emite señales de cambio.
4. **CharacterStats** (lógica pura):
   - `generate(rng)` reparte 15 puntos (Vida 4–6, Ataque, Destreza y Magia 2–4) y asigna **tasas de crecimiento** (1–2 buenas y 0–1 mala, con el algoritmo documentado del original).
   - `level_up(rng)` sube al menos 1 punto según los pesos de crecimiento.
   - Derivadas: estamina máxima según la Destreza, maná máximo según la Magia, velocidad base y modificadores de raza, rasgos, sombrero, compañero, equipo y buffs.
   - `total()` resuelve el orden: base + raza + rasgos + equipo + buffs.
5. **Combat** (lógica pura): `damage(attacker_stats, weapon, kind, target, rng)`.
   - Cuerpo a cuerpo: Ataque + arma. Arco: Destreza + flecha. Bastón: Magia × factor.
   - Crítico, mínimo 1 y reducción por defensa del objetivo si la tiene. Aplica los efectos de sombreros y habilidades (Furia duplica el cuerpo a cuerpo, Aura resta 4 al daño recibido, etc.).
6. **Hunger / Survival** (lógica pura): hambre (8 o 12 segmentos, con ritmo de bajada), daño por inanición, comida, regeneración de maná y estamina.
7. **DistrictGenerator** (lógica pura y determinista): `generate(seed, biome, district_index, mode) → DistrictLayout`.
   - Construye un mapa de **celdas de sala** (p. ej. 6×3 a 10×4 salas de 30×17 tiles), cada una con una plantilla de plataformas elegida según sus aberturas (izquierda, derecha, arriba, abajo).
   - Garantiza un **camino de la entrada a la salida** y coloca recursos (árboles, rocas y vetas por tier, hierba), cofres (normales, dorados y mímicos), luces de bichos, trampas del bioma, enemigos por presupuesto de dificultad y, si toca, el jefe.
   - La salida lleva a una **sala de 3 puertas** con biomas elegidos según las reglas de progresión.
8. **RoomTemplates**: plantillas hechas a mano en texto (tiles sólidos, plataformas de un sentido, escaleras o lianas, puntos de recurso, enemigo y trampa), agrupadas por patrón de aberturas y con variantes por bioma (texturas).
9. **RunState** (lógica pura): semilla, modo, distrito actual, bioma, jugadores, reloj del distrito (guardianes), historial de biomas, contadores para desbloqueos (enemigos por bioma, minerales minados, flechas disparadas, pociones usadas, crafteos, etc.) y RNG por subsistema.
10. **Progression / Unlocks** (lógica pura + guardado): evalúa al final de la partida los requisitos de razas, sombreros y compañeros contra los contadores de la partida y los globales. Aplica la probabilidad (20 %, 50 % o 100 %) y persiste en un archivo de usuario. `evaluate(run_counters, global_stats, rng) → [unlocked_ids]`.
11. **Player (Character controller)**: CharacterBody2D con máquina de estados (suelo, aire, dash, ataque, daño, abatido y muerto).
    - Parámetros de sensación: aceleración y frenada, coyote de 0,1 s, búfer de 0,1 s, salto variable (corte de velocidad al soltar), gravedad mayor al caer, dash de distancia fija con i-frames breves y doble salto con estamina.
    - Animador por capas: cuerpo de la raza, sombrero y objeto en la mano, con squash & stretch y polvo al aterrizar.
12. **Tools & Interaction**: el objeto en mano define la acción. Hacha con árbol: madera y palos. Pico con roca o veta: mineral si el tier alcanza. Red con luz: bicho. Arma con enemigo: daño. Poción o comida: consumir. Lanzables: arco. Hay tiempo de uso por tipo de arma.
13. **Enemies**: una base con máquina de estados, patrones legibles (saltar, embestir, pausar, disparar, volar, atravesar paredes), telegrafiado, retroceso, botín (tabla por enemigo: monedas, XP y objetos) y 2 tipos de hitbox (daño por contacto y ataque).
14. **Bosses**: jefes de bioma con fases y patrones; guardianes de Ceniza; Muro de Ceniza con desplazamiento horizontal y proyectiles.
15. **Town**: escena de pueblo generada con variante por bioma: 2 tiendas con tarjetas de artículo, herrero, sastra, peletero, comprador, 4 altares, gallinas y salida al distrito.
16. **UI**: creación de personaje, inventario con crafteo, tiendas y artesanos (menús de 3 ranuras), HUD, selección de habilidad, pausa, opciones, fin de partida, pantalla de desbloqueos y libro de recetas.
17. **Net (cooperativo)**: API de multijugador de alto nivel de Godot (ENet), **host autoritativo**. Los clientes envían su input y el host simula el mundo y replica entidades. Cada jugador tiene su propio inventario (autoridad en el host). La interfaz se abstrae con un *InputSource* por jugador para que un jugador local y uno remoto sean el mismo código.
18. **ArtPipeline**: sprites originales generados por código como en el prototipo (texto con paleta), pero con **paleta ampliada de 48 colores**, contorno sombreado, 3 tonos por material y animaciones completas. Exportables a PNG (`--export-sprites`) para retoque en Aseprite. Fondos parallax procedurales por bioma.
19. **Audio**: efectos sintetizados como en el prototipo y música original de chiptune por bioma (secuenciador simple con patrones en datos).

### Contenido (equivalencias con el original, nombres propios)

**Mundo:** Hondura (≈ Deephaven), la Superficie (≈ Overworld), la Ceniza (≈ Scourge).

**Materiales por tier (≈ Stone, Bone, Ironite, Goldium, Diamondite, Crystalite):** Piedra (Tosco), Hueso (Tribal), Hierro (Elegante), Oro (Real), Diamante (Luminoso) y Cristal de Ceniza (final). Carbón. Bichos de fuego, hielo y rayo, con sus gemas.

**Razas (15, mismos perfiles que el original):**

| Raza | Stats | Equipo inicial | Desbloqueo |
|---|---|---|---|
| Minero *(≈ Peon)* | Vida +1 | Hacha de madera + 2 aleatorios | Por defecto |
| Linajudo *(≈ Noble)* | Vida +1, Magia +1 | Hacha de piedra | 20 % al matar 15 enemigos en una partida |
| Cíclope *(≈ Orclops)* | Vida −1, Ataque +2 | Espada y pico de hueso | 20 % al minar 20 minerales en una partida |
| Elfo de roca *(≈ Dwelf)* | Vida −1, Destreza +4 | Hacha de madera, arco, aleatorio | 20 % al obtener la 1.ª habilidad |
| Veterano *(≈ Crusader)* | Ataque +1 | Hacha de madera, gran hacha de piedra, aleatorio | 20 % al obtener la 2.ª habilidad |
| Antiguo *(≈ Remnant)* | Vida −1, Magia +4 | Hacha de madera, bastón de Rayo | 20 % al ganar |
| Alado *(≈ Trogon)* | Destreza +1 | Hacha, poción grande de vida y de maná | Ganar en menos de 1 hora |
| Terrano *(≈ Earthkin)* | Ataque, Destreza y Magia +1 | Hacha, armadura de hueso, aleatorio | 20 % al llegar al distrito 10 |
| Porcino *(≈ Pigfolk)* | −1 a todo | 3 carnes crudas | Ganar sin usar pociones de vida |
| Batracio *(≈ Qualogg)* | Ataque +2, Destreza +2 | Hacha, red para bichos, aleatorio | Ganar sin craftear |
| Urraca *(≈ Bandicoot)* | Ataque +1, Destreza +3 | Hacha, 2 anillos | 50 % al visitar el Cráter |
| Genio de humo *(≈ Djinn)* | Magia +3 | Hacha, espadón especial, bastón de Bola de fuego | Ganar matando solo 1 enemigo |
| Escamado *(≈ Lizardman)* | Ataque +1, Destreza +3, Magia +1 | Pico de piedra, katana esmeralda | Nombre secreto |
| Engendro *(≈ Scourgeling)* | Magia +4 | Bastón de invocar zombi | 20 cofres dorados en total |
| Caballero fantasma *(≈ Spirit)* | Vida +7, Ataque +3 | Espada de oro, hacha | Vencer al jefe secreto |

**Rasgos (13, elegir 2):** Leñador (50 % de no gastar hacha), Minero de vetas (50 % de no gastar pico), Recolector (50 % de doble cosecha en hierba), Alquimista (50 % de poción grande), Artesano (+10 % de calidad), Agresivo (Ataque +2, Destreza −2), Defensivo (Vida +4, Ataque −2), Veloz (Destreza +4), Robusto (Vida +4), Tragón (hambre 12), Listo (Magia +8), Cerrajero (abre cofres dorados sin llave) y Carterista (roba monedas al pasar junto a los vecinos; **en el original no funcionaba, aquí sí**).

**Habilidades (14):**
- *Guerrero:* Furia (cuerpo a cuerpo ×2, 10 s de duración, 46 s de recarga), Carga (aliados +velocidad), Aura guardiana (−4 al daño recibido), Hoja del caballero (salto extra con proyectil perforante hacia abajo) y Hacha arrojadiza.
- *Mago:* Clarividencia (+20 de maná), Levitar (sin gravedad 10 s), Armas arcanas (el cuerpo a cuerpo de los aliados hace daño extra igual a la Magia), Súbdito nigromante (invoca algo que dispara 6 bolas de fuego) y Parpadeo (teletransporte corto).
- *Explorador:* Lobo huargo (invoca un lobo que empuja y daña), Flecha druídica, Fuego fatuo (duplica el daño de las flechas que lo atraviesan), Rugido cazador (aliados +10 de Destreza) y Tiro triple.

**Biomas (9 + Nido), con trampas, enemigos y jefes:**

| Bioma | Puerta | Trampa | Enemigos | Jefes |
|---|---|---|---|---|
| Bosque Hundido | verde claro | bloques de pinchos móviles (1 de daño) | cerdo, avispa (colmenas de 7), jabalí, limo verde, araña verde | Tiranodonte (600 de vida), Corsario Morsa (850) |
| Ciénaga | verde oscuro | esporas que escupen bolas (1) | babosa, chamán y porrero de la tribu, cangrejo roca, mímico | — |
| Pradera Roja | roja y rosa | ninguna | oveja, seta saltarina, seta soldado, seta maga, medusa (espada de gelatina) | — |
| Cavernas | gris | huevos de araña (3 = Madre Araña) | araña morada, murciélago, mímico, cangrejo roca | Madre Araña (400, atraviesa paredes) |
| Mazmorra | piedra oscura | bolas de pinchos giratorias (4) | esqueleto guerrero y arquero, minotauro, genio, mímico | Rey Esqueleto (600) |
| Tundra | blanca | bloques de hielo que caen (2) | conejo, limo azul, caballero y hada de hielo | Yeti (150), Reina de Escarcha (850, esquirlas orbitando) |
| Volcán | naranja | bolas de fuego verticales (6) | buey de fuego, diablillo, dragón | Dragón Negro (800, atraviesa paredes) |
| Cantera de Cristal | turquesa | cuchillas de cristal giratorias | babosa de cristal, gólem y murciélago de cristal | Paladín de Cuarzo (300) |
| Cráter Estelar | violeta | bolas cósmicas verticales (6) | esqueleto y mariposa cósmicos | Capitán Estelar (1700) |
| Nido de Ceniza (distrito 21) | — | — | cabeza de Ceniza, necrófago, gusano de Ceniza | **Muro de Ceniza** (final) |

Además: **guardianes de Ceniza** (en todos los distritos al agotar el tiempo), **Gallo Rey** (en el pueblo, al matar gallinas) y **Sir Ventolín, caballero fantasma** (jefe secreto de la gema espiritual, unos 4000 de vida, con 2 espadas que lo siguen).

**Reglas de las puertas:** en el distrito 1 siempre se juega el Bosque. Las puertas ofrecen biomas por tier de dificultad según el distrito (fácil: Bosque y Ciénaga; medio: Pradera, Cavernas y Tundra; difícil: Cantera, Volcán y Mazmorra; muy difícil: Cráter). Siempre hay al menos una opción de tier menor o igual al actual. En el distrito 20 la salida lleva al Nido.

**Sombreros (24, efectos equivalentes a los del original):** cinta de recolector, casco de minero, bufanda berserker, sombrero de arquero, sombrero de mago, orejas de conejo (triple salto), ala de murciélago (dash ×2), casco de tiranodonte, gafas de avispa (caída lenta y +velocidad), máscara tiki (±Vida al entrar en un distrito), barba de mago, corona de héroe, sombrero de seta, huevo de araña, máscara de esqueleto (25 % de crítico), sombrero de dragón (bola de fuego sin arma), máscara de Ceniza (drena vida), corona de escarcha, yelmo vikingo, yelmo de dragón negro (dash y saltos gratis), capucha del rey esqueleto, tricornio (monedas ×2), cabeza del autor (cosmético con truco) y yelmo real (daño ÷2, por partida sin recibir daño).

**Compañeros (9):** Hada regeneradora (+1 de Vida por distrito), Murciélago anciano (suelta objetos), Escarabajo veloz (velocidad ×2), Guardia mecánico (cuchilla al hacer dash en el aire), Limo flotante (sin gravedad), Ojo de gorgona (+1 de maná cada 1,5 s), Fantasma gelatinoso (saltos infinitos), Llama de esperanza (+1 punto extra al subir de nivel) y Dron de la cuarta era (vuelo y velocidad ×2).

**Altares (4 dioses originales, mismas apuestas):** Karvoth, dragón rojo (+5 Ataque o −1 Vida máx.); Mhul'ruk, devorador de almas (+2 a todo o −1 Vida); Aelyn, la de los prados (curación total o nada); Sera la jinete de grifo (+5 Destreza o nada).

**Números base (del original, ajustables):** herramientas de madera con 50 de durabilidad; pociones de vida de 2 y 5, y de maná de 3 y 7; los guardianes aparecen a los 5 min (en grupos de 5, 9999 de daño, llegan a la salida en 15–30 s); altar a 500; gema espiritual a 2000; hambre de 8; espada de madera +2 de Ataque; cadena de equipo (Hueso +1 Vida y +2 stat → Diamante +6 Vida y +10 Ataque, etc.) según la tabla del pueblo.

### Guardado
- **Perfil** (JSON en la carpeta de usuario): desbloqueos, estadísticas globales, ajustes y controles.
- **Partida en curso:** se guarda solo al entrar en un pueblo (semilla, distrito, personaje e inventario) y se borra al morir, como corresponde a un roguelike.

---

## Testing Decisions

- **Qué es un buen test:** comprueba el **comportamiento observable** a través de la interfaz pública de un módulo (entradas → salidas o eventos), nunca detalles internos. Deterministas: todo RNG se inyecta con semilla.
- **Runner:** el mismo enfoque que en el prototipo *La Gran Presa*: un runner propio en headless (`--headless -s tests/run_tests.gd`), clases base con `check` y `check_eq`, y código de salida distinto de 0 si algo falla. Ese es el **precedente** (prior art).
- **Seams propuestos** (módulos puros, de más alto nivel posible):
  1. **Crafting:** cada receta de la tabla produce su resultado; la conmutatividad (a + b = b + a); los consumos correctos; las combinaciones inválidas no hacen nada; la distribución de calidades con y sin Artesano en N tiradas; las recetas de artesano (3 materiales iguales).
  2. **CharacterStats y Progression:** la generación respeta los rangos (15 puntos, límites) para muchas semillas; subir de nivel suma al menos 1; las estadísticas totales resuelven raza + rasgos + equipo + buffs en orden estable; los desbloqueos se conceden si y solo si se cumple el requisito (con RNG fijado).
  3. **DistrictGenerator:** para cientos de semillas y todos los biomas, la salida es alcanzable desde la entrada (búsqueda sobre el grafo de plataformas con las capacidades de salto base), el número de enemigos está dentro del presupuesto, los biomas de las 3 puertas son distintos y cumplen las reglas de tier, y hay determinismo.
  4. **Inventory y Combat:** apilado hasta 99, dividir y mover; fórmulas de daño (cuerpo a cuerpo, arco, bastón, crítico, mínimo 1, habilidades).
- **Smoke tests:** en headless, crear un personaje con semilla fija, recorrer el distrito 1 → pueblo → distrito 2 simulando frames, abrir un cofre, craftear, matar un jefe con modo dios y activar el fin de partida. Todo sin errores.
- **Co-op:** test de integración en loopback (host y cliente en el mismo proceso), comprobando que la entrada del cliente mueve a su personaje en el host y que la réplica llega.
- **No automatizado:** la sensación de movimiento, la legibilidad del arte y el balance se validan jugando, con capturas automáticas (`--shots`) de cada bioma y pantalla.

---

## Out of Scope

- **Cualquier asset, texto, nombre propio, música o sonido del juego original** (se crea todo nuevo).
- Integración con Steam (logros, lobbies, *workshop*). El online es por IP o código mediante ENet.
- Cooperativo a pantalla partida local (el original era online; se puede estudiar después).
- Consolas, móvil y web.
- Contenido nuevo que no exista en el original (primero clonar; ampliar después).
- Reproducir los **bugs** del original (rasgos con valores distintos a su descripción, Carterista que no hace nada, etc.): se implementan los valores que el original **aplicaba de verdad**, con descripciones correctas.

---

## Further Notes

### Hitos de implementación
1. **Base jugable:** movimiento pulido, distrito del Bosque generado, recolección, inventario y crafteo básico, hambre, enemigos del Bosque, subir de nivel, muerte y fin de partida.
2. **Estructura completa:** pueblo (tiendas, artesanos, comprador, altares y gallinas), 3 puertas, guardianes de Ceniza, cofres y mímicos, arcos y bastones, pociones, habilidades y rasgos.
3. **Todos los biomas y jefes,** el Nido y el Muro de Ceniza, y el modo Demente.
4. **Metaprogresión:** razas, sombreros, compañeros, desbloqueos, guardado y estadísticas globales, y el jefe secreto.
5. **Cooperativo online** de 1 a 4 jugadores.
6. **Pulido:** música, arte final, parallax, opciones y rendimiento.

### Lecciones del prototipo anterior aplicadas
- Personajes más grandes (16×24) y **más fotogramas**; nada de "animar" solo moviendo los pies.
- Movimiento con aceleración, coyote, búfer e interpolación de física; cámara suavizada.
- Capturas automáticas, incluidas de cerca (×3), para revisar el arte.
- La lógica pura va separada de la escena para poder testearla.

### Referencias de investigación
- Magicite Wiki (Fandom): Beginners Guide, Races, Biomes, Bosses, Skills, Traits, Stats, Companions, Hats, Crafting, Town, Items, Weapons.
- Ficha de Steam de *Magicite* (app 268750).

### Pendiente
- El repositorio de GitHub se crea al tener el primer hito jugable. Hay que iniciar sesión con `gh auth login`. Esta spec se publicará como issue con la etiqueta `ready-for-agent`.
