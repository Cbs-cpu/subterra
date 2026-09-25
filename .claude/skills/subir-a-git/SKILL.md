---
name: subir-a-git
description: Regla del proyecto Subterra - todo cambio que se haga en el repo se commitea y se sube a GitHub (origin/main, https://github.com/Cbs-cpu/subterra). Usar al terminar cualquier tarea que modifique archivos del proyecto.
---

# Subir todo a git

En este proyecto **todo lo que se haga se sube a git**. Al terminar cada tarea que cambie archivos:

1. Comprueba que el proyecto compila y que pasan los tests:
   ```bash
   "C:/Users/Cobos/Desktop/Godot_v4.6.3-stable_win64_console.exe" --headless --path . -s res://tests/run_tests.gd
   ```
   Si algo falla, arréglalo antes de subir (o, si no se puede, súbelo igualmente indicando en el mensaje qué falla y avisa al usuario).
2. Revisa qué ha cambiado: `git status --short` y `git diff --stat`. No subas carpetas generadas (`shots/`, `art_export/`, `.godot/` ya están en `.gitignore`).
3. Commit con un mensaje en español que explique el cambio, terminado con la línea de atribución que indique la sesión.
4. Sube: `git push origin main`.
5. Verifica que `git ls-remote origin main` coincide con `git rev-parse HEAD` y díselo al usuario en una línea.

No hagas `push --force` ni reescribas el historial salvo que el usuario lo pida explícitamente.
