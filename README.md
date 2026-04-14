# cab87

Prototype "crazy cab" style game built in Godot 4.6.

- High-speed arcade cab handling with a slidy feel
- Third-person chase camera pulled further back than classic Crazy Taxi
- Simple procedural city generator that lays out driveable roads and colorful blocky buildings

## Controls

- **Accelerate:** W / Up Arrow
- **Brake / Reverse:** S / Down Arrow
- **Steer:** A / D or Left / Right Arrows
- **Handbrake / Drift:** Space
- **Reset Car:** R (snap back to origin)

## Project layout

- `project.godot` – Godot 4 project config
- `scenes/main.tscn` – entry scene (city + player car + light)
- `scenes/player_car.tscn` – car body, collision, and chase camera rig
- `scripts/player_car.gd` – arcade cab controller with basic sliding
- `scripts/city_generator.gd` – lightweight procedural city block generator

Open the project in Godot 4.6, run the **Main** scene, and start weaving through traffic-sized streets.
