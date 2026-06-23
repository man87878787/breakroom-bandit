"""Main game loop, state machine, HUD, and rendering for Breakroom Bandit."""
from __future__ import annotations

import math
import random

import pygame

from . import settings as S
from .entities import Boss, Coin, Player, ScentMarker, Spill
from .level import Level

# Game states
TITLE, PLAY, CAUGHT, ASLEEP, WIN = "title", "play", "caught", "asleep", "win"

SENSE_LABELS = {
    "HEARING": "EARS",
    "SCENT": "NOSE",
    "SIGHT": "EYES",
}

WIN_QUIPS = [
    "You clocked out with a full snack stash. The vending machines salute you.",
    "Snack quota met. The Boss is still looking for his stapler.",
]
CAUGHT_QUIPS = [
    "\"Got a minute to chat about synergy?\" -- The Boss",
    "The Boss caught you mid-snack. Mandatory team-building ensues.",
    "Busted! The Boss wants to 'circle back' on your coffee breaks.",
]
ASLEEP_QUIPS = [
    "You dozed off at your desk. The Boss draws a moustache on your face.",
    "Out of caffeine, out of luck. Nap time is over, bandit.",
]


class Game:
    def __init__(self) -> None:
        pygame.init()
        pygame.display.set_caption("Breakroom Bandit")
        self.screen = pygame.display.set_mode((S.WIDTH, S.HEIGHT))
        self.clock = pygame.time.Clock()
        self.font_sm = pygame.font.SysFont("consolas", 16)
        self.font_md = pygame.font.SysFont("consolas", 22, bold=True)
        self.font_lg = pygame.font.SysFont("consolas", 44, bold=True)
        self.state = TITLE
        self.reset()

    # --- lifecycle ----------------------------------------------------------
    def reset(self) -> None:
        self.level = Level()
        self.player = Player(self.level)
        self.boss = Boss(self.level)
        self.coins: list[Coin] = []
        self.scent: list[ScentMarker] = []
        self.spills: list[Spill] = []
        self.coin_bank = 0
        self.snacks = 0
        self.sleep = S.SLEEP_MAX
        self.scent_timer = 0.0
        self.vend_cooldown = 0.0
        self.toast = ""
        self.toast_time = 0.0
        self.end_quip = ""
        self._spawn_coins(S.COIN_COUNT)

    def _spawn_coins(self, n: int) -> None:
        reserved = set(self.level.coffee_tiles) | set(self.level.vending_tiles)
        reserved.add(self.level.player_spawn)
        reserved.add(self.level.boss_spawn)
        choices = [t for t in self.level.floor_tiles if t not in reserved]
        random.shuffle(choices)
        for tx, ty in choices[:n]:
            cx, cy = self.level.tile_center(tx, ty)
            self.coins.append(Coin(cx, cy))

    def _toast(self, msg: str, secs: float = 2.5) -> None:
        self.toast = msg
        self.toast_time = secs

    # --- main loop ----------------------------------------------------------
    def run(self) -> None:
        running = True
        while running:
            dt = self.clock.tick(S.FPS) / 1000.0
            dt = min(dt, 0.05)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    self._on_keydown(event)
            if self.state == PLAY:
                self.update(dt)
            self.draw()
            pygame.display.flip()
        pygame.quit()

    def _on_keydown(self, event: pygame.event.Event) -> None:
        if event.key == pygame.K_ESCAPE:
            pygame.event.post(pygame.event.Event(pygame.QUIT))
            return
        if self.state in (TITLE, CAUGHT, ASLEEP, WIN):
            if event.key in (pygame.K_RETURN, pygame.K_SPACE):
                if self.state != TITLE:
                    self.reset()
                self.state = PLAY
            return
        if self.state == PLAY and event.key == pygame.K_SPACE:
            self._spill_coffee()

    def _spill_coffee(self) -> None:
        spill = Spill(self.player.x, self.player.y)
        self.spills.append(spill)
        # Spilling coffee instantly breaks the existing scent trail nearby.
        self.scent = [
            m for m in self.scent
            if math.hypot(m.x - spill.x, m.y - spill.y) > Spill.RADIUS
        ]
        self._toast("Coffee spilled! Scent trail broken.", 2.0)

    # --- update -------------------------------------------------------------
    def update(self, dt: float) -> None:
        keys = pygame.key.get_pressed()
        tier = S.active_sense_tier(self.snacks)

        self.player.update(dt, keys, self.level)

        # Sleepiness meter ticks down; the coffee station tops it back up.
        on_coffee = self.player.tile in self.level.coffee_tiles
        if on_coffee:
            self.sleep = min(S.SLEEP_MAX, self.sleep + S.SLEEP_REFILL * dt)
        else:
            self.sleep -= S.SLEEP_DECAY * dt
        if self.sleep <= 0:
            self.sleep = 0
            self.end_quip = random.choice(ASLEEP_QUIPS)
            self.state = ASLEEP
            return

        # Drop scent markers while moving (unless standing in a fresh spill).
        self.scent_timer -= dt
        in_spill = any(math.hypot(s.x - self.player.x, s.y - self.player.y) <= Spill.RADIUS for s in self.spills)
        if self.player.moving and self.scent_timer <= 0 and not in_spill:
            self.scent_timer = S.SCENT_INTERVAL
            self.scent.append(ScentMarker(self.player.x, self.player.y))
        for m in self.scent:
            m.life -= dt
        self.scent = [m for m in self.scent if m.life > 0]

        for s in self.spills:
            s.life -= dt
        self.spills = [s for s in self.spills if s.life > 0]

        # Coins
        prect = self.player.rect
        for coin in self.coins:
            if not coin.collected and prect.colliderect(coin.rect):
                coin.collected = True
                self.coin_bank += 1
        self.coins = [c for c in self.coins if not c.collected]

        # Vending machines
        self.vend_cooldown = max(0.0, self.vend_cooldown - dt)
        if self.player.tile in self.level.vending_tiles and self.vend_cooldown <= 0:
            if self.coin_bank >= S.SNACK_PRICE:
                self.coin_bank -= S.SNACK_PRICE
                self.snacks += 1
                self.vend_cooldown = 1.0
                self._on_snack_secured()

        # Boss
        self.boss.update(dt, self.level, self.player, self.scent, tier)
        if not self.player.boxed and self.boss.rect.colliderect(self.player.rect):
            self.end_quip = random.choice(CAUGHT_QUIPS)
            self.state = CAUGHT
            return

        if self.snacks >= S.WIN_SNACKS:
            self.end_quip = random.choice(WIN_QUIPS)
            self.state = WIN

        if self.toast_time > 0:
            self.toast_time -= dt

    def _on_snack_secured(self) -> None:
        new_tier = S.active_sense_tier(self.snacks)
        unlock = {
            1: "Boss unlocked SUPER HEARING! Hold SHIFT to sneak.",
            2: "Boss unlocked SUPER SMELL! Press SPACE to spill coffee.",
            3: "Boss unlocked X-RAY VISION! Stand still to hide in a box.",
        }
        if new_tier in unlock and S.active_sense_tier(self.snacks - 1) < new_tier:
            self._toast(unlock[new_tier], 3.5)
        else:
            self._toast(f"Snack secured! ({self.snacks}/{S.WIN_SNACKS})", 2.0)
        # Restock a couple of coins so the heist can continue.
        self._spawn_coins(3)

    # --- rendering ----------------------------------------------------------
    def draw(self) -> None:
        self.screen.fill(S.C_FLOOR)
        self._draw_office()
        if self.state in (PLAY, CAUGHT, ASLEEP, WIN):
            self._draw_world()
        self._draw_hud()
        if self.state == TITLE:
            self._draw_title()
        elif self.state in (CAUGHT, ASLEEP, WIN):
            self._draw_end()

    def _draw_office(self) -> None:
        for ty in range(S.GRID_H):
            for tx in range(S.GRID_W):
                rect = pygame.Rect(tx * S.TILE, ty * S.TILE + S.HUD_HEIGHT, S.TILE, S.TILE)
                if self.level.is_wall(tx, ty):
                    pygame.draw.rect(self.screen, S.C_WALL, rect)
                    pygame.draw.rect(self.screen, S.C_WALL_TOP, rect, 2)
                else:
                    color = S.C_FLOOR_LIT if self.level.is_lit(tx, ty) else S.C_FLOOR
                    pygame.draw.rect(self.screen, color, rect)
                    pygame.draw.rect(self.screen, S.C_GRID, rect, 1)

        for tx, ty in self.level.coffee_tiles:
            self._draw_fixture(tx, ty, S.C_COFFEE, "C")
        for tx, ty in self.level.vending_tiles:
            self._draw_fixture(tx, ty, S.C_VENDING, "$")

    def _draw_fixture(self, tx: int, ty: int, color, glyph: str) -> None:
        rect = pygame.Rect(tx * S.TILE + 3, ty * S.TILE + S.HUD_HEIGHT + 3, S.TILE - 6, S.TILE - 6)
        pygame.draw.rect(self.screen, color, rect, border_radius=5)
        label = self.font_sm.render(glyph, True, (20, 24, 30))
        self.screen.blit(label, label.get_rect(center=rect.center))

    def _to_screen(self, x: float, y: float) -> tuple[int, int]:
        return int(x), int(y + S.HUD_HEIGHT)

    def _draw_world(self) -> None:
        # Spills
        for s in self.spills:
            pos = self._to_screen(s.x, s.y)
            surf = pygame.Surface((int(Spill.RADIUS * 2), int(Spill.RADIUS * 2)), pygame.SRCALPHA)
            pygame.draw.circle(surf, (*S.C_SPILL, 150), (int(Spill.RADIUS), int(Spill.RADIUS)), int(Spill.RADIUS))
            self.screen.blit(surf, (pos[0] - Spill.RADIUS, pos[1] - Spill.RADIUS))

        # Scent markers
        for m in self.scent:
            alpha = max(40, int(180 * (m.life / S.SCENT_LIFETIME)))
            pos = self._to_screen(m.x, m.y)
            surf = pygame.Surface((10, 10), pygame.SRCALPHA)
            pygame.draw.circle(surf, (*S.C_SCENT, alpha), (5, 5), 5)
            self.screen.blit(surf, (pos[0] - 5, pos[1] - 5))

        # Coins (with a little bob)
        t = pygame.time.get_ticks() / 300.0
        for coin in self.coins:
            pos = self._to_screen(coin.x, coin.y + math.sin(t + coin.bob) * 2)
            pygame.draw.circle(self.screen, S.C_COIN, pos, Coin.SIZE // 2)
            pygame.draw.circle(self.screen, (160, 120, 20), pos, Coin.SIZE // 2, 2)

        # Boss sight cone hint when sight is active and the Boss is alert
        self._draw_boss(self.boss)
        self._draw_player(self.player)

    def _draw_boss(self, boss: Boss) -> None:
        pos = self._to_screen(boss.x, boss.y)
        rect = pygame.Rect(0, 0, Boss.SIZE, Boss.SIZE)
        rect.center = pos
        color = S.C_BOSS_ALERT if boss.alert > 0 else S.C_BOSS
        pygame.draw.rect(self.screen, color, rect, border_radius=4)
        # angry eyebrows
        pygame.draw.line(self.screen, (20, 20, 20), (rect.left + 5, rect.top + 9), (rect.centerx - 1, rect.top + 6), 2)
        pygame.draw.line(self.screen, (20, 20, 20), (rect.right - 5, rect.top + 9), (rect.centerx + 1, rect.top + 6), 2)
        if boss.alert > 0:
            bang = self.font_md.render("!", True, S.C_WARN)
            self.screen.blit(bang, (rect.centerx - 4, rect.top - 20))

    def _draw_player(self, player: Player) -> None:
        pos = self._to_screen(player.x, player.y)
        if player.boxed:
            rect = pygame.Rect(0, 0, S.TILE - 4, S.TILE - 4)
            rect.center = pos
            pygame.draw.rect(self.screen, S.C_BOX, rect, border_radius=3)
            pygame.draw.rect(self.screen, (120, 90, 50), rect, 2, border_radius=3)
            pygame.draw.line(self.screen, (120, 90, 50), rect.midtop, rect.midbottom, 2)
            pygame.draw.line(self.screen, (120, 90, 50), rect.midleft, rect.midright, 2)
            return
        rect = pygame.Rect(0, 0, Player.SIZE, Player.SIZE)
        rect.center = pos
        color = S.C_PLAYER_SNEAK if player.sneaking else S.C_PLAYER
        pygame.draw.rect(self.screen, color, rect, border_radius=6)
        if player.sneaking:
            tip = self.font_sm.render("sneak", True, S.C_TEXT_DIM)
            self.screen.blit(tip, (rect.centerx - 18, rect.top - 16))

    # --- HUD ----------------------------------------------------------------
    def _draw_hud(self) -> None:
        pygame.draw.rect(self.screen, S.C_HUD_BG, (0, 0, S.WIDTH, S.HUD_HEIGHT))
        pygame.draw.line(self.screen, (60, 64, 80), (0, S.HUD_HEIGHT), (S.WIDTH, S.HUD_HEIGHT), 2)

        # Title + score
        title = self.font_md.render("BREAKROOM BANDIT", True, S.C_TEXT)
        self.screen.blit(title, (14, 8))
        score = self.font_sm.render(
            f"Coins: {self.coin_bank}   Snacks: {self.snacks}/{S.WIN_SNACKS}   (snack price: {S.SNACK_PRICE})",
            True, S.C_TEXT_DIM)
        self.screen.blit(score, (14, 38))

        # Sleepiness meter
        self._draw_meter(14, 62, 260, 18, self.sleep / S.SLEEP_MAX, "SLEEPINESS")

        # Active boss powers
        tier = S.active_sense_tier(self.snacks)
        powers = []
        if tier >= 1:
            powers.append("HEARING")
        if tier >= 2:
            powers.append("SCENT")
        if tier >= 3:
            powers.append("SIGHT")
        label = "Boss senses: " + (", ".join(powers) if powers else "NONE (blind wander)")
        psurf = self.font_sm.render(label, True, S.C_WARN if powers else S.C_GOOD)
        self.screen.blit(psurf, (320, 12))

        # live detection alert
        if self.boss.alert > 0 and self.boss.last_sense:
            warn = self.font_md.render(f"BOSS {self.boss.last_sense}S YOU!", True, S.C_WARN)
            self.screen.blit(warn, (320, 34))
        else:
            calm = self.font_sm.render("Status: Boss is none the wiser...", True, S.C_GOOD)
            self.screen.blit(calm, (320, 38))

        controls = self.font_sm.render(
            "WASD move | SHIFT sneak | SPACE spill coffee | stand still = hide in box",
            True, S.C_TEXT_DIM)
        self.screen.blit(controls, (320, 64))

        # toast
        if self.toast_time > 0 and self.toast:
            tsurf = self.font_sm.render(self.toast, True, S.C_COIN)
            bg = tsurf.get_rect(midtop=(S.WIDTH // 2, S.HUD_HEIGHT + 6)).inflate(16, 8)
            pygame.draw.rect(self.screen, (0, 0, 0), bg, border_radius=6)
            self.screen.blit(tsurf, tsurf.get_rect(midtop=(S.WIDTH // 2, S.HUD_HEIGHT + 10)))

    def _draw_meter(self, x, y, w, h, frac, label) -> None:
        frac = max(0.0, min(1.0, frac))
        pygame.draw.rect(self.screen, S.C_METER_BG, (x, y, w, h), border_radius=4)
        color = S.C_METER_LOW if frac < 0.3 else S.C_METER_FILL
        pygame.draw.rect(self.screen, color, (x, y, int(w * frac), h), border_radius=4)
        lab = self.font_sm.render(label, True, S.C_TEXT)
        self.screen.blit(lab, (x + w + 8, y))

    # --- overlays -----------------------------------------------------------
    def _overlay(self) -> None:
        surf = pygame.Surface((S.WIDTH, S.HEIGHT), pygame.SRCALPHA)
        surf.fill((0, 0, 0, 180))
        self.screen.blit(surf, (0, 0))

    def _center_text(self, text, font, color, y) -> None:
        surf = font.render(text, True, color)
        self.screen.blit(surf, surf.get_rect(center=(S.WIDTH // 2, y)))

    def _draw_title(self) -> None:
        self._overlay()
        self._center_text("BREAKROOM BANDIT", self.font_lg, S.C_COIN, 150)
        lines = [
            "Collect coins, raid the vending machines for snacks,",
            "and dodge the Boss -- who grows a new super-sense",
            "every single time you secure a snack.",
            "",
            "WASD / arrows: move      SHIFT: sneak quietly",
            "SPACE: spill coffee (break scent trail)",
            "Stand perfectly still: hide under a cardboard box",
            "",
            "Keep the SLEEPINESS meter up at the coffee station (C).",
            f"Secure {S.WIN_SNACKS} snacks to clock out a legend.",
        ]
        y = 220
        for ln in lines:
            self._center_text(ln, self.font_sm, S.C_TEXT, y)
            y += 26
        self._center_text("Press ENTER to start", self.font_md, S.C_GOOD, y + 14)

    def _draw_end(self) -> None:
        self._overlay()
        if self.state == WIN:
            self._center_text("SNACK QUOTA COMPLETE!", self.font_lg, S.C_GOOD, 230)
        elif self.state == ASLEEP:
            self._center_text("ZZZ... YOU FELL ASLEEP", self.font_lg, S.C_METER_LOW, 230)
        else:
            self._center_text("CAUGHT BY THE BOSS!", self.font_lg, S.C_BOSS, 230)
        self._center_text(self.end_quip, self.font_sm, S.C_TEXT, 300)
        self._center_text(f"Snacks secured: {self.snacks}/{S.WIN_SNACKS}", self.font_md, S.C_COIN, 350)
        self._center_text("Press ENTER to play again", self.font_md, S.C_GOOD, 410)


def main() -> None:
    Game().run()


if __name__ == "__main__":
    main()
