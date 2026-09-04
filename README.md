# CLO3D MUSEUM — plantilla WebAR

Esta plantilla está pensada para una exposición museográfica de prendas conceptuales creadas en CLO3D.

## Cómo funciona

Una sola web carga distintas prendas según el parámetro `?look=` de la URL:

- `...?look=01`
- `...?look=02`
- `...?look=03`

Cada alumno puede tener un QR diferente apuntando a su número.

## Archivos principales

- `index.html` — interfaz de la exposición.
- `styles.css` — diseño visual.
- `app.js` — carga la pieza según el QR/URL.
- `looks.json` — aquí editas nombre, alumno, concepto y archivo GLB.
- `models/` — coloca aquí los modelos optimizados.
- `.nojekyll` — evita que GitHub Pages procese el sitio con Jekyll.

## Agregar un alumno

1. Exporta/optimiza su prenda como GLB.
2. Nómbrala, por ejemplo, `look04.glb`.
3. Súbela a `models/`.
4. Agrega un nuevo objeto dentro de `looks.json`:

```json
{
  "id": "04",
  "title": "NOMBRE DE LA OBRA",
  "student": "Nombre del alumno",
  "year": "2026",
  "technique": "CLO3D · Moda digital",
  "concept": "Texto museográfico.",
  "model": "models/look04.glb",
  "scale": "1 1 1"
}
```

5. El QR debe apuntar a:
   `https://TU-USUARIO.github.io/TU-REPOSITORIO/?look=04`

## Publicar gratis en GitHub Pages

1. Crea un repositorio público.
2. Sube todos estos archivos conservando la estructura.
3. Ve a **Settings > Pages**.
4. En **Build and deployment**, elige **Deploy from a branch**.
5. Selecciona `main` y `/ (root)`.
6. Guarda.
7. Activa **Enforce HTTPS** si aparece disponible.

## Prueba local

Por seguridad del navegador, no abras `index.html` con doble clic para probar funciones avanzadas.
En VS Code puedes usar una extensión de servidor local o ejecutar:

`python -m http.server 8000`

y abrir:
`http://localhost:8000/?look=01`

## Sobre AR

La plantilla usa `<model-viewer>` con:
- WebXR cuando el navegador/dispositivo lo permite.
- Scene Viewer en Android compatible.
- Quick Look en iOS cuando existe un recurso USDZ compatible.

Para una primera prueba en clase, Android suele ser la ruta más directa con GLB.
Para iPhone, conviene preparar también una versión `.usdz` por look y añadirla como `ios-src` si quieres cubrir iOS de forma consistente.

## Recomendación de peso

No uses directamente la versión maestra de CLO3D. Haz una copia optimizada para móvil.
Como regla práctica inicial, intenta mantener cada GLB tan ligero como sea razonable y prueba en varios teléfonos reales antes de la exposición.
