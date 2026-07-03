import type { MapCanvas } from "../map_canvas.ts";
import type { MapOperation, OperationContext } from "../operation.ts";

export class MazeCorridorWidthOperation implements MapOperation {
  readonly name = "maze-corridor-width";
  private readonly width: number;

  constructor(width: number) {
    if (!Number.isInteger(width) || width < 1) {
      throw new Error("--maze-corridor-width requires a positive integer.");
    }

    this.width = width;
  }

  apply(_map: MapCanvas, context: OperationContext): void {
    context.set_maze_corridor_width(this.width);
  }
}
