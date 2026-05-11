const std = @import("std");
const gpu = @import("../gpu/mod.zig");
const gpu_scene = @import("gpu_scene.zig");
const resources_mod = @import("resources.zig");
const scene_mod = @import("scene.zig");

pub fn renderFrame(
    cb: gpu.api.CommandBuffer,
    resources: resources_mod.SceneResources,
    scene: *const scene_mod.Scene,
    width: u32,
    height: u32,
    clear_color: [4]f32,
) !void {
    const vertex_draw_bytes: []align(@alignOf(gpu_scene.VertexDrawData)) u8 = @alignCast(resources.mutableVertexDrawDataBytes());
    const pixel_draw_bytes: []align(@alignOf(gpu_scene.PixelDrawData)) u8 = @alignCast(resources.mutablePixelDrawDataBytes());
    const vertex_draws = std.mem.bytesAsSlice(gpu_scene.VertexDrawData, vertex_draw_bytes);
    const pixel_draws = std.mem.bytesAsSlice(gpu_scene.PixelDrawData, pixel_draw_bytes);
    try gpu_scene.updateFrameData(scene, width, height, vertex_draws, pixel_draws);
    try resources.uploadFrameData();

    try cb.gpuBeginRenderPass(.{
        .depth_target = .d32_float,
        .clear_color = clear_color,
        .clear_depth = 1.0,
        .render_pass = resources.renderPass(),
    });
    try cb.gpuSetIndexedVertexData(resources.indexedVertexData());
    var active_pipeline: ?u32 = null;
    for (0..resources.drawCount()) |draw_index| {
        const range = resources.drawRange(@intCast(draw_index));
        if (active_pipeline == null or active_pipeline.? != range.material_index) {
            try cb.gpuSetPipeline(resources.pipeline(range.material_index));
            active_pipeline = range.material_index;
        }
        try cb.gpuSetVertexDrawData(resources.vertexDrawData(@intCast(draw_index)));
        try cb.gpuSetPixelDrawData(resources.pixelDrawData(@intCast(draw_index)));
        try cb.gpuDrawIndexedInstanced(range.index_offset, range.index_count, @intCast(range.vertex_offset), 1);
    }
    try cb.gpuEndRenderPass();
}
