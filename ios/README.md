# CLO3D Museum — iPhone AR prototype

Esta carpeta contiene el núcleo iOS/RealityKit de la experiencia museográfica.

## Flujo

1. La app abre la experiencia AR con cámara trasera.
2. El visitante ve “Escanea el código QR para visualizar el diseño”.
3. Los QR internos deben contener texto como `LOOK_01`, `LOOK_02`, etc.
4. Al reconocer el QR, la app busca `look01.usdz`, `look02.usdz`, etc.
5. RealityKit crea un ancla sobre un plano horizontal clasificado como suelo.
6. El avatar/prenda aparece a escala definida en el USDZ.
7. La X elimina la pieza y regresa al modo de escaneo.

## Para crear el proyecto en Xcode

Crea una app iOS SwiftUI y añade `CLO3DMuseumApp.swift` y `ARScannerView.swift` al target.

Añade al Info.plist la clave `NSCameraUsageDescription` con un texto como:

`La cámara se utiliza para escanear las piezas de la exposición y visualizarlas en realidad aumentada.`

Añade los archivos USDZ al target de la aplicación con nombres `look01.usdz`, `look02.usdz`, etc.

## Pendiente para producción

- Diseñar la interfaz final.
- Probar escala real de cada avatar/prenda.
- Añadir feedback visual mientras ARKit encuentra el suelo.
- Definir estrategia de foto/video. iOS limita cómo una app puede capturar/grabar y guardar contenido, por lo que se implementará con permisos y APIs nativas apropiadas.
- Optimizar cada USDZ para móvil.
- Crear los QR físicos de cada alumno.
- Probar en los modelos de iPhone que se usarán en la exposición.

Este código es un prototipo base y todavía requiere abrirse/compilarse como un proyecto Xcode firmado para instalarlo en un iPhone.
