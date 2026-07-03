import { type PixelColor, WALL_COLOR } from "./colors.ts";

export class MapCanvas {
  readonly width: number;
  readonly height: number;
  private readonly pixels: Uint8Array;

  constructor(
    width: number,
    height: number,
    fill_color: PixelColor = WALL_COLOR,
  ) {
    if (!Number.isInteger(width) || width <= 0) {
      throw new Error("Width must be a positive integer.");
    }
    if (!Number.isInteger(height) || height <= 0) {
      throw new Error("Height must be a positive integer.");
    }

    this.width = width;
    this.height = height;
    this.pixels = new Uint8Array(width * height * 4);
    this.fill(fill_color);
  }

  fill(color: PixelColor): void {
    for (let y = 0; y < this.height; y += 1) {
      for (let x = 0; x < this.width; x += 1) {
        this.set_pixel(x, y, color);
      }
    }
  }

  set_pixel(x: number, y: number, color: PixelColor): void {
    if (!this.is_inside(x, y)) {
      return;
    }

    const index = this.pixel_index(x, y);
    this.pixels[index] = color.red;
    this.pixels[index + 1] = color.green;
    this.pixels[index + 2] = color.blue;
    this.pixels[index + 3] = color.alpha;
  }

  get_pixel(x: number, y: number): PixelColor {
    if (!this.is_inside(x, y)) {
      throw new Error(`Pixel ${x},${y} is outside the map.`);
    }

    const index = this.pixel_index(x, y);
    return {
      red: this.pixels[index],
      green: this.pixels[index + 1],
      blue: this.pixels[index + 2],
      alpha: this.pixels[index + 3],
    };
  }

  is_inside(x: number, y: number): boolean {
    return x >= 0 && x < this.width && y >= 0 && y < this.height;
  }

  to_rgba_bytes(): Uint8Array {
    return new Uint8Array(this.pixels);
  }

  private pixel_index(x: number, y: number): number {
    return ((y * this.width) + x) * 4;
  }
}
