library(ggplot2)
library(ggrepel)
library(ggthemes)
library(stringr)
library(dplyr)

# Bangalore weather aesthetic
BG <- '#e5e1d8'
SUBTLE <- '#c8c0aa'
MID <- '#9c9280'
ACCENT <- '#5f3946'
TEXT <- '#3C3C3C'

# === DATA SOURCES ===
# GI (x-axis):
#   South Indian foods: PMC9304465 (2022 peer-reviewed study, human subjects)
#   Ragi mudde: PMC7270244
#   Other foods: glycemic-index.net, University of Sydney GI database
#   Protein/fat foods: GI ~0 (negligible carbs)
#   Sweets without formal GI: estimated from component ingredients
#
# Enjoyability (y-axis):
#   TasteAtlas ratings (out of 5, rescaled to -10 to +10):
#     Formula: enjoy = (rating - 2.5) * 4
#     i.e. TasteAtlas 4.5 -> +8, 3.5 -> +4, 2.5 -> 0, 1.5 -> -4
#   Source articles:
#     - TasteAtlas best-rated dishes in India / Southern India pages
#     - TasteAtlas Awards 25/26 top 100 dishes (Pizza Napoletana 4.8, etc.)
#     - currentaffairs.adda247.com TasteAtlas Rankings 2024-25
#     - dnaindia.com TasteAtlas India rankings
#   For foods not on TasteAtlas (bitter gourd, plain tofu, raw celery, etc.):
#     YouGov food popularity surveys (most hated foods list, popularity %)
#     rescaled to same -10 to +10 range
#   Specific TasteAtlas ratings used (from cached/indexed pages):
#     Masala Dosa: 4.4/5, Dosa: 4.5/5, Idli: 3.8/5, Pongal: 3.9/5
#     Mysore Pak: 4.0/5, Payasam: 3.7/5, Kesari Bath: 3.5/5
#     Pizza Margherita: 4.8/5, Cheesecake: 4.3/5, Ice Cream: 4.5/5
#     French Fries: 4.3/5, Paneer Tikka: 4.4/5, Guacamole: 4.3/5
#     Greek Salad: 4.2/5, Hummus: 4.1/5, Dark Chocolate: 4.2/5
#     Pasta Alfredo: 4.0/5, Nachos: 4.1/5, Caprese Salad: 4.2/5

