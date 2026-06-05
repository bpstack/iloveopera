# TODO — Pendientes y trabajo futuro

---

## Bugs activos

| # | Bug | Plataforma | Estado |
|---|-----|-----------|--------|
| B7 | Guardar proyecto falla si el PDF se abrió por SAF (sin ruta de sistema) | 📱 | 🔴 pendiente — hay que guardar los bytes del PDF, no la ruta |

---

## Pendientes técnicos

- **B7 — Guardar proyecto en móvil con PDF abierto por SAF:** el PDF se abre
  por el selector de Android sin ruta de sistema accesible. Hay que guardar los
  bytes del PDF en la carpeta de la app al crear el proyecto, no la ruta.

- **Validar build en Linux:** la plataforma está en el código pero nunca se ha
  probado en un dispositivo o VM real. Verificar que `flutter run -d linux`
  compila y la app funciona correctamente.

- **Tests pendientes:** las carpetas `test/app/`, `test/core/` y `test/services/`
  están vacías. Añadir tests de integración y de widgets para las features
  principales a medida que el proyecto crezca.

- **Firma Android para distribución formal:** el APK actual usa la clave de
  depuración de Flutter. Si se sube a Google Play o se distribuye oficialmente,
  hay que crear un keystore propio y configurar la firma en
  `android/app/build.gradle.kts`.

---

## Automatización futura (GitHub Actions)

> **Cuándo vale la pena:** cuando haya más de un colaborador, o cuando publiques
> versiones con frecuencia (más de una al mes). Con un solo desarrollador y
> releases ocasionales, hacerlo a mano es perfectamente válido.

- **CI en cada push** — ejecutar `flutter analyze` + `flutter test` automáticamente.
  Corre en Linux (rápido, gratis). Evita subir código roto sin darte cuenta.

- **Release automático al crear un tag** — compilar APK + ZIP Windows y subirlos
  a GitHub Releases solos. Útil cuando los releases sean frecuentes.

  > El build de Windows tarda ~15-20 min en los servidores de GitHub. Dispararlo
  > solo en tags, no en cada push.
