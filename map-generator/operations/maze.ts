import { FLOOR_COLOR, WALL_COLOR } from "../colors.ts";
import type { MapCanvas } from "../map_canvas.ts";
import type { MapOperation, OperationContext } from "../operation.ts";

interface Direction {
  readonly dx: number;
  readonly dy: number;
}

const DIRECTIONS: readonly Direction[] = [
  { dx: 1, dy: 0 },
  { dx: -1, dy: 0 },
  { dx: 0, dy: 1 },
  { dx: 0, dy: -1 },
];

export class MazeOperation implements MapOperation {
  readonly name = "maze";

  apply(map: MapCanvas, context: OperationContext): void {
    map.fill(WALL_COLOR);

    const corridor_width = context.maze_corridor_width;
    const grid_width = this.grid_size(map.width, corridor_width);
    const grid_height = this.grid_size(map.height, corridor_width);

    if (grid_width < 1 || grid_height < 1) {
      return;
    }

    const start_x = context.random.integer(0, grid_width - 1);
    const start_y = context.random.integer(0, grid_height - 1);
    const visited_cells = new Set<string>();
    const stack: Array<{ x: number; y: number }> = [{ x: start_x, y: start_y }];
    visited_cells.add(this.cell_key(start_x, start_y));
    this.carve_cell(map, start_x, start_y, corridor_width);

    while (stack.length > 0) {
      const current = stack[stack.length - 1];
      const directions = this.shuffled_directions(context);
      let carved = false;

      for (const direction of directions) {
        const next_x = current.x + direction.dx;
        const next_y = current.y + direction.dy;

        if (
          !this.can_carve(
            next_x,
            next_y,
            grid_width,
            grid_height,
            visited_cells,
          )
        ) {
          continue;
        }

        this.carve_connection(map, current, direction, corridor_width);
        this.carve_cell(map, next_x, next_y, corridor_width);
        visited_cells.add(this.cell_key(next_x, next_y));
        stack.push({ x: next_x, y: next_y });
        carved = true;
        break;
      }

      if (!carved) {
        stack.pop();
      }
    }

    this.extend_trailing_corridors(
      map,
      corridor_width,
      grid_width,
      grid_height,
    );
  }

  private grid_size(pixel_size: number, corridor_width: number): number {
    return Math.max(
      0,
      Math.floor((pixel_size - corridor_width - 2) / (corridor_width + 1)) + 1,
    );
  }

  private can_carve(
    x: number,
    y: number,
    grid_width: number,
    grid_height: number,
    visited_cells: ReadonlySet<string>,
  ): boolean {
    if (x < 0 || x >= grid_width || y < 0 || y >= grid_height) {
      return false;
    }

    return !visited_cells.has(this.cell_key(x, y));
  }

  private carve_cell(
    map: MapCanvas,
    cell_x: number,
    cell_y: number,
    corridor_width: number,
  ): void {
    this.carve_rectangle(
      map,
      this.cell_pixel(cell_x, corridor_width),
      this.cell_pixel(cell_y, corridor_width),
      corridor_width,
      corridor_width,
    );
  }

  private carve_connection(
    map: MapCanvas,
    cell: { x: number; y: number },
    direction: Direction,
    corridor_width: number,
  ): void {
    const cell_x = this.cell_pixel(cell.x, corridor_width);
    const cell_y = this.cell_pixel(cell.y, corridor_width);

    if (direction.dx > 0) {
      this.carve_rectangle(
        map,
        cell_x + corridor_width,
        cell_y,
        1,
        corridor_width,
      );
      return;
    }

    if (direction.dx < 0) {
      this.carve_rectangle(map, cell_x - 1, cell_y, 1, corridor_width);
      return;
    }

    if (direction.dy > 0) {
      this.carve_rectangle(
        map,
        cell_x,
        cell_y + corridor_width,
        corridor_width,
        1,
      );
      return;
    }

    this.carve_rectangle(map, cell_x, cell_y - 1, corridor_width, 1);
  }

  private carve_rectangle(
    map: MapCanvas,
    x: number,
    y: number,
    width: number,
    height: number,
  ): void {
    for (let offset_y = 0; offset_y < height; offset_y += 1) {
      for (let offset_x = 0; offset_x < width; offset_x += 1) {
        map.set_pixel(x + offset_x, y + offset_y, FLOOR_COLOR);
      }
    }
  }

  private cell_pixel(cell_index: number, corridor_width: number): number {
    return 1 + (cell_index * (corridor_width + 1));
  }

  private extend_trailing_corridors(
    map: MapCanvas,
    corridor_width: number,
    grid_width: number,
    grid_height: number,
  ): void {
    const used_width = this.cell_pixel(grid_width - 1, corridor_width) +
      corridor_width;
    const used_height = this.cell_pixel(grid_height - 1, corridor_width) +
      corridor_width;

    for (let x = used_width; x < map.width - 1; x += 1) {
      for (let y = 1; y < map.height - 1; y += 1) {
        if (this.is_floor(map, x - 1, y)) {
          map.set_pixel(x, y, FLOOR_COLOR);
        }
      }
    }

    for (let y = used_height; y < map.height - 1; y += 1) {
      for (let x = 1; x < map.width - 1; x += 1) {
        if (this.is_floor(map, x, y - 1)) {
          map.set_pixel(x, y, FLOOR_COLOR);
        }
      }
    }
  }

  private is_floor(map: MapCanvas, x: number, y: number): boolean {
    const pixel = map.get_pixel(x, y);
    return pixel.red === FLOOR_COLOR.red && pixel.green === FLOOR_COLOR.green &&
      pixel.blue === FLOOR_COLOR.blue;
  }

  private cell_key(x: number, y: number): string {
    return `${x},${y}`;
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
