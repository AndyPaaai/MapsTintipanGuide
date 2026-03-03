# Mapas Guía Tintipán - Especies del Caribe

Este repositorio contiene el script principal de **R** y los mapas de distribución resultantes para la guía de especies marinas enfocada en la isla Tintipán y el Caribe colombiano. 

## Contenido del Proyecto
- **`mapas_taxones_caribe.R`**: Script automatizado en R que utiliza la librería `rgbif` para descargar registros de ocurrencia georreferenciados de especies, géneros y familias de invertebrados, peces, algas y plantas. Adicionalmente, usa los paquetes `ggplot2`, `sf` y `marmap` para procesar la batimetría del Caribe y generar mapas visuales de distribución para cada taxón.
## Fuentes de Datos
Este proyecto ensambla información espacial y biológica de acceso abierto:

1. **Batimetría y Elevación (Mapa Base):**
   - **Fuente:** NOAA (National Oceanic and Atmospheric Administration), específicamente la base de datos *ETOPO*.
   - **Rol:** Se descarga un bloque matricial de la región (-96 a -54 Longitud, 4 a 32 Latitud) a través del paquete `marmap`. Funciona como el "lienzo" base, mostrando las profundidades del Mar Caribe y el relieve costero, diferenciando entre tierra firme y el océano.
   
2. **Registros de Ocurrencia Biológica:**
   - **Fuente:** GBIF (Global Biodiversity Information Facility).
   - **Rol:** A través del paquete de R `rgbif`, el script se conecta a la API de GBIF para descargar todos los registros históricos georreferenciados para cada taxón dentro de las coordenadas del Caribe. Se diseñó para funcionar inteligentemente: busca el ID taxonómico exacto (`taxonKey`), asegurando la descarga exhaustiva no solo de especies individuales (ej. *Rhizophora mangle*), sino también de todos los miembros pertenecientes a agrupaciones mayores como géneros (ej. *Padina*) o familias (ej. *Mytilidae*).

## Componentes Gráficos del Mapa
Cada mapa geográfico construido ha sido estandarizado visualmente usando `ggplot2` y `sf` para garantizar un aspecto profesional y consistente en todos los resultados. Cada gráfico generado contiene:
- **Batimetría Océano:** 5 niveles y cortes de contorno rellenos de distintas tonalidades cian/azul claro para representar rangos de profundidad.
- **Tierra Firme:** Rasterizado en tonos grisáceos continuos que indican altitud.
- **Distribución de Especie:** Los miles de puntos crudos de GBIF son transformados. Se les traza un polígono *"buffer"* circundante (margen de 15km) que unifica los puntos adyacentes, generando una sombra de distribución continua de color marrón rosáceo (`#cdaaa1`).
- **Cartografía Estándar:**
  - **Graticula (Grid):** Cuadrícula punteada blanca de coordenadas superpuesta al océano. Expresa latitudes y longitudes exactas en los ejes en texto grisáceo.
  - **Rosa de los Vientos:** Una indicación formal del Norte (`annotation_north_arrow` con estilo *fancy_orienteering*) fija en la esquina superior derecha para referenciar la orientación.
  - **Estética Limpia:** Fondo marino (`#c1f0f0`) y recuadro limitante negro (panel border) usando una temática mínima. El nombre científico del taxón aparece siempre centrado e itinerado en el título superior.

## Contenido del Repositorio
- **`mapas_taxones_caribe.R`**: Script automatizado principal.
- **`codeSpecieExample.R`**: Archivo secundario con código referencial de una única demostración.
- **Carpetas por Taxón**: Directorios autogenerados con espacios sustituidos por guiones bajos (ej. `Amphibalanus_eburneus`). Cada directorio resguarda el mismo mapa estandarizado en dos formatos listos para usarse:
  - **.png:** Mapa rasterizado de alta calidad (300 dpi).
  - **.svg:** Mapa de formato de Gráficos Vectoriales Escalables, indispensable para maquetar, redimensionar, y componer la "Guía de Especies" sin pérdida de nitidez.

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
