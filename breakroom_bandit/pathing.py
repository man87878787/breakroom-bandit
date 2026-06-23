"""Tiny BFS pathfinder used by the Boss to chase the player."""
from __future__ import annotations

from collections import deque

from .level import Level


def next_step(level: Level, start: tuple[int, int], goal: tuple[int, int]):
    """Return the next tile to move to from ``start`` toward ``goal``.

    Returns ``None`` if no path exists or already at the goal.
    """
    if start == goal:
        return None
    if level.is_wall(*goal):
        return None

    frontier: deque[tuple[int, int]] = deque([start])
    came_from: dict[tuple[int, int], tuple[int, int] | None] = {start: None}

    while frontier:
        current = frontier.popleft()
        if current == goal:
            break
        cx, cy = current
        for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            nxt = (nx, ny)
            if nxt in came_from or level.is_wall(nx, ny):
                continue
            came_from[nxt] = current
            frontier.append(nxt)

    if goal not in came_from:
        return None

    # Walk back from goal to the tile right after start.
    node = goal
    while came_from[node] != start:
        node = came_from[node]
        if node is None:
            return None
    return node
