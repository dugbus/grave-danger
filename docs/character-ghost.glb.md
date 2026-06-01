
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
| #   | name            | rootName        | bboxMin                     | bboxMax                   | renderVertexCount¹ | uploadVertexCount | uploadNaiveVertexCount |
| --- | ---             | ---             | ---                         | ---                       | ---                | ---               | ---                    |
| 0   | character-ghost | character-ghost | -0.39403, 0.11004, -0.24411 | 0.39403, 0.77219, 0.24411 | 1,239              | 593               | 593                    |

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
| 0   | torso     | TRIANGLES | 1              | 261          | 497      | u16     | NORMAL:f32, POSITION:f32, TANGENT:f32, TEXCOORD_0:f32 | 1         | 25.42 KB |
| 1   | arm-right | TRIANGLES | 1              | 76           | 48       | u8      | NORMAL:f32, POSITION:f32, TANGENT:f32, TEXCOORD_0:f32 | 1         | 2.53 KB  |
| 2   | arm-left  | TRIANGLES | 1              | 76           | 48       | u8      | NORMAL:f32, POSITION:f32, TANGENT:f32, TEXCOORD_0:f32 | 1         | 2.53 KB  |

⁴ size estimates GPU memory required by a mesh, in isolation. If accessors are
  shared by other mesh primitives, but the meshes themselves are not reused, then
  the sum of all mesh sizes will overestimate the asset's total size. See "dedup".



 MATERIALS
 ────────────────────────────────────────────
| #   | name     | instances | textures         | alphaMode | doubleSided |
| --- | ---      | ---       | ---              | ---       | ---         |
| 0   | colormap | 3         | baseColorTexture | OPAQUE    | ✓           |



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
| 0   | static                  | 12       | 12       | 0        | 24        | 416 Bytes |
| 1   | idle                    | 3        | 3        | 1        | 120       | 2.4 KB    |
| 2   | walk                    | 4        | 4        | 1        | 80        | 1.52 KB   |
| 3   | sprint                  | 4        | 4        | 1        | 60        | 1.14 KB   |
| 4   | jump                    | 2        | 2        | 1        | 30        | 600 Bytes |
| 5   | fall                    | 2        | 2        | 0        | 20        | 400 Bytes |
| 6   | crouch                  | 4        | 4        | 0        | 8         | 152 Bytes |
| 7   | sit                     | 3        | 3        | 0        | 6         | 112 Bytes |
| 8   | drive                   | 3        | 3        | 0        | 6         | 112 Bytes |
| 9   | die                     | 5        | 5        | 0        | 49        | 940 Bytes |
| 10  | pick-up                 | 3        | 3        | 0        | 30        | 600 Bytes |
| 11  | emote-yes               | 3        | 3        | 1        | 60        | 1.2 KB    |
| 12  | emote-no                | 3        | 3        | 1        | 60        | 1.2 KB    |
| 13  | holding-right           | 2        | 2        | 0        | 4         | 80 Bytes  |
| 14  | holding-left            | 2        | 2        | 0        | 4         | 80 Bytes  |
| 15  | holding-both            | 2        | 2        | 0        | 4         | 80 Bytes  |
| 16  | holding-right-shoot     | 3        | 3        | 0        | 14        | 280 Bytes |
| 17  | holding-left-shoot      | 3        | 3        | 0        | 14        | 280 Bytes |
| 18  | holding-both-shoot      | 3        | 3        | 0        | 18        | 360 Bytes |
| 19  | attack-melee-right      | 4        | 4        | 0        | 52        | 988 Bytes |
| 20  | attack-melee-left       | 4        | 4        | 0        | 52        | 988 Bytes |
| 21  | attack-kick-right       | 4        | 4        | 1        | 64        | 1.22 KB   |
| 22  | attack-kick-left        | 4        | 4        | 1        | 64        | 1.22 KB   |
| 23  | interact-right          | 3        | 3        | 1        | 42        | 840 Bytes |
| 24  | interact-left           | 3        | 3        | 1        | 42        | 840 Bytes |
| 25  | wheelchair-sit          | 3        | 3        | 0        | 6         | 112 Bytes |
| 26  | wheelchair-look-left    | 4        | 4        | 0        | 16        | 312 Bytes |
| 27  | wheelchair-look-right   | 4        | 4        | 0        | 16        | 312 Bytes |
| 28  | wheelchair-move-forward | 4        | 4        | 1        | 47        | 932 Bytes |
| 29  | wheelchair-move-back    | 4        | 4        | 1        | 47        | 932 Bytes |
| 30  | wheelchair-move-left    | 4        | 4        | 1        | 34        | 672 Bytes |
| 31  | wheelchair-move-right   | 4        | 4        | 1        | 34        | 672 Bytes |


