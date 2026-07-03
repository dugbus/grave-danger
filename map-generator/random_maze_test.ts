import { assertEquals } from "@std/assert";
import { TRANSPARENT_COLOR, WALL_COLOR } from "./colors.ts";
import { MapCanvas } from "./map_canvas.ts";
import {
  frame_specs,
  level_sizes,
  render_frame_for_video,
} from "./random-maze.ts";

Deno.test("level_sizes increment from 16 to 256", () => {
  const sizes = level_sizes();

  assertEquals(sizes[0], 16);
  assertEquals(sizes[sizes.length - 1], 256);
  assertEquals(sizes.length, 16);

  for (let index = 1; index < sizes.length; index += 1) {
    assertEquals(sizes[index] - sizes[index - 1], 16);
  }
});

Deno.test("frame_specs creates eight variations per size", () => {
  const specs = frame_specs("test");

  assertEquals(specs.length, 16 * 8);
  assertEquals(specs[0], {
    size: 16,
    variation: 0,
    seed: "test-16-0",
  });
  assertEquals(specs[specs.length - 1], {
    size: 256,
    variation: 7,
    seed: "test-256-7",
  });
});

Deno.test("render_frame_for_video draws transparent pixels as mid gray", () => {
  const source = new MapCanvas(2, 2, WALL_COLOR);
  source.set_pixel(0, 0, TRANSPARENT_COLOR);

  const frame = render_frame_for_video(source, 4);

  assertEquals(frame.get_pixel(0, 0), {
    red: 128,
    green: 128,
    blue: 128,
    alpha: 255,
  });
  assertEquals(frame.get_pixel(3, 3), WALL_COLOR);
});
