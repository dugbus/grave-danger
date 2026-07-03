import type { MapCanvas } from "./map_canvas.ts";
import type { SeededRandom } from "./random.ts";

export interface OperationContext {
  maze_corridor_width: number;
  random: SeededRandom;
  rooms_count: number | null;
  set_maze_corridor_width(width: number): void;
  set_random(random: SeededRandom): void;
  set_rooms_count(count: number | null): void;
}

export interface MapOperation {
  readonly name: string;
  apply(map: MapCanvas, context: OperationContext): void;
}
