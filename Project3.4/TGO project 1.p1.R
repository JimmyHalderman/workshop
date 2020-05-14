setwd("~/Desktop/Wicked_Problems/Togo")


library(tidyverse)
library(sf) 

TGO_int <- read_sf("gadm36_TGO_0.shp")
TGO_adm1 <- read_sf("gadm36_TGO_1.shp")
TGO_adm2 <- read_sf("gadm36_TGO_2.shp")


ggplot() +
geom_sf(data = TGO_adm2,
          size = .25,
          color = "grey",
          fill = "red",
          alpha = .5) +
geom_sf(data = TGO_adm1,
        size = 0.75,
        color = "purple",
        alpha = 0) +
geom_sf(data = TGO_int,
          size = 1.25,
          color = "black",
          alpha = 0) +
geom_sf_text(data= TGO_int,
               aes(label = NAME_0),
               size = 7,
               nudge_x = 0,
               nudge_y = -.4) +
geom_sf_text(data = TGO_adm1,
               aes(label = NAME_1),
               size = 3) +
geom_sf_text(data = TGO_adm2,
               aes(label = NAME_2),
               size = 1)

ggsave("TGO_intl.png")
 

kara <- TGO_adm1 %>%
  filter(NAME_1 == "Kara")

ggplot() +
  geom_sf(data = kara)

TGO_adm2 %>%
  filter(NAME_1 == "Kara") %>%
  ggplot() +
  geom_sf(size = .4) +
  geom_sf_text(aes(label = NAME_2),
               size = 2) +
  geom_sf_text(data = kara,
               aes(label = NAME_1),
               size = 5) +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Kara County", subtitle = "Kara County and it's subdivisions")

ggsave("Kara_County.png")        

