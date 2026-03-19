import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Ellipse
from adjustText import adjust_text
import textwrap

# Bangalore weather aesthetic: warm beige, Tufte minimalism, no chart junk
BG = '#e5e1d8'
SUBTLE = '#c8c0aa'
MID = '#9c9280'
ACCENT = '#5f3946'
TEXT = '#3C3C3C'

# Real Glycemic Index data from published sources:
#   - South Indian foods: PMC9304465 (2022 peer-reviewed study, human subjects)
#   - Ragi mudde: PMC7270244
#   - Other foods: glycemic-index.net, University of Sydney GI database,
#     Harvard Health GI tables, International Tables of GI/GL 2021
#   - Protein/fat foods (steak, salmon, etc.): GI ~0 (negligible carbs)
#   - Sweets without formal GI: estimated from component ingredients + sugar load
#
# Enjoyability: subjective general-consensus scores (-10 to 10)

foods = [
    # === SOUTH INDIAN VEGETARIAN FESTIVAL FOOD ===
    ("Masala Dosa", 79, 9, "si_veg"),         # PMC9304465: plain dosa 79.4
    ("Idli + Sambar", 69, 0, "si_veg"),       # PMC9304465: 68.7
    ("Upma", 68, -3, "si_veg"),               # InDiabetes compiled studies
    ("Ragi Mudde", 51, -6, "si_veg"),         # PMC7270244: 48-53
    ("White Rice", 79, -1, "si_veg"),         # PMC9304465 / InDiabetes
    ("Rasam Rice", 74, -5, "si_veg"),         # Extrapolated: tomato rice 68.9, lemon rice 79.3
    ("Payasam", 68, 4, "si_veg"),             # Ultrahuman / multiple sources: 65-70
    ("Mysore Pak", 82, 6, "si_veg"),          # Estimated: besan + heavy sugar/ghee
    ("Kesari Bath", 81, 3, "si_veg"),         # Estimated: semolina 66 + sugar pushes to 80+
    ("Holige/Obbattu", 68, -3, "si_veg"),      # Estimated: jaggery + maida, ~65-70. Jaggery = not enjoyable
    ("Jackfruit Sweet", 75, -5, "si_veg"),    # PubMed 21789865: jackfruit meal GI 75 + sugar
    ("Pongal", 90, 5, "si_veg"),              # InDiabetes: 87-93

    # === OTHER VEGETARIAN FOODS (all cuisines, no meat/fish/egg) ===

    # Promised Land - low GI, enjoyable
    ("Paneer Tikka", 0, 8, "other"),          # Protein/fat, negligible carbs
    ("Guacamole", 15, 8, "other"),            # Avocado GI ~15
    ("Cheese Platter", 0, 7, "other"),        # Negligible carbs
    ("Dark Chocolate\n(85%)", 23, 7, "other"),# glycemic-index.net: 20-25
    ("Hummus + Veggies", 6, 6, "other"),      # Chickpea hummus GI 6 (Syd Uni)
    ("Greek Salad", 15, 6, "other"),          # Vegetables + feta, very low GI
    ("Caprese Salad", 15, 7, "other"),        # Mozzarella + tomato, low GI
    ("Peanut Butter\n(on celery)", 14, 6, "other"),  # GI 14 (glycemic-index.net)
    ("Nuts (Almonds)", 0, 5, "other"),        # GI ~0, pure fat/protein

    # Delicious Poison - high GI, enjoyable
    ("Margherita Pizza", 70, 9, "other"),     # glycemic-index.net: 60-80
    ("Cheesecake", 56, 9, "other"),           # glycemic-index.net: 50-63
    ("French Fries", 75, 8, "other"),         # glycemic-index.net: 75
    ("Ice Cream", 61, 9, "other"),            # Multiple sources: 60-61
    ("Pasta Alfredo", 55, 7, "other"),        # White pasta GI ~55
    ("Nachos + Cheese", 74, 8, "other"),      # Corn chips GI ~74

    # Virtuous Suffering - low GI, not enjoyable
    ("Steamed Broccoli", 10, -4, "other"),    # GI ~10, most people find it meh
    ("Plain Tofu", 15, -5, "other"),          # GI ~15, bland by itself
    ("Boiled Spinach", 15, -6, "other"),      # GI ~15, joyless
    ("Raw Celery", 0, -7, "other"),           # GI ~0, edible sadness
    ("Bitter Gourd /\nKarela", 15, -8, "other"),  # GI ~15, notoriously hated
    ("Steamed Zucchini", 15, -3, "other"),    # GI ~15, inoffensive but dull

    # Why Does This Exist - high GI, not enjoyable
    ("Plain White Bread", 75, -2, "other"),   # GI 75, boring on its own
    ("Boiled Potato\n(plain)", 78, -3, "other"),  # GI 78, sad without toppings
]

def gi_to_x(gi):
    return 10 - (gi / 5)  # GI 0 -> +10, GI 50 -> 0, GI 100 -> -10

fig, ax = plt.subplots(figsize=(28, 20))

