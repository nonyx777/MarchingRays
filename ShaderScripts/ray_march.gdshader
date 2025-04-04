shader_type spatial;

const vec3 sphere_position = vec3(0.0, 0.0, -5);
const float sphere_radius = 0.5;
const float eps = 0.001;
const vec3 color = vec3(1.0, 0.0, 0.0);
const vec3 light_position = vec3(-5, -2, -2);
const float ambien_strength = 0.1;
const vec3 light_color = vec3(1.0, 1.0, 1.0);
const float shininess = 32.0;

float sphere_sdf(vec3 p){
	return length(sphere_position - p) - sphere_radius;
}

vec3 shade(vec3 point, vec3 camera_position, vec3 normal, vec3 light_direction){
	vec3 ambient = ambien_strength * light_color;
	vec3 diffuse = max(dot(normal, light_direction), 0.0) * light_color;
	vec3 view = normalize(camera_position - point);
	vec3 half_way = normalize(view + light_direction);
	float spec = pow(max(dot(normal, half_way), 0.0), shininess);
	vec3 specular = spec * light_color;
	return ambient + diffuse + specular;
}

void fragment() {
	vec3 ray_origin = vec3(0.0, 0.0, 0.0) + vec3(UV * 2.0 - 1.0, 0.0);
	vec3 ray_direction = normalize(vec3(0.0, 0.0, -1.0));
	
	float depth = 0.0;
	vec3 point = vec3(0.0, 0.0, 0.0);
	for(int i = 0; i < 100; i++){
		float dist = sphere_sdf(ray_origin + depth * ray_direction);
		if(dist <= eps)
			point = ray_origin + depth * ray_direction;
			vec3 normal = normalize(vec3(
				sphere_sdf(vec3(point.x + eps, point.y, point.z)) - sphere_sdf(vec3(point.x - eps, point.y, point.z)),
				sphere_sdf(vec3(point.x, point.y + eps, point.z)) - sphere_sdf(vec3(point.x, point.y - eps, point.z)),
				sphere_sdf(vec3(point.x, point.y, point.z + eps)) - sphere_sdf(vec3(point.x, point.y, point.z - eps))
			));
			ALBEDO = shade(point, vec3(0.0), normal, normalize(light_position - point));
		depth += dist;
		if (dist >= 100.0)
			ALBEDO = vec3(0.0, 0.0, 0.0);
	}
}

//void light() {
	//
//}
