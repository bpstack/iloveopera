# TODO — Revisión exhaustiva de funcionalidades

> Objetivo: que un usuario **desktop** y un usuario **móvil** puedan hacer las
> funciones básicas para las que la app fue diseñada, sin fricción. Revisión
> funcionalidad por funcionalidad, **poco a poco, en varias sesiones**.
>
> Fuente de verdad de qué debe existir: `ROADMAP.md`. Este documento NO añade
> alcance nuevo — solo verifica, corrige y pule lo ya especificado (Fases 0–6).
>
> **Cómo usar:** cada ítem tiene casilla. Estados:
> - `[ ]` pendiente · `[~]` en progreso/parcial · `[x]` verificado OK
> - Cada ítem dice **qué probar** y **en qué plataforma** (🖥️ desktop / 📱 móvil).
> - Bugs ya conocidos marcados con 🐞. Lo arreglado esta sesión, con ✅(fix).

---

## Leyenda de plataformas
- 🖥️ Windows desktop (ratón + teclado, ventana grande)
- 📱 Android móvil (touch, pantalla estrecha < 700 dp)
- 🖥️📱 = debe funcionar igual en ambas

---

## SESIÓN 1 — Núcleo del visor (abrir, ver, navegar, zoom)

> Sin esto nada más importa. Es lo primero que toca el usuario.

### 1.1 Abrir PDF
- [x] 🖥️ Abrir PDF desde botón "Abrir PDF" → se renderiza
- [x] 📱 Abrir PDF vía SAF (selector Android) → bytes → render (R13, nunca validado en device real)
- [x] 🖥️📱 Abrir un segundo PDF reemplaza el primero (single-document) y limpia anotaciones
- [x] 🖥️📱 Cancelar el selector no rompe ni muestra error feo
- [x] 🖥️📱 PDF inexistente / corrupto → mensaje claro, no crash

### 1.2 Visualización multipágina
- [x] 🖥️📱 Todas las páginas se ven, scroll fluido
- [x] 🖥️📱 Páginas de distinto tamaño/orientación se ven correctas (R5)
- [x] 🖥️📱 PDF grande (50+ pág.) no congela ni agota memoria (R9)

### 1.3 Navegación entre páginas
- [x] 🖥️ Botones anterior/siguiente funcionan
- [x] 📱 Botones anterior/siguiente en barra inferior funcionan ✅(fix: barra inferior nueva)
- [x] 🖥️📱 Indicador "N / M" se actualiza al hacer scroll
- [x] 🖥️📱 "Ir a página" (diálogo) salta correctamente
- [x] 🖥️📱 Límites: no pasa de la última ni antes de la primera

### 1.4 Zoom — PRIORIDAD (roto en móvil)
- [x] 🖥️ Zoom con botones +/− y campo de %
- [x] 🖥️ Zoom con Ctrl+rueda del ratón
- [x] 🖥️ "Ajustar a página" funciona
- [x] 📱 Zoom con botones +/−/ajustar en barra inferior ✅(fix: barra inferior nueva)
- [x] 🐞 📱 **Pinch-to-zoom + pan sobre el contenido** (Android real). Causa raíz:
      pdfrx compone los overlays como HERMANOS encima del `InteractiveViewer`; el
      hit-test del `Stack` para en el primer hijo → si el overlay es golpeable, pdfrx
      no recibe el gesto sobre la página (por eso solo funcionaba fuera del PDF).
      ✅(fix: en herramienta MANO el overlay es `IgnorePointer` → pdfrx recibe pan+pinch
      sobre el contenido). En herramientas de anotación, pan/zoom requiere la mano.
      **REVERIFICAR en device:** con la mano, 1 dedo desplaza y 2 dedos hacen zoom SOBRE el PDF.
- [x] 📱 Pan con 1 dedo desplaza el PDF (reportado OK por usuario, confirmar)
- [x] 🖥️📱 El % mostrado nunca se desincroniza del zoom real

### 1.5 Miniaturas
- [x] 🖥️ Barra lateral de miniaturas visible y clicable (solo desktop/ancho)
- [x] 🖥️ Click en miniatura salta a esa página
- [x] 📱 Confirmar decisión: ¿miniaturas ocultas en móvil a propósito? (ahora sí lo están)

