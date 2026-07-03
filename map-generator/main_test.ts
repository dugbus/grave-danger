import { assertEquals, assertNotEquals } from "@std/assert";
import {
  DOOR_COLOR,
  FLOOR_COLOR,
  TRANSPARENT_COLOR,
  WALL_COLOR,
} from "./colors.ts";
import { generate_map, help_text, parse_cli } from "./main.ts";
import type { MapCanvas } from "./map_canvas.ts";
import type { MapOperation, OperationContext } from "./operation.ts";
import { MazeOperation } from "./operations/maze.ts";
import { MazeCorridorWidthOperation } from "./operations/maze_corridor_width.ts";
import { PaintOutOperation } from "./operations/paint_out.ts";
import { RoomsOperation } from "./operations/rooms.ts";
import { RoomsCountOperation } from "./operations/rooms_count.ts";
import { SeedOperation } from "./operations/seed.ts";
import { SurroundWithCavernOperation } from "./operations/surround_with_cavern.ts";
import { SurroundWithCavesOperation } from "./operations/surround_with_caves.ts";
import { SurroundWithWallsOperation } from "./operations/surround_with_walls.ts";
import { encode_png } from "./png_encoder.ts";

Deno.test("parse_cli preserves operation order", () => {
  const parsed = parse_cli([
    "17",
    "15",
    "--maze-corridor-width",
    "2",
    "--maze",
    "--seed",
    "abc",
    "--rooms-count=3",
    "--rooms",
    "--paint-out",
    "4",
    "--surround-with-caves",
    "--surround-with-cavern",
    "--surround-with-walls",
    "--output",
    "map.png",
  ]);

  assertEquals(parsed.width, 17);
  assertEquals(parsed.height, 15);
  assertEquals(parsed.operations.map((operation) => operation.name), [
    "maze-corridor-width",
    "maze",
    "seed",
    "rooms-count",
    "rooms",
    "paint-out",
    "surround-with-caves",
    "surround-with-cavern",
    "surround-with-walls",
  ]);
  assertEquals(parsed.output_path, "map.png");
});

