import { assertEquals, assertNotEquals } from "@std/assert";
import { DOOR_COLOR, FLOOR_COLOR, WALL_COLOR } from "./colors.ts";
import { generate_map, parse_cli } from "./main.ts";
import { MazeOperation } from "./operations/maze.ts";
import { RoomsOperation } from "./operations/rooms.ts";
import { SeedOperation } from "./operations/seed.ts";
import { SurroundWithWallsOperation } from "./operations/surround_with_walls.ts";
import { encode_png } from "./png_encoder.ts";

Deno.test("parse_cli preserves operation order", () => {
  const parsed = parse_cli([
    "17",
    "15",
    "--maze",
    "--seed",
    "abc",
    "--surround-with-walls",
    "--output",
    "map.png",
  ]);

  assertEquals(parsed.width, 17);
  assertEquals(parsed.height, 15);
  assertEquals(parsed.operations.map((operation) => operation.name), [
    "maze",
    "seed",
    "surround-with-walls",
  ]);
  assertEquals(parsed.output_path, "map.png");
});

Deno.test("seed makes generated maps deterministic", () => {
  const first = generate_map(17, 15, [
    new SeedOperation("same"),
    new MazeOperation(),
  ]);
  const second = generate_map(17, 15, [
    new SeedOperation("same"),
    new MazeOperation(),
  ]);

  assertEquals(first.to_rgba_bytes(), second.to_rgba_bytes());
});

Deno.test("different seeds can produce different maps", () => {
  const first = generate_map(17, 15, [
    new SeedOperation("first"),
    new MazeOperation(),
  ]);
  const second = generate_map(17, 15, [
    new SeedOperation("second"),
    new MazeOperation(),
  ]);

  assertNotEquals(first.to_rgba_bytes(), second.to_rgba_bytes());
});

Deno.test("surround_with_walls paints the outside edge black", () => {
  const map = generate_map(6, 5, [new SurroundWithWallsOperation()]);

  for (let x = 0; x < map.width; x += 1) {
    assertEquals(map.get_pixel(x, 0), WALL_COLOR);
    assertEquals(map.get_pixel(x, map.height - 1), WALL_COLOR);
  }

  for (let y = 0; y < map.height; y += 1) {
    assertEquals(map.get_pixel(0, y), WALL_COLOR);
    assertEquals(map.get_pixel(map.width - 1, y), WALL_COLOR);
  }
});

Deno.test("maze creates floors and walls", () => {
  const map = generate_map(9, 9, [
    new SeedOperation("maze"),
    new MazeOperation(),
  ]);
  let floor_count = 0;
  let wall_count = 0;

  for (let y = 0; y < map.height; y += 1) {
    for (let x = 0; x < map.width; x += 1) {
      const pixel = map.get_pixel(x, y);

      if (pixel.red === FLOOR_COLOR.red) {
        floor_count += 1;
      }

      if (pixel.red === WALL_COLOR.red) {
        wall_count += 1;
      }
    }
  }

  assertEquals(floor_count > 0, true);
  assertEquals(wall_count > 0, true);
});

Deno.test("rooms place blue door markers", () => {
  const map = generate_map(24, 20, [
    new SeedOperation("rooms"),
    new RoomsOperation(),
  ]);
  let door_count = 0;

  for (let y = 0; y < map.height; y += 1) {
    for (let x = 0; x < map.width; x += 1) {
      const pixel = map.get_pixel(x, y);

      if (
        pixel.red === DOOR_COLOR.red && pixel.green === DOOR_COLOR.green &&
        pixel.blue === DOOR_COLOR.blue
      ) {
        door_count += 1;
      }
    }
  }

  assertEquals(door_count > 0, true);
});

Deno.test("encode_png emits a PNG signature", () => {
  const map = generate_map(3, 3, []);
  const png = encode_png(map);

  assertEquals([...png.slice(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
});
