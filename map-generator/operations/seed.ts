import type { MapCanvas } from "../map_canvas.ts";
import type { MapOperation, OperationContext } from "../operation.ts";
import { SeededRandom } from "../random.ts";

export class SeedOperation implements MapOperation {
  readonly name = "seed";
  private readonly seed: string;

  constructor(seed: string) {
    if (seed.length === 0) {
      throw new Error("--seed requires a non-empty value.");
    }

    this.seed = seed;
  }

  apply(_map: MapCanvas, context: OperationContext): void {
    context.set_random(new SeededRandom(this.seed));
  }
}
