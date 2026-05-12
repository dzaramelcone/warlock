const scene_mod = @import("scene.zig");
const gpu_scene = @import("gpu_scene.zig");

pub fn For(comptime Gpu: type) type {
    return struct {
        const Self = @This();

        pub fn renderFrame(
            self: Self,
            commands: *Gpu.Commands,
            resources: *Gpu.SceneResources,
            scene: *const scene_mod.Scene,
            width: u32,
            height: u32,
            clear_color: [4]f32,
        ) !void {
            _ = self;

            try gpu_scene.updateFrameData(scene, width, height, resources.mutableVertexDraws(), resources.mutablePixelDraws());
            try resources.uploadFrameData();

            try Gpu.beginRenderPass(commands, resources.renderPass(), clear_color);
            try Gpu.setIndexedVertexData(commands, resources.indexedVertexData());
            var active_pipeline: ?u32 = null;
            for (0..resources.drawCount()) |draw_index| {
                const range = resources.drawRange(@intCast(draw_index));
                if (active_pipeline == null or active_pipeline.? != range.material_index) {
                    try Gpu.setPipeline(commands, resources.pipeline(range.material_index));
                    active_pipeline = range.material_index;
                }
                try Gpu.setVertexDrawData(commands, resources.vertexDrawData(@intCast(draw_index)));
                try Gpu.setPixelDrawData(commands, resources.pixelDrawData(@intCast(draw_index)));
                try Gpu.drawIndexedInstanced(commands, range.index_offset, range.index_count, @intCast(range.vertex_offset), 1);
            }
            try Gpu.endRenderPass(commands);
        }
    };
}
