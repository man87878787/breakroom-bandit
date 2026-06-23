"""Dynamic game entities: the player, the Boss, coins, and trail markers."""
from __future__ import annotations

import math
import random

import pygame

from . import settings as S
from .level import Level
from .pathing import next_step


class Player:
    SIZE = 22

    def __init__(self, level: Level) -> None:
        cx, cy = level.tile_center(*level.player_spawn)
        self.x = float(cx)
        self.y = float(cy)
        self.sneaking = False
        self.moving = False
        self.still_time = 0.0
        self.boxed = False

    @property
    def rect(self) -> pygame.Rect:
        r = pygame.Rect(0, 0, self.SIZE, self.SIZE)
        r.center = (int(self.x), int(self.y))
        return r

    @property
    def tile(self) -> tuple[int, int]:
        return (int(self.x // S.TILE), int(self.y // S.TILE))

    def update(self, dt: float, keys, level: Level) -> None:
        dx = (keys[pygame.K_d] or keys[pygame.K_RIGHT]) - (keys[pygame.K_a] or keys[pygame.K_LEFT])
        dy = (keys[pygame.K_s] or keys[pygame.K_DOWN]) - (keys[pygame.K_w] or keys[pygame.K_UP])
        self.sneaking = bool(keys[pygame.K_LSHIFT] or keys[pygame.K_RSHIFT])

        if dx or dy:
            length = math.hypot(dx, dy)
            dx, dy = dx / length, dy / length
            speed = S.PLAYER_SNEAK_SPEED if self.sneaking else S.PLAYER_SPEED
            self._move(dx * speed * dt, dy * speed * dt, level)
            self.moving = True
            self.still_time = 0.0
            self.boxed = False
        else:
            self.moving = False
            self.still_time += dt
            if self.still_time >= S.BOX_HIDE_DELAY:
                self.boxed = True

    def _move(self, vx: float, vy: float, level: Level) -> None:
        self.x += vx
        if level.rect_hits_wall(self.rect):
            self.x -= vx
        self.y += vy
        if level.rect_hits_wall(self.rect):
            self.y -= vy


class Coin:
    SIZE = 14

    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y
        self.collected = False
        self.bob = random.uniform(0, math.tau)

    @property
    def rect(self) -> pygame.Rect:
        r = pygame.Rect(0, 0, self.SIZE, self.SIZE)
        r.center = (int(self.x), int(self.y))
        return r


class ScentMarker:
    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y
        self.life = S.SCENT_LIFETIME


class Spill:
    """A coffee puddle that masks the scent trail nearby."""

    RADIUS = 1.6 * S.TILE

    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y
        self.life = 5.0


class Boss:
    SIZE = 26

    def __init__(self, level: Level) -> None:
        cx, cy = level.tile_center(*level.boss_spawn)
        self.x = float(cx)
        self.y = float(cy)
        self.alert = 0.0                      # seconds of remaining chase
        self.target_tile: tuple[int, int] | None = None
        self.last_sense = ""                 # which sense triggered most recently

    @property
    def rect(self) -> pygame.Rect:
        r = pygame.Rect(0, 0, self.SIZE, self.SIZE)
        r.center = (int(self.x), int(self.y))
        return r

    @property
    def tile(self) -> tuple[int, int]:
        return (int(self.x // S.TILE), int(self.y // S.TILE))

    def _pick_wander_target(self, level: Level) -> None:
        self.target_tile = random.choice(level.floor_tiles)

    def sense_player(self, level: Level, player: Player, scent: list[ScentMarker], tier: int) -> str:
        """Return a label for the sense that detects the player this frame, else ''."""
        px, py = player.x, player.y
        dist = math.hypot(px - self.x, py - self.y)

        # Tier 3: line-of-sight in illuminated corridors (defeated by the box).
        if tier >= 3 and not player.boxed:
            if dist <= S.SIGHT_RANGE and level.is_lit(*player.tile):
                if level.line_of_sight_clear(*self.tile, *player.tile):
                    return "SIGHT"

        # Tier 2: scent tracking (defeated by spilling coffee on the trail).
        if tier >= 2 and scent:
            nearest = min(scent, key=lambda m: math.hypot(m.x - self.x, m.y - self.y))
            if math.hypot(nearest.x - self.x, nearest.y - self.y) <= S.SIGHT_RANGE:
                self._scent_target = level.world_to_tile(nearest.x, nearest.y)
                return "SCENT"

        # Tier 1: hearing running footsteps (defeated by sneaking with Shift).
        if tier >= 1 and player.moving and not player.sneaking:
            if dist <= S.HEAR_RANGE:
                return "HEARING"

        return ""

    def update(self, dt: float, level: Level, player: Player, scent: list[ScentMarker], tier: int) -> None:
        self._scent_target = None
        sense = self.sense_player(level, player, scent, tier)
        if sense:
            self.alert = S.ALERT_DURATION
            self.last_sense = sense
            if sense == "SCENT" and getattr(self, "_scent_target", None):
                self.target_tile = self._scent_target
            else:
                self.target_tile = player.tile

        if self.alert > 0:
            self.alert -= dt
            speed = S.BOSS_CHASE_SPEED
            if self.target_tile is None:
                self.target_tile = player.tile
        else:
            speed = S.BOSS_WANDER_SPEED
            if self.target_tile is None or self.tile == self.target_tile:
                self._pick_wander_target(level)

        self._step_toward(dt, level, speed)

    def _step_toward(self, dt: float, level: Level, speed: float) -> None:
        if self.target_tile is None:
            return
        step = next_step(level, self.tile, self.target_tile)
        if step is None:
            self.target_tile = None
            return
        tx, ty = level.tile_center(*step)
        dx, dy = tx - self.x, ty - self.y
        d = math.hypot(dx, dy)
        if d < 1e-3:
            return
        move = min(speed * dt, d)
        self.x += dx / d * move
        self.y += dy / d * move
