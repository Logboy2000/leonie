shader_type canvas_item;

uniform float distortion_strength : hint_range(0.0, 10.0) = 0.0;
uniform float chroma_strength : hint_range(0.0, 10.0) = 0.0;

// Simple hash-based noise (cheap + random)
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) +
		   (c - a) * u.y * (1.0 - u.x) +
		   (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = UV;

	// Time-based drifting noise
	float t = TIME * 0.5;
	vec2 noise_uv = uv * 6.0 + vec2(t, t * 1.3);

	float n = noise(noise_uv);
	float n2 = noise(noise_uv + 10.0);

	// Random distortion offset
	vec2 distortion = vec2(
		n - 0.5,
		n2 - 0.5
	) * 0.03 * distortion_strength;

	// Chromatic aberration offsets
	vec2 chroma_offset = distortion * 0.5 * chroma_strength;

	float r = texture(TEXTURE, uv + distortion + chroma_offset).r;
	float g = texture(TEXTURE, uv + distortion).g;
	float b = texture(TEXTURE, uv + distortion - chroma_offset).b;

	COLOR = vec4(r, g, b, 1.0);
}
