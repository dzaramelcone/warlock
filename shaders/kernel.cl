typedef unsigned int u32;

__kernel void render(__global u32* pixels, int width, int height, float time) {
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    if (x >= width || y >= height) return;

    const float2 uv = (float2)(
        ((float)x / (float)width) * 2.0f - 1.0f,
        ((float)y / (float)height) * 2.0f - 1.0f
    );

    const float wave = 0.5f + 0.5f * sin(uv.x * 10.0f + time * 2.0f);
    const float pulse = 0.5f + 0.5f * cos(length(uv) * 18.0f - time * 5.0f);
    const float vignette = clamp(1.15f - dot(uv, uv) * 0.65f, 0.0f, 1.0f);

    const uint r = (uint)(255.0f * wave * vignette);
    const uint g = (uint)(255.0f * pulse * vignette);
    const uint b = (uint)(255.0f * (0.55f + 0.45f * uv.y * uv.y) * vignette);

    pixels[y * width + x] = (r << 16) | (g << 8) | b;
}
