# ==============================================================================
# 1. INSTALACIÓN Y CARGA DE PAQUETES
# ==============================================================================
# Si te falta alguno, quita el "#" de la siguiente línea y ejecútala una vez:
#install.packages(c("rgbif", "sf", "ggplot2", "dplyr", "marmap", "ggnewscale", "ggspatial"))
install.packages("ggspatial")

library(rgbif)
library(sf)
library(ggplot2)
library(dplyr)
library(marmap)
library(ggnewscale)
library(ggspatial) # Nuevo paquete para la rosa de los vientos

# ==============================================================================
# 2. DESCARGA Y PROCESAMIENTO DE DATOS DE LA ESPECIE (GBIF)
# ==============================================================================
cat("Descargando datos de GBIF...\n")
gbif_data <- occ_data(
  scientificName = "Rhizophora mangle", 
  hasCoordinate = TRUE, 
  limit = 10000, # Puedes subir este límite si necesitas más precisión
  decimalLongitude = "-95,-55", 
  decimalLatitude = "5,35",
  curlopts = list(timeout = 300, connecttimeout = 300) # Esto evita que se corte la conexión
) 

# Verificamos si descargó correctamente
print(paste("Se descargaron", nrow(gbif_data$data), "registros."))

# Limpiar datos
df_puntos <- gbif_data$data %>%
  filter(!is.na(decimalLongitude) & !is.na(decimalLatitude)) %>%
  select(decimalLongitude, decimalLatitude)

# Convertir a espacial, proyectar a metros, crear el buffer de 15km y unir
puntos_sf <- st_as_sf(df_puntos, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326)
puntos_proj <- st_transform(puntos_sf, crs = 3857)

cat("Creando polígonos de distribución (sombreado)...\n")
area_distribucion <- st_buffer(puntos_proj, dist = 15000) %>% 
  st_union() %>% 
  st_sf()

# Transformar de vuelta a coordenadas geográficas
area_distribucion_wgs84 <- st_transform(area_distribucion, crs = 4326)

# ==============================================================================
# 3. DESCARGA Y PREPARACIÓN DE TOPOGRAFÍA Y BATIMETRÍA (NOAA)
# ==============================================================================
cat("Descargando modelo de elevación de la NOAA...\n")
# resolution = 4 es un buen balance. Usa 2 si quieres mucho más detalle (tardará más)
bathy_data <- getNOAA.bathy(lon1 = -96, lon2 = -54, lat1 = 4, lat2 = 32, resolution = 1)

# Convertir a formato compatible con ggplot
bathy_df <- fortify.bathy(bathy_data)

# Separar el océano (z <= 0) de la tierra firme (z > 0)
ocean_df <- bathy_df %>% filter(z <= 0)
land_df  <- bathy_df %>% filter(z > 0)

# ==============================================================================
# 4. CREACIÓN DEL MAPA FINAL
# ==============================================================================
cat("Generando el mapa final...\n")

mapa_final <- ggplot() +
  
  # --- Capa 1: Océano (Batimetría) ---
  geom_contour_filled(data = ocean_df, aes(x = x, y = y, z = z), 
                      breaks = c(-10000, -4000, -2000, -500, -100, 0)) +
  scale_fill_manual(
    values = c("#5bc8c8", "#74d2d2", "#8edcdc", "#a7e6e6", "#c1f0f0"),
    guide = "none"
  ) +
  
  # --- Reiniciar escala de colores para la tierra ---
  new_scale_fill() +
  
  # --- Capa 2: Tierra (Relieve) ---
  geom_raster(data = land_df, aes(x = x, y = y, fill = z), alpha = 0.85) +
  scale_fill_gradient(
    low = "#f4f4f4", high = "#9a9a9a", 
    guide = "none"
  ) +
  
  # --- Capa 3: Distribución de la Especie ---
  geom_sf(data = area_distribucion_wgs84, 
          fill = "#cdaaa1", color = "#b0857a", 
          alpha = 0.8, size = 0.3, 
          inherit.aes = FALSE) +
  
  # --- Rosa de los vientos ---
  annotation_north_arrow(
    location = "tr", # "tr" = Top Right (Arriba a la derecha)
    which_north = "true",
    pad_x = unit(0.2, "in"), pad_y = unit(0.2, "in"),
    style = north_arrow_fancy_orienteering(
      fill = c("grey20", "white"),
      line_col = "grey20"
    )
  ) +
  
  # --- Límites del mapa y estética ---
  coord_sf(xlim = c(-95, -58), ylim = c(7, 30), expand = FALSE) +
  theme_minimal() +
  theme(
    panel.grid.major = element_line(color = "white", linetype = "dotted", size = 0.3),
    axis.title = element_blank(),
    axis.text = element_text(color = "gray40", size = 8),
    panel.border = element_rect(color = "black", fill = NA, size = 0.5),
    panel.background = element_rect(fill = "#c1f0f0", color = NA) # Fondo por si quedan huecos
  )

# Mostrar el mapa en tu visualizador
print(mapa_final)
