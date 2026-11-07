uniform int sepia_region_count = 0;
uniform vec2 sepia_points[512];
uniform ivec4 sepia_counts = ivec4(0);
uniform ivec4 sepia_inversions = ivec4(0);
uniform float sepia_feather = 0.12;

// Only the post-process uses these for depthless pixels. Surface concealment remains depth-based.
uniform vec4 sepia_plane_heights = vec4(0.0);
uniform vec4 sepia_background_bounds[4];

float sepia_polygon_distance(vec2 point, int offset, int count) {
	bool inside = false;
	float closest = 100000.0;
	for (int i = 0; i < 128; i++) {
		if (i >= count) { break; }
		vec2 a = sepia_points[offset + i];
		vec2 b = sepia_points[offset + ((i + 1) % count)];
		vec2 edge = b - a;
		float ratio = clamp(dot(point - a, edge) / max(dot(edge, edge), 0.000001), 0.0, 1.0);
		closest = min(closest, length(point - (a + edge * ratio)));
		if ((a.y > point.y) != (b.y > point.y)) {
			if (point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x) { inside = !inside; }
		}
	}
	return inside ? closest : -closest;
}

float sepia_distance(vec2 point) {
	float union_distance = -100000.0;
	int offset = 0;
	for (int region = 0; region < 4; region++) {
		if (region >= sepia_region_count) { break; }
		int count = sepia_counts[region];
		if (count >= 3) {
			float distance = sepia_polygon_distance(point, offset, count);
			if (sepia_inversions[region] != 0) { distance = -distance; }
			union_distance = max(union_distance, distance);
		}
		offset += count;
	}
	return union_distance;
}

float sepia_mask(vec3 position_world) {
	return smoothstep(-sepia_feather, 0.0, sepia_distance(position_world.xz));
}

float sepia_background_mask(vec3 ray_origin, vec3 ray_direction) {
	float union_distance = -100000.0;
	int offset = 0;
	for (int region = 0; region < 4; region++) {
		if (region >= sepia_region_count) { break; }
		int count = sepia_counts[region];
		if (count >= 3) {
			float distance = -100000.0;
			if (abs(ray_direction.y) > 0.000001) {
				float travel = (sepia_plane_heights[region] - ray_origin.y) / ray_direction.y;
				if (travel >= 0.0) {
					vec2 point = (ray_origin + ray_direction * travel).xz;
					vec4 bounds = sepia_background_bounds[region];
					// Most void pixels are far from a footprint. Reject them cheaply before the polygon loop.
					float gap = max(max(bounds.x - point.x, point.x - bounds.z), max(bounds.y - point.y, point.y - bounds.w));
					distance = gap >= sepia_feather ? -gap : sepia_polygon_distance(point, offset, count);
				}
			}
			if (sepia_inversions[region] != 0) { distance = -distance; }
			union_distance = max(union_distance, distance);
		}
		offset += count;
	}
	return smoothstep(-sepia_feather, 0.0, union_distance);
}
