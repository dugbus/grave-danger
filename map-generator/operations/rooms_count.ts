import type { MapCanvas } from "../map_canvas.ts";
import type { MapOperation, OperationContext } from "../operation.ts";

export class RoomsCountOperation implements MapOperation {
  readonly name = "rooms-count";
  private readonly count: number;

  constructor(count: number) {
    if (!Number.isInteger(count) || count < 1) {
      throw new Error("--rooms-count requires a positive integer.");
    }

    this.count = count;
  }

  apply(_map: MapCanvas, context: OperationContext): void {
    context.set_rooms_count(this.count);
  }
}
