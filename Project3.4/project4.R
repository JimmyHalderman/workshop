#install.packages("rgl", dependencies = TRUE)
#install.packages("rayshader", dependencies = TRUE)
#install.packages("rayrender", dependencies = TRUE)

rm(list=ls(all=TRUE))
library(raster)
library(sf)
library(tidyverse)
library(rayshader)
library(rayrender)
library(rgl)

setwd("~/Desktop/Wicked_Problems/Project3.4")

tgo_topo<- raster("tgo_srtm_topo_100m.tif")
tgo_adm2<- read_sf("gadm36_TGO_2.Shp")

tgo_topo <- raster("tgo_srtm_topo_100m.tif")
tgo_adm2  <- read_sf("gadm36_tgo_2.shp")
Centre <- tgo_adm2 %>%
  filter(NAME_2 == "Centre")
Kara <- tgo_adm2 %>%
  filter(NAME_2 == "Kara")
combined_adm2s <- st_union(Kara, Centre)
combined_topo <- crop(tgo_topo, combined_adm2s)

combined_matrix <- raster_to_matrix(combined_topo)
combined_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(combined_matrix)) %>%
  plot_map()
ambientshadows <- ambient_shade(combined_matrix)
combined_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(combined_matrix), color = "lightblue") %>%
  add_shadow(ray_shade(combined_matrix, sunaltitude = 3, zscale = 33, lambert = FALSE), max_darken = 0.5) %>%
  add_shadow(lamb_shade(combined_matrix, sunaltitude = 3, zscale = 33), max_darken = 0.7) %>%
  add_shadow(ambientshadows, max_darken = 0.1) %>%
  plot_3d(combined_matrix, zscale = 20,windowsize = c(1000,1000), 
          phi = 40, theta = 135, zoom = 0.5, 
          background = "grey", shadowcolor = "grey5", 
          soliddepth = -50, shadowdepth = -100)
render_snapshot(title_text = "Centreand Kara", 
                title_size = 50,
                title_color = "grey90")



obj <- ggplot() +
  geom_sf(data = combined_adm2s,
          size = 4.5,
          linetype = "11",
          color = "gold",
          alpha = 0) +
  theme_Karaid() + theme(legend.position="none") +
  scale_x_continuous(expand=c(0,0)) +
  scale_y_continuous(expand=c(0,0)) +
  labs(x=NULL, y=NULL, title=NULL)

png("combined.png", width = 1420, height = 1680, units = "px", bg = "transparent")
obj
dev.off()
overlay_img <- png::readPNG("combined.png")
combined_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(combined_matrix)) %>%
  add_overlay(overlay_img, alphalayer = 0.95) %>%
  plot_map()




combined_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(combined_matrix), color = "lightblue") %>%
  add_shadow(ray_shade(combined_matrix, sunaltitude = 3, zscale = 33, lambert = FALSE), max_darken = 0.5) %>%
  add_shadow(lamb_shade(combined_matrix, sunaltitude = 3, zscale = 33), max_darken = 0.7) %>%
  add_shadow(ambientshadows, max_darken = 0.1) %>%
  add_overlay(overlay_img, alphalayer = 0.95) %>%
  plot_3d(combined_matrix, zscale = 20,windowsize = c(1000,1000), 
          phi = 40, theta = 135, zoom = 0.75, 
          background = "grey", shadowcolor = "grey5", 
          soliddepth = -50, shadowdepth = -100)
render_snapshot(title_text = "Centre and Kara with borders", 
                title_size = 50,
                title_color = "grey")
load("all_polys.RData")


obj <- ggplot() +
  geom_sf(data = combined_adm2s,
          size = 5.0,
          linetype = "11",
          color = "gold",
          alpha = 0) +
  geom_sf(data = all_polys,
          size = 0.75,
          color = "gray",
          fill = "gold",
          alpha = 0.5) +
  theme_Karaid() + theme(legend.position="none") +
  scale_x_continuous(expand=c(0,0)) +
  scale_y_continuous(expand=c(0,0)) +
  labs(x=NULL, y=NULL, title=NULL)
