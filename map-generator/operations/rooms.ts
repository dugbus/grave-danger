import { DOOR_COLOR, FLOOR_COLOR, WALL_COLOR } from "../colors.ts";
import type { MapCanvas } from "../map_canvas.ts";
import type { MapOperation, OperationContext } from "../operation.ts";

enum RoomSide {
  North,
  East,
  South,
  West,
}

interface RoomBounds {
  readonly x: number;
  readonly y: number;
  readonly width: number;
  readonly height: number;
}

export class RoomsOperation implements MapOperation {
  readonly name = "rooms";

  apply(map: MapCanvas, context: OperationContext): void {
    if (map.width < 7 || map.height < 7) {
      return;
    }

    const target_room_count = this.target_room_count(map, context);
    const rooms: RoomBounds[] = [];
    const maximum_attempts = target_room_count * 30;

    for (
      let attempt = 0;
      attempt < maximum_attempts && rooms.length < target_room_count;
      attempt += 1
    ) {
      const room = this.create_room_candidate(map, context);

      if (
        rooms.some((existing_room) => this.rooms_overlap(existing_room, room))
      ) {
        continue;
      }

      this.carve_room(map, room);
      this.clear_outer_surround(map, room);
      this.place_door(map, room, context);
      rooms.push(room);
    }
  }

  private target_room_count(map: MapCanvas, context: OperationContext): number {
    if (context.rooms_count !== null) {
      return context.rooms_count;
    }

    const area = map.width * map.height;
    return Math.max(1, Math.min(12, Math.floor(area / 180)));
  }

  private create_room_candidate(
    map: MapCanvas,
    context: OperationContext,
  ): RoomBounds {
    const maximum_width = Math.min(12, map.width - 2);
    const maximum_height = Math.min(10, map.height - 2);
    const width = context.random.integer(5, maximum_width);
    const height = context.random.integer(5, maximum_height);

    return {
      x: context.random.integer(1, map.width - width - 1),
      y: context.random.integer(1, map.height - height - 1),
      width,
      height,
    };
  }

  private rooms_overlap(first: RoomBounds, second: RoomBounds): boolean {
    return first.x - 1 < second.x + second.width &&
      first.x + first.width + 1 > second.x &&
      first.y - 1 < second.y + second.height &&
      first.y + first.height + 1 > second.y;
  }

  private carve_room(map: MapCanvas, room: RoomBounds): void {
    for (let y = room.y; y < room.y + room.height; y += 1) {
      for (let x = room.x; x < room.x + room.width; x += 1) {
        const is_wall = x === room.x || x === room.x + room.width - 1 ||
          y === room.y || y === room.y + room.height - 1;
        map.set_pixel(x, y, is_wall ? WALL_COLOR : FLOOR_COLOR);
      }
    }
  }

  private clear_outer_surround(map: MapCanvas, room: RoomBounds): void {
    const left = room.x - 1;
    const right = room.x + room.width;
    const top = room.y - 1;
    const bottom = room.y + room.height;

    for (let x = left; x <= right; x += 1) {
      this.clear_if_not_edge(map, x, top);
      this.clear_if_not_edge(map, x, bottom);
    }

    for (let y = top; y <= bottom; y += 1) {
      this.clear_if_not_edge(map, left, y);
      this.clear_if_not_edge(map, right, y);
    }
  }

  private clear_if_not_edge(map: MapCanvas, x: number, y: number): void {
    if (
      x <= 0 || x >= map.width - 1 || y <= 0 || y >= map.height - 1 ||
      !map.is_inside(x, y)
    ) {
      return;
    }

    map.set_pixel(x, y, FLOOR_COLOR);
  }

  private place_door(
    map: MapCanvas,
    room: RoomBounds,
    context: OperationContext,
  ): void {
    const side = context.random.item(
      [
        RoomSide.North,
        RoomSide.East,
        RoomSide.South,
        RoomSide.West,
      ] as const,
    );

    if (side === RoomSide.North) {
      map.set_pixel(
        context.random.integer(room.x + 1, room.x + room.width - 2),
        room.y,
        DOOR_COLOR,
      );
      return;
    }

    if (side === RoomSide.East) {
      map.set_pixel(
        room.x + room.width - 1,
        context.random.integer(room.y + 1, room.y + room.height - 2),
        DOOR_COLOR,
      );
      return;
    }

    if (side === RoomSide.South) {
      map.set_pixel(
        context.random.integer(room.x + 1, room.x + room.width - 2),
        room.y + room.height - 1,
        DOOR_COLOR,
      );
      return;
    }

    map.set_pixel(
      room.x,
      context.random.integer(room.y + 1, room.y + room.height - 2),
      DOOR_COLOR,
    );
  }
}
