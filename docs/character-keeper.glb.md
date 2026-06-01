
 OVERVIEW
 ────────────────────────────────────────────
| key                | value                 |
| ---                | ---                   |
| version            | 2.0                   |
| generator          | UnityGLTF             |
| extensionsUsed     | KHR_texture_transform |
| extensionsRequired | none                  |



 SCENES
 ────────────────────────────────────────────
| #   | name             | rootName         | bboxMin                     | bboxMax                  | renderVertexCount¹ | uploadVertexCount | uploadNaiveVertexCount |
| --- | ---              | ---              | ---                         | ---                      | ---                | ---               | ---                    |
| 0   | character-keeper | character-keeper | -0.40568, 0.02203, -0.26273 | 0.40568, 0.8845, 0.27434 | 3,423              | 2,075             | 2,075                  |

¹ Expected number of vertices processed by the vertex shader for one render
  pass, without considering the vertex cache.

² Expected number of vertices uploaded to GPU, assuming each Accessor
  is uploaded only once. Actual number uploaded may be higher, 
  dependent on the implementation and vertex buffer layout.

³ Expected number of vertices uploaded to GPU, assuming each Primitive
  is uploaded once, duplicating vertex attributes shared among Primitives.



 MESHES
 ────────────────────────────────────────────
| #   | name      | mode      | meshPrimitives | glPrimitives | vertices | indices | attributes                                            | instances | size¹    |
| --- | ---       | ---       | ---            | ---          | ---      | ---     | ---                                                   | ---       | ---      |
| 0   | leg-right | TRIANGLES | 1              | 110          | 218      | u8      | NORMAL:f32, POSITION:f32, TANGENT:f32, TEXCOORD_0:f32 | 1         | 10.79 KB |
| 1   | torso     | TRIANGLES | 1              | 202          | 340      | u16     | NORMAL:f32, POSITION:f32, TANGENT:f32, TEXCOORD_0:f32 | 1         | 17.53 KB |
| 2   | head      | TRIANGLES | 1              | 447          | 787      | u16     | NORMAL:f32, POSITION:f32, TANGENT:f32, TEXCOORD_0:f32 | 1         | 40.46 KB |
| 3   | arm-right | TRIANGLES | 1              | 136          | 256      | u16     | NORMAL:f32, POSITION:f32, TANGENT:f32, TEXCOORD_0:f32 | 1         | 13.1 KB  |
| 4   | arm-left  | TRIANGLES | 1              | 136          | 256      | u16     | NORMAL:f32, POSITION:f32, TANGENT:f32, TEXCOORD_0:f32 | 1         | 13.1 KB  |
| 5   | leg-left  | TRIANGLES | 1              | 110          | 218      | u8      | NORMAL:f32, POSITION:f32, TANGENT:f32, TEXCOORD_0:f32 | 1         | 10.79 KB |

⁴ size estimates GPU memory required by a mesh, in isolation. If accessors are
  shared by other mesh primitives, but the meshes themselves are not reused, then
  the sum of all mesh sizes will overestimate the asset's total size. See "dedup".



 MATERIALS
 ────────────────────────────────────────────
| #   | name     | instances | textures         | alphaMode | doubleSided |
| --- | ---      | ---       | ---              | ---       | ---         |
| 0   | colormap | 6         | baseColorTexture | OPAQUE    | ✓           |



 TEXTURES
 ────────────────────────────────────────────
| #   | name     | uri                   | slots            | instances | mimeType  | compression | resolution | size     | gpuSize⁵ |
| --- | ---      | ---                   | ---              | ---       | ---       | ---         | ---        | ---      | ---      |
| 0   | colormap | Textures/colormap.png | baseColorTexture | 1         | image/png |             | 512x512    | 10.96 KB | 1.4 MB   |

⁵ gpuSize estimates minimum VRAM memory allocation. Older devices may require
  additional memory for GPU compression formats.



 ANIMATIONS
 ────────────────────────────────────────────
| #   | name                    | channels | samplers | duration | keyframes | size      |
| --- | ---                     | ---      | ---      | ---      | ---       | ---       |
| 0   | static                  | 21       | 21       | 0        | 42        | 728 Bytes |
| 1   | idle                    | 4        | 4        | 1        | 160       | 3.2 KB    |
| 2   | walk                    | 7        | 7        | 1        | 140       | 2.72 KB   |
| 3   | sprint                  | 7        | 7        | 1        | 105       | 2.04 KB   |
| 4   | jump                    | 7        | 7        | 1        | 79        | 1.56 KB   |
| 5   | fall                    | 5        | 5        | 0        | 50        | 1 KB      |
| 6   | crouch                  | 8        | 8        | 0        | 16        | 296 Bytes |
| 7   | sit                     | 5        | 5        | 0        | 10        | 192 Bytes |
| 8   | drive                   | 5        | 5        | 0        | 10        | 192 Bytes |
| 9   | die                     | 8        | 8        | 0        | 79        | 1.54 KB   |
| 10  | pick-up                 | 4        | 4        | 0        | 40        | 800 Bytes |
| 11  | emote-yes               | 4        | 4        | 1        | 80        | 1.6 KB    |
| 12  | emote-no                | 4        | 4        | 1        | 80        | 1.6 KB    |
| 13  | holding-right           | 2        | 2        | 0        | 4         | 80 Bytes  |
| 14  | holding-left            | 2        | 2        | 0        | 4         | 80 Bytes  |
| 15  | holding-both            | 2        | 2        | 0        | 4         | 80 Bytes  |
| 16  | holding-right-shoot     | 4        | 4        | 0        | 20        | 400 Bytes |
| 17  | holding-left-shoot      | 4        | 4        | 0        | 20        | 400 Bytes |
| 18  | holding-both-shoot      | 4        | 4        | 0        | 24        | 480 Bytes |
| 19  | attack-melee-right      | 7        | 7        | 0        | 88        | 1.71 KB   |
| 20  | attack-melee-left       | 7        | 7        | 0        | 88        | 1.71 KB   |
| 21  | attack-kick-right       | 7        | 7        | 1        | 112       | 2.18 KB   |
| 22  | attack-kick-left        | 7        | 7        | 1        | 112       | 2.18 KB   |
| 23  | interact-right          | 4        | 4        | 1        | 55        | 1.1 KB    |
| 24  | interact-left           | 4        | 4        | 1        | 55        | 1.1 KB    |
| 25  | wheelchair-sit          | 7        | 7        | 0        | 14        | 256 Bytes |
| 26  | wheelchair-look-left    | 9        | 9        | 0        | 34        | 656 Bytes |
| 27  | wheelchair-look-right   | 9        | 9        | 0        | 34        | 656 Bytes |
| 28  | wheelchair-move-forward | 9        | 9        | 1        | 70        | 1.38 KB   |
| 29  | wheelchair-move-back    | 9        | 9        | 1        | 70        | 1.38 KB   |
| 30  | wheelchair-move-left    | 9        | 9        | 1        | 57        | 1.12 KB   |
| 31  | wheelchair-move-right   | 9        | 9        | 1        | 57        | 1.12 KB   |


