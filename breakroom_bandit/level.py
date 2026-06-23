"""Parses the office map and provides tile/collision helpers."""
from __future__ import annotations

import pygame

from . import settings as S


class Level:
    """Holds the static office layout: walls, lit tiles, and fixtures."""

    def __init__(self) -> None:
        self.rows = [list(row) for row in S.OFFICE_MAP]
        self.player_spawn = (0, 0)
        self.boss_spawn = (0, 0)
        self.coffee_tiles: list[tuple[int, int]] = []
        self.vending_tiles: list[tuple[int, int]] = []
        self.lit: set[tuple[int, int]] = set()
        self.walls: set[tuple[int, int]] = set()
        self.floor_tiles: list[tuple[int, int]] = []

        for ty, row in enumerate(self.rows):
            for tx, ch in enumerate(row):
                if ch == "#":
                    self.walls.add((tx, ty))
                    continue
                # Everything below counts as a walkable floor tile.
                self.floor_tiles.append((tx, ty))
                if ch == "L":
                    self.lit.add((tx, ty))
                elif ch == "C":
                    self.coffee_tiles.append((tx, ty))
                elif ch == "V":
                    self.vending_tiles.append((tx, ty))
                elif ch == "P":
                    self.player_spawn = (tx, ty)
                elif ch == "B":
                    self.boss_spawn = (tx, ty)

    # --- queries ------------------------------------------------------------
    def is_wall(self, tx: int, ty: int) -> bool:
        if tx < 0 or ty < 0 or tx >= S.GRID_W or ty >= S.GRID_H:
            return True
        return (tx, ty) in self.walls

    def is_lit(self, tx: int, ty: int) -> bool:
        return (tx, ty) in self.lit

    def tile_center(self, tx: int, ty: int) -> tuple[float, float]:
        return (tx * S.TILE + S.TILE / 2, ty * S.TILE + S.TILE / 2)

    def world_to_tile(self, x: float, y: float) -> tuple[int, int]:
        return (int(x // S.TILE), int(y // S.TILE))

    def rect_hits_wall(self, rect: pygame.Rect) -> bool:
        x0 = rect.left // S.TILE
        x1 = rect.right // S.TILE
        y0 = rect.top // S.TILE
        y1 = rect.bottom // S.TILE
        for ty in range(y0, y1 + 1):
            for tx in range(x0, x1 + 1):
                if self.is_wall(tx, ty):
                    if pygame.Rect(tx * S.TILE, ty * S.TILE, S.TILE, S.TILE).colliderect(rect):
                        return True
        return False

    def line_of_sight_clear(self, ax: int, ay: int, bx: int, by: int) -> bool:
        """Bresenham walk between two tiles; blocked by any wall in between."""
        dx = abs(bx - ax)
        dy = abs(by - ay)
        sx = 1 if ax < bx else -1
        sy = 1 if ay < by else -1
        err = dx - dy
        x, y = ax, ay
        while True:
            if (x, y) != (ax, ay) and (x, y) != (bx, by):
                if self.is_wall(x, y):
                    return False
            if x == bx and y == by:
                return True
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x += sx
            if e2 < dx:
                err += dx
                y += sy
