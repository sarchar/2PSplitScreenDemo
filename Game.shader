shader_type canvas_item;

// player2_view is the Viewport texture rendered by player 2 camera
uniform sampler2D player2_view : hint_albedo;

// the slope of the line to divide the screen. we'll use the center of the screen in UV space
// as the point on the line
uniform vec2 line_slope;

// separation is a constant in pixels on how far apart the players are
uniform float separation;

// single_camera_max_separation is the distance in pixels for how far apart players need to be
// before starting the transition to two cameras.
uniform float single_camera_max_separation;

// camera_smooth_split_distance is how far the players have to separate (in addition to 
// single_camera_max_separation) to complete the transition to two cameras
uniform float camera_smooth_split_distance;

// the smoothstep cutoff distance for fading out one camera and into the next
uniform float smoothstep_amplitude : hint_range(0, 1) = 0.0125;

// the amount to shift the player's UV by
// TODO: the size of the circle to keep the player on
uniform float player_uv_shift : hint_range(0, 1) = 0.15;

// compute the distance point `test` is to the line defined by points (pt1, pt2)
// source: https://stackoverflow.com/questions/9246100/how-can-i-implement-the-distance-from-a-point-to-a-line-segment-in-glsl
float lineDistance(vec2 pt1, vec2 pt2, vec2 test) {
	vec2 lineDir = pt2 - pt1;
	vec2 perpDir = vec2(lineDir.y, -lineDir.x);
	vec2 dirToPt1 = pt1 - test;
	return dot(normalize(perpDir), dirToPt1);
}

// translate the UV coordinates perpendicular to the separating line
// this effectively moves the camera to always keep the player in a reasonable
// location in their half of the screen
vec2 moveUVPerpendicularToLine(vec2 pt1, vec2 pt2, vec2 uv, float howFar) {
	vec2 lineDir = pt2 - pt1;
	vec2 perpDir = normalize(vec2(lineDir.y, -lineDir.x));
	
	// perpDir is a vector perpendicular to the line, just add that to UV
	return uv + perpDir * howFar;
}

void fragment() {
	// We'll modify UV coordinates, so put them into a variable
	vec2 uv = UV;

	// get two points on the separating line
	vec2 pt1 = vec2(0.5, 0.5);
	vec2 pt2 = pt1 + line_slope;
	
	// if separation is close enough, just render player1's camera, otherwise gradually increase smoothstep separation
	if(separation < single_camera_max_separation) {
		COLOR = texture(TEXTURE, uv);
	} else {
		float sepscale = min(1.0, (separation - single_camera_max_separation) / camera_smooth_split_distance);
		float smoothstep_size = smoothstep_amplitude * smoothstep(single_camera_max_separation, 
		                                                          single_camera_max_separation + camera_smooth_split_distance, 
													              separation);
		
		float ld = lineDistance(pt1, pt2, uv);

		// adjust the psuedo-cameras for the players to "center" them in their half of the screen
		if(ld > 0.0) {
			// player 1, adjust the UVs slightly
			uv = moveUVPerpendicularToLine(pt1, pt2, uv, player_uv_shift * sepscale);
		} else {
			uv = moveUVPerpendicularToLine(pt1, pt2, uv, -player_uv_shift * sepscale); // opposite direction for player 2
		}
		
		// the rest of the code blends between the two cameras:
		// ratio1 = how much of camera 1 is visible, smoothstep to zero around the dividing line
		// ratio2 = how much of camera 2 is visible, smoothstep to zero around the dividing line
		float ratio1 = smoothstep(smoothstep_size, 2.0*smoothstep_size,  ld + smoothstep_size);
		float ratio2 = smoothstep(smoothstep_size, 2.0*smoothstep_size, -ld + smoothstep_size);

		// sample the two camera texture
		vec4 p1c = mix(vec4(0.0, 0.0, 0.0, 1.0), texture(TEXTURE, uv), ratio1);
		vec4 p2c = mix(vec4(0.0, 0.0, 0.0, 1.0), texture(player2_view, uv), ratio2);
		
		// combine their colors, leave alpha alone
		COLOR = vec4(p1c.rgb + p2c.rgb, 1.0);
	}
}