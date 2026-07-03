#!/usr/bin/env -S deno run --allow-write --allow-run=ffmpeg

import { type PixelColor } from "./colors.ts";
import { generate_map } from "./main.ts";
import { MapCanvas } from "./map_canvas.ts";
import { MazeOperation } from "./operations/maze.ts";
import { MazeCorridorWidthOperation } from "./operations/maze_corridor_width.ts";
import { PaintOutOperation } from "./operations/paint_out.ts";
import { RoomsOperation } from "./operations/rooms.ts";
import { RoomsCountOperation } from "./operations/rooms_count.ts";
import { SeedOperation } from "./operations/seed.ts";
import { SurroundWithCavesOperation } from "./operations/surround_with_caves.ts";
import { encode_png } from "./png_encoder.ts";
import { SeededRandom } from "./random.ts";

const MINIMUM_SIZE = 16;
const MAXIMUM_SIZE = 256;
const SIZE_STEP = 16;
const VARIATIONS_PER_SIZE = 8;
const FRAME_SIZE = 256;
const DEFAULT_FRAMERATE = 8;
const TRANSPARENT_DISPLAY_COLOR: PixelColor = {
  red: 128,
  green: 128,
  blue: 128,
  alpha: 255,
};

interface ScriptOptions {
  readonly output_path: string;
  readonly framerate: number;
  readonly seed: string;
  readonly keep_frames: boolean;
  readonly dry_run: boolean;
}

interface FrameSpec {
  readonly size: number;
  readonly variation: number;
  readonly seed: string;
}

export function level_sizes(): number[] {
  const sizes: number[] = [];

  for (let size = MINIMUM_SIZE; size <= MAXIMUM_SIZE; size += SIZE_STEP) {
    sizes.push(size);
  }

  return sizes;
}

export function frame_specs(seed: string): FrameSpec[] {
  const specs: FrameSpec[] = [];

  for (const size of level_sizes()) {
    for (let variation = 0; variation < VARIATIONS_PER_SIZE; variation += 1) {
      specs.push({
        size,
        variation,
        seed: `${seed}-${size}-${variation}`,
      });
    }
  }

  return specs;
}

export function render_frame_for_video(
  source: MapCanvas,
  frame_size: number = FRAME_SIZE,
): MapCanvas {
  const frame = new MapCanvas(
    frame_size,
    frame_size,
    TRANSPARENT_DISPLAY_COLOR,
  );

  for (let y = 0; y < frame.height; y += 1) {
    for (let x = 0; x < frame.width; x += 1) {
      const source_x = Math.min(
        source.width - 1,
        Math.floor((x * source.width) / frame.width),
      );
      const source_y = Math.min(
        source.height - 1,
        Math.floor((y * source.height) / frame.height),
      );
      const source_pixel = source.get_pixel(source_x, source_y);

      if (source_pixel.alpha === 0) {
        frame.set_pixel(x, y, TRANSPARENT_DISPLAY_COLOR);
        continue;
      }

      frame.set_pixel(x, y, {
        red: source_pixel.red,
        green: source_pixel.green,
        blue: source_pixel.blue,
        alpha: 255,
      });
    }
  }

  return frame;
}

async function main(args: readonly string[]): Promise<void> {
  const options = parse_options(args);
  const frame_directory = await Deno.makeTempDir({
    prefix: "random-maze-frames-",
  });

  try {
    await write_frames(frame_directory, options.seed);

    if (options.dry_run) {
      console.log(`Wrote frames to ${frame_directory}`);
      return;
    }

    await run_ffmpeg(frame_directory, options);

    if (options.keep_frames) {
      console.log(`Kept frames in ${frame_directory}`);
    }
  } finally {
    if (!options.keep_frames && !options.dry_run) {
      await Deno.remove(frame_directory, { recursive: true });
    }
  }
}

async function write_frames(
  frame_directory: string,
  seed: string,
): Promise<void> {
  const random = new SeededRandom(seed);
  let frame_index = 1;

  for (const spec of frame_specs(seed)) {
    const map = generate_random_level(spec, random);
    const frame = render_frame_for_video(map);
    const frame_path = `${frame_directory}/frame_${
      String(frame_index).padStart(4, "0")
    }.png`;
    await Deno.writeFile(frame_path, encode_png(frame));
    frame_index += 1;
  }
}

