# Mapas Guía Tintipán - Especies del Caribe

Este repositorio contiene el script principal de **R** y los mapas de distribución resultantes para la guía de especies marinas enfocada en la isla Tintipán y el Caribe colombiano. 

## Contenido del Proyecto
- **`mapas_taxones_caribe.R`**: Script automatizado en R que utiliza la librería `rgbif` para descargar registros de ocurrencia georreferenciados de especies, géneros y familias de invertebrados, peces, algas y plantas. Adicionalmente, usa los paquetes `ggplot2`, `sf` y `marmap` para procesar la batimetría del Caribe y generar mapas visuales de distribución para cada taxón.
- **`codeSpecieExample.R`**: Un archivo con código de ejemplo inicial.
- **Carpetas por Taxón**: Directorios generados automáticamente para cada especie o grupo taxonómico documentado. Cada subcarpeta contiene:
  - Un mapa en formato **PNG** (alta resolución, 300 dpi) para rápida visualización o reportes.
  - Un mapa en formato vectorial **SVG** para edición e incrustación en la guía gráfica sin perder calidad.

## Uso del Script (`mapas_taxones_caribe.R`)
El script fue adaptado para resolver inteligentemente taxones a diferentes niveles (familia, género, o especie) usando identificadores de GBIF (`taxonKey`). 

### Para ejecutar o añadir nuevas especies:
1. Abre el script en tu entorno local de R/RStudio.
2. Agrega los nombres científicos (ej. `"Acropora cervicornis"`) en la lista `lista_taxones`.
3. Ejecuta el archivo, el cual generará la nueva carpeta local junto a los vectores si encuentra coordenadas en la región delimitada.

## Dependencias
Se requiere instalación de librerías locales, particularmente:
\`\`\`R
c("rgbif", "sf", "ggplot2", "dplyr", "marmap", "ggnewscale", "ggspatial", "svglite")
\`\`\`
