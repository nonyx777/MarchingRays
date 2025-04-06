shader_type spatial;

uniform vec3 sphere_position = vec3(0.0, 0.0, -2);
uniform vec3 box_position = vec3(0.0, 0.0, -2);
const float sphere_radius = 0.2;
const vec2 torus_radi = vec2(0.2, 0.08);
const float eps = 0.001;
const vec3 color1 = vec3(0.0, 0.0, 5.0);
const vec3 color2 = vec3(5.0, 0.0, 0.0);
const vec3 light_position = vec3(-10, 10, -3);
const float ambient_strength = 0.1;
const vec3 light_color = vec3(1.0, 1.0, 1.0);
const float shininess = 32.0;
uniform float smoothness: hint_range(0.0, 1.0) = 0.5;
//uniform float sphere_ypos: hint_range(-1.0, 1.0) = 0.0;

//Primitive Combination Functions
float opSmoothUnion(float d1, float d2, float k, out float blend_factor){
	float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
	blend_factor = h;
	return mix(d2, d1, h) - k*h*(1.0 - h);
}

float sphereSDF(vec3 p, float s, vec2 t){
	return length(p) - s;
}
float boxSDF(vec3 p, float s, vec2 t){
	vec3 q = abs(p) - s;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}
float torusSDF(vec3 p, float s, vec2 t){
	vec2 q = vec2(length(p.xz) - t.x, p.y);
	return length(q) - t.y;
}

vec3 shade(vec3 point, vec3 camera_position, vec3 normal, vec3 light_direction){
	vec3 ambient = ambient_strength * light_color;
	vec3 diffuse = max(dot(normal, light_direction), 0.0) * light_color;
	vec3 view = normalize(camera_position - point);
	vec3 half_way = normalize(view + light_direction);
	float spec = pow(max(dot(normal, half_way), 0.0), shininess);
	vec3 specular = spec * light_color;
	return ambient + diffuse + specular;
}

#define rayMarchUnion(sdf1, sdf2, sdf3, shader, eps, light_position, position1, position2, oscY, ray_origin, ray_direction, s_radius, t_radii, prim_color1, prim_color2, depth, point, dist, outputColor)\
{\
	depth = 0.0;\
	point = vec3(0.0, 0.0, 0.0);\
	dist = 0.0;\
	float dist1 = 0.0;\
	float dist2 = 0.0;\
	for(int i = 0; i < 100; i++){\
		dist1 = sdf1((ray_origin + depth * ray_direction) - position1, s_radius, t_radii);\
		dist2 = sdf2((ray_origin + depth * ray_direction) - (position2 + vec3(0.0, oscY, 0.0)), s_radius, t_radii);\
		dist = sdf3(dist1, dist2, smoothness, blend_factor);\
		if(dist <= eps){\
			point = ray_origin + depth * ray_direction;\
			vec3 normal = normalize(vec3(\
				sdf3(\
					sdf1(vec3(point.x + eps, point.y, point.z) - position1, s_radius, t_radii),\
					sdf2(vec3(point.x + eps, point.y, point.z) - (position2 + vec3(0.0, oscY, 0.0)), s_radius, t_radii),\
					smoothness,\
					dummy\
				) -\
				sdf3(\
					sdf1(vec3(point.x - eps, point.y, point.z) - position1, s_radius, t_radii),\
					sdf2(vec3(point.x - eps, point.y, point.z) - (position2 + vec3(0.0, oscY, 0.0)), s_radius, t_radii),\
					smoothness,\
					dummy\
				),\
				sdf3(\
					sdf1(vec3(point.x, point.y + eps, point.z) - position1, s_radius, t_radii),\
					sdf2(vec3(point.x, point.y + eps, point.z) - (position2 + vec3(0.0, oscY, 0.0)), s_radius, t_radii),\
					smoothness,\
					dummy\
				) -\
				sdf3(\
					sdf1(vec3(point.x, point.y - eps, point.z) - position1, s_radius, t_radii),\
					sdf2(vec3(point.x, point.y - eps, point.z) - (position2 + vec3(0.0, oscY, 0.0)), s_radius, t_radii),\
					smoothness,\
					dummy\
				),\
				sdf3(\
					sdf1(vec3(point.x, point.y, point.z + eps) - position1, s_radius, t_radii),\
					sdf2(vec3(point.x, point.y, point.z + eps) - (position2 + vec3(0.0, oscY, 0.0)), s_radius, t_radii),\
					smoothness,\
					dummy\
				) -\
				sdf3(\
					sdf1(vec3(point.x, point.y, point.z - eps) - position1, s_radius, t_radii),\
					sdf2(vec3(point.x, point.y, point.z - eps) - (position2 + vec3(0.0, oscY, 0.0)), s_radius, t_radii),\
					smoothness,\
					dummy\
				)\
			));\
			vec3 color = mix(prim_color1, prim_color2, blend_factor);\
			outputColor = shader(point, ray_origin, normal, normalize(light_position - point)) * color;\
			break;\
		}\
		if (dist >= 100.0){\
			discard;\
			break;\
		}\
		depth += dist;\
	}\
}\

