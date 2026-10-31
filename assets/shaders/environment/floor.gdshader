shader_type spatial;

uniform vec4 color_a : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform vec4 color_b : source_color = vec4(0.12, 0.12, 0.12, 1.0);
uniform float tile_size = 7.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = floor(world_pos.xz / tile_size);
	float checker = mod(p.x + p.y, 2.0);
	ALBEDO = mix(color_a.rgb, color_b.rgb, checker);
}