---

## SESIÓN 2 — Anotación: texto y "tipp-ex" (rect)

### 2.1 Añadir texto
- [x] 🖥️ Herramienta texto → click coloca → diálogo → texto aparece donde se hizo click
- [x] 📱 Herramienta texto → tap coloca → diálogo → texto aparece donde se hizo tap
- [x] 🖥️📱 Texto vacío/cancelado no crea anotación
- [x] 🖥️📱 Posición fiel al zoom (cambiar zoom no descoloca el texto) — R5

### 2.2 Editar texto
- [x] 🖥️ Doble-click sobre texto reabre diálogo de edición
- [x] 📱 Doble-tap sobre texto reabre diálogo de edición
- [x] 🖥️📱 Borrar todo el texto en edición → elimina la anotación

### 2.3 Estilo de fuente
- [x] 🖥️ Panel derecho: cambiar familia/tamaño/color afecta en vivo
- [x] 📱 Bottom-sheet (FAB propiedades): cambiar familia/tamaño/color afecta en vivo
- [x] 🖥️📱 Las 5 fuentes del set se ven distintas y se embeben al exportar

### 2.4 Mover texto
- [x] 🖥️ Arrastrar texto seleccionado lo mueve, suelta donde toca
- [x] 📱 Arrastrar texto con el dedo lo mueve
- [x] 🖥️📱 Mover no descoloca respecto al cursor/dedo ✅(fix: drag elevado al
      padre → el handle de resize sigue al texto/rect en vivo durante el arrastre,
      ya no salta al soltar)

### 2.5 Redimensionar texto — PRIORIDAD (roto)
- [x] 🐞 🖥️📱 **Handle inferior-derecho del cuadro de texto** — usuario: "solo ancho al
      principio, el vertical no persiste, el punto se desincroniza del vértice".
      Mismo bug en desktop. ✅(fix aplicado esta sesión: texto ahora redimensiona
      ancho+alto como el rect, handle usa dims explícitas, ClipRect). **REVERIFICAR
      en device** que: agarra bien el handle / cambia ambas dimensiones / el punto
      queda pegado al vértice / no salta al empezar.

### 2.6 Rectángulo "tipp-ex"
- [x] 🖥️📱 Crear rect, por defecto blanco, tapa el contenido
- [x] 🖥️📱 Cambiar color y opacidad en vivo
- [x] 🖥️📱 Redimensionar rect (esto funciona OK según usuario — usar de referencia)
- [x] 🖥️📱 Mover y eliminar rect

### 2.7 Eliminar / seleccionar
- [x] 🖥️📱 Botón eliminar borra la anotación seleccionada
- [x] 🖥️📱 Tap/click en zona vacía deselecciona ✅(fix: la capa de captura de
      tap de fondo ahora también se monta en modo seleccionar; antes la rama
      de deselect era código muerto y no respondía)
- [x] 🖥️📱 Selección visible (borde) clara

---

## SESIÓN 3 — Anotación avanzada: dibujo, resaltado, historial

### 3.1 Dibujo a mano alzada
- [ ] 🖥️ Trazo con ratón fluido, sigue el cursor
- [ ] 📱 Trazo con dedo fluido, sigue el dedo
- [ ] 🖥️📱 Color y grosor configurables en vivo
- [ ] 🖥️📱 Trazo queda fiel al zoom y se exporta bien
- [ ] 🐞 📱 Confirmar que dibujar no entra en conflicto con pan/zoom de pdfrx

### 3.2 Resaltado
- [ ] 🖥️📱 Crear zona resaltada semitransparente
- [ ] 🖥️📱 Color/opacidad configurables
- [ ] 🖥️📱 Mover/redimensionar/eliminar

### 3.3 Undo / Redo
- [ ] 🖥️ Ctrl+Z / Ctrl+Y funcionan
- [ ] 🖥️📱 Botones undo/redo se habilitan/deshabilitan correctamente
- [ ] 🖥️📱 Undo/redo cubre añadir, mover, redimensionar, borrar, estilo
- [ ] 🖥️📱 Estado consistente tras muchas operaciones

---

## SESIÓN 4 — Export y persistencia (lo que el usuario "se lleva")

