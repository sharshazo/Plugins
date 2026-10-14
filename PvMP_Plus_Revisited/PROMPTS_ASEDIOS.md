# PvMP+ — Prompts para la ventana de Asedios

Archivos en `Plugins\PvMP_Plus_Revisited\PvMP_Plus\Resources\Siege\`.

Para que el juego los acepte, cada imagen debe cumplir:

- Formato **TGA de 32 bits**.
- **Tamaño exacto** (indicado en cada sección).
- **Mismo nombre** que el archivo actual.

Los textos (TA, IM, TR, LG, LC, el título y el canal) los pone el plugin. Por eso las imágenes van **sin letras**.

**Negative prompt** para todas las imágenes:
```
text, letters, numbers, watermark, logo, signature, modern sci-fi, neon, blurry, photo, people, characters
```

---

## 1. Fondo de la ventana — `siege_bg.tga` (250×100)

```
Lord of the Rings Online style UI panel, wide horizontal frame 250x100, dark weathered leather and old stone texture, ornate antique gold border with small Celtic knot corners, a slim darker title band across the top 22 pixels, a thin engraved gold divider line near the bottom, subtle vignette, Middle-earth medieval fantasy, warm torch light, no text, flat front view, game UI asset
```

La ventana coloca los elementos así:

- **Título:** franja de arriba, 0–24 px.
- **Botones:** fila central, de 28 a 72 px.
- **Canal:** línea de abajo, de 76 a 96 px.

Deja esas zonas lisas, sin dibujos.

---

## 2. Botones de fortaleza (44×44)

El plugin escribe encima las letras de cada fortaleza y una franja azul o roja según quién la tiene. Deja el **centro oscuro y liso** para que se lean.

**Normal — `siege_btn_normal.tga`**
```
Square fantasy game button 44x44, Lord of the Rings Online style, dark iron and old leather center, bevelled antique bronze-gold frame with small rivets in the corners, subtle top highlight, empty dark center for text, flat front view, no text
```

**Ratón encima — `siege_btn_hover.tga`**
```
Square fantasy game button 44x44, Lord of the Rings Online style, dark iron center, bright polished gold frame with a soft warm golden inner glow, small rivets in the corners, empty dark center for text, flat front view, no text
```

**Bajo ataque — `siege_btn_active.tga`**
```
Square fantasy game button 44x44, Lord of the Rings Online style, dark scorched iron center with faint glowing embers, frame made of hot red-orange metal with fiery inner glow and small sparks, sense of battle and siege, empty dark center for text, flat front view, no text
```

---

## 3. Opcional: emblemas por fortaleza (si después quieres iconos en vez de letras)

| Fortaleza | Prompt |
|---|---|
| Tol Ascarnen (TA) | `small square emblem icon, ancient stone island fortress with a tall white tower over a river, gold rim, LOTRO style, no text` |
| Isendeep Mine (IM) | `small square emblem icon, crossed dwarven pickaxes over a dark mine entrance, gold rim, LOTRO style, no text` |
| Tírith Rhaw (TR) | `small square emblem icon, elven watchtower on a green hill with a banner, gold rim, LOTRO style, no text` |
| Lugazag (LG) | `small square emblem icon, jagged black orc fortress with red torches, gold rim, LOTRO style, no text` |
| Grimwood Lumber Camp (LC) | `small square emblem icon, axe stuck in a log with a palisade wall behind, gold rim, LOTRO style, no text` |

Si los generas, pásamelos y adapto los botones para que muestren el emblema.
