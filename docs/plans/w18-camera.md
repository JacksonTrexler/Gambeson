# w18-camera: gesture pan, elliptical edge-pan, windowed-edge pause

Read: edge-pan exists (`BattleCamera.edge_dir`, meadows-tails.md #2): pointer <=3 design px of an edge, corners diagonal, unit vector, constant speed `PAN`, over HUD side panels none, null pointer on `WM_MOUSE_EXIT` / app focus out. Middle-drag + arrow keys exist. No zoom exists.

## Calls
1. Edge zone = outside an ellipse inscribed in the view (r = |(p-c)/(view/2)|). Dead zone `EDGE_DEAD`=0.88 (16 px at top/bottom, 29 px at the sides). Speed ramps smoothstep from r=0.88 to r=1 and holds 1 past it (corners). Direction = the offset from centre normalised, so top-middle and top-right (any point at r>=1) move at the same speed (1.0); top-right just points diagonally. Replaces the 3 px square zone (`edge_dir` -> `edge_vec`, length 0..1).
2. Map tempering `map_gain(map_px, view)` = sqrt(longer side / view) clamped 0.75..2: a one-screen map 1x, under half a screen 0.75x, a 4-screen map 2x. Applies to edge-pan and trackpad pan; not the arrow keys (unchanged) nor touch (1:1 direct).
3. Trackpad: `InputEventPanGesture` pans the view `delta * GESTURE * gain / zoom` (wheel direction: delta.y>0 view goes down). Ignored over HUD panels / with a panel open so lists still scroll. `GESTURE` unverified on hardware: one constant, flip sign if the OS scroll feels backwards.
4. Touch: two or more fingers down, `InputEventScreenDrag` pans 1:1 (ground follows fingers; split by finger count).
5. Pinch/magnify: skipped (no zoom in the game; adding one is a feature).
6. Windowed very-edge pause: poll `DisplayServer.mouse_get_position()` against the window rect each frame (no events when the cursor leaves fast, so `WM_MOUSE_EXIT` alone leaves a stale edge position and a runaway pan). Fullscreen: inside the window rect. Windowed: also not on the outermost `WINDOW_RING`=2 screen px. Mouse-exit / focus-out notifications kept as well. Headless: skipped.
