# Subterra

- Motor: Godot 4.6.3 (`C:/Users/Cobos/Desktop/Godot_v4.6.3-stable_win64_console.exe`), GDScript.
- Tests: `--headless --path . -s res://tests/run_tests.gd`. Compilar todo: `-s res://tools/check.gd`.
- **Regla: todo lo que se haga se commitea y se sube a GitHub** (`origin/main`, https://github.com/Cbs-cpu/subterra). Sigue la skill `subir-a-git` al terminar cada tarea.
- El arte es original y se genera por código (`scripts/art/`). No se copian assets de Magicite.
- Interfaz: todo texto se dibuja con `UiKit` (paleta verde/amarilla, `max_w` para que quepa) con la fuente pixelada `assets/fonts/subterra_pixel.ttf` (se edita en `tools/make_font.py`; tamaños reales múltiplos de 4 vía `UiKit.px`). Tras tocar la UI, ejecuta el juego con `-- --ui-audit` (con ventana, no headless): debe acabar en `UI TOTAL problemas: 0`.
