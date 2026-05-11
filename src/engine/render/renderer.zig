const scene_mod = @import("scene.zig");
const gpu_scene = @import("gpu_scene.zig");

pub fn ForGpu(comptime Gpu: type) type {
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

            try Gpu.gpuBeginRenderPass(commands, resources.renderPass(), clear_color);
            try Gpu.gpuSetIndexedVertexData(commands, resources.indexedVertexData());
            var active_pipeline: ?u32 = null;
            for (0..resources.drawCount()) |draw_index| {
                const range = resources.drawRange(@intCast(draw_index));
                if (active_pipeline == null or active_pipeline.? != range.material_index) {
                    try Gpu.gpuSetPipeline(commands, resources.pipeline(range.material_index));
                    active_pipeline = range.material_index;
                }
                try Gpu.gpuSetVertexDrawData(commands, resources.vertexDrawData(@intCast(draw_index)));
                try Gpu.gpuSetPixelDrawData(commands, resources.pixelDrawData(@intCast(draw_index)));
                try Gpu.gpuDrawIndexedInstanced(commands, range.index_offset, range.index_count, @intCast(range.vertex_offset), 1);
            }
            try Gpu.gpuEndRenderPass(commands);
        }
    };
}
