export class SeededRandom {
  private state: number;

  constructor(seed: string | number = Date.now()) {
    this.state = typeof seed === "number" ? seed >>> 0 : hash_seed(seed);

    if (this.state === 0) {
      this.state = 0x6d2b79f5;
    }
  }

  next(): number {
    this.state = (this.state + 0x6d2b79f5) >>> 0;
    let value = this.state;
    value = Math.imul(value ^ (value >>> 15), value | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  }

  integer(minimum: number, maximum: number): number {
    if (maximum < minimum) {
      throw new Error("Random integer maximum must be at least the minimum.");
    }

    return Math.floor(this.next() * (maximum - minimum + 1)) + minimum;
  }

  item<T>(items: readonly T[]): T {
    if (items.length === 0) {
      throw new Error("Cannot choose from an empty array.");
    }

    return items[this.integer(0, items.length - 1)];
  }
}

function hash_seed(seed: string): number {
  let hash = 2166136261;
  for (let index = 0; index < seed.length; index += 1) {
    hash ^= seed.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }

  return hash >>> 0;
}
