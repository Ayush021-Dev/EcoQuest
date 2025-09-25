shader_type canvas_item;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float distance = length(UV - center);
    
    if (distance > 0.5) {
        COLOR.a = 0.0; // Make it transparent outside the circle
    }
    // Don't override COLOR if we're inside the circle - keep the ColorRect's brown color
}