### 4.1 Exportar a PDF nuevo
- [ ] 🖥️ Exportar → elegir destino → PDF nuevo con todas las anotaciones
- [ ] 📱 Exportar → guardar/compartir → PDF nuevo correcto
- [ ] 🖥️📱 Original NUNCA modificado
- [ ] 🖥️📱 Fidelidad: posición/color/tamaño/fuente igual que en pantalla (R5/R8)
- [ ] 🖥️📱 Tamaño/orientación de cada página respetados (R5)
- [ ] 🖥️📱 Calidad de rasterizado aceptable (DPI 200) — no borroso (R6)
- [ ] 🖥️📱 Feedback de progreso/éxito/error claro

### 4.2 Guardar / reabrir proyecto
- [ ] 🖥️ Guardar proyecto (copia PDF + JSON anotaciones)
- [ ] 📱 Guardar proyecto desde menú 3 puntos ✅(fix: menú ya no se recorta)
- [ ] 🖥️📱 Pantalla "Proyectos guardados": listar, abrir, borrar
- [ ] 🖥️📱 Reabrir restaura página, zoom y todas las anotaciones
- [ ] 🖥️📱 Cerrar app y reabrir proyecto → seguir donde se dejó
- [ ] 🖥️📱 "Actualizar proyecto" vs "Guardar nuevo" se comporta bien

---

## SESIÓN 5 — UI/UX responsive y pulido transversal

### 5.1 Layout responsive
- [ ] 🐞 📱 **App bar móvil no debe desbordar** ni recortar acciones ✅(fix: nav+zoom
      movidos a barra inferior; appbar = abrir + menú)
- [ ] 📱 Barra inferior nueva no choca con el FAB de propiedades (verificar; reubicar FAB si tapa "ajustar")
- [ ] 🖥️ Layout ancho: miniaturas + toolbar + visor + panel propiedades caben sin apreturas
- [ ] 🖥️📱 Cambio de orientación / resize de ventana no rompe layout
- [ ] 📱 Teclado al escribir texto no tapa el diálogo

### 5.2 Herramientas (toolbar)
- [ ] 🖥️ Toolbar vertical izquierda: iconos claros, herramienta activa marcada
- [ ] 📱 Toolbar horizontal superior: todos los iconos accesibles (scroll si hace falta)
- [ ] 🖥️📱 Tooltips/etiquetas comprensibles
- [ ] 🖥️📱 Cursor correcto por herramienta (desktop)

### 5.3 Tema y consistencia
- [ ] 🖥️📱 Tema claro/oscuro coherente en todas las pantallas
- [ ] 🖥️📱 Textos UI en español, sin strings sueltos en inglés
- [ ] 🖥️📱 Estados vacíos / carga / error con mensajes claros

### 5.4 Robustez
- [ ] 🖥️📱 No crashea al operar sin documento abierto
- [ ] 🖥️📱 `flutter analyze` = 0 issues
- [ ] 🖥️📱 Tests existentes pasan (`flutter test`)

---

## Bugs activos priorizados (resumen vivo)

| # | Bug | Plataforma | Estado |
|---|-----|-----------|--------|
| B1 | Pan/zoom no funciona sobre el contenido | 📱 | 🟢 verificado en device (mano=IgnorePointer→pdfrx recibe gesto) |
| B2 | Resize cuadro de texto incorrecto | 🖥️📱 | 🟢 verificado en device |
| B3 | App bar móvil recortaba guardar/exportar | 📱 | 🟢 corregido (barra inferior) |
| B4 | FAB propiedades podría tapar barra inferior | 📱 | 🟢 verificado |
| B5 | Tap en vacío no deseleccionaba (modo seleccionar) | 🖥️📱 | 🟢 corregido (capa de captura en select) |
| B6 | Handle de resize no seguía al mover | 🖥️📱 | 🟢 corregido (drag elevado al padre) |

---

## Método de trabajo por sesión
1. Tomar UNA sección (o subsección) de este TODO.
2. Reproducir cada ítem en la(s) plataforma(s) indicada(s).
3. Marcar `[x]` lo que funcione; abrir/anotar 🐞 lo que falle con detalle exacto.
4. Arreglar, `flutter analyze`, rebuild, reverificar.
5. Commit pequeño por arreglo. Actualizar la tabla de bugs y este TODO.
