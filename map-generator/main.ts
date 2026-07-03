#!/usr/bin/env -S deno run --allow-write

import { MapCanvas } from "./map_canvas.ts";
import type { MapOperation, OperationContext } from "./operation.ts";
import { MazeOperation } from "./operations/maze.ts";
import { MazeCorridorWidthOperation } from "./operations/maze_corridor_width.ts";
import { PaintOutOperation } from "./operations/paint_out.ts";
import { RoomsOperation } from "./operations/rooms.ts";
import { RoomsCountOperation } from "./operations/rooms_count.ts";
import { SeedOperation } from "./operations/seed.ts";
import { SurroundWithCavernOperation } from "./operations/surround_with_cavern.ts";
import { SurroundWithCavesOperation } from "./operations/surround_with_caves.ts";
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
  maze_corridor_width: number;
  random: SeededRandom;
  rooms_count: number | null;

  constructor() {
    this.maze_corridor_width = 1;
    this.random = new SeededRandom();
    this.rooms_count = null;
  }

  set_maze_corridor_width(width: number): void {
    this.maze_corridor_width = width;
  }

  set_random(random: SeededRandom): void {
    this.random = random;
  }

  set_rooms_count(count: number | null): void {
    this.rooms_count = count;
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
    throw new Error(help_text());
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

    if (arg === "--maze-corridor-width") {
      index += 1;
      operations.push(
        new MazeCorridorWidthOperation(
          parse_positive_integer(
            read_option_value(args, index, "--maze-corridor-width"),
            "--maze-corridor-width",
          ),
        ),
      );
      continue;
    }

    if (arg.startsWith("--maze-corridor-width=")) {
      operations.push(
        new MazeCorridorWidthOperation(
          parse_positive_integer(
            arg.slice("--maze-corridor-width=".length),
            "--maze-corridor-width",
          ),
        ),
      );
      continue;
    }

    if (arg === "--maze") {
      operations.push(new MazeOperation());
      continue;
    }

    if (arg === "--rooms-count") {
      index += 1;
      operations.push(
        new RoomsCountOperation(
          parse_positive_integer(
            read_option_value(args, index, "--rooms-count"),
            "--rooms-count",
          ),
        ),
      );
      continue;
    }

    if (arg.startsWith("--rooms-count=")) {
      operations.push(
        new RoomsCountOperation(
          parse_positive_integer(
            arg.slice("--rooms-count=".length),
            "--rooms-count",
          ),
        ),
      );
      continue;
    }

    if (arg === "--surround-with-walls") {
      operations.push(new SurroundWithWallsOperation());
      continue;
    }

    if (arg === "--surround-with-cavern") {
      operations.push(new SurroundWithCavernOperation());
      continue;
    }

    if (arg === "--surround-with-caves") {
      operations.push(new SurroundWithCavesOperation());
      continue;
    }

    if (arg === "--rooms") {
      operations.push(new RoomsOperation());
      continue;
    }

    if (arg === "--paint-out") {
      index += 1;
      operations.push(
        new PaintOutOperation(
          parse_non_negative_integer(
            read_option_value(args, index, "--paint-out"),
            "--paint-out",
          ),
        ),
      );
      continue;
    }

    if (arg.startsWith("--paint-out=")) {
      operations.push(
        new PaintOutOperation(
          parse_non_negative_integer(
            arg.slice("--paint-out=".length),
            "--paint-out",
          ),
        ),
      );
      continue;
    }

    throw new Error(`Unknown argument: ${arg}\n${help_text()}`);
  }

  if (output_path.length === 0) {
    throw new Error(`Missing --output path.\n${help_text()}`);
  }

  return {
    width,
    height,
    operations,
    output_path,
  };
}

async function main(args: readonly string[]): Promise<void> {
  if (args.includes("--help") || args.includes("-h")) {
    console.log(help_text());
    return;
  }

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

function parse_positive_integer(value: string, option_name: string): number {
  const parsed = Number(value);

  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error(`${option_name} requires a positive integer.`);
  }

  return parsed;
}

function parse_non_negative_integer(
  value: string,
  option_name: string,
): number {
  const parsed = Number(value);

  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error(`${option_name} requires a non-negative integer.`);
  }

  return parsed;
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

export function help_text(): string {
  return [
    "Usage: map-generator [width] [height] [...operations] --output map.png",
    "",
    "Operations are applied in the order they appear.",
    "",
    "Options:",
    "  --help, -h                         Show this help.",
    "  --seed <seed>                      Set the random seed for later operations.",
    "  --maze-corridor-width <pixels>     Set walkable maze corridor width for later --maze operations. Walls stay 1 pixel thick.",
    "  --maze                             Fill the map with a maze. Black pixels are walls and white pixels are floor.",
    "  --rooms-count <count>              Set how many rooms later --rooms operations try to place.",
    "  --rooms                            Add random rooms. Blue pixels mark intended door positions.",
    "  --surround-with-walls              Paint the outside map edge as walls.",
    "  --surround-with-cavern             Paint an organic orthogonal cavern boundary with transparent outside pixels.",
    "  --surround-with-caves              Build a rough circle-based cave outline with a protected side-to-side route.",
    "  --paint-out <pixel-count>          Scatter white pixels through non-edge wall pixels.",
    "  --output <path>                    Write the generated PNG.",
    "",
    "Examples:",
    "  map-generator 64 64 --seed demo --maze --surround-with-walls --output map.png",
    "  map-generator 64 64 --seed cave --maze --rooms-count 5 --rooms --surround-with-cavern --output cavern.png",
    "  map-generator 96 64 --seed caves --maze --rooms-count 8 --rooms --surround-with-caves --output caves.png",
    "  map-generator 96 64 --seed demo --maze-corridor-width 2 --maze --rooms-count 8 --rooms --paint-out 50 --surround-with-walls --output map.png",
    "  map-generator 48 48 --seed demo --rooms-count 4 --rooms --surround-with-walls --output rooms.png",
  ].join("\n");
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
