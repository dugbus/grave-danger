import { TRANSPARENT_COLOR, WALL_COLOR } from "../colors.ts";
import type { MapCanvas } from "../map_canvas.ts";
import type { MapOperation, OperationContext } from "../operation.ts";

export class SurroundWithCavernOperation implements MapOperation {
  readonly name = "surround-with-cavern";

  apply(map: MapCanvas, context: OperationContext): void {
    if (map.width < 8 || map.height < 8) {
      this.paint_outer_transparent(map);
      return;
    }

    const minimum_margin = Math.max(
      1,
      Math.floor(Math.min(map.width, map.height) * 0.06),
    );
    const maximum_margin = Math.max(
      minimum_margin,
      Math.floor(Math.min(map.width, map.height) * 0.18),
    );
    const left_margin = this.create_margin_profile(
      map.height,
      minimum_margin,
      maximum_margin,
      context,
    );
    const right_margin = this.create_margin_profile(
      map.height,
      minimum_margin,
      maximum_margin,
      context,
    );
    const top_margin = this.create_margin_profile(
      map.width,
      minimum_margin,
      maximum_margin,
      context,
    );
    const bottom_margin = this.create_margin_profile(
      map.width,
      minimum_margin,
      maximum_margin,
      context,
    );

    const inside_mask = this.create_inside_mask(
      map,
      left_margin,
      right_margin,
      top_margin,
      bottom_margin,
    );

    for (let y = 0; y < map.height; y += 1) {
      for (let x = 0; x < map.width; x += 1) {
        if (!this.is_inside_mask(inside_mask, map, x, y)) {
          map.set_pixel(x, y, TRANSPARENT_COLOR);
        }
      }
    }

    for (let y = 0; y < map.height; y += 1) {
      for (let x = 0; x < map.width; x += 1) {
        if (
          this.is_inside_mask(inside_mask, map, x, y) &&
          this.is_next_to_outside(inside_mask, map, x, y)
        ) {
          map.set_pixel(x, y, WALL_COLOR);
        }
      }
    }

    this.connect_wall_corners(map);
  }

  private create_margin_profile(
    length: number,
    minimum_margin: number,
    maximum_margin: number,
    context: OperationContext,
  ): number[] {
    const profile: number[] = [];
    let margin = context.random.integer(minimum_margin, maximum_margin);

    for (let index = 0; index < length; index += 1) {
      if (index > 0 && context.random.next() < 0.55) {
        margin += context.random.integer(-1, 1);
      }

      margin = Math.max(minimum_margin, Math.min(maximum_margin, margin));
      profile.push(margin);
    }

    if (new Set(profile).size === 1 && maximum_margin > minimum_margin) {
      const middle_index = Math.floor(length / 2);
      profile[middle_index] = Math.min(
        maximum_margin,
        profile[middle_index] + 1,
      );
    }

    return profile;
  }

  private create_inside_mask(
    map: MapCanvas,
    left_margin: readonly number[],
    right_margin: readonly number[],
    top_margin: readonly number[],
    bottom_margin: readonly number[],
  ): boolean[] {
    const inside_mask: boolean[] = [];

    for (let y = 0; y < map.height; y += 1) {
      for (let x = 0; x < map.width; x += 1) {
        inside_mask.push(
          x > left_margin[y] &&
            x < map.width - 1 - right_margin[y] &&
            y > top_margin[x] &&
            y < map.height - 1 - bottom_margin[x],
        );
      }
    }

    return inside_mask;
  }

  private is_next_to_outside(
    inside_mask: readonly boolean[],
    map: MapCanvas,
    x: number,
    y: number,
  ): boolean {
    return !this.is_inside_mask(inside_mask, map, x - 1, y) ||
      !this.is_inside_mask(inside_mask, map, x + 1, y) ||
      !this.is_inside_mask(inside_mask, map, x, y - 1) ||
      !this.is_inside_mask(inside_mask, map, x, y + 1);
  }

  private is_inside_mask(
    inside_mask: readonly boolean[],
    map: MapCanvas,
    x: number,
    y: number,
  ): boolean {
    if (!map.is_inside(x, y)) {
      return false;
    }

    return inside_mask[(y * map.width) + x];
  }

  private connect_wall_corners(map: MapCanvas): void {
    for (let y = 0; y < map.height - 1; y += 1) {
      for (let x = 0; x < map.width - 1; x += 1) {
        const top_left_wall = this.is_wall(map, x, y);
        const top_right_wall = this.is_wall(map, x + 1, y);
        const bottom_left_wall = this.is_wall(map, x, y + 1);
        const bottom_right_wall = this.is_wall(map, x + 1, y + 1);

        if (
          top_left_wall && bottom_right_wall && !top_right_wall &&
          !bottom_left_wall
        ) {
          this.connect_corner(map, x + 1, y, x, y + 1);
          continue;
        }

        if (
          top_right_wall && bottom_left_wall && !top_left_wall &&
          !bottom_right_wall
        ) {
          this.connect_corner(map, x, y, x + 1, y + 1);
        }
      }
    }
  }

  private connect_corner(
    map: MapCanvas,
    first_x: number,
    first_y: number,
    second_x: number,
    second_y: number,
  ): void {
    if (this.is_transparent(map, first_x, first_y)) {
      map.set_pixel(first_x, first_y, WALL_COLOR);
      return;
    }

    if (this.is_transparent(map, second_x, second_y)) {
      map.set_pixel(second_x, second_y, WALL_COLOR);
    }
  }

  private is_wall(map: MapCanvas, x: number, y: number): boolean {
    const pixel = map.get_pixel(x, y);
    return pixel.red === WALL_COLOR.red && pixel.green === WALL_COLOR.green &&
      pixel.blue === WALL_COLOR.blue && pixel.alpha === WALL_COLOR.alpha;
  }

  private is_transparent(map: MapCanvas, x: number, y: number): boolean {
    return map.get_pixel(x, y).alpha === 0;
  }

  private paint_outer_transparent(map: MapCanvas): void {
    for (let x = 0; x < map.width; x += 1) {
      map.set_pixel(x, 0, TRANSPARENT_COLOR);
      map.set_pixel(x, map.height - 1, TRANSPARENT_COLOR);
    }

    for (let y = 0; y < map.height; y += 1) {
      map.set_pixel(0, y, TRANSPARENT_COLOR);
      map.set_pixel(map.width - 1, y, TRANSPARENT_COLOR);
    }
  }
}
