import { TRANSPARENT_COLOR, WALL_COLOR } from "../colors.ts";
import type { MapCanvas } from "../map_canvas.ts";
import type { MapOperation, OperationContext } from "../operation.ts";

interface Point {
  readonly x: number;
  readonly y: number;
}

export class SurroundWithCavesOperation implements MapOperation {
  readonly name = "surround-with-caves";

  apply(map: MapCanvas, context: OperationContext): void {
    if (map.width < 10 || map.height < 10) {
      this.paint_outer_transparent(map);
      return;
    }

    const route = this.create_protected_route(map, context);
    const route_radius = Math.max(
      2,
      Math.floor(Math.min(map.width, map.height) * 0.08),
    );
    let inside_mask = this.create_empty_mask(map);

    this.add_route_circles(inside_mask, map, route, route_radius, context);
    this.add_side_circles(inside_mask, map, route, route_radius, context);
    this.rough_edges(inside_mask, map, route, route_radius, context);
    this.protect_route(inside_mask, map, route, route_radius);
    inside_mask = this.keep_route_connected_component(inside_mask, map, route);
    this.apply_mask(map, inside_mask);
    this.trace_walls(map, inside_mask);
    this.connect_wall_corners(map);
    this.paint_outer_transparent(map);
  }

  private create_empty_mask(map: MapCanvas): boolean[] {
    return new Array(map.width * map.height).fill(false);
  }

  private create_protected_route(
    map: MapCanvas,
    context: OperationContext,
  ): Point[] {
    const route: Point[] = [];
    let y = Math.floor(map.height / 2) + context.random.integer(-2, 2);

    for (let x = 2; x < map.width - 2; x += 1) {
      if (x > 2 && context.random.next() < 0.35) {
        y += context.random.integer(-1, 1);
      }

      y = Math.max(2, Math.min(map.height - 3, y));
      route.push({ x, y });
    }

    return route;
  }

  private add_route_circles(
    inside_mask: boolean[],
    map: MapCanvas,
    route: readonly Point[],
    route_radius: number,
    context: OperationContext,
  ): void {
    const step = Math.max(2, route_radius);

    for (let index = 0; index < route.length; index += step) {
      const point = route[index];
      this.add_circle(
        inside_mask,
        map,
        point.x,
        point.y,
        context.random.integer(route_radius, route_radius + 2),
      );
    }

    const last_point = route[route.length - 1];
    this.add_circle(inside_mask, map, last_point.x, last_point.y, route_radius);
  }

  private add_side_circles(
    inside_mask: boolean[],
    map: MapCanvas,
    route: readonly Point[],
    route_radius: number,
    context: OperationContext,
  ): void {
    const circle_count = Math.max(
      6,
      Math.floor((map.width * map.height) / 220),
    );

    for (let index = 0; index < circle_count; index += 1) {
      const route_point = context.random.item(route);
      const radius = context.random.integer(
        Math.max(3, route_radius - 1),
        Math.max(4, route_radius + 4),
      );
      const x = Math.max(
        2,
        Math.min(
          map.width - 3,
          route_point.x + context.random.integer(-radius * 2, radius * 2),
        ),
      );
      const y = Math.max(
        2,
        Math.min(
          map.height - 3,
          route_point.y + context.random.integer(-radius * 3, radius * 3),
        ),
      );

      this.add_circle(inside_mask, map, x, y, radius);
    }
  }

  private rough_edges(
    inside_mask: boolean[],
    map: MapCanvas,
    route: readonly Point[],
    route_radius: number,
    context: OperationContext,
  ): void {
    const rough_mask = [...inside_mask];

    for (let y = 1; y < map.height - 1; y += 1) {
      for (let x = 1; x < map.width - 1; x += 1) {
        const index = this.mask_index(map, x, y);
        const neighbor_count = this.count_inside_neighbors(
          inside_mask,
          map,
          x,
          y,
        );

        if (
          inside_mask[index] &&
          neighbor_count <= 5 &&
          !this.is_route_protected(route, route_radius, x, y) &&
          context.random.next() < 0.38
        ) {
          rough_mask[index] = false;
          continue;
        }

        if (
          !inside_mask[index] && neighbor_count >= 5 &&
          context.random.next() < 0.22
        ) {
          rough_mask[index] = true;
        }
      }
    }

    for (let index = 0; index < rough_mask.length; index += 1) {
      inside_mask[index] = rough_mask[index];
    }
  }

