# iloveopera — CLAUDE.md

Editor PDF local-first en Flutter. Codename `iloveopera`.  
Fuente de verdad: `ROADMAP.md`. Leerlo entero antes de tocar código.

## Levantar el proyecto

```powershell
flutter run -d windows
```

Requisitos: VS Build Tools 2022 + workload "Desktop development with C++", Modo Desarrollador de Windows activado.

## Comandos frecuentes

```bash
dart run build_runner build   # regenerar código tras editar entidades domain
flutter test                  # todos los tests
flutter analyze               # 0 issues esperado
flutter build windows --release
```

## Estado actual

Fases 0–6 completadas. Las 16 funcionalidades de v1 implementadas.  
Ver checklist en `ROADMAP.md` §Fases.

## Reglas obligatorias (resumen)

- Lee `ROADMAP.md` completo antes de codificar.
- No modificar el PDF original — guardar/exportar siempre como archivo nuevo.
- Solo dependencias MIT / BSD / Apache-2.0. Syncfusion y SDKs comerciales: prohibidos.
- Coordenadas de anotación siempre relativas a la página (nunca píxeles de pantalla).
- `domain` no importa Flutter ni libs externas. `presentation` no importa `data`.
- Tras editar entidades con code-gen: `dart run build_runner build --delete-conflicting-outputs`.
- Identificadores en inglés, textos UI en español.
- Seguir solo doc oficial de Riverpod 3.x y freezed 3.x (los ejemplos 2.x rompen).

## Secretos — NUNCA commitear

- ❌ **Nunca** poner `certificate_password` (ni ninguna contraseña/clave) en
  `pubspec.yaml` ni en ningún archivo versionado. La firma MSIX recibe la
  contraseña por CLI: `dart run msix:create --certificate-password <PASSWORD>`.
- `windows/iloveopera.pfx` (clave privada) está en `.gitignore` — mantenerlo así.
- Antes de cualquier commit, revisar que el diff no incluya contraseñas, tokens
  ni claves privadas.

## Plataformas

Android · Windows · Linux. iOS / macOS / Web: fuera de alcance.

## Stack

Flutter 3.44+ / Dart 3.12+ · Riverpod 3.x · pdfrx (render) · pdf+printing (export) · freezed 3.x
