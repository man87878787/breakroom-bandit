"""Game-wide constants, colors, and the office map layout."""

# --- Tiles / geometry -------------------------------------------------------
TILE = 32
HUD_HEIGHT = 96

# Office floor plan. One character per tile.
#   '#' wall
#   '.' plain floor
#   'L' illuminated corridor floor (matters for the Boss's line-of-sight sense)
#   'C' coffee station (refills the sleepiness meter)
#   'V' vending machine (spend coins to secure a snack)
#   'P' player spawn
#   'B' boss spawn
OFFICE_MAP = [
    "#########################",
    "#P..........#.....C.....#",
    "#..####.....#.....#####.#",
    "#..#V.#.....#.........#.#",
    "#..#..#.LLLLLLLLL.....#.#",
    "#..#..#.....#...L.....#.#",
    "#.......###.#...L.....#.#",
    "#.LLLLL.#.#.#...L.....V.#",
    "#.L...L.#.#.....L.....#.#",
    "#.L.B.L.#.#.LLLLL.....#.#",
    "#.L...L.#.#.#.........#.#",
    "#.LLLLL.#...#.#######.#.#",
    "#.......#...#.......#.#.#",
    "#.#####.....#.....#.#.#.#",
    "#.....#.V...#.....#...#.#",
    "#.###.#.....#####.#####.#",
    "#...........#...........#",
    "#..C........#........V..#",
    "#########################",
]

GRID_W = len(OFFICE_MAP[0])
GRID_H = len(OFFICE_MAP)
WIDTH = GRID_W * TILE
HEIGHT = GRID_H * TILE + HUD_HEIGHT
FPS = 60

# --- Colors (clear, flat color blocks per entity) ---------------------------
C_FLOOR = (38, 42, 54)
C_FLOOR_LIT = (74, 70, 48)
C_WALL = (24, 26, 34)
C_WALL_TOP = (52, 56, 70)
C_GRID = (44, 48, 62)

C_PLAYER = (90, 200, 255)
C_PLAYER_SNEAK = (60, 130, 170)
C_BOSS = (235, 80, 90)
C_BOSS_ALERT = (255, 160, 40)
C_COIN = (255, 214, 64)
C_VENDING = (130, 220, 130)
C_VENDING_EMPTY = (80, 110, 80)
C_COFFEE = (180, 130, 80)
C_SPILL = (110, 70, 40)
C_SCENT = (150, 120, 200)
C_BOX = (200, 165, 110)

C_HUD_BG = (16, 18, 24)
C_TEXT = (235, 238, 245)
C_TEXT_DIM = (150, 156, 170)
C_GOOD = (120, 230, 140)
C_WARN = (255, 120, 120)
C_METER_BG = (40, 44, 56)
C_METER_FILL = (120, 210, 255)
C_METER_LOW = (255, 110, 110)

# --- Gameplay tuning --------------------------------------------------------
PLAYER_SPEED = 165.0          # px/sec when running
PLAYER_SNEAK_SPEED = 78.0     # px/sec while holding Shift
BOSS_WANDER_SPEED = 95.0
BOSS_CHASE_SPEED = 150.0

COIN_COUNT = 9
SNACK_PRICE = 3               # coins per snack
WIN_SNACKS = 5                # snacks needed to clock out victorious

SLEEP_MAX = 100.0
SLEEP_DECAY = 4.0             # per second
SLEEP_REFILL = 70.0          # per second while at coffee station

# Boss sensory ranges
HEAR_RANGE = 4.2 * TILE       # how close running footsteps can be heard
SIGHT_RANGE = 8.0 * TILE      # line-of-sight reach in lit corridors
ALERT_DURATION = 3.0          # seconds the Boss keeps chasing after a detection

# Scent trail
SCENT_INTERVAL = 0.18         # seconds between dropped scent markers
SCENT_LIFETIME = 6.0          # seconds a marker lingers

# Hiding under the cardboard box
BOX_HIDE_DELAY = 0.55         # seconds of standing still before the box drops

# Sense unlock schedule: number of snacks secured -> highest sense tier active.
# Tier 0 none, 1 hearing, 2 scent, 3 sight.
def active_sense_tier(snacks_secured: int) -> int:
    if snacks_secured >= 3:
        return 3
    if snacks_secured >= 2:
        return 2
    if snacks_secured >= 1:
        return 1
    return 0