#define rayMarch(sdf, shader, eps, light_position, position, ray_origin, ray_direction, s_radius, t_radii, prim_color, depth, point, dist, outputColor)\
{\
	depth = 0.0;\
	point = vec3(0.0, 0.0, 0.0);\
	dist = 0.0;\
	for(int i = 0; i < 100; i++){\
		dist = sdf((ray_origin + depth * ray_direction) - position, s_radius, t_radii);\
		if(dist <= eps){\
			point = ray_origin + depth * ray_direction;\
			vec3 normal = normalize(vec3(\
				sdf(vec3(point.x + eps, point.y, point.z) - position, s_radius, t_radii) - sdf(vec3(point.x - eps, point.y, point.z) - position, s_radius, t_radii),\
				sdf(vec3(point.x, point.y + eps, point.z) - position, s_radius, t_radii) - sdf(vec3(point.x, point.y - eps, point.z) - position, s_radius, t_radii),\
				sdf(vec3(point.x, point.y, point.z + eps) - position, s_radius, t_radii) - sdf(vec3(point.x, point.y, point.z - eps) - position, s_radius, t_radii)\
			));\
			outputColor = shader(point, ray_origin, normal, normalize(light_position - point)) * prim_color;\
			break;\
		}\
		if (dist >= 100.0){\
			outputColor = vec3(0.0);\
			break;\
		}\
		depth += dist;\
	}\
}\

void fragment() {
	float yawAngle = radians(1.0);
	vec3 col1 = vec3(cos(yawAngle), 0.0, sin(yawAngle));
	vec3 col2 = vec3(0.0, 1.0, 0.0);
	vec3 col3 = vec3(-sin(yawAngle), 0.0, cos(yawAngle));
	mat3 rotation = mat3(col1, col2, col3);
	float aspectRatio = 16.0 / 16.0;
	float fov = 45.0;
	float fovRad = radians(fov);
	vec2 uv = UV * 2.0 - 1.0;
	uv.x *= aspectRatio;
	float fovScale = 1.0 / tan(fovRad / 2.0);
	uv.x /= fovScale;
	uv.y /= fovScale;
	vec3 ray_origin = vec3(-2.0, 2.0, 0.5);
	vec3 forward = normalize(sphere_position - ray_origin);
	vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
	vec3 up = normalize(cross(forward, right));
	vec3 ray_direction = normalize(vec3(forward + uv.x * right + uv.y * up));
	float oscY = sin(TIME);
	float blend_factor = 0.0;
	float dummy = 0.0;

	vec3 final_color = vec3(0.0);
	float depth = 0.0;
	vec3 point = vec3(0.0, 0.0, 0.0);
	float dist = 0.0;
	//rayMarch(sphereSDF, shade, eps, light_position, sphere_position, ray_origin, ray_direction, sphere_radius, torus_radi, color2, depth, point, dist, final_color);
	rayMarchUnion(boxSDF, sphereSDF, opSmoothUnion, shade, eps, light_position, box_position, sphere_position, oscY, ray_origin, ray_direction, sphere_radius, torus_radi, color2, color1, depth, point, dist, final_color);
	ALBEDO = final_color;
}