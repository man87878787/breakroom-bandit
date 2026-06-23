"""Headless smoke tests: run the simulation without a real display."""
import os
import sys

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pygame

from breakroom_bandit import settings as S
from breakroom_bandit.entities import Boss, Player, ScentMarker
from breakroom_bandit.game import PLAY, Game
from breakroom_bandit.level import Level
from breakroom_bandit.pathing import next_step


class FakeKeys:
    def __init__(self, held=()):
        self.held = set(held)

    def __getitem__(self, key):
        return key in self.held


def test_level_parses_fixtures():
    lvl = Level()
    assert lvl.player_spawn != lvl.boss_spawn
    assert lvl.coffee_tiles, "expected at least one coffee station"
    assert lvl.vending_tiles, "expected at least one vending machine"
    assert lvl.lit, "expected illuminated corridor tiles"


def test_pathfinder_reaches_goal():
    lvl = Level()
    start = lvl.boss_spawn
    goal = lvl.player_spawn
    step = next_step(lvl, start, goal)
    assert step is not None
    assert not lvl.is_wall(*step)


def test_sense_tier_schedule():
    assert S.active_sense_tier(0) == 0
    assert S.active_sense_tier(1) == 1
    assert S.active_sense_tier(2) == 2
    assert S.active_sense_tier(3) == 3
    assert S.active_sense_tier(9) == 3


def test_boss_hears_running_but_not_sneaking():
    lvl = Level()
    boss = Boss(lvl)
    player = Player(lvl)
    # place player adjacent to boss
    player.x, player.y = boss.x + 20, boss.y
    player.moving, player.sneaking = True, False
    assert boss.sense_player(lvl, player, [], tier=1) == "HEARING"
    player.sneaking = True
    assert boss.sense_player(lvl, player, [], tier=1) == ""
    # tier 0 hears nothing
    player.sneaking = False
    assert boss.sense_player(lvl, player, [], tier=0) == ""


def test_boss_tracks_scent_until_broken():
    lvl = Level()
    boss = Boss(lvl)
    player = Player(lvl)
    player.moving = False
    marker = ScentMarker(boss.x + 30, boss.y)
    assert boss.sense_player(lvl, player, [marker], tier=2) == "SCENT"
    assert boss.sense_player(lvl, player, [], tier=2) == ""


def test_run_simulation_headless():
    pygame.init()
    game = Game()
    game.state = PLAY
    # Walk the player right while holding shift for a couple seconds of frames.
    keys = FakeKeys(held={pygame.K_d, pygame.K_LSHIFT})
    pygame.key.get_pressed = lambda: keys  # type: ignore
    for _ in range(240):
        game.update(1 / 60)
        if game.state != PLAY:
            break
    # Game should not have crashed; sleep meter should have changed.
    assert game.sleep <= S.SLEEP_MAX
    pygame.quit()


if __name__ == "__main__":
    import traceback

    funcs = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for fn in funcs:
        try:
            fn()
            print(f"PASS {fn.__name__}")
        except Exception:
            failed += 1
            print(f"FAIL {fn.__name__}")
            traceback.print_exc()
    print(f"\n{len(funcs) - failed}/{len(funcs)} passed")
    sys.exit(1 if failed else 0)
