shader_type spatial;

uniform sampler2D ripple_texture;

uniform vec2 ripple_center = vec2(0.5);
uniform float ripple_radius = 0.0;
uniform float ripple_width = 0.04;

uniform float ripple_strength = 3.0;

void fragment() {
    float d = distance(UV, ripple_center);

    // Circular ripple mask
    float ripple = exp(
        -pow((d - ripple_radius) / ripple_width, 2.0)
    );

    // Sample the ripple at two nearby positions
    float px = 0.002;

    float h_x1 = exp(
        -pow((distance(UV + vec2(px, 0.0), ripple_center)
        - ripple_radius) / ripple_width, 2.0)
    );

    float h_x2 = exp(
        -pow((distance(UV - vec2(px, 0.0), ripple_center)
        - ripple_radius) / ripple_width, 2.0)
    );

    float h_y1 = exp(
        -pow((distance(UV + vec2(0.0, px), ripple_center)
        - ripple_radius) / ripple_width, 2.0)
    );

    float h_y2 = exp(
        -pow((distance(UV - vec2(0.0, px), ripple_center)
        - ripple_radius) / ripple_width, 2.0)
    );

    // Surface slope
    float dx = (h_x1 - h_x2);
    float dy = (h_y1 - h_y2);

    // Convert slope into tangent-space normal
    NORMAL_MAP = normalize(
        vec3(
            -dx * ripple_strength,
            -dy * ripple_strength,
            1.0
        )
    );
}