# Biblioteca Turbine


## Revisión 3 del 19 de octubre de 2026

La biblioteca incluida conserva sus clases y funciones públicas. El gestor de temporizadores vuelve a comprobar la programación vigente antes de ejecutar cada callback. Reprogramar un temporizador pendiente, cambiarlo de gestor o modificar su fecha durante su propio callback no provoca un disparo anticipado ni sobrescribe la fecha elegida. Un callback que falla se desactiva de forma aislada. Se conservan los constructores de Timer, los eventos Tick, el cambio de intervalo y la descarga.
