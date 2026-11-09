shader_type spatial;

uniform vec3 albedo :source_color;
uniform vec3 albedo_furnel :source_color;
uniform float roughness :hint_range(0.0, 1.0, 0.1);
uniform float metal :hint_range(0.0, 1.0, 0.1);
uniform sampler2D texturemap1;
uniform sampler2D texturemap2;
uniform vec2 wave_dir1 ;
uniform vec2 wave_dir2 ;
uniform float timescale :hint_range(0.00, 1.00, 0.01) ;

uniform sampler3D wave;
uniform float noise_scale = 10.0;
uniform float hight_scale = 0.15;
uniform vec4 color_deep: source_color;
uniform vec4 color_shallow: source_color;
uniform float beers_law = 2.8;
uniform float depth_offset=-0.75;

uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

varying float hight;
varying vec3 world_pos;

float fresnel(float amount, vec3 normal , vec3 view){
	return pow((1.0-clamp(dot(normalize(normal),normalize(view)),0.0,1.0)),amount);
}

void fragment() {

		// Depth variables and calc
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_texture);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float depth_blend = exp((-view.z+VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	vec3 screen_color = textureLod (SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
	vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color = mix(screen_color* depth_color, depth_color* 0.25, depth_blend_power * 0.5);


	vec2 time1 =(TIME*wave_dir1)*timescale;
	vec2 time2 =(TIME*wave_dir2)*timescale;
	vec3 normal1 = texture(texturemap1,UV+time1).rgb;
	vec3 normal2 = texture(texturemap2,UV+time2).rgb;
	vec3 normal_blend= mix(normal1,normal2,0.5);

	METALLIC = metal;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;

	float fresnel = fresnel(5.0,NORMAL,VIEW);
	vec3 surface_color = mix(albedo , albedo_furnel , fresnel);

	ALBEDO = mix(surface_color, color, 0.75);
	// Called for every pixel the material is visible on.


	}
void vertex(){
	world_pos = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	hight = texture( wave , world_pos / noise_scale + TIME * timescale ).r;
	VERTEX.y += hight * hight_scale;
	}


//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
