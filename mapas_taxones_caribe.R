# ==============================================================================
# 1. CARGA DE PAQUETES
# ==============================================================================
paquetes <- c("rgbif", "sf", "ggplot2", "dplyr", "marmap", "ggnewscale", "ggspatial", "svglite")
nuevos_paquetes <- paquetes[!(paquetes %in% installed.packages()[, "Package"])]
if (length(nuevos_paquetes)) install.packages(nuevos_paquetes, repos = "https://cloud.r-project.org")

library(rgbif)
library(sf)
library(ggplot2)
library(dplyr)
library(marmap)
library(ggnewscale)
library(ggspatial)

# ==============================================================================
# 2. DESCARGA DE MAPA BASE (NOAA) - ¡SE HACE SOLO UNA VEZ!
# ==============================================================================
cat("Descargando modelo de elevación de la NOAA (Caribe)...\n")
# resolution = 4 es rápido. Cambia a 1 o 2 si necesitas más resolución en el mapa final
bathy_data <- getNOAA.bathy(lon1 = -96, lon2 = -54, lat1 = 4, lat2 = 32, resolution = 4)
bathy_df <- fortify.bathy(bathy_data)

ocean_df <- bathy_df %>% filter(z <= 0)
land_df <- bathy_df %>% filter(z > 0)

# ==============================================================================
# 3. FUNCIÓN PARA GENERAR EL MAPA POR TAXÓN
# ==============================================================================
generar_mapa_especie <- function(nombre_especie) {
  cat("\n==================================================\n")
  cat("Procesando:", nombre_especie, "\n")

  # 3.1 Descarga de datos (GBIF)
  cat("Descargando datos de GBIF...\n")

  # Usamos tryCatch para evitar que un error de conexión detenga todo el ciclo
  gbif_data <- tryCatch(
    {
      key <- name_backbone(name = nombre_especie)$usageKey
      if (is.null(key)) {
        cat("⚠️ No se encontró un ID taxonómico en GBIF para", nombre_especie, "\n")
        return(NULL)
      }
      occ_data(
        taxonKey = key,
        hasCoordinate = TRUE,
        limit = 10000,
        decimalLongitude = "-95,-55",
        decimalLatitude = "5,35",
        curlopts = list(timeout = 300, connecttimeout = 300)
      )
    },
    error = function(e) {
      cat("⚠️ Error de conexión al buscar", nombre_especie, "\n")
      return(NULL)
    }
  )

  # Verificar si hay datos
  if (is.null(gbif_data) || is.null(gbif_data$data) || nrow(gbif_data$data) == 0) {
    cat("⚠️ No se encontraron registros para", nombre_especie, "en esta área. Saltando...\n")
    return(NULL)
  }

  cat("Se descargaron", nrow(gbif_data$data), "registros.\n")

  # 3.2 Limpieza y procesamiento espacial
  df_puntos <- gbif_data$data %>%
    filter(!is.na(decimalLongitude) & !is.na(decimalLatitude)) %>%
    select(decimalLongitude, decimalLatitude)

  puntos_sf <- st_as_sf(df_puntos, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326)
  puntos_proj <- st_transform(puntos_sf, crs = 3857)

  cat("Creando polígonos de distribución (sombreado)...\n")
  # Se crea el buffer y se unen los polígonos superpuestos
  area_distribucion <- st_buffer(puntos_proj, dist = 15000) %>%
    st_union() %>%
    st_sf()

  area_distribucion_wgs84 <- st_transform(area_distribucion, crs = 4326)

  # 3.3 Creación del Mapa
  cat("Generando el mapa de", nombre_especie, "...\n")
  mapa_final <- ggplot() +

    # Capa 1: Océano
    geom_contour_filled(
      data = ocean_df, aes(x = x, y = y, z = z),
      breaks = c(-10000, -4000, -2000, -500, -100, 0)
    ) +
    scale_fill_manual(values = c("#5bc8c8", "#74d2d2", "#8edcdc", "#a7e6e6", "#c1f0f0"), guide = "none") +
    new_scale_fill() +

    # Capa 2: Tierra
    geom_raster(data = land_df, aes(x = x, y = y, fill = z), alpha = 0.85) +
    scale_fill_gradient(low = "#f4f4f4", high = "#9a9a9a", guide = "none") +

    # Capa 3: Especie/Taxón
    geom_sf(data = area_distribucion_wgs84, fill = "#cdaaa1", color = "#b0857a", alpha = 0.8, size = 0.3, inherit.aes = FALSE) +

    # Capa 4: Rosa de los vientos
    annotation_north_arrow(
      location = "tr", which_north = "true",
      pad_x = unit(0.2, "in"), pad_y = unit(0.2, "in"),
      style = north_arrow_fancy_orienteering(fill = c("grey20", "white"), line_col = "grey20")
    ) +

    # Límites, Título y Estética
    coord_sf(xlim = c(-95, -58), ylim = c(7, 30), expand = FALSE) +
    labs(title = paste("Distribución en el Caribe:", nombre_especie)) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold.italic", size = 14, hjust = 0.5), # Título centrado
      panel.grid.major = element_line(color = "white", linetype = "dotted", size = 0.3),
      axis.title = element_blank(),
      axis.text = element_text(color = "gray40", size = 8),
      panel.border = element_rect(color = "black", fill = NA, size = 0.5),
      panel.background = element_rect(fill = "#c1f0f0", color = NA)
    )

  # 3.4 Guardar el mapa como imagen
  # Reemplaza espacios con guiones bajos para el nombre del archivo y carpeta
  nombre_base <- gsub(" ", "_", nombre_especie)
  dir.create(nombre_base, showWarnings = FALSE)

  nombre_archivo_png <- file.path(nombre_base, paste0("Mapa_", nombre_base, ".png"))
  nombre_archivo_svg <- file.path(nombre_base, paste0("Mapa_", nombre_base, ".svg"))

  ggsave(filename = nombre_archivo_png, plot = mapa_final, width = 10, height = 7, dpi = 300)
  ggsave(filename = nombre_archivo_svg, plot = mapa_final, width = 10, height = 7)

  cat("✅ Mapas (PNG y SVG) guardados en la carpeta:", nombre_base, "\n")

  return(mapa_final)
}

# ==============================================================================
# 4. EJECUCIÓN CON LA LISTA DE TAXONES
# ==============================================================================

# Lista curada para compatibilidad con GBIF (Solo los taxones faltantes)
lista_taxones <- c(
  "Padina",
  "Corallinales", # En lugar de "algas coralinas crustosas"
  "Isognomon",
  "Spondylus",
  "Pecten",
  "Mytilidae", # En lugar de "famillia mytilidae"
  "Ophiothrix",
  "Ophiopsila",
  "Ophioderma"
)

# Ejecutar el bucle
for (taxon in lista_taxones) {
  generar_mapa_especie(taxon)
}

cat("\n🎉 ¡Proceso terminado! Revisa la carpeta de tu proyecto para ver las 27 imágenes guardadas.\n")
