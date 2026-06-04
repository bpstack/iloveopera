# iloveopera — Guía completa del proyecto

> Documentación detallada pensada para alguien que parte casi de cero en
> programación. Explica primero las **ideas base** (lenguaje, Flutter, compilar,
> arquitectura limpia) y después **recorre el repositorio carpeta por carpeta**
> con sus archivos más importantes.

---

## Índice

1. [Conceptos previos que necesitas saber](#1-conceptos-previos-que-necesitas-saber)
   1.1 [¿En qué lenguaje está escrito iloveopera?](#11-en-qué-lenguaje-está-escrito-iloveopera)
   1.2 [¿Qué es Flutter?](#12-qué-es-flutter)
   1.3 [¿Qué es "compilar"?](#13-qué-es-compilar)
   1.4 [¿Qué es "ejecutar en modo debug"?](#14-qué-es-ejecutar-en-modo-debug)
   1.5 [¿Qué es un paquete / dependencia?](#15-qué-es-un-paquete--dependencia)
   1.6 [¿Qué es código generado (build_runner / freezed / json_serializable)?](#16-qué-es-código-generado-build_runner--freezed--json_serializable)
2. [¿Qué hace iloveopera?](#2-qué-hace-iloveopera)
3. [Las tres ideas de arquitectura del proyecto](#3-las-tres-ideas-de-arquitectura-del-proyecto)
   3.1 [Clean Architecture feature-first](#31-clean-architecture-feature-first)
   3.2 [Riverpod para el estado](#32-riverpod-para-el-estado)
   3.3 [pdfrx + pdf + printing para los PDF](#33-pdfrx--pdf--printing-para-los-pdf)
4. [Recorrido por el árbol de carpetas](#4-recorrido-por-el-árbol-de-carpetas)
   4.1 [Raíz del repositorio](#41-raíz-del-repositorio)
   4.2 [`lib/` — el corazón del código](#42-lib--el-corazón-del-código)
   4.3 [`lib/app/` — composición de la app](#43-libapp--composición-de-la-app)
   4.4 [`lib/core/` — utilidades transversales](#44-libcore--utilidades-transversales)
   4.5 [`lib/features/pdf_viewer/` — abrir y ver PDF (Fase 1)](#45-libfeaturespdf_viewer--abrir-y-ver-pdf-fase-1)
   4.6 [`lib/features/annotation/` — la capa de anotación (Fases 2 y 3)](#46-libfeaturesannotation--la-capa-de-anotación-fases-2-y-3)
   4.7 [`lib/features/export/` — exportar PDF nuevo (Fase 4)](#47-libfeaturesexport--exportar-pdf-nuevo-fase-4)
   4.8 [`lib/features/project/` — guardar / reabrir sesión (Fase 5)](#48-libfeaturesproject--guardar--reabrir-sesión-fase-5)
   4.9 [`lib/services/` — infraestructura compartida](#49-libservices--infraestructura-compartida)
   4.10 [`lib/shared/` y `lib/features_future/`](#410-libshared-y-libfeatures_future)
   4.11 [`assets/` — fuentes TTF embebidas](#411-assets--fuentes-ttf-embebidas)
   4.12 [`test/` — pruebas automatizadas](#412-test--pruebas-automatizadas)
   4.13 [Carpetas de plataforma (`android/`, `windows/`, `linux/`)](#413-carpetas-de-plataforma-android-windows-linux)
   4.14 [Carpetas autogeneradas (no tocar)](#414-carpetas-autogeneradas-no-tocar)
5. [Los archivos de configuración importantes](#5-los-archivos-de-configuración-importantes)
6. [Cómo se relacionan las piezas en tiempo de ejecución](#6-cómo-se-relacionan-las-piezas-en-tiempo-de-ejecución)
7. [Comandos útiles del día a día](#7-comandos-útiles-del-día-a-día)
8. [Glosario rápido](#8-glosario-rápido)

---

## 1. Conceptos previos que necesitas saber

### 1.1 ¿En qué lenguaje está escrito iloveopera?

Está escrito en **Dart**. Todo el código fuente del proyecto son archivos
`.dart` (mira cualquier archivo de `lib/`).

**Dart** es un lenguaje creado por Google. Algunas de sus características:

- **Tipado opcional fuerte**: puedes declarar `String` (texto), `int` (entero),
  `double` (decimal), `bool` (verdadero/falso), `List<T>` (lista), etc. Si
  declaras una variable como `int`, el compilador te avisa si intentas meter
  texto ahí.
- **Orientado a objetos**: hay clases, herencia, interfaces implícitas, etc.
- **AOT y JIT**: el mismo código se puede compilar **por anticipado** (AOT, "ahead
  of time") para producir binarios rápidos, o **interpretar en caliente**
  (JIT, "just in time") durante el desarrollo para recargar al instante.
- **Null safety**: distingue "puede ser nulo" (`String?`) de "nunca es nulo"
  (`String`). Te obliga a comprobar los nulos antes de usarlos.

Ejemplo real sacado de este proyecto (`lib/main.dart`):

```dart
void main() {
  runApp(const ProviderScope(child: IloveoperaApp()));
}
```

`void main()` es el **punto de entrada** del programa: la primera función que
se ejecuta. Llama a `runApp(...)`, que le dice a Flutter "esta es la app que
tienes que pintar".

### 1.2 ¿Qué es Flutter?

**Flutter** es un **framework** (un conjunto de herramientas y reglas) que
permite escribir **una sola base de código** y compilar apps para:

- Android (móvil/tablet)
- iOS (móvil/tablet — *fuera del alcance de este proyecto*)
- Windows (escritorio)
- macOS (escritorio — *fuera de alcance*)
- Linux (escritorio)
- Web (navegador — *fuera de alcance*)

Su idea central: en lugar de usar los componentes nativos del sistema (botones
nativos de Android, de Windows, etc.), Flutter **pinta todos los píxeles
directamente** usando su propio motor gráfico (Skia / Impeller). Eso le permite
verse **idéntico** en todas las plataformas.

Los elementos visuales se llaman **Widgets**. Un botón es un Widget
(`ElevatedButton`, `IconButton`, `FilledButton`...). Un texto es un Widget
(`Text`). Una columna que apila cosas verticalmente es un Widget (`Column`).
Incluso un margen es un Widget. **Todo** se compone combinando Widgets.

```dart
Scaffold(
  appBar: AppBar(title: const Text('Hola')),
  body: const Center(child: Text('Bienvenido a iloveopera')),
)
```

- `Scaffold` = la "estructura" de una pantalla (app bar + cuerpo + menú).
- `AppBar` = la barra de arriba.
- `Center` = centra su hijo.
- `Text` = muestra texto.

Flutter tiene una librería gigante de Widgets prefabricados (botones, listas,
diálogos, animaciones, gestos, etc.) y tú los combinas para construir tu UI.

### 1.3 ¿Qué es "compilar"?

El código que escribes en Dart es **texto** (como una receta en un papel). La
computadora no entiende texto, solo entiende **instrucciones de máquina** (una
secuencia larguísima de números). **Compilar** es traducir ese texto a
instrucciones que el procesador puede ejecutar.

Hay dos grandes modos:

1. **Compilación AOT (Ahead Of Time)**: se hace **una vez** y produces un
   binario (.exe en Windows, .apk en Android, .AppImage en Linux). El usuario
   final lo ejecuta y va rapidísimo, sin más preparación. Es el modo "release".
2. **Compilación/interpretación JIT (Just In Time)**: el programa se traduce
   **mientras corre**. Permite **hot reload** (recargar al instante cuando
   guardas un archivo) y por eso es el modo "debug" durante el desarrollo.

En este proyecto verás dos comandos típicos:

```powershell
flutter run -d windows        # modo debug: compilación JIT, hot reload activo
flutter build windows --release  # modo release: binario optimizado
```

### 1.4 ¿Qué es "ejecutar en modo debug"?

Cuando ejecutas `flutter run -d windows` ocurren varias cosas a la vez:

1. Flutter **comprueba** qué dispositivos hay conectados (`-d windows` significa
   "la versión de escritorio para Windows").
2. **Compila el código Dart** en JIT.
3. **Lanza la app** en una ventana nativa de Windows.
4. Se queda **vigilando** tus archivos. Cuando guardas un cambio, lo envía a la
   app en ejecución y la UI se actualiza **sin perder el estado** (es lo que se
   llama *hot reload*).
5. Los `print()` de Dart salen en la **consola** desde la que lanzaste el
   comando.

Si la compilación falla, **no arranca** y la consola muestra el error. Por eso
muchas veces，我们会 "leer" la consola igual que un médico lee un análisis.

### 1.5 ¿Qué es un paquete / dependencia?

Un **paquete** (en inglés *package*) es código que otro programador ya escribió
y que tú puedes reutilizar. Es lo mismo que una "librería" en otros lenguajes.

En Flutter los paquetes se declaran en `pubspec.yaml`. Cuando haces
`flutter pub get`, Flutter los descarga a `~/.pub-cache` y los deja listos para
importar. Ejemplo de `pubspec.yaml` de este proyecto:

```yaml
dependencies:
  flutter_riverpod: ^3.3.1   # gestión de estado
  pdfrx: ^2.4.3              # render de PDF
  pdf: ^3.12.0               # generar PDF
  printing: ^5.14.3          # diálogo de impresión / exportar
  file_selector: ^1.1.0      # selector de archivos del sistema
  freezed_annotation: ^3.1.0 # anotaciones para clases inmutables
  uuid: ^4.5.3               # generar IDs únicos
```

Y luego en el código los importas así:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
```

**Regla del proyecto**: solo se permiten paquetes con licencia **MIT, BSD o
Apache-2.0**. Syncfusion y cualquier SDK comercial están prohibidos (ver
`ROADMAP.md` §1.5).

### 1.6 ¿Qué es código generado (build_runner / freezed / json_serializable)?

Hay partes del código que son **repetitivas y mecánicas**. Por ejemplo, si tienes
una clase `Annotation` con 10 campos, "a mano" tendrías que escribir un
constructor, un `copyWith`, un `toString`, `==`, `hashCode`, un `toJson`, un
`fromJson`... son cientos de líneas mecánicas.

Para no escribirlas a mano, este proyecto usa **generadores de código**: tú
escribes una declaración corta con **anotaciones** (palabras que empiezan por
`@`), y un programa (`build_runner`) genera el resto en archivos `.g.dart` o
`.freezed.dart`.

Mira `lib/features/annotation/domain/entities/annotation.dart`:

```dart
@freezed
sealed class Annotation with _$Annotation {
  const factory Annotation.text({
    required String id,
    required int pageNumber,
    required PageRect rect,
    required String text,
    ...
  }) = TextAnnotation;
  ...
}
```

`@freezed` significa "genera todo el código repetitivo de esta clase". Cuando
editas este archivo, tienes que ejecutar:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Esto crea/actualiza:

- `annotation.freezed.dart` → `copyWith`, `==`, `toString`, pattern matching.
- `annotation.g.dart` → `fromJson` / `toJson`.

**Regla del proyecto**: esos archivos generados **nunca los editas a mano**;
se regeneran.

---

## 2. ¿Qué hace iloveopera?

Es un **editor de PDF local**, offline, privado. El usuario:

1. **Abre un PDF** desde su sistema de archivos (o desde SAF en Android).
2. Lo **visualiza** página por página, con miniaturas y zoom.
3. Le **anota cosas encima** con cuatro herramientas:
   - **Texto libre** (con familia, tamaño y color de fuente configurables).
   - **Rectángulo opaco** ("tipp-ex") para tapar texto y escribir encima.
   - **Dibujo a mano alzada** (trazo libre con color y grosor).
   - **Resaltado** de zonas (cuadrado semitransparente).
4. **Mueve, redimensiona, edita o elimina** cada anotación.
5. **Deshace/rehace** cambios (undo/redo).
6. **Guarda la sesión** (proyecto) para seguir editando otro día. La app
   **copia el PDF original** dentro de su almacenamiento y guarda las
   anotaciones como JSON. El PDF original **nunca** se toca.
7. **Exporta un PDF nuevo** con las anotaciones ya "quemadas" (incrustadas
   como parte del documento), eligiendo nombre y carpeta destino.

**Privacidad absoluta**: nada sale del dispositivo. No hay servidor, no hay
cuentas, no hay Internet, no hay telemetría.

**Plataformas soportadas**: Windows, Android, Linux.

---

## 3. Las tres ideas de arquitectura del proyecto

### 3.1 Clean Architecture feature-first

El proyecto está dividido en **features** (funcionalidades), y cada feature
tiene **tres capas**:

```
  presentation  ──►  domain  ◄──  data
   (UI + estado)    (núcleo)     (infra)
```

- **domain** = el "cerebro" puro. Solo Dart, sin Flutter, sin paquetes externos.
  Define **entidades** (qué es una `Annotation`, un `PdfSession`...), **contratos**
  (qué tiene que cumplir un `PdfRepository` o un `AnnotationStore`) y **casos de
  uso** (acciones como "abrir PDF", "añadir anotación", "deshacer").
- **data** = la implementación técnica de esos contratos usando paquetes reales
  (pdfrx, file_selector, etc.). Es la **única capa** que sabe de pdfrx, de
  archivos, de píxeles.
- **presentation** = la **UI** (Widgets) y los **providers de Riverpod** (que
  conectan la UI con la lógica). No conoce los detalles de `data`; solo le pide
  cosas a `domain` a través de los providers.

La regla de dependencias es estricta:

> `domain` no importa Flutter ni librerías externas.  
> `presentation` no importa `data` (solo `domain`).  
> `data` implementa los contratos de `domain`.

**¿Por qué?** Para que cambiar pdfrx por otra librería en el futuro toque
**solo `data`**, sin romper ni la UI ni la lógica.

Las cuatro features del proyecto son:

| Feature              | Función                              | Fase |
|----------------------|--------------------------------------|------|
| `pdf_viewer`         | Abrir, mostrar, navegar, hacer zoom  | 1    |
| `annotation`         | Anotar encima (texto, rect, trazo, highlight) | 2 y 3 |
| `export`             | Exportar PDF nuevo con todo "quemado" | 4    |
| `project`            | Guardar y reabrir sesiones           | 5    |

Hay además `features_future/` con **carpetas vacías** (solo `.gitkeep`) para
firma, sellos, búsqueda, notas, OCR, cifrado, modo lectura. Sirven para que
nadie improvise la ubicación de esas features cuando se implementen; mientras
tanto, no contienen nada.

### 3.2 Riverpod para el estado

**Riverpod** es el sistema de gestión de estado. Sustituye al "setState" clásico
de Flutter y permite que **cualquier widget** pueda leer o cambiar el estado
**sin prop drilling** (sin pasar datos de padre a hijo a nieto...).

En este proyecto verás muchos **providers**:

```dart
final annotationStoreProvider = Provider<AnnotationStore>((ref) {
  final store = AnnotationStoreImpl();
  ref.onDispose(store.clear);
  return store;
});
```

Esto significa: "crea una sola instancia compartida de `AnnotationStoreImpl`
para toda la app; cuando se cierre, llama a `clear()`".

En la UI se leen así:

```dart
final tool = ref.watch(annotationToolProvider);   // se redibuja si cambia
ref.read(annotationToolProvider.notifier).set(AnnotationTool.pan); // cambiar
```

`ref.watch` = "dame el valor y redibújame cuando cambie".  
`ref.read` = "dame el valor ahora, no me redibujes".

**`AsyncNotifier`** es la variante para valores asíncronos (operaciones que
tardan, como "abrir PDF" o "exportar"). Tiene estados `loading`, `data`,
`error`.

### 3.3 pdfrx + pdf + printing para los PDF

El proyecto usa **dos librerías distintas** para PDF y eso es a propósito:

- **pdfrx** = **lee y renderiza** PDF. Convierte páginas a imágenes que Flutter
  puede mostrar. Usa el motor **pdfium** (el mismo que usa Chrome) y permite
  zoom, scroll, miniaturas, selección de texto. **No escribe** PDF; solo los
  visualiza. Licencia MIT.
- **pdf** + **printing** = **escribe y construye** PDF nuevos. Permite generar
  un PDF desde cero dibujando texto, imágenes, formas. Licencia Apache-2.0.

**Estrategia de export (Opción A, "rasterizar")**:

1. pdfrx convierte cada página original a una **imagen PNG** a alta resolución.
2. El paquete `pdf` crea un **nuevo documento** colocando esa imagen al tamaño
   real de la página.
3. Encima de cada imagen, `pdf` dibuja las anotaciones con sus fuentes TTF
   embebidas.
4. Se guarda como **archivo nuevo**. El original no se toca.

Como pega: el PDF exportado **pierde la capa de texto seleccionable** del
original (es una imagen). Es una decisión consciente: el flujo es "tapar y
anotar", no "editar texto original".

---

## 4. Recorrido por el árbol de carpetas

### 4.1 Raíz del repositorio

```
C:\Users\dz\projects\iloveopera\
├── android/        # configuración Android (Gradle, manifest, etc.)
├── assets/         # archivos empaquetados (fuentes TTF)
├── build/          # salida de compilación (se regenera, NO TOCAR)
├── lib/            # todo el código Dart de la app
├── linux/          # configuración Linux
├── test/           # tests automáticos
├── windows/        # configuración Windows
├── .dart_tool/     # autogenerado por Dart/Flutter (NO TOCAR)
├── .git/           # control de versiones Git (NO TOCAR)
├── .idea/          # configuración de IntelliJ/Android Studio (NO TOCAR)
├── analysis_options.yaml
├── BUILD.md
├── CLAUDE.md
├── iloveopera.iml
├── pubspec.lock
├── pubspec.yaml
├── README.md
├── ROADMAP.md
└── TODO.md
```

Archivos sueltos importantes:

- **`pubspec.yaml`** = manifiesto del proyecto Dart/Flutter. Declara nombre,
  versión, dependencias de runtime, dependencias de desarrollo, configuración
  de assets (las fuentes) y configuración `msix` (empaquetado Windows).
  Piensa en él como el "package.json" de Node o el "pom.xml" de Maven.
- **`pubspec.lock`** = archivo generado por `flutter pub get` que **fija las
  versiones exactas** de cada dependencia. Garantiza que dos desarrolladores
  tengan las mismas versiones.
- **`analysis_options.yaml`** = reglas del analizador estático (linter). Activa
  el conjunto `flutter_lints` y permite customizar reglas. `flutter analyze`
  ejecuta estas reglas.
- **`ROADMAP.md`** = **fuente de verdad** del proyecto. Explica decisiones
  técnicas, fases, dependencias, reglas. Cualquier desarrollador o modelo
  *debe* leerlo antes de tocar código.
- **`CLAUDE.md`** = instrucciones rápidas para un asistente de IA. Resumen de
  comandos, estado, reglas.
- **`BUILD.md`** = cómo construir instalables en Windows, Android, Linux.
- **`TODO.md`** = checklist de revisión de funcionalidades (Fases 0–6).
- **`README.md`** = el que Flutter generó por defecto. Apenas tiene contenido;
  el verdadero README es el ROADMAP.
- **`iloveopera.iml`** = configuración de IntelliJ (NO TOCAR manualmente).
- **`.gitignore`** = indica a Git qué archivos ignorar (builds, caché, etc.).

### 4.2 `lib/` — el corazón del código

`lib/` es donde vive **todo** el código Dart que tú escribes. Solo hay un
archivo en la raíz de `lib/`: `main.dart`.

**`lib/main.dart`** (8 líneas)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  runApp(const ProviderScope(child: IloveoperaApp()));
}
```

- `void main()` = arranque de cualquier programa Dart.
- `runApp(...)` = le pasa a Flutter el Widget raíz.
- `ProviderScope` = instala Riverpod en toda la app. Sin esto, ningún provider
  funcionaría.
- `IloveoperaApp` = la clase que define toda la app (la veremos en `app/`).

El resto de `lib/` está organizado en subcarpetas por responsabilidad.

### 4.3 `lib/app/` — composición de la app

`lib/app/` es donde se **ensambla** la app, pero **no** contiene lógica de
negocio.

```
lib/app/
├── app.dart                    # el Widget raíz
├── router/.gitkeep             # (vacío, navegación mínima por ahora)
└── theme/
    └── app_theme.dart          # colores, tema claro/oscuro
```

**`app.dart`** declara `IloveoperaApp`, un `ConsumerWidget` (un Widget con
acceso a Riverpod). Devuelve un `MaterialApp` con:

- `title: 'iloveopera'`
- tema claro (`AppTheme.light()`)
- tema oscuro (`AppTheme.dark()`)
- `themeMode: ThemeMode.system` → sigue el ajuste del sistema operativo
- `home: const ViewerScreen()` → la única pantalla real de la app

`debugShowCheckedModeBanner: false` quita la cinta de "DEBUG" en la esquina
superior derecha.

**`theme/app_theme.dart`** define los dos temas usando Material 3 y un color
semilla (seed) `Colors.indigo`. A partir de ese color, `ColorScheme.fromSeed`
genera toda la paleta coherente (primary, secondary, tertiary, surface...).

**Regla**: la app no usa el sistema de rutas de Flutter (`go_router`, etc.)
porque **solo hay una pantalla principal** (`ViewerScreen`). Cuando se abre la
lista de proyectos, se hace con `Navigator.push` directamente.

### 4.4 `lib/core/` — utilidades transversales

```
lib/core/
├── constants/.gitkeep
├── errors/.gitkeep
├── extensions/.gitkeep
├── utils/.gitkeep
└── result/
    └── result.dart
```

`core/` contiene código **reutilizable por todas las features**, sin depender de
ninguna feature concreta. Por ahora casi todo está vacío (los `.gitkeep` son
archivos vacíos cuyo único fin es que Git guarde la carpeta).

Lo único con contenido es **`core/result/result.dart`** (30 líneas), que define
el tipo `Result<T>`:

```dart
sealed class Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  R when<R>({
    required R Function(T value) success,
    required R Function(Object error) failure,
  });
}
class Success<T> extends Result<T> { final T value; }
class Failure<T> extends Result<T> { final Object error; }
```

Es el equivalente a `Either<Success, Failure>` de Haskell/Rust: una operación
que puede **acabar bien** (con un valor) o **mal** (con un error). Se usa en
los repositorios para no lanzar excepciones a la UI; la UI hace
`result.when(success: ..., failure: ...)` y decide qué mostrar.

### 4.5 `lib/features/pdf_viewer/` — abrir y ver PDF (Fase 1)

Esta es la feature más grande y la **primera que se implementó**. Es la
encargada de:

- Mostrar el diálogo del sistema para elegir un PDF.
- Cargarlo en memoria (pdfrx).
- Renderizar las páginas.
- Gestionar navegación (anterior/siguiente, ir a página, miniaturas).
- Gestionar zoom (campo numérico, botones +/-, ajustar a la página).

```
lib/features/pdf_viewer/
├── domain/
│   ├── entities/
│   │   ├── pdf_failure.dart      # tipos de error
│   │   └── pdf_session.dart      # sesión abierta (metadata)
│   ├── repositories/
│   │   └── pdf_repository.dart   # contrato abstracto
│   └── usecases/
│       ├── open_pdf_from_picker.dart
│       └── render_thumbnail.dart
├── data/
│   ├── datasources/
│   │   └── pdfrx_data_source.dart   # wrapper directo de pdfrx
│   └── repositories/
│       └── pdf_repository_impl.dart # implementación del contrato
└── presentation/
    ├── providers/
    │   ├── pdf_session_provider.dart  # el provider de la sesión
    │   ├── thumbnail_provider.dart    # miniaturas reactivas
    │   ├── viewer_controller_provider.dart  # el controlador del visor
    │   └── viewer_state_providers.dart      # página actual, zoom actual
    ├── screens/
    │   └── viewer_screen.dart  # la pantalla principal
    └── widgets/
        ├── page_navigation_bar.dart
        ├── pdf_viewer_widget.dart
        ├── thumbnail_rail.dart
        └── zoom_controls.dart
```

**`domain/entities/pdf_failure.dart`**: define la jerarquía sellada de
errores:

- `PdfCancelledByUser` = el usuario canceló el diálogo.
- `PdfInvalidFile` = el archivo no se puede parsear.
- `PdfIoError` = problema de lectura/escritura.
- `PdfPageOutOfRange` = se pidió una página que no existe.

**`domain/entities/pdf_session.dart`**: define dos clases puras (sin Flutter):

- `PdfSession` = la sesión abierta. Tiene `sourceName` (nombre a mostrar),
  `pageCount` (cuántas páginas), `pages` (lista de `PdfPageInfo`), y dos campos
  opcionales: `sourcePath` (ruta del archivo, que es `null` en Android SAF) y
  `projectId` (UUID si se restauró desde un proyecto guardado).
- `PdfPageInfo` = metadata de una página: `pageNumber`, `widthPoints`,
  `heightPoints` (en **puntos PDF**, no en píxeles).

**`domain/repositories/pdf_repository.dart`**: el **contrato** que la capa
`data` implementa. Define:

- `openPdfFromPath(path, displayName, projectId)` → `Result<PdfSession>`
- `openPdfFromBytes(bytes, displayName)` → `Result<PdfSession>`
- `close()` para liberar el documento nativo.
- `isOpen` getter.
- `renderThumbnail(pageNumber, maxPixelSize)` → bytes PNG.

**`domain/usecases/open_pdf_from_picker.dart`**: clase `OpenPdfFromPicker`.
Coordinación entre el `FileService` (pide el archivo) y el `PdfRepository` (lo
abre). Devuelve `Result<PdfSession>`. Si el usuario cancela, devuelve
`PdfCancelledByUser`. Si la ruta está vacía (caso SAF), usa
`openPdfFromBytes`; si no, `openPdfFromPath`.

**`domain/usecases/render_thumbnail.dart`**: caso de uso trivial, solo delega al
repositorio. Sirve para mantener la simetría con el resto (cada acción
importante es un caso de uso testeable).

**`data/datasources/pdfrx_data_source.dart`**: la **única** clase que importa
`package:pdfrx/pdfrx.dart`. Es un envoltorio fino que:

- Mantiene una única instancia de `PdfDocument` (el documento abierto).
- `openFromPath` y `openFromBytes` cierran el anterior y abren el nuevo.
- `renderPagePng` rasteriza una página a PNG conservando la relación de
  aspecto y limitando el lado mayor a `maxPixelSize` (defecto 120 px para
  miniaturas).
- Libera la imagen nativa con `dispose()` para no fugar memoria.

**`data/repositories/pdf_repository_impl.dart`**: implementa `PdfRepository`.
Envuelve todas las llamadas en `try/catch` y mapea excepciones crudas a los
tipos `PdfFailure` del dominio. La capa `presentation` nunca ve una excepción
de pdfrx sin envolver.

**`presentation/providers/pdf_session_provider.dart`**: archivo clave de la
infraestructura Riverpod. Declara:

- `pdfrxDataSourceProvider` → singleton de `PdfrxDataSource` (vive hasta que
  la app se cierre).
- `pdfRepositoryProvider` → `PdfRepositoryImpl` cableado con el data source.
- `fileServiceProvider` → `FileServiceImpl`.
- `openPdfFromPickerProvider` → caso de uso cableado.
- `pdfSessionProvider` → `Notifier<PdfSession?>` (el estado de "qué PDF
  está abierto"; `null` significa "ninguno").

**`presentation/providers/viewer_controller_provider.dart`**: un `Notifier` que
guarda el `PdfViewerController` de pdfrx (el objeto que maneja scroll, zoom,
goto...). Lo publica para que zoom/navegación/miniaturas puedan controlarlo
sin tener referencias directas.

**`presentation/providers/viewer_state_providers.dart`**: dos `Notifier`
simples: `currentPageProvider` (int, 1-based; 0 si no hay documento) y
`currentZoomProvider` (double; 0 si no hay documento). Se actualizan a partir
del `PdfViewerController`.

**`presentation/providers/thumbnail_provider.dart`**: `FutureProvider.family`
que devuelve los bytes PNG de la miniatura de una página. Usa el repositorio
y `pdfRepositoryProvider`.

**`presentation/screens/viewer_screen.dart`**: la **pantalla principal**.
Es un `ConsumerStatefulWidget`. Maneja dos layouts:

- **Ancho** (≥ 700 dp, escritorio): barra de miniaturas a la izquierda, panel
  de herramientas, visor, panel de propiedades a la derecha.
- **Estrecho** (< 700 dp, móvil): barra de herramientas horizontal arriba,
  visor, barra inferior con navegación y zoom, FAB para abrir el panel de
  propiedades como bottom sheet.

Su `AppBar` muestra los botones:

- **Abrir PDF** (siempre visible).
- **Proyectos guardados** (cuando hay documento).
- **Guardar / Actualizar proyecto** (cuando hay documento).
- **Exportar PDF** (cuando hay documento).
- **Navegación de página** y **controles de zoom** (en el AppBar ancho).

**`presentation/widgets/pdf_viewer_widget.dart`**: el Widget que envuelve
`PdfViewer` de pdfrx. Crea su propio `PdfViewerController`, lo publica en
`viewerControllerProvider`, escucha sus cambios para mantener sincronizados
`currentPageProvider` y `currentZoomProvider`. Configura:

- `panEnabled` solo si la herramienta activa es la de "mano" (en cualquier
  otra herramienta, los gestos van a la capa de anotaciones).
- `scaleEnabled: true` → pinch-zoom siempre disponible (con 2 dedos, no
  compite con los taps de la capa de anotación).
- `pageOverlaysBuilder` → devuelve `AnnotationLayer` por página.
- `onKey` → captura Ctrl+Z (deshacer) y Ctrl+Y (rehacer) a nivel global.

**`presentation/widgets/thumbnail_rail.dart`**: la columna de miniaturas a la
izquierda. Cada thumbnail se renderiza bajo demanda usando `thumbnailProvider`.
Tap en una miniatura llama a `controller.goToPage(pageNumber: ...)`.

**`presentation/widgets/zoom_controls.dart`**: los botones +/-/fit y un campo
editable de porcentaje. Lee el zoom **real** del controlador de pdfrx (no un
número inventado), de modo que siempre coincide con lo que ves en pantalla.
Cada cambio aplica `setZoom(..., duration: Duration.zero)` para no acumular
animaciones al hacer clic rápido.

**`presentation/widgets/page_navigation_bar.dart`**: anterior / "N / M" /
siguiente / botón "ir a página" (abre un diálogo con input numérico).

### 4.6 `lib/features/annotation/` — la capa de anotación (Fases 2 y 3)

Esta feature es la **capa de edición**. Se compone **encima** del visor
(dentro de `pageOverlaysBuilder`).

```
lib/features/annotation/
├── domain/
│   ├── entities/
│   │   ├── annotation.dart       # tipos de anotación (sealed union)
│   │   ├── annotation.freezed.dart  # generado
│   │   ├── annotation.g.dart        # generado
│   │   ├── page_rect.dart        # rectángulo en coords de página
│   │   ├── page_rect.freezed.dart
│   │   ├── page_rect.g.dart
│   │   ├── pdf_point.dart        # punto en coords de página
│   │   ├── pdf_point.freezed.dart
│   │   └── pdf_point.g.dart
│   ├── repositories/
│   │   └── annotation_store.dart  # contrato del almacén
│   └── usecases/
│       ├── add_annotation.dart
│       ├── move_annotation.dart
│       ├── redo_annotation.dart
│       ├── remove_annotation.dart
│       ├── undo_annotation.dart
│       └── update_annotation.dart
├── data/
│   └── repositories/
│       └── annotation_store_impl.dart   # implementación en memoria
└── presentation/
    ├── painters/
    │   └── stroke_painter.dart
    ├── providers/
    │   └── annotation_providers.dart   # providers y state notifiers
    └── widgets/
        ├── annotation_layer.dart        # overlay por página
        ├── properties_panel.dart        # panel de propiedades (derecha)
        └── tool_panel.dart              # toolbar de iconos
```

**`domain/entities/annotation.dart`**: el corazón del modelo. Define una
**unión sellada** (`sealed class Annotation`) con cuatro variantes:

- `TextAnnotation` = texto libre. Campos: id, pageNumber, rect, text,
  fontFamily, fontSize, colorArgb.
- `RectAnnotation` = rectángulo opaco ("tipp-ex"). Campos: id, pageNumber,
  rect, colorArgb, opacity.
- `StrokeAnnotation` = trazo a mano alzada. Campos: id, pageNumber, points
  (lista de `PagePoint`), rect (bounding box), colorArgb, strokeWidth.
- `HighlightAnnotation` = rectángulo semitransparente. Campos: id, pageNumber,
  rect, colorArgb (amarillo por defecto), opacity (0.4 por defecto).

El color se almacena como `int` ARGB (32 bits) y **no** como `Color` de
Flutter: así el `domain` se mantiene puro (no importa `dart:ui`). La UI hace la
conversión con `Color(argb)`.

**`domain/entities/page_rect.dart`**: rectángulo en **puntos PDF relativos a
la página** (1 punto = 1/72 pulgadas). Origen en la esquina superior
izquierda. Sistema de coordenadas **fijo** independientemente del zoom.

**`domain/entities/pdf_point.dart`**: punto 2D en puntos PDF. Se llama
`PagePoint` para no colisionar con `PdfPoint` de pdfrx.

**`domain/repositories/annotation_store.dart`**: contrato del almacén de
anotaciones. Métodos: `listAll`, `listForPage`, `getById`, `add`, `update`,
`remove`, `clear`, `undo`, `redo`, `canUndo`, `canRedo`, `toJson`,
`loadFromJson`.

**`domain/usecases/`**: 6 clases diminutas, una por acción. Cada una recibe
un `AnnotationStore` y delega. Esto permite **testear cada caso de uso
aisladamente** y obliga a que la lógica pase siempre por un punto único
(consistente con la regla "toda mutación debe ser deshacible").

**`data/repositories/annotation_store_impl.dart`**: implementación en memoria
del almacén. Mantiene una lista `_items` y dos pilas (`_undoStack` y
`_redoStack`) limitadas a **50 niveles** (cap de memoria). Cada mutación
(`add`, `update`, `remove`) hace un **snapshot** de la lista antes de
modificarla y limpia la pila de redo. `toJson`/`loadFromJson` permiten
serializar el estado entero (base de la persistencia de proyectos).

**`presentation/painters/stroke_painter.dart`**: dos `CustomPainter` de bajo
nivel:

- `StrokePainter` = pinta un trazo **terminado** (los puntos están en coords
  PDF; el painter resta el offset del bbox y multiplica por el `scale`).
- `InProgressStrokePainter` = pinta un trazo **en curso** mientras el usuario
  dibuja (los puntos están en píxeles de pantalla, no en puntos PDF todavía).

**`presentation/providers/annotation_providers.dart`**: archivo denso (287
líneas) con todos los providers de anotación:

- `annotationStoreProvider` → `AnnotationStoreImpl` singleton por sesión.
- 6 providers de casos de uso (`addAnnotationProvider`, etc.).
- **Estilos por herramienta** (cuatro `NotifierProvider<TextStyleSpec>`,
  `RectStyleSpec`, `StrokeStyleSpec`, `HighlightStyleSpec`) con sus
  `setColor`, `setSize`, `setOpacity`, etc.
- `annotationToolProvider` → herramienta activa (`AnnotationTool` enum:
  `pan`, `select`, `addText`, `addRect`, `addStroke`, `addHighlight`). En
  móvil arranca en `pan`; en escritorio, en `select`.
- `selectedAnnotationProvider` → id de la anotación seleccionada, o `null`.
- `annotationsProvider` → la **lista reactiva** de todas las anotaciones.
  Métodos: `addLocal`, `moveLocal`, `updateLocal`, `removeLocal`,
  `undoAnnotations`, `redoAnnotations`, `clearAll`, `restoreFromStore`.
- `annotationsForPageProvider(page)` → selector familia que filtra por página.
- `undoRedoProvider` → `{canUndo, canRedo}` reactivo (escucha
  `annotationsProvider` para reconstruir las pilas).
- `curadoFontsProvider` → expone `FontRegistry.curado` a la UI.

**`presentation/widgets/annotation_layer.dart`** (660 líneas): el widget más
complejo. Es un `ConsumerStatefulWidget` montado **una vez por página** por
pdfrx. Calcula un `scale` (píxeles/punto) y monta:

- Si la herramienta es de "punto único" (texto, rect, highlight): un
  `GestureDetector` que captura taps y crea la anotación en la posición.
- Si la herramienta es de "trazo": un `_StrokeDrawingLayer` que dibuja en vivo.
- Por cada anotación: un `_AnnotationWidget` posicionado y escalado, con su
  propio `GestureDetector` para moverla.
- Para la anotación seleccionada: un **handle de redimensionado** en la
  esquina inferior derecha.
- Si la herramienta es `pan`, la capa entera es **transparente al puntero**
  (`IgnorePointer`) para que pdfrx reciba el scroll y el pinch-zoom.

**`presentation/widgets/properties_panel.dart`** (597 líneas): el panel de la
derecha. Es **contextual**: muestra controles diferentes según:

- La herramienta activa (defaults para nuevas anotaciones: familia, tamaño,
  color de fuente; color + opacidad para rect/highlight; color + grosor para
  trazo).
- O, si la herramienta es `select` y hay una anotación seleccionada, los
  controles para **editar en vivo** esa anotación concreta.

Si no hay nada relevante que mostrar, se oculta (`SizedBox.shrink()`).

**`presentation/widgets/tool_panel.dart`** (164 líneas): la barra de iconos
vertical (escritorio) u horizontal (móvil). Contiene las 6 herramientas +
undo/redo + eliminar selección. En el layout vertical (escritorio), los
botones de uso frecuente (pan, select) tienen etiqueta debajo.

### 4.7 `lib/features/export/` — exportar PDF nuevo (Fase 4)

```
lib/features/export/
├── domain/
│   ├── repositories/
│   │   └── pdf_exporter.dart        # contrato
│   └── usecases/
│       └── export_to_new_pdf.dart   # caso de uso
├── data/
│   └── repositories/
│       └── raster_pdf_exporter.dart # implementación (Opción A)
└── presentation/
    └── providers/
        └── export_providers.dart    # AsyncNotifier
```

**`domain/repositories/pdf_exporter.dart`**: contrato minimalista. Un único
método `export({dpi, outputPath})`.

**`domain/usecases/export_to_new_pdf.dart`**: clase trivial que delega. Existe
por simetría con el resto de features (consistencia de patrón).

**`data/repositories/raster_pdf_exporter.dart`** (191 líneas): la
implementación real. Hace lo descrito en §3.3:

1. Lee cada TTF de `FontRegistry.curado` y lo embebe en el PDF de salida
   (`pw.Font.ttf(data)`).
2. Recorre las páginas del documento pdfrx.
3. Para cada página, llama a `page.render(fullWidth: pageW*rasterScale,
   fullHeight: pageH*rasterScale)` donde `rasterScale = dpi/72.0`.
4. Convierte el resultado a PNG con `ui.Image.toByteData`.
5. Crea una `pw.Page` con tamaño nativo (`PdfPageFormat(pageW, pageH)`).
6. Apila (en un `pw.Stack`): la imagen de fondo, los highlights, los rects,
   los textos, y un `pw.CustomPaint` final con los trazos (con inversión de Y
   porque `PdfGraphics` usa origen abajo-izquierda).
7. Serializa el documento con `pdfDoc.save()` y lo escribe en `outputPath`.

**`presentation/providers/export_providers.dart`**: `AsyncNotifier` que
orquesta el flujo:

1. Llama a `getSaveLocation` (diálogo "Guardar como" del sistema).
2. Si el usuario cancela, no hace nada.
3. Si confirma, lee el `PdfDocument` y la lista de anotaciones de los
   providers correspondientes.
4. Construye un `RasterPdfExporter` y llama al caso de uso.
5. Devuelve `AsyncLoading` durante el proceso, `AsyncData` al terminar o
   `AsyncError` si falla.

`kDefaultExportDpi = 200` es el equilibrio entre calidad y tamaño (R6).

### 4.8 `lib/features/project/` — guardar / reabrir sesión (Fase 5)

```
lib/features/project/
├── domain/
│   ├── entities/
│   │   └── edit_project.dart
│   ├── repositories/
│   │   └── project_repository.dart
│   └── usecases/
│       ├── delete_project.dart
│       ├── list_projects.dart
│       └── save_project.dart
├── data/
│   └── repositories/
│       └── project_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── project_providers.dart
    └── screens/
        └── projects_screen.dart
```

**`domain/entities/edit_project.dart`**: clase inmutable con `id` (UUID), `name`
(nombre del PDF), `savedAt` (timestamp UTC), `pageCount`, `pdfCopyPath` (ruta
absoluta al PDF **copiado** dentro del almacenamiento de la app),
`projectJsonPath` (ruta al JSON de metadata).

**`domain/repositories/project_repository.dart`**: contrato con 4 métodos:
`saveProject`, `listProjects`, `loadProject`, `deleteProject`.

**`domain/usecases/`**: tres clases finas (save, list, delete), una por
acción.

**`data/repositories/project_repository_impl.dart`** (140 líneas):
implementación basada en sistema de archivos. Estructura en el directorio de
documentos de la app:

```
iloveopera/projects/<uuid>/
├── project.json   # metadata + anotaciones serializadas
└── document.pdf   # copia del PDF original
```

El esquema de `project.json` es:

```json
{
  "schema": 1,
  "id": "...",
  "name": "Documento.pdf",
  "savedAt": "2026-06-03T12:00:00.000Z",
  "pageCount": 5,
  "annotations": [ ... ]
}
```

**Decisión clave (R12)**: al guardar, **se copia el PDF original** dentro de
la app. El archivo del usuario **no se referencia nunca**. Esto evita que un
movimiento o borrado del original rompa la sesión. El precio es duplicar el
archivo en disco.

**`presentation/providers/project_providers.dart`**: contiene el
`ProjectsNotifier`, un `AsyncNotifier<List<EditProject>>`. Su método principal
es `saveCurrentSession()`, que:

1. Lee la sesión actual (`pdfSessionProvider`).
2. Si no hay ruta (caso SAF en Android), lanza `StateError` (aún no
   soportado en Fase 5).
3. Pide al repositorio que guarde (este copia el PDF + escribe el JSON).
4. Actualiza la sesión con el `projectId` para que futuros guardados
   **sobreescriban** el mismo proyecto.
5. Refresca la lista.

`openProject(EditProject)` lee las anotaciones del JSON, abre la copia del
PDF, resetea el estado de anotaciones, restaura la sesión con `projectId`,
pone la página 1, zoom 0, herramienta `select`.

**`presentation/screens/projects_screen.dart`** (150 líneas): la pantalla
auxiliar con la lista de proyectos guardados. `Scaffold` con `AppBar`,
botón de refrescar, `ListView` de `Card`/`ListTile`. Cada proyecto muestra
icono PDF, nombre, fecha formateada (DD/MM/AAAA HH:MM) y páginas, con
botones "Abrir" y "Eliminar". Al abrir, navega de vuelta al viewer
(`Navigator.pop`).

### 4.9 `lib/services/` — infraestructura compartida

```
lib/services/
├── file_service/
│   └── file_service.dart     # interfaz + impl con file_selector
├── font_registry/
│   └── font_registry.dart    # catálogo de fuentes TTF
└── storage_service/.gitkeep
```

**`file_service/file_service.dart`**: tres cosas:

- `abstract class FileService` con `Future<PickedFile?> pickPdf()`.
- `class PickedFile` con `bytes`, `displayName`, `path` (path puede ser `null`
  en Android SAF).
- `class FileServiceImpl implements FileService` que usa `file_selector` para
  mostrar el diálogo. Lee los bytes con `readAsBytes()` y el path con
  `file.path`.

**`font_registry/font_registry.dart`**: la **única** fuente de verdad sobre
qué familias de fuente existen. Define:

- `FontRegistry.curado` = lista inmutable de 5 familias: Roboto, Open Sans,
  Lato, Merriweather, Source Code Pro.
- `FontFamily` con `family` (lo que entiende Flutter), `assetPath` (ruta al
  TTF) y `license` (OFL o Apache-2.0).
- `FontRegistry.byName(name)` para buscar.

**`storage_service/`**: carpeta vacía, reservada para una abstracción
adicional de almacenamiento en el futuro (R12, etc.).

### 4.10 `lib/shared/` y `lib/features_future/`

**`lib/shared/widgets/.gitkeep`**: widgets reutilizables entre features (por
ejemplo, botones genéricos, diálogos). Vacía por ahora.

**`lib/features_future/`**: 7 carpetas vacías con `.gitkeep`:

```
features_future/
├── encryption/.gitkeep   # cifrado / contraseña
├── notes/.gitkeep        # notas adhesivas
├── ocr/.gitkeep          # OCR local
├── reading_mode/.gitkeep # modo lectura
├── search/.gitkeep       # búsqueda de texto
├── signature/.gitkeep    # firma manuscrita
└── stamps/.gitkeep       # sellos personalizados
```

Estas son **features planificadas pero NO implementadas**. Las carpetas
vacías indican la ubicación correcta para cuando llegue el momento. El
ROADMAP es explícito: **NO implementar** hasta que se decida.

### 4.11 `assets/` — fuentes TTF embebidas

```
assets/fonts/
├── Lato-Regular.ttf           (~640 KB)
├── Merriweather-Regular.ttf   (~280 KB)
├── OpenSans-Regular.ttf       (~145 KB)
├── Roboto-Regular.ttf         (~500 KB)
└── SourceCodePro-Regular.ttf  (~205 KB)
```

Cada TTF está **declarado** en `pubspec.yaml` bajo `flutter.fonts`. Esto le
dice a Flutter que las empaquete dentro de la app. Se usan:

- Al **mostrar** la fuente en la UI (`TextStyle(fontFamily: 'Roboto')`).
- Al **embeber** la fuente en el PDF de salida durante el export (ROADMAP
  §2.5) — sin esto, la fuente elegida no se vería en otros lectores de PDF.

Las licencias son **OFL-1.1** (SIL Open Font License) o **Apache-2.0**,
todas permiten **embebido y redistribución**.

### 4.12 `test/` — pruebas automatizadas

```
test/
├── widget_test.dart                                   # test por defecto de Flutter (placeholder)
├── app/.gitkeep
├── core/.gitkeep
├── services/.gitkeep
├── features/
│   ├── annotation/
│   │   ├── store_json_test.dart                       # serialización JSON del almacén
│   │   ├── stroke_highlight_serialization_test.dart   # serialización de trazo y highlight
│   │   ├── undo_redo_test.dart                        # comportamiento de undo/redo
│   │   └── usecases_test.dart                         # los 6 casos de uso
│   ├── export/
│   │   └── export_to_new_pdf_test.dart                # caso de uso de export
│   ├── pdf_viewer/
│   │   └── open_pdf_from_picker_test.dart             # caso de uso abrir PDF
│   └── project/
│       └── project_usecases_test.dart                 # save/list/delete de proyectos
└── fixtures/
    ├── fixed_file_service.dart    # FileService falso para tests
    ├── multipage.pdf              # PDF multipágina para tests
    └── sample.pdf                 # PDF pequeño para tests
```

Los tests están escritos con `flutter_test` (el framework estándar). Siguen
un patrón de **mocks manuales**: una clase `_CapturExporter`,
`_InMemoryProjectRepo`, etc. implementan el contrato del dominio en memoria
para verificar el comportamiento sin tocar disco ni pdfrx.

Por convención del proyecto, **al menos los casos de uso del dominio** de cada
fase se testan (regla §8.4 del ROADMAP).

### 4.13 Carpetas de plataforma (`android/`, `windows/`, `linux/`)

Cada SO tiene una carpeta con la configuración nativa necesaria para que
Flutter pueda generar un binario:

**`windows/`** (escritorio Windows):
- `flutter/` = assets y librerías que Flutter necesita.
- `runner/` = código C++ (CMake) que compila la ventana nativa y la enlaza con
  la DLL de Flutter.
- `CMakeLists.txt` = script de CMake para compilar.
- `iloveopera.cer` y `iloveopera.pfx` = certificado autofirmado usado para
  firmar el `.msix` (el instalable de Windows Store). El password está en
  `pubspec.yaml` bajo `msix_config`.

**`android/`** (móvil Android):
- `app/` = módulo de aplicación (su propio `build.gradle.kts`).
- `gradle/` = configuración de Gradle (el sistema de build de Android).
- `build.gradle.kts`, `settings.gradle.kts` = scripts de build.
- `gradlew` y `gradlew.bat` = "wrappers" para invocar Gradle sin instalarlo
  globalmente.
- `local.properties` = rutas locales (NO se commitea; SDK de Android, etc.).

**`linux/`** (escritorio Linux):
- `flutter/` = assets y librerías de Flutter.
- `runner/` = código C++ (CMake) para la ventana GTK.
- `CMakeLists.txt` = script de build.

**No deberías tocar estos archivos** salvo que cambies el nombre de la app,
el icono, o el package identifier. El `local.properties` se regenera solo
con `flutter pub get` si hace falta.

### 4.14 Carpetas autogeneradas (no tocar)

- `.dart_tool/` = caché de Dart/Flutter (metadatos de paquetes, configuración
  del SDK, etc.). Se regenera con `flutter pub get`.
- `.idea/` = configuración del IDE IntelliJ/Android Studio (indexación, etc.).
- `build/` = **salida de compilación** (binarios, objetos intermedios). Se
  regenera con `flutter build`. Ocupa mucho y se ignora en Git.
- `pubspec.lock` = sí se commitea (fija versiones), pero **no se edita** a
  mano; Flutter lo regenera con `flutter pub get` / `flutter pub upgrade`.

---

## 5. Los archivos de configuración importantes

### `pubspec.yaml` (extracto)

```yaml
name: iloveopera
description: "Editor local de PDFs — anota, dibuja y resalta sin servidor."
publish_to: 'none'
version: 1.0.0+1
environment:
  sdk: ^3.12.1
```

- `name`: nombre del paquete (debe ser único si lo publicas en pub.dev; aquí
  no se publica).
- `publish_to: 'none'`: impide publicarlo accidentalmente.
- `version`: `1.0.0+1` = versión 1.0.0, build 1.
- `environment.sdk`: requiere Dart ≥ 3.12.1.

Las **dependencias** se dividen en `dependencies` (runtime) y
`dev_dependencies` (solo desarrollo). Algunas claves:

| Paquete              | Licencia    | Para qué                                           |
|----------------------|-------------|----------------------------------------------------|
| `flutter_riverpod`   | MIT         | Gestión de estado                                  |
| `pdfrx`              | MIT         | Render del PDF (motor pdfium)                      |
| `file_selector`      | BSD-3       | Diálogo "Abrir archivo" del SO                     |
| `freezed_annotation` | MIT         | Anotaciones para generar código inmutable          |
| `json_annotation`    | BSD-3       | Anotaciones para serializar a JSON                 |
| `uuid`               | MIT         | Generar UUIDs para anotaciones y proyectos         |
| `pdf`                | Apache-2.0  | Generar PDF de salida                              |
| `printing`           | Apache-2.0  | Rasterizar páginas + diálogo de impresión          |
| `path_provider`      | BSD-3       | Directorios estándar de la app                     |
| `path`               | BSD-3       | Manipular rutas portable                           |
| `cupertino_icons`    | MIT         | Iconos estilo iOS (no se usan apenas)              |

En `dev_dependencies`:

| Paquete              | Para qué                                       |
|----------------------|------------------------------------------------|
| `flutter_test`       | Framework de tests                             |
| `flutter_lints`      | Conjunto de reglas de linter recomendadas      |
| `freezed`            | Genera el código de clases inmutables          |
| `build_runner`       | Motor de generación de código                  |
| `json_serializable`  | Genera `fromJson` / `toJson`                   |
| `msix`               | Empaqueta la app Windows como `.msix`          |

### `msix_config`

Bloque específico de Windows. Define:

- `display_name`, `publisher_display_name`: lo que se ve en el instalador.
- `publisher`, `identity_name`: identificadores únicos estilo CN= / com.
- `msix_version`: versión del paquete.
- `description`: descripción del paquete.
- `languages: es`: idioma(s) soportados.
- `capabilities: runFullTrust`: la app necesita acceso completo al sistema
  (necesario para abrir/guardar archivos).
- `sign_msix: true` + `certificate_path` + `certificate_password`: firma el
  instalable con un certificado autofirmado (suficiente para instalar en
  local; para distribuir por la Store haría falta uno de Microsoft).

### `analysis_options.yaml`

Activa `package:flutter_lints/flutter.yaml`, un conjunto de lints
recomendados. Se ejecuta con `flutter analyze`. Si todo está limpio, no sale
ningún mensaje.

---

## 6. Cómo se relacionan las piezas en tiempo de ejecución

Imaginemos que pulsas "Abrir PDF" en la app. El flujo es:

```
[Usuario] toca "Abrir PDF" en ViewerScreen
        │
        ▼
[ViewerScreen._openPdf] llama a openPdfFromPickerProvider
        │
        ▼
[OpenPdfFromPicker.call]
  ├── Llama a FileService.pickPdf() (file_selector del SO)
  │     └── Si cancela → Failure(PdfCancelledByUser)
  ├── Si path no vacío → PdfRepository.openPdfFromPath
  │     └── PdfRepositoryImpl.openPdfFromPath
  │           └── PdfrxDataSource.openFromPath
  │                 └── PdfDocument.openFile (motor pdfium)
  ├── Si path vacío → PdfRepository.openPdfFromBytes
  │     └── PdfRepositoryImpl.openPdfFromBytes
  │           └── PdfrxDataSource.openFromBytes
  │                 └── PdfDocument.openData
  └── Devuelve Result<PdfSession>:
        Success(PdfSession(sourceName, pageCount, pages, ...))
        o Failure(...)
        │
        ▼
[ViewerScreen] en success:
  ├── annotationsProvider.notifier.clearAll()   # reset anotaciones
  ├── annotationToolProvider.set(select)        # reset herramienta
  ├── pdfSessionProvider.set(session)           # nueva sesión
  ├── currentPageProvider.set(1)
  ├── currentZoomProvider.set(0)
  └── SnackBar de confirmación

[PdfViewerWidget] escucha pdfSessionProvider:
  ├── Renderiza PdfViewer con PdfDocumentRefDirect(document)
  ├── Crea PdfViewerController y lo publica en viewerControllerProvider
  └── Inyecta AnnotationLayer en cada page overlay
        │
        ▼
[AnnotationLayer] para la página visible:
  ├── Lee annotationsForPageProvider(page)
  ├── Si herramienta es "addText" y se hace tap:
  │     ├── Muestra diálogo de texto (modal)
  │     ├── Genera id (uuid via timestamp)
  │     ├── Crea TextAnnotation
  │     └── annotationsProvider.addLocal(...)
  └── Pinta cada anotación con CustomPainters / Widgets posicionados
```

Si luego pulsas "Exportar PDF":

```
[Usuario] toca "Exportar PDF"
        │
        ▼
[ViewerScreen._exportPdf] llama a exportProvider.notifier.exportPdf()
        │
        ▼
[ExportNotifier.exportPdf]
  ├── getSaveLocation(suggestedName: 'anotaciones.pdf')
  │     └── Si cancela → return (no cambia nada)
  ├── state = AsyncLoading()
  ├── Lee dataSource.document (PdfDocument vivo)
  ├── Lee annotationStore.listAll() (todas las anotaciones)
  ├── Construye RasterPdfExporter(document, annotations)
  ├── Llama a ExportToNewPdf(exporter)(dpi: 200, outputPath: result.path)
  │     │
  │     ▼
  │   [RasterPdfExporter.export]
  │     ├── Carga y embebe las 5 fuentes TTF (FontRegistry + rootBundle)
  │     ├── Por cada página:
  │     │   ├── page.render(fullWidth: w*scale, fullHeight: h*scale)
  │     │   ├── Convierte a PNG (ui.Image → ByteData)
  │     │   ├── Crea pw.Page con PdfPageFormat(w, h)
  │     │   └── Apila: bgImage + highlights + rects + textos + strokes
  │     └── pdfDoc.save() → bytes → File(outputPath).writeAsBytes(bytes)
  └── state = AsyncData(null)   o   AsyncError(e)
        │
        ▼
[ViewerScreen] muestra SnackBar("PDF exportado correctamente.")
```

---

## 7. Comandos útiles del día a día

```powershell
flutter run -d windows                    # ejecutar en Windows (debug, hot reload)
flutter run -d <device-id>                # ejecutar en Android (ver `flutter devices`)
flutter run -d linux                      # ejecutar en Linux

flutter pub get                           # descarga dependencias y actualiza pubspec.lock
flutter pub upgrade                       # sube versiones dentro del rango del pubspec

dart run build_runner build --delete-conflicting-outputs
                                          # regenera *.freezed.dart y *.g.dart
                                          # tras editar entidades con @freezed / @JsonSerializable

flutter test                              # ejecuta todos los tests
flutter test test/features/annotation    # solo los tests de annotation
flutter analyze                           # análisis estático (esperado: 0 issues)

flutter build windows --release           # binario release de Windows
flutter build apk --release               # APK release de Android
flutter build linux --release             # AppImage release de Linux

flutter doctor                            # diagnóstico del entorno
flutter clean                             # borra build/ y .dart_tool/ (resuelve muchos males)
```

`flutter clean` + `flutter pub get` es el clásico "apaga y enciende" de
Flutter cuando algo inexplicable pasa tras un cambio de dependencias.

---

## 8. Glosario rápido

| Término                | Significado en este proyecto                                  |
|------------------------|---------------------------------------------------------------|
| **Widget**             | Bloque de UI inmutable. Todo en Flutter se compone con ellos. |
| **Provider**           | "Variable reactiva global" administrada por Riverpod.          |
| **Notifier**           | Provider con estado mutable (`state = ...`).                  |
| **AsyncNotifier**      | Notifier cuyo estado es asíncrono (loading/data/error).       |
| **sealed class**       | Clase con un conjunto cerrado de subtipos. `switch` exhaustivo.|
| **freezed**            | Generador de código para clases inmutables/sealed.            |
| **build_runner**       | Programa que ejecuta generadores de código.                   |
| **.g.dart**            | Archivo **generado** (json_serializable). NO editar.          |
| **.freezed.dart**      | Archivo **generado** (freezed). NO editar.                    |
| **FFI**                | Foreign Function Interface. pdfrx usa FFI para hablar con pdfium (C++). |
| **Native Assets**      | Mecanismo de Dart/Flutter para empaquetar binarios nativos (usado por pdfrx). |
| **SAF**                | Storage Access Framework. Sistema de Android para acceder a archivos sin pedir permisos globales. |
| **pubspec.yaml**       | Manifiesto del proyecto (deps, assets, configuración).        |
| **dpi**                | Puntos por pulgada. Controla la calidad del rasterizado al exportar. |
| **PDF point (pt)**     | 1/72 de pulgada. Unidad de medida interna de los PDF.         |
| **ARGB**               | Formato de color: Alpha + Red + Green + Blue, empaquetado en un int de 32 bits. |
| **CustomPainter**      | Widget de bajo nivel que pinta directamente sobre un Canvas.  |
| **LayoutBuilder**      | Widget que expone el ancho/alto disponible a su hijo.         |
| **MediaQuery**         | Acceso a info del dispositivo (tamaño de pantalla, plataforma, brillo, etc.). |
| **ConsumerWidget**     | Widget con acceso a Riverpod (`ref` en `build`).              |
| **hot reload**         | Recargar la app en ejecución conservando el estado, al guardar un .dart. |
| **msix**               | Formato de instalable para Windows 10/11.                     |

---

> Si te quedas atascado, el orden de consulta es: 1) este documento, 2)
> `ROADMAP.md` (decisiones cerradas), 3) `BUILD.md` (problemas de build), 4)
> `TODO.md` (estado de las verificaciones), 5) documentación oficial de
> Flutter y Riverpod 3.x (los ejemplos de 2.x en internet **no aplican**, ver
> regla §8.3 del ROADMAP).
