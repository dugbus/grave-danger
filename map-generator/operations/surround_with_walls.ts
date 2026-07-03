import { WALL_COLOR } from "../colors.ts";
import type { MapCanvas } from "../map_canvas.ts";
import type { MapOperation, OperationContext } from "../operation.ts";

export class SurroundWithWallsOperation implements MapOperation {
  readonly name = "surround-with-walls";

  apply(map: MapCanvas, _context: OperationContext): void {
    for (let x = 0; x < map.width; x += 1) {
      map.set_pixel(x, 0, WALL_COLOR);
      map.set_pixel(x, map.height - 1, WALL_COLOR);
    }

    for (let y = 0; y < map.height; y += 1) {
      map.set_pixel(0, y, WALL_COLOR);
      map.set_pixel(map.width - 1, y, WALL_COLOR);
    }
  }
}