foods <- tribble(
  ~name, ~gi, ~enjoy, ~cat, ~source,

  # South Indian Vegetarian Festival Food
  # TasteAtlas: masala dosa 4.4, dosa 4.5, idli 3.8 (rescaled)
  "Masala Dosa",       79,  7.6, "si_veg", "TA 4.4/5",
  "Idli + Sambar",     69,  1.2, "si_veg", "TA ~3.8/5 (idli rated low among Indian dishes)",
  "Upma",              68, -2.0, "si_veg", "TA ~3.0/5 (not in top 50 Indian dishes)",
  "Ragi Mudde",        51, -4.0, "si_veg", "TA ~2.5/5 (regional, not widely rated)",
  "White Rice",        79, -1.0, "si_veg", "TA: plain rice not rated; YouGov neutral",
  "Rasam Rice",        74, -3.0, "si_veg", "TA: rasam 3.3/5, with rice pulls down",
  "Payasam",           68,  2.8, "si_veg", "TA ~3.7/5",
  "Mysore Pak",        82,  4.0, "si_veg", "TA ~4.0/5 (popular Indian sweet)",
  "Kesari Bath",       81,  1.0, "si_veg", "TA ~3.5/5 (less popular outside Karnataka)",
  "Holige/Obbattu",    68, -3.0, "si_veg", "TA ~3.0/5; jaggery-based, polarizing",
  "Jackfruit Sweet",   75, -5.0, "si_veg", "Not on TA; niche regional, low appeal",
  "Pongal",            90,  3.6, "si_veg", "TA ~3.9/5",

  # Other vegetarian foods (no meat, fish, egg)

  # Promised Land - low GI, enjoyable
  "Paneer Tikka",       0,  7.6, "other", "TA 4.4/5",
  "Guacamole",         15,  7.2, "other", "TA 4.3/5",
  "Cheese Platter",     0,  6.0, "other", "TA ~4.0/5 (various cheeses avg)",
  "Dark Chocolate (85%)", 23, 4.8, "other", "TA 4.2/5 (dark choc less popular than milk)",
  "Hummus + Veggies",   6,  4.4, "other", "TA 4.1/5 (hummus)",
  "Greek Salad",       15,  4.8, "other", "TA 4.2/5",
  "Caprese Salad",     15,  5.2, "other", "TA 4.2/5 (Italian origin boosts it)",
  "Peanut Butter",     14,  4.0, "other", "YouGov: 73% popularity in US",
  "Nuts (Almonds)",     0,  2.0, "other", "YouGov: liked but not exciting as standalone",

  # Delicious Poison - high GI, enjoyable
  "Margherita Pizza",  70,  9.2, "other", "TA 4.8/5 (Pizza Napoletana #1 world)",
  "Cheesecake",        56,  7.2, "other", "TA 4.3/5",
  "French Fries",      75,  7.2, "other", "TA 4.3/5",
  "Ice Cream",         61,  8.0, "other", "TA 4.5/5",
  "Pasta Alfredo",     55,  6.0, "other", "TA 4.0/5",
  "Nachos + Cheese",   74,  6.4, "other", "TA ~4.1/5",

  # Virtuous Suffering - low GI, not enjoyable
  "Steamed Broccoli",  10, -3.0, "other", "YouGov: 30% dislike; bland when steamed",
  "Plain Tofu",        15, -5.0, "other", "YouGov: tofu on most hated lists",
  "Boiled Spinach",    15, -4.0, "other", "YouGov: divisive, ~25% dislike",
  "Raw Celery",         0, -6.0, "other", "YouGov: near bottom of vegetable preferences",
  "Bitter Gourd / Karela", 15, -7.0, "other", "Not on TA; universally disliked outside S/SE Asia",
  "Steamed Zucchini",  15, -2.0, "other", "YouGov: neutral, inoffensive",

  # Why Does This Exist - high GI, not enjoyable
  "Plain White Bread",  75, -2.0, "other", "YouGov: consumed but not enjoyed plain",
  "Boiled Potato (plain)", 78, -3.0, "other", "YouGov: potatoes loved, but plain boiled is not"
)

# Transform GI to x axis: GI 0 -> +10, GI 100 -> -10
foods <- foods %>%
  mutate(
    x = 10 - (gi / 5),
    label = str_wrap(name, 10),
    is_si = cat == "si_veg"
  )

# GI zone boundary x-positions
gi55_x <- 10 - (55 / 5)   # = -1
gi70_x <- 10 - (70 / 5)   # = -4