Deno.test("help_text includes example commands", () => {
  const text = help_text();

  assertEquals(text.includes("Examples:"), true);
  assertEquals(text.includes("--maze-corridor-width 2"), true);
  assertEquals(text.includes("--rooms-count 8"), true);
  assertEquals(text.includes("--surround-with-cavern"), true);
  assertEquals(text.includes("--surround-with-caves"), true);
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

Deno.test("surround_with_walls restores edge holes when it runs later", () => {
  const map = generate_map(8, 8, [
    new EdgeHoleOperation(),
    new SurroundWithWallsOperation(),
  ]);

  assertEquals(map.get_pixel(7, 3), WALL_COLOR);
});

Deno.test("surround_with_walls does not clear the inner ring", () => {
  const map = generate_map(8, 8, [
    new InnerWallOperation(),
    new SurroundWithWallsOperation(),
  ]);

  assertEquals(map.get_pixel(1, 1), WALL_COLOR);
  assertEquals(map.get_pixel(6, 4), WALL_COLOR);
});

Deno.test("surround_with_cavern creates an organic transparent surround", () => {
  const map = generate_map(48, 36, [
    new SeedOperation("cavern"),
    new FillFloorOperation(),
    new SurroundWithCavernOperation(),
  ]);

  assert_outer_edge_is_transparent(map);
  assertEquals(count_pixels(map, FLOOR_COLOR) > 0, true);
  assertEquals(count_pixels(map, TRANSPARENT_COLOR) > 0, true);
  assertEquals(count_pixels(map, WALL_COLOR) > 0, true);
  assertEquals(has_irregular_floor_span(map), true);
});

Deno.test("surround_with_cavern traces connected wall corners", () => {
  const map = generate_map(48, 36, [
    new SeedOperation("cavern-diagonal"),
    new FillFloorOperation(),
    new SurroundWithCavernOperation(),
  ]);

  assertEquals(has_diagonal_only_wall_step(map), false);
});

Deno.test("surround_with_caves creates a rough transparent cave outline", () => {
  const map = generate_map(64, 48, [
    new SeedOperation("caves"),
    new FillFloorOperation(),
    new SurroundWithCavesOperation(),
  ]);

  assert_outer_edge_is_transparent(map);
  assertEquals(count_pixels(map, FLOOR_COLOR) > 0, true);
  assertEquals(count_pixels(map, TRANSPARENT_COLOR) > 0, true);
  assertEquals(count_pixels(map, WALL_COLOR) > 0, true);
  assertEquals(has_irregular_floor_span(map), true);
  assertEquals(has_diagonal_only_wall_step(map), false);
});

Deno.test("surround_with_caves keeps the cave shape connected left-to-right", () => {
  const map = generate_map(64, 48, [
    new SeedOperation("caves-route"),
    new MazeCorridorWidthOperation(2),
    new MazeOperation(),
    new SurroundWithCavesOperation(),
  ]);

  assertEquals(has_left_to_right_opaque_path(map), true);
});

Deno.test("surround_with_caves does not paint a white center route", () => {
  const map = generate_map(96, 64, [
    new SeedOperation("caves-no-band"),
    new SurroundWithCavesOperation(),
  ]);

  assertEquals(count_pixels(map, FLOOR_COLOR), 0);
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

Deno.test("maze corridor width paints wider walkable areas", () => {
  const map = generate_map(15, 15, [
    new SeedOperation("wide"),
    new MazeCorridorWidthOperation(2),
    new MazeOperation(),
  ]);

  assertEquals(has_floor_rectangle(map, 2, 2), true);
});

Deno.test("maze extends trailing corridors without creating a full inner gap", () => {
  const map = generate_map(32, 24, [
    new SeedOperation("double-wall"),
    new MazeCorridorWidthOperation(2),
    new MazeOperation(),
    new SurroundWithWallsOperation(),
  ]);
  let right_inner_floor_count = 0;
  let right_inner_wall_count = 0;

  for (let y = 1; y < map.height - 1; y += 1) {
    const pixel = map.get_pixel(map.width - 2, y);

    if (pixel.red === FLOOR_COLOR.red) {
      right_inner_floor_count += 1;
    }

    if (pixel.red === WALL_COLOR.red) {
      right_inner_wall_count += 1;
    }
  }

  assertEquals(right_inner_floor_count > 0, true);
  assertEquals(right_inner_wall_count > 0, true);
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

Deno.test("rooms_count controls requested room count on open maps", () => {
  const map = generate_map(48, 48, [
    new SeedOperation("room-count"),
    new RoomsCountOperation(4),
    new RoomsOperation(),
  ]);

  assertEquals(count_pixels(map, DOOR_COLOR), 4);
});

Deno.test("paint_out scatters floors through interior wall pixels", () => {
  const map = generate_map(10, 10, [
    new SeedOperation("paint"),
    new PaintOutOperation(12),
  ]);

  assertEquals(count_pixels(map, FLOOR_COLOR), 12);

  for (let x = 0; x < map.width; x += 1) {
    assertEquals(map.get_pixel(x, 0), WALL_COLOR);
    assertEquals(map.get_pixel(x, map.height - 1), WALL_COLOR);
  }

  for (let y = 0; y < map.height; y += 1) {
    assertEquals(map.get_pixel(0, y), WALL_COLOR);
    assertEquals(map.get_pixel(map.width - 1, y), WALL_COLOR);
  }
});

Deno.test("encode_png emits a PNG signature", () => {
  const map = generate_map(3, 3, []);
  const png = encode_png(map);

  assertEquals([...png.slice(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
});

function count_pixels(
  map: ReturnType<typeof generate_map>,
  color: typeof DOOR_COLOR,
): number {
  let count = 0;

  for (let y = 0; y < map.height; y += 1) {
    for (let x = 0; x < map.width; x += 1) {
      const pixel = map.get_pixel(x, y);

      if (
        pixel.red === color.red && pixel.green === color.green &&
        pixel.blue === color.blue && pixel.alpha === color.alpha
      ) {
        count += 1;
      }
    }
  }

  return count;
}

function assert_outer_edge_is_transparent(
  map: ReturnType<typeof generate_map>,
): void {
  for (let x = 0; x < map.width; x += 1) {
    assertEquals(map.get_pixel(x, 0), TRANSPARENT_COLOR);
    assertEquals(map.get_pixel(x, map.height - 1), TRANSPARENT_COLOR);
  }

  for (let y = 0; y < map.height; y += 1) {
    assertEquals(map.get_pixel(0, y), TRANSPARENT_COLOR);
    assertEquals(map.get_pixel(map.width - 1, y), TRANSPARENT_COLOR);
  }
}

function has_irregular_floor_span(
  map: ReturnType<typeof generate_map>,
): boolean {
  const left_edges = new Set<number>();
  const right_edges = new Set<number>();

  for (let y = 1; y < map.height - 1; y += 1) {
    let first_floor = -1;
    let last_floor = -1;

    for (let x = 1; x < map.width - 1; x += 1) {
      if (is_color(map, x, y, FLOOR_COLOR)) {
        if (first_floor === -1) {
          first_floor = x;
        }

        last_floor = x;
      }
    }

    if (first_floor !== -1) {
      left_edges.add(first_floor);
      right_edges.add(last_floor);
    }
  }

  return left_edges.size > 1 || right_edges.size > 1;
}

function has_diagonal_only_wall_step(
  map: ReturnType<typeof generate_map>,
): boolean {
  for (let y = 0; y < map.height - 1; y += 1) {
    for (let x = 0; x < map.width - 1; x += 1) {
      const top_left_wall = is_color(map, x, y, WALL_COLOR);
      const top_right_wall = is_color(map, x + 1, y, WALL_COLOR);
      const bottom_left_wall = is_color(map, x, y + 1, WALL_COLOR);
      const bottom_right_wall = is_color(map, x + 1, y + 1, WALL_COLOR);

      if (
        top_left_wall && bottom_right_wall && !top_right_wall &&
        !bottom_left_wall
      ) {
        return true;
      }

      if (
        top_right_wall && bottom_left_wall && !top_left_wall &&
        !bottom_right_wall
      ) {
        return true;
      }
    }
  }

  return false;
}

function is_color(
  map: ReturnType<typeof generate_map>,
  x: number,
  y: number,
  color: typeof DOOR_COLOR,
): boolean {
  const pixel = map.get_pixel(x, y);
  return pixel.red === color.red && pixel.green === color.green &&
    pixel.blue === color.blue && pixel.alpha === color.alpha;
}

function has_floor_rectangle(
  map: ReturnType<typeof generate_map>,
  width: number,
  height: number,
): boolean {
  for (let y = 0; y <= map.height - height; y += 1) {
    for (let x = 0; x <= map.width - width; x += 1) {
      if (is_floor_rectangle(map, x, y, width, height)) {
        return true;
      }
    }
  }

  return false;
}

function has_left_to_right_opaque_path(
  map: ReturnType<typeof generate_map>,
): boolean {
  const queue: Array<{ x: number; y: number }> = [];
  const visited = new Set<string>();

  for (let x = 1; x <= 2; x += 1) {
    for (let y = 1; y < map.height - 1; y += 1) {
      if (is_opaque(map, x, y)) {
        queue.push({ x, y });
        visited.add(`${x},${y}`);
      }
    }
  }

  for (let index = 0; index < queue.length; index += 1) {
    const point = queue[index];

    if (point.x >= map.width - 3) {
      return true;
    }

    for (
      const neighbor of [
        { x: point.x - 1, y: point.y },
        { x: point.x + 1, y: point.y },
        { x: point.x, y: point.y - 1 },
        { x: point.x, y: point.y + 1 },
      ]
    ) {
      const key = `${neighbor.x},${neighbor.y}`;

      if (
        visited.has(key) || !map.is_inside(neighbor.x, neighbor.y) ||
        !is_opaque(map, neighbor.x, neighbor.y)
      ) {
        continue;
      }

      visited.add(key);
      queue.push(neighbor);
    }
  }

  return false;
}

function is_opaque(
  map: ReturnType<typeof generate_map>,
  x: number,
  y: number,
): boolean {
  return map.get_pixel(x, y).alpha > 0;
}

function is_floor_rectangle(
  map: ReturnType<typeof generate_map>,
  x: number,
  y: number,
  width: number,
  height: number,
): boolean {
  for (let offset_y = 0; offset_y < height; offset_y += 1) {
    for (let offset_x = 0; offset_x < width; offset_x += 1) {
      const pixel = map.get_pixel(x + offset_x, y + offset_y);

      if (
        pixel.red !== FLOOR_COLOR.red || pixel.green !== FLOOR_COLOR.green ||
        pixel.blue !== FLOOR_COLOR.blue
      ) {
        return false;
      }
    }
  }

  return true;
}

class EdgeHoleOperation implements MapOperation {
  readonly name = "edge-hole";

  apply(map: MapCanvas, _context: OperationContext): void {
    map.set_pixel(map.width - 1, 3, FLOOR_COLOR);
  }
}

class InnerWallOperation implements MapOperation {
  readonly name = "inner-wall";

  apply(map: MapCanvas, _context: OperationContext): void {
    map.fill(FLOOR_COLOR);
    map.set_pixel(1, 1, WALL_COLOR);
    map.set_pixel(map.width - 2, 4, WALL_COLOR);
  }
}

class FillFloorOperation implements MapOperation {
  readonly name = "fill-floor";

  apply(map: MapCanvas, _context: OperationContext): void {
    map.fill(FLOOR_COLOR);
  }
}
