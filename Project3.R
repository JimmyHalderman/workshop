rm(list=ls(all=TRUE))
#install.packages("sf", dependencies = TRUE)
#install.packages("tidyverse", dependencies = TRUE)
#install.packages("maptools", dependencies = TRUE)
#install.packages("spatstat", dependencies = TRUE)

library(raster)
library(sf)
library(tidyverse)
library(maptools)
library(spatstat)
library(units)

setwd("~/Desktop/Wicked_Problems/Project3")
my_pop20 <- raster("tgo_ppp_2020.tif")
tgo_adm1 <- read_sf("gadm36_tgo_1.shp")
tgo_adm2 <- read_sf("gadm36_tgo_2.shp")
Centre<- tgo_adm2 %>%
  filter(NAME_2 == "Golfe (incl Lomé)")

Centre_pop20 <- crop(my_pop20, Centre)
Centre_pop20 <- mask(Centre_pop20, Centre)
pop <- floor(cellStats(Centre_pop20, 'sum'))

st_write(Centre, "Centre.shp", delete_dsn=TRUE)
Centre_with_mtools <- readShapeSpatial("Centre.shp")
win <- as(Centre_with_mtools, "owin")
plot(win)
Centre_adm2_ppp <- rpoint(pop, f = as.im(Centre_pop20), win = win)

bw <- bw.ppl(Centre_adm2_ppp)
save(bw, file = "bw_both.RData")

load("bw.RData")
Centre_density_image <- density.ppp(Centre_adm2_ppp, sigma = bw)
plot(Centre_density_image)
Dsg <- as(Centre_density_image, "SpatialGridDataFrame") 
Dim <- as.image.SpatialGridDataFrame(Dsg) 
Dcl <- contourLines(Dim, levels = 1110000)  
SLDF <- ContourLines2SLDF(Dcl, CRS("+proj=longlat +datum=WGS84 +no_defs"))
sf_multiline_obj <- st_as_sf(SLDF, sf)
plot(sf_multiline_obj)

png("multiline_obj.png", width = 1200, height = 1200)
plot(sf_multiline_obj)
dev.off()
png("sm_dsg_conts.png", width = 1200, height = 1200)

plot(Dsg, main = NULL)
plot(sf_multiline_obj, add = TRUE)
inside_polys <- st_polygonize(sf_multiline_obj)


outside_lines <- st_difference(sf_multiline_obj, inside_polys)


outside_buffers <- st_buffer(outside_lines, 0.001)
outside_intersects <- st_difference(Centre, outside_buffers)


oi_polys <- st_cast(outside_intersects, "POLYGON")


in_polys <- st_collection_extract(inside_polys, "POLYGON")


in_polys[ ,1] <- NULL
oi_polys[ ,1:15] <- NULL


in_polys <- st_cast(in_polys, "POLYGON")
oi_polys <- st_cast(oi_polys, "POLYGON")
all_polys <- st_union(in_polys, oi_polys)
all_polys <- st_collection_extract(all_polys, "POLYGON")
all_polys <- st_cast(all_polys, "POLYGON")
all_polys_sp <- all_polys %>%
  unique()
all_polys_sp_ext <- raster::extract(Centre_pop20, all_polys_sp, df = TRUE)
all_polys_sp_ttls <- all_polys_sp_ext %>%
  group_by(ID) %>%
  summarize(pop20 = sum(tgo_ppp_2019, na.rm = TRUE))
all_polys_sp <- all_polys_sp %>%
  add_column(pop20 = all_polys_sp_ttls$pop20) %>%
  mutate(area = as.numeric(st_area(all_polys_sp) %>%
                             set_units(km^2))) %>%
  mutate(density = as.numeric(pop20 / area))
#plot(all_polys_sp)
all_polys_sp <- all_polys_sp %>%
  filter(density > 100) %>%
  filter(density < 250)
sp_cntr_pts <-  all_polys_sp %>%
  st_centroid() %>%
  st_cast("MULTIPOINT")