png("combined.png", width = 1400, height = 1600, units = "px", bg = "transparent")
obj
dev.off()
overlay_img <- png::readPNG("combined.png")
combined_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(combined_matrix), color = "blue") %>%
  add_shadow(ray_shade(combined_matrix, sunaltitude = 3, zscale = 33, lambert = FALSE), max_darken = 0.5) %>%
  add_shadow(lamb_shade(combined_matrix, sunaltitude = 3, zscale = 33), max_darken = 0.7) %>%
  add_shadow(ambientshadows, max_darken = 0.1) %>%
  add_overlay(overlay_img, alphalayer = 0.95) %>%
  plot_3d(combined_matrix, zscale = 20,windowsize = c(1000,1000), 
          phi = 40, theta = 135, zoom = 0.75, 
          background = "grey", shadowcolor = "grey5", 
          soliddepth = -50, shadowdepth = -100)
render_snapshot(title_text = "Urban Areas & Healthsites Across Centre& 
                Kara", 
                title_size = 50,
                title_color = "grey90")

tgo_roads  <- read_sf("tgo_roads.shp")
adm2_roads <- st_crop(tgo_roads, combined_adm2s)
primary <- adm2_roads %>%
  filter(F_CODE_DES == "Road")
secondary <- adm2_roads %>%
  filter(RTT_DESCRI == "Secondary Route")
obj <- ggplot() +
  geom_sf(data = combined_adm2s,
          size = 5.0,
          linetype = "11",
          color = "gold",
          alpha = 0) +
  geom_sf(data = all_polys,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.5) +
  geom_sf(data = primary,
          size = 1.5,
          color = "lightblue") +
  geom_sf(data = secondary,
          size = 1.5,
          color = "chocolate1") +
  theme_Karaid() + theme(legend.position="none") +
  scale_x_continuous(expand=c(0,0)) +
  scale_y_continuous(expand=c(0,0)) +
  labs(x=NULL, y=NULL, title=NULL)
png("combined.png", width = 1420, height = 1680, units = "px", bg = "transparent")
obj
dev.off()
overlay_img <- png::readPNG("combined.png")
combined_matrix %>%
  sphere_shade() %>%
  add_water(detect_water(combined_matrix), color = "blue") %>%
  add_shadow(ray_shade(combined_matrix, sunaltitude = 3, zscale = 33, lambert = FALSE), max_darken = 0.5) %>%
  add_shadow(lamb_shade(combined_matrix, sunaltitude = 3, zscale = 33), max_darken = 0.7) %>%
  add_shadow(ambientshadows, max_darken = 0.1) %>%
  add_overlay(overlay_img, alphalayer = 0.95) %>%
  plot_3d(combined_matrix, zscale = 20,windowsize = c(1000,1000), 
          phi = 40, theta = 135, zoom = 0.75, 
          background = "grey", shadowcolor = "black", 
          soliddepth = -50, shadowdepth = -100)
render_snapshot(title_text = "Road Networks & Urban Areas in Centreand 
                Kara", 
                title_size = 50,
                title_color = "grey90")
render_label(combined_matrix, "Oyem", textcolor ="white", linecolor = "white", 
             x = 330, y = 850, z = 1000, textsize = 2.5, linewidth = 4, zscale = 10, freetype = FALSE)
render_snapshot(title_text = "Centre and Kara Primary Urban Area", 
                title_size = 50,
                title_color = "grey90")




ad <- tgo_adm2 %>%
  filter(NAME_2 == "Kara" )

combined_topo <- crop(tgo_topo, combined_adm2s)
combined_topo <- mask(combined_topo, combined_adm2s)

overlay_img<- png::readPNG("Kara_hospitals_roads_density_points.png")

combined_matrix%>%
  height_shade()%>%
  sphere_shade()%>%
  add_water(detect_water(combined_matrix))%>%
  add_overlay(overlay_img,alpalayer - 0.95)%>%
  plot_map()

ambientshadows <- ambient_shade(combined_matrix)

combined_matrix %>%
  Sphere_shade() %>%
  add_water(detect_water(combined_matrix), colo = "blue") %>%
  add_shadow(ray_shade(combined_matrix,sunaltitude = 3, zscale = 33, lambert = FALSE), max_darken=0.5) %>%