  private protect_route(
    inside_mask: boolean[],
    map: MapCanvas,
    route: readonly Point[],
    route_radius: number,
  ): void {
    for (const point of route) {
      this.add_circle(inside_mask, map, point.x, point.y, route_radius);
    }
  }

  private keep_route_connected_component(
    inside_mask: readonly boolean[],
    map: MapCanvas,
    route: readonly Point[],
  ): boolean[] {
    const connected_mask = this.create_empty_mask(map);
    const start = route[Math.floor(route.length / 2)];
    const queue: Point[] = [start];
    connected_mask[this.mask_index(map, start.x, start.y)] = true;

    for (let index = 0; index < queue.length; index += 1) {
      const point = queue[index];

      for (const neighbor of this.orthogonal_neighbors(point)) {
        if (!map.is_inside(neighbor.x, neighbor.y)) {
          continue;
        }

        const neighbor_index = this.mask_index(map, neighbor.x, neighbor.y);

        if (!inside_mask[neighbor_index] || connected_mask[neighbor_index]) {
          continue;
        }

        connected_mask[neighbor_index] = true;
        queue.push(neighbor);
      }
    }

    return connected_mask;
  }

  private apply_mask(map: MapCanvas, inside_mask: readonly boolean[]): void {
    for (let y = 0; y < map.height; y += 1) {
      for (let x = 0; x < map.width; x += 1) {
        if (!inside_mask[this.mask_index(map, x, y)]) {
          map.set_pixel(x, y, TRANSPARENT_COLOR);
        }
      }
    }
  }

  private trace_walls(map: MapCanvas, inside_mask: readonly boolean[]): void {
    for (let y = 0; y < map.height; y += 1) {
      for (let x = 0; x < map.width; x += 1) {
        if (
          inside_mask[this.mask_index(map, x, y)] &&
          this.is_next_to_outside(inside_mask, map, x, y)
        ) {
          map.set_pixel(x, y, WALL_COLOR);
        }
      }
    }
  }

  private add_circle(
    inside_mask: boolean[],
    map: MapCanvas,
    center_x: number,
    center_y: number,
    radius: number,
  ): void {
    const radius_squared = radius * radius;

    for (let y = center_y - radius; y <= center_y + radius; y += 1) {
      for (let x = center_x - radius; x <= center_x + radius; x += 1) {
        if (!map.is_inside(x, y)) {
          continue;
        }

        const distance_x = x - center_x;
        const distance_y = y - center_y;

        if (
          (distance_x * distance_x) + (distance_y * distance_y) <=
            radius_squared
        ) {
          inside_mask[this.mask_index(map, x, y)] = true;
        }
      }
    }
  }

  private is_route_protected(
    route: readonly Point[],
    route_radius: number,
    x: number,
    y: number,
  ): boolean {
    const route_point = route[Math.max(0, Math.min(route.length - 1, x - 2))];
    const distance_x = x - route_point.x;
    const distance_y = y - route_point.y;
    const protected_radius = Math.max(2, Math.floor(route_radius * 0.65));
    return (distance_x * distance_x) + (distance_y * distance_y) <=
      protected_radius * protected_radius;
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

    return inside_mask[this.mask_index(map, x, y)];
  }

  private count_inside_neighbors(
    inside_mask: readonly boolean[],
    map: MapCanvas,
    x: number,
    y: number,
  ): number {
    let count = 0;

    for (let offset_y = -1; offset_y <= 1; offset_y += 1) {
      for (let offset_x = -1; offset_x <= 1; offset_x += 1) {
        if (offset_x === 0 && offset_y === 0) {
          continue;
        }

        if (this.is_inside_mask(inside_mask, map, x + offset_x, y + offset_y)) {
          count += 1;
        }
      }
    }

    return count;
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

  private orthogonal_neighbors(point: Point): Point[] {
    return [
      { x: point.x - 1, y: point.y },
      { x: point.x + 1, y: point.y },
      { x: point.x, y: point.y - 1 },
      { x: point.x, y: point.y + 1 },
    ];
  }

  private is_wall(map: MapCanvas, x: number, y: number): boolean {
    const pixel = map.get_pixel(x, y);
    return pixel.red === WALL_COLOR.red && pixel.green === WALL_COLOR.green &&
      pixel.blue === WALL_COLOR.blue && pixel.alpha === WALL_COLOR.alpha;
  }

  private is_transparent(map: MapCanvas, x: number, y: number): boolean {
    return map.get_pixel(x, y).alpha === 0;
  }

  private mask_index(map: MapCanvas, x: number, y: number): number {
    return (y * map.width) + x;
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
