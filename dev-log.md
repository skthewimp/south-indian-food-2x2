# Dev Log: The South Indian Vegetarian Food Problem

## Project overview
A 2x2 scatter plot comparing vegetarian foods on Glycemic Index vs. Enjoyability, with the hypothesis that South Indian vegetarian festival food clusters uniquely badly on both dimensions.

## Prompt sequence

### 1. Initial request
Asked Claude to create a 2x2 of South Indian foods on healthy/unhealthy vs enjoyable/not enjoyable axes, with specific examples of where foods should go (masala dosa = enjoyable, jackfruit sweet = not enjoyable, etc.).

### 2. First version - SI foods only
Claude produced a matplotlib scatter with ~35 South Indian foods. Problem: chart only showed SI foods, couldn't see the contrast with other cuisines.

### 3. Expanded to all cuisines
Asked for foods from all cuisines (Italian, Japanese, Mexican, Mediterranean, etc.) alongside SI foods. This showed the contrast but had too many foods cluttering the chart.

### 4. Curated to ~28 foods
Trimmed to 28 foods across cuisines with just two categories: "South Indian Veg (Festival)" vs "Everything Else." Added a dashed ellipse around the SI cluster. Much clearer thesis.

### 5. Real GI data
Challenged on data sources for health scores. Claude found PMC9304465 (2022 peer-reviewed study testing 23 South Indian breakfast foods on human subjects) and PMC7270244 (millet foods). Rebuilt x-axis using actual published GI values instead of guesswork.

### 6. Vegetarian-only version
Requested all foods be vegetarian (no fish, no egg, no meat). Also needed all four quadrants populated - the "virtuous suffering" quadrant was empty. Added broccoli, tofu, celery, bitter gourd, etc.

### 7. Holige correction
Corrected that holige (made with jaggery) should be rated as not enjoyable. Jaggery-based sweets are polarizing.

### 8. Aesthetic overhaul
Migrated from default matplotlib to the "Bangalore weather chart" aesthetic (Tufte minimalism, warm beige background #e5e1d8, muted palette). This was stored as a permanent preference in Claude's memory.

### 9. Font size iterations
Multiple rounds of increasing font sizes - labels kept appearing too small in the rendered output. matplotlib's adjustText library was not handling label repulsion well at larger font sizes.

### 10. Switch to R + ggrepel
Rewrote entire chart in R using ggplot2 + ggrepel + ggthemes. ggrepel handled label placement much better than Python's adjustText. Added str_wrap(name, 10) for text wrapping.

### 11. ggrepel tuning
Increased force, box.padding, force_pull, and max.iter parameters to get labels to actually separate at larger font sizes.

### 12. Quadrant label positioning
Moved quadrant labels ("DELICIOUS POISON", "THE PROMISED LAND", etc.) to corners so they don't overlap with data points.

### 13. Enjoyability data sourcing
Challenged on enjoyability data sources. Attempted to fetch TasteAtlas ratings and YouGov survey data. TasteAtlas blocks direct scraping (403). Used data from search results and article excerpts that quoted TasteAtlas scores. YouGov food popularity surveys provided data for foods not on TasteAtlas (vegetables, plain preparations).

Rescaling formula for TasteAtlas: `enjoy = (rating - 2.5) * 4` maps the 0-5 TasteAtlas scale to -10/+10.

## Technical decisions

- **R over Python**: ggrepel is simply better than adjustText for label placement. No contest.
- **Tufte aesthetic**: Warm beige background (#e5e1d8), no gridlines, minimal axes, muted color palette. Matches the Bangalore weather chart style.
- **Two categories only**: "SI Veg Festival" (square markers, maroon) vs "Everything Else" (circle markers, dark gray). Simpler than per-cuisine colors.
- **GI-to-x transform**: `x = 10 - (gi / 5)` puts GI 0 at +10 (right/safe) and GI 100 at -10 (left/bad).
- **coord_fixed()**: Equal aspect ratio so the quadrants are visually balanced.

## Data sources
- GI: PMC9304465, PMC7270244, glycemic-index.net, University of Sydney GI Database
- Enjoyability: TasteAtlas ratings (rescaled), YouGov food preference surveys
