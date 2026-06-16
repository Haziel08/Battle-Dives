shader_type canvas_item;

uniform float intensidad : hint_range(0.0, 1.0) = 0.7;
uniform float velocidad : hint_range(0.1, 5.0) = 1.0;
uniform vec4 tinte_agua : source_color = vec4(0.15, 0.25, 0.2, 1.0);

// Función de ruido simple
float ruido(vec2 uv) {
	return fract(sin(dot(uv, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido_suave(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	f = f * f * (3.0 - 2.0 * f);
	float a = ruido(i);
	float b = ruido(i + vec2(1.0, 0.0));
	float c = ruido(i + vec2(0.0, 1.0));
	float d = ruido(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * velocidad;

	// --- Distorsión de empañado (ondas lentas y suaves) ---
	float onda1 = sin(uv.x * 8.0 + t * 0.6) * cos(uv.y * 6.0 + t * 0.4);
	float onda2 = cos(uv.x * 12.0 - t * 0.5) * sin(uv.y * 10.0 + t * 0.7);
	vec2 distorsion = vec2(onda1, onda2) * 0.018 * intensidad;

	// --- Ruido orgánico (sedimento en suspensión) ---
	float sedimento = ruido_suave(uv * 6.0 + vec2(t * 0.3, t * 0.2));
	sedimento += ruido_suave(uv * 12.0 - vec2(t * 0.2, t * 0.4)) * 0.5;
	sedimento = sedimento / 1.5;

	// --- Viñeta (bordes más oscuros, como el agua real) ---
	vec2 centro = uv - 0.5;
	float vineta = 1.0 - dot(centro, centro) * 2.5;
	vineta = clamp(vineta, 0.0, 1.0);

	// --- Burbujas/partículas flotando (puntos de luz) ---
	vec2 uv_burbuja = uv * vec2(8.0, 4.0) + vec2(0.0, -t * 0.15);
	float burbuja = ruido(floor(uv_burbuja));
	float burbuja_forma = length(fract(uv_burbuja) - 0.5);
	float particula = step(0.45, burbuja) * step(burbuja_forma, 0.06) * 0.4;

	// --- Color final ---
	// Tinte café-verdoso-azul (agua turbia de cenote)
	vec4 color_agua = vec4(
		tinte_agua.r + sedimento * 0.12,   // café del sedimento
		tinte_agua.g + sedimento * 0.08,   // verde del agua
		tinte_agua.b + (1.0 - sedimento) * 0.1,  // azul del agua limpia
		1.0
	);

	// Mezcla todo
	float alpha_base = intensidad * 0.72;
	float alpha_vineta = alpha_base * (0.6 + (1.0 - vineta) * 0.4);

	COLOR = color_agua;
	COLOR.rgb += vec3(particula);           // partículas claras flotando
	COLOR.rgb *= (0.7 + sedimento * 0.3);  // variación de luminosidad
	COLOR.a = alpha_vineta + sedimento * intensidad * 0.15;
}