# QuestSync (LOTRO_Quest_Assistant)

Asistente de misiones en español para **The Lord of the Rings Online**:
traduce nombres, diálogos y objetivos de las misiones usando una base
de datos propia (más de 14.000 misiones), con un tracker flotante,
un libro de misiones estilo pergamino, mapa integrado, y narración por
voz con IA.

## Características

- **Traducción profesional al español** del nombre, diálogo y
  objetivos de cada misión activa — no es traducción automática en
  vivo, sale de una base propia extraída y verificada.
- **Tracker flotante** ("Misiones activas"): lista siempre visible de
  tus misiones seguidas, con colores distintos por tipo (principal,
  grupo, repetible) y botón para ocultar cada una.
- **Libro de misión**: ventana con el detalle narrativo completo,
  estilo pergamino/tapa de cuero acorde a la interfaz nativa del
  juego — se abre solo al aceptar o completar una misión.
- **Mapa y rutas integrados** (MoorMap/Waypoint): marca el punto de
  cada objetivo de misión con un click, con desglose por etapa cuando
  una misión tiene varios lugares conocidos.
- **Buscador/ventana principal** (QuestSync): listado completo
  filtrable por zona, con vista de detalle.
- **Ayudas de recolección**: nodos de materiales y cofres
  cercanos/relevantes, con opción de marcarlos como encontrados.
- **Narración por voz con IA** 🔊: botón "Narrar" en cualquier
  misión para escucharla en voz alta, más un botón de
  silenciar/activar (verde = encendido). Requiere el compañero
  [**Narrador_IA**](https://github.com/sharshazo/Narrador_IA) — ver
  esa sección más abajo.

## Instalación

1. Copiá la carpeta `LOTRO_Quest_Assistant` completa dentro de:
   ```
   Documentos\The Lord of the Rings Online\Plugins\
   ```
2. Abrí LOTRO → **Opciones → Plugins** → tildá **"QuestSync"**.

Con esto ya tenés el tracker, el mapa y la traducción funcionando.

### Narración por voz (opcional)

Los botones de narrar/silenciar necesitan una pieza aparte corriendo
en tu PC (LOTRO no permite reproducir audio desde un addon) — es
gratis, un solo instalador de un click:

- [**Narrador_IA**](https://github.com/sharshazo/Narrador_IA) — la app
  que sintetiza y reproduce la voz (`Instalar.bat`, sin conocimientos
  de programación).

Sin esa pieza, QuestSync funciona igual — solo no vas a escuchar la
narración.

## Créditos

Integra datos de referencia de Compendium y MoorMap/Waypoint
(addons de terceros ya instalados por separado por el usuario).
