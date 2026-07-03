import type { MapCanvas } from "./map_canvas.ts";
import type { SeededRandom } from "./random.ts";

export interface OperationContext {
  random: SeededRandom;
  set_random(random: SeededRandom): void;
}

export interface MapOperation {
  readonly name: string;
  apply(map: MapCanvas, context: OperationContext): void;
}