#png("Centre_urban_areas_update.png", width = 1200, height = 1200)
#plot(Centre_pop20)
#plot(st_geometry(all_polys_sp), add = TRUE)
#dev.off()
ggplot() +
  geom_sf(data = Centre,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_sp,
          fill = "lightblue",
          size = 0.25,
          alpha = 0.5)
#ggsave("Centre_urban_areas.png")
ggplot() +
  geom_sf(data = Centre,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_sp,
          fill = "lightblue",
          size = 0.25,
          alpha = 0.5) +
  geom_sf(data = sp_cntr_pts,
          aes(size = pop20,
              color = density),
          show.legend = 'point') +
  scale_color_gradient(low = "yellow", high = "red") +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Urbanized Areas throughout Centre, tgo")
#ggsave("Centre_urbanized_areas_with_Dots.png")
tgo_roads  <- read_sf("tgo_roads.shp")
adm2_roads <- st_crop(tgo_roads, Centre)
primary <- adm2_roads %>%
  filter(F_CODE_DES == "Road")
trail <- adm2_roads %>%
  filter(F_CODE_DES == "Trail")
#tertiary <- adm2_roads %>%
#  filter(highway == "tertiary")
ggplot() +
  geom_sf(data = Centre,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_sp,
          size = 0.75,
          color = "gray50",
          fill = "blue",
          alpha = 0.15) +
  geom_sf(data = primary,
          size = 1.5,
          color = "lightpink") +
  geom_sf(data = trail,
          size = 1,
          color = "chocolate1") +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Roadways throughout Centre, tgo")
ggsave("Centre_urban_areas_with_roads.png")
ggplot() +
  geom_sf(data = Centre,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_sp,
          size = 0.75,
          color = "gray50",
          fill = "blue",
          alpha = 0.15) +
  geom_sf(data = primary,
          size = 1.5,
          color = "lightpink") +
  geom_sf(data = trail,
          size = 1,
          color = "chocolate1") +
  geom_sf(data = sp_cntr_pts,
          aes(size = pop20,
              color = density),
          show.legend = 'point') +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Roadways and Hospitals throughout Centre")
ggsave("Centre_urban_areas_roads_roads.png")
tgo_healthsites  <- read_sf("healthsites.shp")
adm2_healthsites <- st_crop(tgo_healthsites, Centre)
hospitals <- adm2_healthsites %>%
  filter(amenity == "hospital")
clinics <- adm2_healthsites %>%
  filter(healthcare == "clinic")
other_hcfs <- adm2_healthsites %>%
  filter(healthcare == "doctors" | healthcare == "dentist" | healthcare == "pharmacy")
ggplot() +
  geom_sf(data = Centre,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_sp,
          size = 0.75,
          color = "gray50",
          fill = "blue",
          alpha = 0.15) +
  geom_sf(data = hospitals,
          size = 3,
          color = "red") +
  geom_sf(data = clinics,
          size = 2,
          color = "purple") +
  geom_sf(data = other_hcfs,
          size = 1,
          color = "blue") +
  ggtitle("Access to Health Care Serivces throughout Centre, tgo")
ggsave("Centre_hospital_sites.png")
ggplot() +
  geom_sf(data = Centre,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_sp,
          size = 0.75,
          color = "gray50",
          fill = "blue",
          alpha = 0.15) +
  geom_sf(data = primary,
          size = 1.5,
          color = "lightpink") +
  geom_sf(data = secondary,
          size = 1,
          color = "chocolate1") +
  geom_sf(data = tertiary,
          size = 0.5,
          color = "royalblue") +
  geom_sf(data = sp_cntr_pts,
          aes(size = pop20,
              color = density),
          show.legend = 'point') +
  geom_sf(data = hospitals,
          size = 3,
          color = "red") +
  geom_sf(data = clinics,
          size = 2,
          color = "purple") +
  geom_sf(data = other_hcfs,
          size = 1,
          color = "blue") +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Roadways and Hospitals throughout Centre")
ggsave("Centre_hospitals_roads_density_points.png")

