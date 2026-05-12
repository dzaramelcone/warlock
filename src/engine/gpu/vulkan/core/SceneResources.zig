const gpu_scene = @import("../../scene_data.zig");
const SceneBuffers = @import("SceneBuffers.zig");
const ScenePipeline = @import("ScenePipeline.zig");
const TextureBinding = @import("TextureBinding.zig");

    pipelines: []ScenePipeline,
    buffers: SceneBuffers,
    texture_binding: TextureBinding,

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.pipelines[0].device.waitIdle() catch {};
        self.buffers.deinit();
        for (self.pipelines) |scene_pipeline| scene_pipeline.deinit();
        self.buffers.vertex_buffer.device.context.allocator.free(self.pipelines);
        self.texture_binding.deinit();
    }

    pub fn renderPass(self: *Self) *ScenePipeline {
        return &self.pipelines[0];
    }

    pub fn pipeline(self: *Self, pipeline_index: u32) *ScenePipeline {
        return &self.pipelines[pipeline_index];
    }

    pub fn indexedVertexData(self: *Self) *SceneBuffers {
        return &self.buffers;
    }

    pub fn mutableVertexDraws(self: *Self) []gpu_scene.VertexDrawData {
        return self.buffers.mutableVertexDraws();
    }

    pub fn mutablePixelDraws(self: *Self) []gpu_scene.PixelDrawData {
        return self.buffers.mutablePixelDraws();
    }

    pub fn uploadFrameData(self: Self) !void {
        try self.buffers.uploadFrameData();
    }

    pub fn drawRange(self: Self, draw_index: u32) gpu_scene.Draw {
        return self.buffers.draw_data[draw_index];
    }

    pub fn vertexDrawData(self: *Self, draw_index: u32) *gpu_scene.VertexDrawData {
        return &self.buffers.vertex_draw_data[draw_index];
    }

    pub fn pixelDrawData(self: *Self, draw_index: u32) *gpu_scene.PixelDrawData {
        return &self.buffers.pixel_draw_data[draw_index];
    }

    pub fn vertexCount(self: Self) u32 {
        return self.buffers.vertex_count;
    }

    pub fn indexCount(self: Self) u32 {
        return self.buffers.index_count;
    }

    pub fn drawCount(self: Self) u32 {
        return self.buffers.draw_count;
    }
