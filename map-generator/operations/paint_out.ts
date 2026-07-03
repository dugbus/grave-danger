import { FLOOR_COLOR, WALL_COLOR } from "../colors.ts";
import type { MapCanvas } from "../map_canvas.ts";
import type { MapOperation, OperationContext } from "../operation.ts";

export class PaintOutOperation implements MapOperation {
  readonly name = "paint-out";
  private readonly pixel_count: number;

  constructor(pixel_count: number) {
    if (!Number.isInteger(pixel_count) || pixel_count < 0) {
      throw new Error("--paint-out requires a non-negative integer.");
    }

    this.pixel_count = pixel_count;
  }

  apply(map: MapCanvas, context: OperationContext): void {
    if (map.width < 3 || map.height < 3) {
      return;
    }

    let painted_count = 0;
    let attempt_count = 0;
    const maximum_attempts = Math.max(this.pixel_count * 20, 1);

    while (
      painted_count < this.pixel_count && attempt_count < maximum_attempts
    ) {
      attempt_count += 1;
      const x = context.random.integer(1, map.width - 2);
      const y = context.random.integer(1, map.height - 2);
      const pixel = map.get_pixel(x, y);

      if (
        pixel.red !== WALL_COLOR.red || pixel.green !== WALL_COLOR.green ||
        pixel.blue !== WALL_COLOR.blue
      ) {
        continue;
      }

      map.set_pixel(x, y, FLOOR_COLOR);
      painted_count += 1;
    }
  }
}
