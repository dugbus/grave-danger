import type { MapCanvas } from "./map_canvas.ts";

const PNG_SIGNATURE = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]);

export function encode_png(map: MapCanvas): Uint8Array {
  const raw_image = create_filtered_scanlines(map);
  const chunks = [
    create_chunk("IHDR", create_ihdr_data(map.width, map.height)),
    create_chunk("IDAT", create_zlib_stored_data(raw_image)),
    create_chunk("IEND", new Uint8Array()),
  ];
  return concatenate_uint8_arrays([PNG_SIGNATURE, ...chunks]);
}

function create_filtered_scanlines(map: MapCanvas): Uint8Array {
  const rgba_bytes = map.to_rgba_bytes();
  const stride = map.width * 4;
  const scanlines = new Uint8Array((stride + 1) * map.height);

  for (let y = 0; y < map.height; y += 1) {
    const scanline_offset = y * (stride + 1);
    const rgba_offset = y * stride;
    scanlines[scanline_offset] = 0;
    scanlines.set(
      rgba_bytes.subarray(rgba_offset, rgba_offset + stride),
      scanline_offset + 1,
    );
  }

  return scanlines;
}

function create_ihdr_data(width: number, height: number): Uint8Array {
  const data = new Uint8Array(13);
  const view = new DataView(data.buffer);
  view.setUint32(0, width);
  view.setUint32(4, height);
  data[8] = 8;
  data[9] = 6;
  data[10] = 0;
  data[11] = 0;
  data[12] = 0;
  return data;
}

function create_zlib_stored_data(data: Uint8Array): Uint8Array {
  const blocks: Uint8Array[] = [new Uint8Array([0x78, 0x01])];

  for (let offset = 0; offset < data.length; offset += 65535) {
    const block = data.subarray(offset, Math.min(offset + 65535, data.length));
    const is_final_block = offset + block.length >= data.length;
    const header = new Uint8Array(5);
    header[0] = is_final_block ? 0x01 : 0x00;
    header[1] = block.length & 0xff;
    header[2] = (block.length >>> 8) & 0xff;
    const inverse_length = (~block.length) & 0xffff;
    header[3] = inverse_length & 0xff;
    header[4] = (inverse_length >>> 8) & 0xff;
    blocks.push(header, block);
  }

  blocks.push(uint32_to_bytes(adler32(data)));
  return concatenate_uint8_arrays(blocks);
}

function create_chunk(type: string, data: Uint8Array): Uint8Array {
  const type_bytes = new TextEncoder().encode(type);
  const chunk = new Uint8Array(4 + type_bytes.length + data.length + 4);
  const view = new DataView(chunk.buffer);
  view.setUint32(0, data.length);
  chunk.set(type_bytes, 4);
  chunk.set(data, 8);
  view.setUint32(
    8 + data.length,
    crc32(concatenate_uint8_arrays([type_bytes, data])),
  );
  return chunk;
}

function adler32(data: Uint8Array): number {
  let a = 1;
  let b = 0;

  for (const byte of data) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }

  return ((b << 16) | a) >>> 0;
}

function crc32(data: Uint8Array): number {
  let crc = 0xffffffff;

  for (const byte of data) {
    crc ^= byte;

    for (let bit = 0; bit < 8; bit += 1) {
      const mask = -(crc & 1);
      crc = (crc >>> 1) ^ (0xedb88320 & mask);
    }
  }

  return (crc ^ 0xffffffff) >>> 0;
}

function uint32_to_bytes(value: number): Uint8Array {
  const bytes = new Uint8Array(4);
  const view = new DataView(bytes.buffer);
  view.setUint32(0, value);
  return bytes;
}

function concatenate_uint8_arrays(arrays: readonly Uint8Array[]): Uint8Array {
  const length = arrays.reduce((total, array) => total + array.length, 0);
  const combined = new Uint8Array(length);
  let offset = 0;

  for (const array of arrays) {
    combined.set(array, offset);
    offset += array.length;
  }

  return combined;
}