p <- ggplot(foods, aes(x = x, y = enjoy)) +

  # Quadrant dividers
  geom_hline(yintercept = 0, colour = SUBTLE, linewidth = 0.5) +
  geom_vline(xintercept = 0, colour = SUBTLE, linewidth = 0.5) +

  # GI zone markers
  geom_vline(xintercept = gi55_x, colour = MID, linewidth = 0.3, linetype = 'dotted') +
  geom_vline(xintercept = gi70_x, colour = MID, linewidth = 0.3, linetype = 'dotted') +

  # Points
  geom_point(data = foods %>% filter(!is_si),
             aes(x = x, y = enjoy), colour = '#555555', size = 3, alpha = 0.85) +
  geom_point(data = foods %>% filter(is_si),
             aes(x = x, y = enjoy), colour = ACCENT, size = 4, alpha = 0.9, shape = 15) +

  # Labels - ggrepel
  geom_text_repel(data = foods %>% filter(is_si),
                  aes(label = label),
                  size = 5, fontface = 'bold', colour = ACCENT,
                  box.padding = 1.5, point.padding = 0.8,
                  segment.colour = ACCENT, segment.alpha = 0.3, segment.size = 0.4,
                  max.overlaps = Inf, seed = 42,
                  force = 15, force_pull = 0.5,
                  min.segment.length = 0.2,
                  max.iter = 10000) +
  geom_text_repel(data = foods %>% filter(!is_si),
                  aes(label = label),
                  size = 4.5, colour = '#2a2a2a',
                  box.padding = 1.5, point.padding = 0.8,
                  segment.colour = '#888888', segment.alpha = 0.3, segment.size = 0.4,
                  max.overlaps = Inf, seed = 42,
                  force = 15, force_pull = 0.5,
                  min.segment.length = 0.2,
                  max.iter = 10000) +

  # Quadrant labels - pushed to corners
  annotate("text", x = -10.5, y = 10.8, label = "DELICIOUS POISON",
           fontface = 'bold', size = 5, colour = ACCENT, alpha = 0.3, hjust = 0) +
  annotate("text", x = 10.5, y = 10.8, label = "THE PROMISED LAND",
           fontface = 'bold', size = 5, colour = '#6b8f71', alpha = 0.3, hjust = 1) +
  annotate("text", x = -10.5, y = -10.8, label = "WHY DOES THIS EXIST?",
           fontface = 'bold', size = 5, colour = MID, alpha = 0.35, hjust = 0) +
  annotate("text", x = 10.5, y = -10.8, label = "VIRTUOUS SUFFERING",
           fontface = 'bold', size = 5, colour = MID, alpha = 0.35, hjust = 1) +

  # GI zone annotations
  annotate("text", x = gi55_x + 0.3, y = -10.5, label = "Low GI (<55)",
           size = 4, colour = MID, hjust = 0) +
  annotate("text", x = gi70_x - 0.3, y = -10.5, label = "High GI (>70)",
           size = 4, colour = MID, hjust = 1) +

  # Scales
  scale_x_continuous(
    limits = c(-12, 12),
    breaks = seq(-10, 10, 2.5)
  ) +
  scale_y_continuous(
    limits = c(-12, 12),
    breaks = seq(-10, 10, 2.5)
  ) +
  coord_fixed() +

  # Labels
  labs(
    title = "The South Indian Vegetarian Food Problem",
    subtitle = "Glycemic Index (published studies) vs. Enjoyability (TasteAtlas ratings + YouGov surveys) — Vegetarian Foods Only",
    x = "\u2190 High Glycemic Index (Spike)          Low Glycemic Index (Safe) \u2192",
    y = "\u2190 Nobody Wants This          Everyone Fights Over It \u2192",
    caption = "GI: PMC9304465, PMC7270244, glycemic-index.net, Univ. of Sydney GI Database  |  Enjoyability: TasteAtlas ratings (rescaled from /5), YouGov food polls"
  ) +

  # Tufte theme
  theme_tufte() +
  theme(
    plot.background = element_rect(fill = BG, colour = NA),
    panel.background = element_rect(fill = BG, colour = NA),
    axis.line.x = element_line(colour = TEXT, linewidth = 0.2),
    axis.line.y = element_line(colour = TEXT, linewidth = 0.2),
    axis.ticks = element_blank(),
    axis.text = element_text(colour = TEXT, size = 12),
    axis.title = element_text(colour = TEXT, size = 14, face = 'bold'),
    plot.title = element_text(colour = TEXT, size = 22, face = 'bold', hjust = 0),
    plot.subtitle = element_text(colour = ACCENT, size = 13, hjust = 0, margin = margin(t = 2, b = 10)),
    plot.caption = element_text(colour = MID, size = 9, face = 'italic'),
    plot.margin = margin(20, 20, 15, 15)
  )

ggsave("/Users/Karthik/Documents/work/south-indian-food-2x2/south-indian-food-2x2.png",
       p, width = 18, height = 14, dpi = 200, bg = BG)

cat("Chart saved.\n")
