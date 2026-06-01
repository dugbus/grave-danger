
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
| #   | name      | rootName  | bboxMin                | bboxMax                 | renderVertexCount¹ | uploadVertexCount | uploadNaiveVertexCount |
| --- | ---       | ---       | ---                    | ---                     | ---                | ---               | ---                    |
| 0   | pine-fall | pine-fall | -0.589, -0.1, -0.66728 | 0.589, 2.20246, 0.66728 | 1,008              | 668               | 668                    |

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
| 0   | pine-fall | TRIANGLES | 1              | 336          | 668      | u16     | NORMAL:f32, POSITION:f32, TANGENT:f32, TEXCOORD_0:f32 | 1         | 34.08 KB |

⁴ size estimates GPU memory required by a mesh, in isolation. If accessors are
  shared by other mesh primitives, but the meshes themselves are not reused, then
  the sum of all mesh sizes will overestimate the asset's total size. See "dedup".



 MATERIALS
 ────────────────────────────────────────────
| #   | name     | instances | textures         | alphaMode | doubleSided |
| --- | ---      | ---       | ---              | ---       | ---         |
| 0   | colormap | 1         | baseColorTexture | OPAQUE    | ✓           |



 TEXTURES
 ────────────────────────────────────────────
| #   | name     | uri                   | slots            | instances | mimeType  | compression | resolution | size     | gpuSize⁵ |
| --- | ---      | ---                   | ---              | ---       | ---       | ---         | ---        | ---      | ---      |
| 0   | colormap | Textures/colormap.png | baseColorTexture | 1         | image/png |             | 512x512    | 10.96 KB | 1.4 MB   |

⁵ gpuSize estimates minimum VRAM memory allocation. Older devices may require
  additional memory for GPU compression formats.



 ANIMATIONS
 ────────────────────────────────────────────
No animations found.

