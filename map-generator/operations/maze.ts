import { FLOOR_COLOR, WALL_COLOR } from "../colors.ts";
import type { MapCanvas } from "../map_canvas.ts";
import type { MapOperation, OperationContext } from "../operation.ts";

interface Direction {
  readonly dx: number;
  readonly dy: number;
}

const DIRECTIONS: readonly Direction[] = [
  { dx: 2, dy: 0 },
  { dx: -2, dy: 0 },
  { dx: 0, dy: 2 },
  { dx: 0, dy: -2 },
];

export class MazeOperation implements MapOperation {
  readonly name = "maze";

  apply(map: MapCanvas, context: OperationContext): void {
    map.fill(WALL_COLOR);

    if (map.width < 3 || map.height < 3) {
      return;
    }

    const start_x =
      context.random.integer(0, Math.floor((map.width - 2) / 2)) * 2 + 1;
    const start_y =
      context.random.integer(0, Math.floor((map.height - 2) / 2)) * 2 + 1;
    const stack: Array<{ x: number; y: number }> = [{ x: start_x, y: start_y }];
    map.set_pixel(start_x, start_y, FLOOR_COLOR);

    while (stack.length > 0) {
      const current = stack[stack.length - 1];
      const directions = this.shuffled_directions(context);
      let carved = false;

      for (const direction of directions) {
        const next_x = current.x + direction.dx;
        const next_y = current.y + direction.dy;

        if (!this.can_carve(map, next_x, next_y)) {
          continue;
        }

        map.set_pixel(
          current.x + (direction.dx / 2),
          current.y + (direction.dy / 2),
          FLOOR_COLOR,
        );
        map.set_pixel(next_x, next_y, FLOOR_COLOR);
        stack.push({ x: next_x, y: next_y });
        carved = true;
        break;
      }

      if (!carved) {
        stack.pop();
      }
    }
  }

  private can_carve(map: MapCanvas, x: number, y: number): boolean {
    if (x <= 0 || x >= map.width - 1 || y <= 0 || y >= map.height - 1) {
      return false;
    }

    const pixel = map.get_pixel(x, y);
    return pixel.red === WALL_COLOR.red && pixel.green === WALL_COLOR.green &&
      pixel.blue === WALL_COLOR.blue;
  }

  private shuffled_directions(context: OperationContext): Direction[] {
    const directions = [...DIRECTIONS];
    for (let index = directions.length - 1; index > 0; index -= 1) {
      const swap_index = context.random.integer(0, index);
      const current = directions[index];
      directions[index] = directions[swap_index];
      directions[swap_index] = current;
    }

    return directions;
  }
}
