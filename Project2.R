rm(list=ls(all=TRUE))

library(sf)
library(raster)
library(tidyverse)
library(doParallel)
library(snow)
library(rasterVis)


setwd("~/Desktop/Wicked_Problems/Project2")

f <- list.files(pattern="tgo_esaccilc_dst", recursive=TRUE)

lulc <- stack(lapply(f, function(i) raster(i, band=1)))

load("myTGO_adm1.RData")
load("TGO_adm2.RData")

TGO_adm0 <- read_sf("gadm36_TGO_0.shp")


nms <- sub("0_100m_2015.tif", "", sub("tgo_esaccilc_", "", f))
names(lulc) <- nms
topo <- raster("tgo_srtm_topo_100m.tif")
slope <- raster("tgo_srtm_slope_100m.tif")
ntl <- raster("tgo_viirs_100m_2015.tif")
lulc <- addLayer(lulc, topo, slope, ntl)
names(lulc)[c(1,10:12)] <- c("water","topo","slope", "ntl")

plot(lulc[[12]])

plot(lulc[[8]])
plot(st_geometry(myTGO_adm1), add = TRUE)

plot(lulc[[10]])
contour(lulc[[10]], add = TRUE)

#ncores <- detectCores() - 1
#beginCluster(ncores)
#lulc_vals_adm2 <- raster::extract(lulc,TGO_adm2, df = TRUE)
#endCluster()
#save(lulc_vals_adm2, file = "lulc_vals_adm2.RData")

load("lulc_vals_adm2.RData")

TGO_adm2 <- bind_cols(TGO_adm2, lulc_vals_adm2)

TGO_adm2<- cbind(ntl,TGO_adm2)

lulc_ttls_adm2 <- lulc_vals_adm2 %>%
  group_by(ID) %>%
  summarize_all(sum, na.rm = TRUE)
TGO_adm2 <- bind_cols(TGO_adm2, lulc_ttls_adm2)
ggplot(TGO_adm2, aes(log(pop20))) +
  geom_histogram()
ggsave("project2_part1_histogram.png")

ggplot(TGO_adm2, aes(log(pop20))) +
  geom_density()
ggsave("project2_part1_density.png")

ggplot(TGO_adm2, aes(log(pop20))) +
  geom_histogram(aes(y = ..density..), color = "black", fill = "white") + 
  geom_density(alpha = 0.2, fill = "#FF6666") + 
  theme_minimal()
ggsave("project2_part1_density&histogram.png")

ggplot(TGO_adm2, aes(log(ntl))) +
  geom_histogram(aes(y = ..density..), color = "black", fill = "white") + 
  geom_density(alpha = 0.2, fill = "#FF6666") + 
  theme_minimal()
ggsave("project2_part1_ntl.png")

ggplot(TGO_adm2, aes(pop20, ntl)) + 
  geom_point(size = .1, color = "red") +
  geom_smooth()
ggsave("project2_part1_ntl&pop20.png")
fit <- lm(pop20 ~ ntl, data=TGO_adm2)
summary(fit)

ggplot(lm(pop20 ~ ntl + dst19 + dst20, data=TGO_adm2)) + 
  geom_point(aes(x=.fitted, y=.resid), size = .1) +
  geom_smooth(aes(x=.fitted, y=.resid))
fit <- lm(pop20 ~ ntl + dst19 + dst20, data=TGO_adm2)
summary(fit)

ggplot(lm(pop20 ~ water + dst011_100m_2015.tif + dst04 + dst13 + dst14 + dst15 + dst16 + dst19 + dst20 + topo + slope + ntl, data=TGO_adm2)) + 
  geom_point(aes(x=.fitted, y=.resid), size = .1) +
  geom_smooth(aes(x=.fitted, y=.resid))
ggsave("project2_part1_all_together.png")
fit <- lm(pop20 ~ water + dst011_100m_2015.tif + dst04 + dst13 + dst14 + dst15 + dst16 + dst19 + dst20 + topo + slope + ntl, data=TGO_adm2)
summary(fit)





# Part 2 Begins
mytgo_pop <- raster("tgo_ppp_2020.tif")
lulc <- mask(lulc, tgo_int)
names(lulc) <- c("water", "dst011" , "dst040", "dst130", "dst140", "dst150", 
                 "dst160", "dst190", "dst200", "topo", "slope", "ntl")
names(mytgo_adm2)[17:28] <- c("water", "dst011" , "dst040", "dst130", "dst140", "dst150", 
                              "dst160", "dst190", "dst200", "topo", "slope", "ntl")
my_model <- lm(pop19 ~  water + dst011 + dst040 + dst130 + dst140 + dst150 + dst160 + dst190 + dst200 + topo + slope + ntl, data=mytgo_adm2)
#predicted_values <- raster::predict(lulc, my_model, progress="window")
#save(predicted_values, file = "predicted_values.RData")
load("predicted_values.RData")
base <- predicted_values - minValue(predicted_values)
cellStats(base, sum) 
#ncores <- detectCores() - 1
#beginCluster(ncores)
#pred_vals_adm2 <- raster::extract(predicted_values, mytgo_adm2, df=TRUE)
#endCluster()
#save(pred_vals_adm2, file = "pred_vals_adm2.RData")



load("pred_vals_adm2.RData")
pred_ttls_adm2 <- aggregate(. ~ ID, pred_vals_adm2, sum)


raster_layer <- rasterize(mytgo_adm2, predicted_values, field = "layer")
gridcell_proportion <- predicted_values / raster_layer
population_layer <- rasterize(mytgo_adm2, predicted_values, field = "pop19")
population <- gridcell_proportion * population_layer
cellStats(population, sum)
sum(mytgo_adm2$pop19)
png("project2_part2_population.png")
plot(population)
dev.off()
diff <- population - mytgo_pop
cellStats(abs(diff), sum)
png("project2_part2_diff.png")
plot(diff)
dev.off()
plot(diff)
Centre <- mytgo_adm2 %>%
  filter(NAME_2 == "Centre")
urban_diff <- mask(diff, Centre)
urban_pop <- mask(mytgo_pop, Centre)
#extGMN <- c(13.03, 14.20, -2.67, -0.85)
extGMN <- c(8.15, 9.92, -0.707, 0.9)
Centre_diff <- crop(urban_diff, extGMN)
Centre_pop <- crop(urban_pop, extGMN)
plot(Centre_diff)
png("project2_part2_Centre_diff.png")
plot(Centre_diff)
dev.off()
plot(Centre_pop)
png("project2_part2_Centre_pop.png")
plot(Centre_pop)
dev.off()
rasterVis::plot3D(Centre_pop)




