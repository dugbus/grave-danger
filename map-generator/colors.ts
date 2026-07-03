export interface PixelColor {
  readonly red: number;
  readonly green: number;
  readonly blue: number;
  readonly alpha: number;
}

/** Pixel color used for impassable wall tiles. */
export const WALL_COLOR: PixelColor = {
  red: 0,
  green: 0,
  blue: 0,
  alpha: 255,
};

/** Pixel color used for walkable floor tiles. */
export const FLOOR_COLOR: PixelColor = {
  red: 255,
  green: 255,
  blue: 255,
  alpha: 255,
};

/** Pixel color used to mark where doors should be placed. */
export const DOOR_COLOR: PixelColor = {
  red: 0,
  green: 0,
  blue: 255,
  alpha: 255,
};

/** Pixel color used outside organic cavern bounds. */
export const TRANSPARENT_COLOR: PixelColor = {
  red: 0,
  green: 0,
  blue: 0,
  alpha: 0,
};
