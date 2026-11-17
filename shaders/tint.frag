#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
	mat4 qt_Matrix;
	float qt_Opacity;
	vec4 tint;
	float shadow;
	float contrast;
};
layout(binding = 1) uniform sampler2D source;

// Recolour an icon: keep its shading (luminance) but paint it in `tint`.
void main() {
	vec4 c = texture(source, qt_TexCoord0);
	vec3 rgb = c.a > 0.0 ? c.rgb / c.a : vec3(0.0);
	float l = dot(rgb, vec3(0.299, 0.587, 0.114));
	l = clamp((l - 0.08) * contrast, 0.0, 1.0);
	vec3 col = tint.rgb * (shadow + (1.13 - shadow) * l);
	col = mix(col, vec3(1.0), smoothstep(0.88, 1.0, l) * 0.25);
	fragColor = vec4(col * c.a, c.a) * qt_Opacity;
}
