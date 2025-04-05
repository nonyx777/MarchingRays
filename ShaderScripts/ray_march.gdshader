shader_type spatial;

uniform vec3 sphere_position = vec3(0.0, 0.2, -5);
uniform vec3 box_position = vec3(0.0, -0.2, -5);
const float sphere_radius = 0.2;
const vec2 torus_radi = vec2(0.2, 0.08);
const float eps = 0.001;
const vec3 color1 = vec3(2.0, 4.0, 3.0);
const vec3 color2 = vec3(3.0, 2.0, 4.0);
const vec3 light_position = vec3(-10, 10, -3);
const float ambient_strength = 0.1;
const vec3 light_color = vec3(1.0, 1.0, 1.0);
const float shininess = 32.0;
uniform float smoothness: hint_range(0.0, 1.0) = 0.5;
uniform float sphere_ypos: hint_range(-1.0, 1.0) = 0.0;

//Primitive Combination Functions
float opSmoothUnion(float d1, float d2, float k){
	float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
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

vec3 sphere(vec3 position, vec3 ray_origin, vec3 ray_direction, float s_radius, vec2 t_radius, vec3 col){
	position += vec3(0.0, sphere_ypos, 0.0);
	float depth = 0.0;
	vec3 point = vec3(0.0, 0.0, 0.0);
	float dist = 0.0;
	for(int i = 0; i < 100; i++){
		dist = sphereSDF((ray_origin + depth * ray_direction) - position, s_radius, t_radius);//(0.2, 0.08)
		if(dist <= eps){
			point = ray_origin + depth * ray_direction;
			vec3 normal = normalize(vec3(
				sphereSDF(vec3(point.x + eps, point.y, point.z) - position, sphere_radius, t_radius) - sphereSDF(vec3(point.x - eps, point.y, point.z) - position, sphere_radius, t_radius),
				sphereSDF(vec3(point.x, point.y + eps, point.z) - position, sphere_radius, t_radius) - sphereSDF(vec3(point.x, point.y - eps, point.z) - position, sphere_radius, t_radius),
				sphereSDF(vec3(point.x, point.y, point.z + eps) - position, sphere_radius, t_radius) - sphereSDF(vec3(point.x, point.y, point.z - eps) - position, sphere_radius, t_radius)
			));
			return shade(point, ray_origin, normal, normalize(light_position - point)) * col;
		}
		depth += dist;
		if (dist >= 100.0)
			return vec3(0.0);
	}
	return vec3(0.0);
}

vec3 torus(vec3 position, vec3 ray_origin, vec3 ray_direction, float s_radius, vec2 t_radius, vec3 col){
	float depth = 0.0;
	vec3 point = vec3(0.0, 0.0, 0.0);
	float dist = 0.0;
	for(int i = 0; i < 100; i++){
		dist = torusSDF((ray_origin + depth * ray_direction) - position, s_radius, t_radius);//(0.2, 0.08)
		if(dist <= eps){
			point = ray_origin + depth * ray_direction;
			vec3 normal = normalize(vec3(
				torusSDF(vec3(point.x + eps, point.y, point.z) - position, sphere_radius, t_radius) - torusSDF(vec3(point.x - eps, point.y, point.z) - position, sphere_radius, t_radius),
				torusSDF(vec3(point.x, point.y + eps, point.z) - position, sphere_radius, t_radius) - torusSDF(vec3(point.x, point.y - eps, point.z) - position, sphere_radius, t_radius),
				torusSDF(vec3(point.x, point.y, point.z + eps) - position, sphere_radius, t_radius) - torusSDF(vec3(point.x, point.y, point.z - eps) - position, sphere_radius, t_radius)
			));
			return shade(point, ray_origin, normal, normalize(light_position - point)) * col;
		}
		depth += dist;
		if (dist >= 100.0)
			return vec3(0.0);
	}
	return vec3(0.0);
}

vec3 box(vec3 position, vec3 ray_origin, vec3 ray_direction, float s_radius, vec2 t_radius, vec3 col){
	float depth = 0.0;
	vec3 point = vec3(0.0, 0.0, 0.0);
	float dist = 0.0;
	for(int i = 0; i < 100; i++){
		dist = boxSDF((ray_origin + depth * ray_direction) - position, s_radius, t_radius);//(0.2, 0.08)
		if(dist <= eps){
			point = ray_origin + depth * ray_direction;
			vec3 normal = normalize(vec3(
				boxSDF(vec3(point.x + eps, point.y, point.z) - position, sphere_radius, t_radius) - boxSDF(vec3(point.x - eps, point.y, point.z) - position, sphere_radius, t_radius),
				boxSDF(vec3(point.x, point.y + eps, point.z) - position, sphere_radius, t_radius) - boxSDF(vec3(point.x, point.y - eps, point.z) - position, sphere_radius, t_radius),
				boxSDF(vec3(point.x, point.y, point.z + eps) - position, sphere_radius, t_radius) - boxSDF(vec3(point.x, point.y, point.z - eps) - position, sphere_radius, t_radius)
			));
			return shade(point, ray_origin, normal, normalize(light_position - point)) * col;
		}
		depth += dist;
		if (dist >= 100.0)
			return vec3(0.0);
	}
	return vec3(0.0);
}

void fragment() {
	float yawAngle = radians(1.0);
	vec3 col1 = vec3(cos(yawAngle), 0.0, sin(yawAngle));
	vec3 col2 = vec3(0.0, 1.0, 0.0);
	vec3 col3 = vec3(-sin(yawAngle), 0.0, cos(yawAngle));
	mat3 rotation = mat3(col1, col2, col3);
	float aspectRatio = 16.0 / 16.0;
	float fov = 10.0;
	float fovRad = radians(fov);
	vec2 uv = UV * 2.0 - 1.0;
	uv.x *= aspectRatio;
	float fovScale = 1.0 / tan(fovRad / 2.0);
	uv.x /= fovScale;
	uv.y /= fovScale;
	vec3 ray_origin = vec3(-2.0, 3.0, 0.5);
	vec3 ray_direction = normalize(vec3(0.0, 0.0, -5.0) - ray_origin);
	vec3 forward = normalize(vec3(0.0, 0.0, -5.0) - ray_origin);
	vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
	vec3 up = normalize(cross(forward, right));
	ray_direction = normalize(vec3(forward + uv.x * right + uv.y * up));

	//ALBEDO = sphere(sphere_position, ray_origin, ray_direction, sphere_radius, torus_radi);
	float depth = 0.0;
	vec3 point = vec3(0.0, 0.0, 0.0);
	float dist = 0.0;
	float dist1 = 0.0;
	float dist2 = 0.0;
	for(int i = 0; i < 100; i++){
		dist1 = boxSDF((ray_origin + depth * ray_direction) - box_position, sphere_radius, torus_radi);//(0.2, 0.08)
		dist2 = sphereSDF((ray_origin + depth * ray_direction) - (sphere_position + vec3(0.0, sphere_ypos, 0.0)), sphere_radius, torus_radi);
		dist = opSmoothUnion(dist1, dist2, 0.5);
		if(dist <= eps){
			point = ray_origin + depth * ray_direction;
			vec3 normal = normalize(vec3(
				opSmoothUnion(
					boxSDF(vec3(point.x + eps, point.y, point.z) - box_position, sphere_radius, torus_radi),
					sphereSDF(vec3(point.x + eps, point.y, point.z) - (sphere_position + vec3(0.0, sphere_ypos, 0.0)), sphere_radius, torus_radi),	
					smoothness	
				) - 
				opSmoothUnion(
					boxSDF(vec3(point.x - eps, point.y, point.z) - box_position, sphere_radius, torus_radi),
					sphereSDF(vec3(point.x - eps, point.y, point.z) - (sphere_position + vec3(0.0, sphere_ypos, 0.0)), sphere_radius, torus_radi),	
					smoothness	
				),
				opSmoothUnion(
					boxSDF(vec3(point.x, point.y + eps, point.z) - box_position, sphere_radius, torus_radi),
					sphereSDF(vec3(point.x, point.y + eps, point.z) - (sphere_position + vec3(0.0, sphere_ypos, 0.0)), sphere_radius, torus_radi),	
					smoothness	
				) - 
				opSmoothUnion(
					boxSDF(vec3(point.x, point.y - eps, point.z) - box_position, sphere_radius, torus_radi),
					sphereSDF(vec3(point.x, point.y - eps, point.z) - (sphere_position + vec3(0.0, sphere_ypos, 0.0)), sphere_radius, torus_radi),	
					smoothness	
				),
				opSmoothUnion(
					boxSDF(vec3(point.x, point.y, point.z + eps) - box_position, sphere_radius, torus_radi),
					sphereSDF(vec3(point.x, point.y, point.z + eps) - (sphere_position + vec3(0.0, sphere_ypos, 0.0)), sphere_radius, torus_radi),	
					smoothness	
				) - 
				opSmoothUnion(
					boxSDF(vec3(point.x, point.y, point.z - eps) - box_position, sphere_radius, torus_radi),
					sphereSDF(vec3(point.x, point.y, point.z - eps) - (sphere_position + vec3(0.0, sphere_ypos, 0.0)), sphere_radius, torus_radi),	
					smoothness	
				)
			));
			vec3 color = mix(color1, color2, (dist1 + dist2) / 2.0);
			ALBEDO = shade(point, ray_origin, normal, normalize(light_position - point)) * color;
		}
		depth += dist;
		if (dist >= 100.0)
			//ALBEDO = vec3(0.0);
			discard;
	}
}