function generate_random_level(
  spec: FrameSpec,
  random: SeededRandom,
): MapCanvas {
  const corridor_width = spec.size < 48 ? 1 : random.integer(1, 3);
  const rooms_count = Math.max(
    1,
    Math.floor(spec.size / 32) + random.integer(0, 2),
  );
  const paint_out_count = Math.floor(
    spec.size * spec.size * random.next() * 0.018,
  );

  return generate_map(spec.size, spec.size, [
    new SeedOperation(spec.seed),
    new MazeCorridorWidthOperation(corridor_width),
    new MazeOperation(),
    new RoomsCountOperation(rooms_count),
    new RoomsOperation(),
    new PaintOutOperation(paint_out_count),
    new SurroundWithCavesOperation(),
  ]);
}

async function run_ffmpeg(
  frame_directory: string,
  options: ScriptOptions,
): Promise<void> {
  const command = new Deno.Command("ffmpeg", {
    args: [
      "-y",
      "-framerate",
      String(options.framerate),
      "-i",
      `${frame_directory}/frame_%04d.png`,
      "-vf",
      `scale=${FRAME_SIZE}:${FRAME_SIZE}:flags=neighbor`,
      "-pix_fmt",
      "yuv420p",
      options.output_path,
    ],
  });
  const output = await command.output();

  if (!output.success) {
    const stderr = new TextDecoder().decode(output.stderr);
    throw new Error(`ffmpeg failed:\n${stderr}`);
  }
}

function parse_options(args: readonly string[]): ScriptOptions {
  let output_path = "random-maze.mp4";
  let framerate = DEFAULT_FRAMERATE;
  let seed: string = crypto.randomUUID();
  let keep_frames = false;
  let dry_run = false;

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];

    if (arg === "--help" || arg === "-h") {
      console.log(help_text());
      Deno.exit(0);
    }

    if (arg === "--output") {
      index += 1;
      output_path = read_option_value(args, index, "--output");
      continue;
    }

    if (arg.startsWith("--output=")) {
      output_path = arg.slice("--output=".length);
      continue;
    }

    if (arg === "--framerate") {
      index += 1;
      framerate = parse_positive_integer(
        read_option_value(args, index, "--framerate"),
        "--framerate",
      );
      continue;
    }

    if (arg.startsWith("--framerate=")) {
      framerate = parse_positive_integer(
        arg.slice("--framerate=".length),
        "--framerate",
      );
      continue;
    }

    if (arg === "--seed") {
      index += 1;
      seed = read_option_value(args, index, "--seed");
      continue;
    }

    if (arg.startsWith("--seed=")) {
      seed = arg.slice("--seed=".length);
      continue;
    }

    if (arg === "--keep-frames") {
      keep_frames = true;
      continue;
    }

    if (arg === "--dry-run") {
      dry_run = true;
      continue;
    }

    throw new Error(`Unknown argument: ${arg}\n${help_text()}`);
  }

  if (output_path.length === 0) {
    throw new Error("--output requires a path.");
  }

  if (seed.length === 0) {
    throw new Error("--seed requires a non-empty value.");
  }

  return {
    output_path,
    framerate,
    seed,
    keep_frames,
    dry_run,
  };
}

function parse_positive_integer(value: string, option_name: string): number {
  const parsed = Number(value);

  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error(`${option_name} requires a positive integer.`);
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

function help_text(): string {
  return [
    "Usage: random-maze.ts [options]",
    "",
    "Generates 8 random maze variations for every size from 16x16 to 256x256,",
    "renders transparent pixels as mid gray, and combines the frames with ffmpeg.",
    "",
    "Options:",
    "  --output <path>       Video path. Defaults to random-maze.mp4.",
    "  --framerate <fps>     Video framerate. Defaults to 8.",
    "  --seed <seed>         Deterministic seed. Defaults to a random UUID.",
    "  --keep-frames         Keep the generated PNG frame directory.",
    "  --dry-run             Write frames but skip ffmpeg.",
    "  --help, -h            Show this help.",
    "",
    "Example:",
    "  ./random-maze.ts --seed demo --output random-maze.mp4",
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
