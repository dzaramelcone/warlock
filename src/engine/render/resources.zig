const gpu = @import("../gpu/mod.zig");
const images = @import("../images/mod.zig");
const gpu_scene = @import("gpu_scene.zig");

pub const ShaderBytes = struct {
    vertex: []const u8,
    fragment: []const u8,
};

pub const TextureBytes = struct {
    pub const Level = images.texture.MipLevel;

    pub const Filter = enum {
        nearest,
        linear,
    };

    pub const MipmapMode = enum {
        nearest,
        linear,
    };

    pub const AddressMode = enum {
        repeat,
        clamp_to_edge,
    };

    width: u32,
    height: u32,
    rgba: []const u8,
    levels: []const Level,
    mag_filter: Filter = .linear,
    min_filter: Filter = .linear,
    mipmap_mode: MipmapMode = .linear,
    address_mode: AddressMode = .repeat,
};

pub const SceneResources = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        deinit: *const fn (*anyopaque) void,
        renderPass: *const fn (*anyopaque) *gpu.api.GpuRenderPass,
        pipeline: *const fn (*anyopaque, u32) *gpu.api.GpuPipeline,
        indexedVertexData: *const fn (*anyopaque) *gpu.api.GpuIndexedVertexData,
        mutableVertexDrawDataBytes: *const fn (*anyopaque) []u8,
        mutablePixelDrawDataBytes: *const fn (*anyopaque) []u8,
        uploadFrameData: *const fn (*anyopaque) anyerror!void,
        drawRange: *const fn (*anyopaque, u32) gpu_scene.Draw,
        vertexDrawData: *const fn (*anyopaque, u32) *gpu.api.GpuVertexDrawData,
        pixelDrawData: *const fn (*anyopaque, u32) *gpu.api.GpuPixelDrawData,
        vertexCount: *const fn (*anyopaque) u32,
        indexCount: *const fn (*anyopaque) u32,
        drawCount: *const fn (*anyopaque) u32,
    };

    pub fn deinit(self: SceneResources) void {
        self.vtable.deinit(self.ptr);
    }

    pub fn renderPass(self: SceneResources) *gpu.api.GpuRenderPass {
        return self.vtable.renderPass(self.ptr);
    }

    pub fn pipeline(self: SceneResources, pipeline_index: u32) *gpu.api.GpuPipeline {
        return self.vtable.pipeline(self.ptr, pipeline_index);
    }

    pub fn indexedVertexData(self: SceneResources) *gpu.api.GpuIndexedVertexData {
        return self.vtable.indexedVertexData(self.ptr);
    }

    pub fn mutableVertexDrawDataBytes(self: SceneResources) []u8 {
        return self.vtable.mutableVertexDrawDataBytes(self.ptr);
    }

    pub fn mutablePixelDrawDataBytes(self: SceneResources) []u8 {
        return self.vtable.mutablePixelDrawDataBytes(self.ptr);
    }

    pub fn uploadFrameData(self: SceneResources) !void {
        try self.vtable.uploadFrameData(self.ptr);
    }

    pub fn drawRange(self: SceneResources, draw_index: u32) gpu_scene.Draw {
        return self.vtable.drawRange(self.ptr, draw_index);
    }

    pub fn vertexDrawData(self: SceneResources, draw_index: u32) *gpu.api.GpuVertexDrawData {
        return self.vtable.vertexDrawData(self.ptr, draw_index);
    }

    pub fn pixelDrawData(self: SceneResources, draw_index: u32) *gpu.api.GpuPixelDrawData {
        return self.vtable.pixelDrawData(self.ptr, draw_index);
    }

    pub fn vertexCount(self: SceneResources) u32 {
        return self.vtable.vertexCount(self.ptr);
    }

    pub fn indexCount(self: SceneResources) u32 {
        return self.vtable.indexCount(self.ptr);
    }

    pub fn drawCount(self: SceneResources) u32 {
        return self.vtable.drawCount(self.ptr);
    }
};
