# PvMP+ — Prompts para las imágenes nuevas (estilo moderno tipo LUI)

**Estilo común.** Pega este bloque al inicio de cada prompt:

> Modern dark fantasy MMO UI asset, clean flat-gradient style inspired by modern game HUDs (LUI-like), slate/charcoal base (#101218 to #232835), thin 1px border #3C4250, subtle inner glow, crisp pixel-perfect edges, transparent background (PNG with alpha), no text, no watermark, no drop shadow outside the canvas, centered, high contrast, readable at very small size.

**Colores de acento:**

- Monstruos/Creeps: rojo `#FF6B6B` → `#B01E2E`.
- Pueblos libres/Freeps: azul `#7CC4FF` → `#1E5BC8`.
- Oro (detalles): `#C9A45A`.
- Neutro: `#E6E9EF`.

**Cómo usar las imágenes:**

1. Genera cada imagen a 4× u 8× su tamaño final y redúcela al tamaño exacto (filtro Lanczos).
2. Guárdala como **TGA de 32 bits con alfa** y con **el mismo nombre**, en la carpeta indicada. Ruta base: `Plugins/PvMP_Plus_Revisited/PvMP_Plus/Resources/`.
3. Haz una copia de la imagen original antes de reemplazarla.
4. El tamaño debe ser exactamente el indicado. Si no lo es, se deforma en el juego.

---

## 1. Pestañas de estadísticas — `Tabs/` (50×50, se mezclan en modo superposición)

Cada icono tiene 4 estados con el mismo dibujo: `normal`, `_mouseover` (+15 % de brillo), `_selected` (acento dorado) y `_selected_mouseover` (dorado + brillo).

- **stats.tga** (estadísticas del personaje): "minimal emblem icon of a heraldic shield with a small rising chart line inside, silver line-art on transparent, 50x50, soft glow".
- **kills.tga** (registro de golpes mortales): "minimal icon of two crossed swords over a small skull, silver line-art, transparent, 50x50".
- **barChart.tga** (gráficas): "minimal icon of three vertical bars of increasing height with rounded tops, silver line-art, transparent, 50x50".
- **Variante selected:** añade "gold accent #C9A45A on the main shape, faint gold circular glow behind".
- **Variante mouseover:** añade "slightly brighter, subtle white rim light".

## 2. Botones del panel — `OverviewButtons/` (16×16)

Son iconos diminutos: usa formas muy simples y gruesas, sin detalles finos.

- **chat_button.tga:** "tiny speech bubble icon, solid light silver #E6E9EF, 2px rounded, 16x16, transparent".
- **statistics_button.tga:** "tiny bar chart icon, three solid bars, light silver, 16x16".
- **secondary_windows_button.tga:** "tiny icon of two overlapping rounded windows, light silver, 16x16".
- **settings_button.tga:** "tiny gear icon with 6 teeth, light silver, 16x16".

## 3. Fortalezas — `KeepIcons/` (24×24)

- **BlueFire.tga:** "small stylized flame icon, cyan-blue gradient #7CC4FF to #1E5BC8, bright white core, soft outer glow, transparent, 24x24, modern flat game icon".
- **RedFire.tga:** igual, con "crimson gradient #FF6B6B to #B01E2E".

## 4. Aviso de enemigos en el mapa — `MapIcons/` (151×29)

- **enemy_position_overlay.tga:** "horizontal rounded callout pill 151x29, dark slate translucent fill (#101218 at 85% opacity), 1px border #3C4250, red accent bar 3px on the left edge (#FF6B6B), small red warning chevron at the left, empty space for text, transparent background".
- **enemy_position_overlay_empty.tga:** el mismo dibujo, pero "without the red accent, border only at 50% opacity" (es el parpadeo).

## 5. Icono del plugin — `Icon.tga` (32×32)

"Square app icon 32x32 with rounded corners (radius 6), dark slate gradient background, a minimal emblem: half red half blue split shield with a thin gold rim and a tiny crossed-swords mark in the center, crisp, readable at 32px".

## 6. Barra de arrastre — `DragBar/` (2000×20)

El juego recorta la imagen al ancho de la ventana. Por eso el dibujo debe ser **uniforme en horizontal**, con los detalles solo en los primeros 40 px de la izquierda.

- **dragbar.tga:** "seamless horizontal title strip 2000x20, dark slate vertical gradient #232835 to #12151C, 1px top highlight #3C4250, 1px gold bottom line #C9A45A, small 6-dot grip pattern at the far left, no other details".
- **dragbar_clicked.tga:** igual, con "brighter gold bottom line #F0CB78 and slightly lighter grip dots".
- **Esquinas de sombra** (`drag_topleft/topright/bottomleft/bottomright` 10×10, `drag_topmid/bottommid` 1×10, `drag_midleft/midright` 10×1): "soft black outer shadow gradient from 70% to 0% opacity, rounded corner radius 8". Cada pieza debe continuar a la siguiente sin cortes.

## 7. Barras de progreso — `ProgressBar/Red|Blue|Grey/`

Ya las cambié por unas modernas, generadas por código al tamaño exacto. Si quieres probar otras:

- **bar_filled.tga** (1×14, se repite en horizontal): "1px wide vertical gradient strip, top highlight line, saturated accent gradient (red/blue/silver), darker bottom line".
- **bar_empty.tga** (1×14): "1px wide vertical gradient, near-black tinted with the accent color, inner shadow at the top".
- **bar_middle.tga** (1×18): borde de 2 px arriba y 2 px abajo, **transparente en el centro**.
- **bar_left.tga / bar_right.tga** (6×18): extremos redondeados (radio 4) con el mismo borde.

---

### Consejos para que se vea "dinámico" como LUI

- Usa la misma paleta, el mismo borde (`#3C4250`) y el mismo radio en todo.
- Haz los estados `mouseover` y `selected` de cada pestaña, porque son los que dan la sensación de movimiento.
- Evita los relieves dorados antiguos y las texturas de pergamino. Usa degradados suaves con un brillo arriba.
