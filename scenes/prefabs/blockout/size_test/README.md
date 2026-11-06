# Larger module experiment

Open `res://scenes/game-scenes/level_size_test.tscn` and press F6.

This copies the current level with 25% larger building geometry and placement distances. Meshes and collision shapes are resized together; node scales remain unchanged. Original level and kit are untouched. Player movement, jump-pad strength, enemies, lighting settings, and material colors retain their source settings; player/enemy/pad positions move with the expanded layout.

Modules: floor 5 × 0.625 × 5; wall 5 × 5 × 0.625; block 5 cubed; pillar 1.25 × 5 × 1.25; slope 5 wide, 5 rise, 10 run; platform 5 × 0.625 × 10 with top at Y=5.

Compare against the original using F6: room to slide and turn, ramp-to-block joins, wall-jump reach, and jump-pad landings. Increased vertical distances may require additional traversal effort; player abilities are deliberately unchanged for comparison. This is a one-time layout snapshot, not a linked copy of future level edits.
