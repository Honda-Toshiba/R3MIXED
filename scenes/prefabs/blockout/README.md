# Blockout kit

Script-free StaticBody3D scenes with matching visual and collision geometry, unit scale, and material color #0079a7. Mesh and shape resources are local to each instance.

| Piece | Dimensions (X × Y × Z) |
| --- | --- |
| Floor | 8 × 1 × 8 |
| Wall | 8 × 8 × 1 |
| Block | 8 × 8 × 8 |
| Pillar | 2 × 8 × 2 |
| Platform | 8 × 1 × 16; top at Y=8 |
| Slope | 8 wide, 8 rise, 16 run |

Floor origins are at the top surface; walls, blocks and pillars use base-center origins. Platforms use a ground datum origin, with the slab centered at Y=7.5. Slopes use footprint-center origins and rise toward local −Z from LowEdge (0,0,8) to HighEdge (0,8,−8).

In example.tscn, floor at (0,0,12), slope at (0,0,0), and platform at (0,0,−16) join flush. Use 8-unit snapping for full modules and 1-unit snapping for smaller adjustments. Rotate sections in 90-degree increments.

Enable Editable Children to adjust an instance. Edit mesh and shape dimensions together, maintaining their offsets; leave node scale at (1,1,1). Custom slopes also require matching convex collision points and edge markers.

The official layout is res://scenes/game-scenes/level.tscn. The temporary size-test kit and layout have been retired.
