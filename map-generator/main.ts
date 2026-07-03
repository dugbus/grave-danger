#!/usr/bin/env -S deno run --allow-write

import { MapCanvas } from "./map_canvas.ts";
import type { MapOperation, OperationContext } from "./operation.ts";
import { MazeOperation } from "./operations/maze.ts";
import { RoomsOperation } from "./operations/rooms.ts";
import { SeedOperation } from "./operations/seed.ts";
import { SurroundWithWallsOperation } from "./operations/surround_with_walls.ts";
import { encode_png } from "./png_encoder.ts";
import { SeededRandom } from "./random.ts";

interface ParsedCli {
  readonly width: number;
  readonly height: number;
  readonly operations: readonly MapOperation[];
  readonly output_path: string;
}

class GeneratorOperationContext implements OperationContext {
  random: SeededRandom;

  constructor() {
    this.random = new SeededRandom();
  }

  set_random(random: SeededRandom): void {
    this.random = random;
  }
}

export function generate_map(
  width: number,
  height: number,
  operations: readonly MapOperation[],
): MapCanvas {
  const map = new MapCanvas(width, height);
  const context = new GeneratorOperationContext();

  for (const operation of operations) {
    operation.apply(map, context);
  }

  return map;
}

export function parse_cli(args: readonly string[]): ParsedCli {
  if (args.length < 2) {
    throw new Error(usage());
  }

  const width = parse_dimension(args[0], "width");
  const height = parse_dimension(args[1], "height");
  const operations: MapOperation[] = [];
  let output_path = "";

  for (let index = 2; index < args.length; index += 1) {
    const arg = args[index];

    if (arg === "--output") {
      index += 1;
      output_path = read_option_value(args, index, "--output");
      continue;
    }

    if (arg.startsWith("--output=")) {
      output_path = arg.slice("--output=".length);
      if (output_path.length === 0) {
        throw new Error("--output requires a path.");
      }
      continue;
    }

    if (arg === "--seed") {
      index += 1;
      operations.push(
        new SeedOperation(read_option_value(args, index, "--seed")),
      );
      continue;
    }

    if (arg.startsWith("--seed=")) {
      operations.push(new SeedOperation(arg.slice("--seed=".length)));
      continue;
    }

    if (arg === "--maze") {
      operations.push(new MazeOperation());
      continue;
    }

    if (arg === "--surround-with-walls") {
      operations.push(new SurroundWithWallsOperation());
      continue;
    }

    if (arg === "--rooms") {
      operations.push(new RoomsOperation());
      continue;
    }

    throw new Error(`Unknown argument: ${arg}\n${usage()}`);
  }

  if (output_path.length === 0) {
    throw new Error(`Missing --output path.\n${usage()}`);
  }

  return {
    width,
    height,
    operations,
    output_path,
  };
}

async function main(args: readonly string[]): Promise<void> {
  const parsed = parse_cli(args);
  const map = generate_map(parsed.width, parsed.height, parsed.operations);
  await Deno.writeFile(parsed.output_path, encode_png(map));
}

function parse_dimension(value: string, name: string): number {
  const dimension = Number(value);

  if (!Number.isInteger(dimension) || dimension <= 0) {
    throw new Error(`${name} must be a positive integer.`);
  }

  return dimension;
}

function read_option_value(
  args: readonly string[],
  index: number,
  option_name: string,
): string {
  const value = args[index];

  if (value === undefined || value.length === 0 || value.startsWith("--")) {
    throw new Error(`${option_name} requires a value.`);
  }

  return value;
}

function usage(): string {
  return "Usage: map-generator [width] [height] [...operations] --output map.png";
}

if (import.meta.main) {
  try {
    await main(Deno.args);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(message);
    Deno.exit(1);
  }
}