# Tufte: warm background, no chart junk
fig.patch.set_facecolor(BG)
ax.set_facecolor(BG)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.spines['left'].set_linewidth(0.3)
ax.spines['bottom'].set_linewidth(0.3)
ax.spines['left'].set_color(TEXT)
ax.spines['bottom'].set_color(TEXT)
ax.tick_params(colors=TEXT, labelsize=16, length=0)
ax.grid(False)

# Subtle quadrant dividers instead of colored fills
ax.axhline(y=0, color=SUBTLE, linewidth=0.8)
ax.axvline(x=0, color=SUBTLE, linewidth=0.8)

# GI zone markers - subtle vertical references
ax.axvline(x=gi_to_x(55), color=MID, linewidth=0.5, linestyle=':', alpha=0.5)
ax.axvline(x=gi_to_x(70), color=MID, linewidth=0.5, linestyle=':', alpha=0.5)
ax.text(gi_to_x(55) + 0.2, -10.2, "Low GI (<55)", fontsize=14, color=MID)
ax.text(gi_to_x(70) - 4.5, -10.2, "High GI (>70)", fontsize=14, color=MID)

# Quadrant labels - muted, unobtrusive
ax.text(-7, 10, "DELICIOUS POISON", fontsize=20, fontweight='bold',
        color=ACCENT, alpha=0.35, ha='center')
ax.text(7.5, 10, "THE PROMISED LAND", fontsize=20, fontweight='bold',
        color='#6b8f71', alpha=0.35, ha='center')
ax.text(-7, -9.2, "WHY DOES THIS EXIST?", fontsize=20, fontweight='bold',
        color=MID, alpha=0.4, ha='center')
ax.text(7.5, -9.2, "VIRTUOUS SUFFERING", fontsize=20, fontweight='bold',
        color=MID, alpha=0.4, ha='center')

np.random.seed(7)

si_xs, si_ys = [], []
texts = []
for name, gi, enjoy, cat in foods:
    x = gi_to_x(gi) + np.random.uniform(-0.3, 0.3)
    y = enjoy + np.random.uniform(-0.3, 0.3)

    if cat == "si_veg":
        si_xs.append(x); si_ys.append(y)
        ax.scatter(x, y, c=ACCENT, s=140, marker='s', alpha=0.9,
                   edgecolors=ACCENT, linewidth=0.8, zorder=10)
        label = textwrap.fill(name, 10)
        texts.append(ax.text(x, y, label, fontsize=22, color=ACCENT,
                             fontweight='bold', ha='left', va='center'))
    else:
        ax.scatter(x, y, c=MID, s=100, marker='o', alpha=0.7,
                   edgecolors=BG, linewidth=0.5, zorder=5)
        label = textwrap.fill(name, 10)
        texts.append(ax.text(x, y, label, fontsize=20, color=TEXT,
                             fontweight='normal', ha='left', va='center'))

# Repel overlapping labels (like ggrepel)
adjust_text(texts, ax=ax,
            arrowprops=dict(arrowstyle='-', color=MID, alpha=0.4, lw=0.8),
            expand=(3.0, 3.0),
            force_text=(3.0, 3.0),
            force_points=(2.0, 2.0),
            force_objects=(2.0, 2.0),
            ensure_inside_axes=False,
            iterations=500)

# Legend - minimal, Tufte-style
h1 = plt.Line2D([0], [0], marker='s', color='none', markerfacecolor=ACCENT,
                markersize=11, markeredgecolor=ACCENT, markeredgewidth=0.8,
                label='South Indian Veg (Festival)')
h2 = plt.Line2D([0], [0], marker='o', color='none', markerfacecolor=MID,
                markersize=10, markeredgecolor=BG, markeredgewidth=0.5,
                label='Everything Else')
legend = ax.legend(handles=[h1, h2], loc='lower left', fontsize=16,
                   frameon=False, labelcolor=TEXT)

# Axis labels
ax.set_xlabel("← High Glycemic Index (Spike)          Low Glycemic Index (Safe) →",
              fontsize=18, fontweight='bold', color=TEXT, labelpad=16)
ax.set_ylabel("← Nobody Wants This          Everyone Fights Over It →",
              fontsize=18, fontweight='bold', color=TEXT, labelpad=16)

# Title
ax.set_title("The South Indian Vegetarian Food Problem",
             fontsize=28, fontweight='bold', color=TEXT, pad=10, loc='left')
ax.text(0, 1.03, "Real Glycemic Index Data vs. Enjoyability — Vegetarian Foods Only",
        transform=ax.transAxes, fontsize=16, color=ACCENT, ha='left')

ax.set_xlim(-11, 11)
ax.set_ylim(-11, 11)
ax.set_aspect('equal')

# Source citation
fig.text(0.5, 0.005,
         "GI Sources: PMC9304465 (South Indian Breakfast Foods, 2022)  ·  PMC7270244 (Millet Foods)  ·  "
         "glycemic-index.net  ·  University of Sydney GI Database  ·  Harvard Health GI Tables",
         ha='center', fontsize=11, color=MID, style='italic')

plt.tight_layout(rect=[0, 0.025, 1, 0.97])
plt.savefig("/Users/Karthik/Documents/work/south-indian-food-2x2/south-indian-food-2x2.png",
            dpi=200, bbox_inches='tight', facecolor=BG)
plt.close()
print("Chart saved.")
