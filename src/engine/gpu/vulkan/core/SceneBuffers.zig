const Api = @import("../../api.zig");
const HostBuffer = @import("HostBuffer.zig");
const gpu_scene = @import("../../scene_data.zig");

vertex_buffer: HostBuffer,
index_buffer: HostBuffer,
draw_buffer: HostBuffer,
draw_data: []gpu_scene.Draw,
vertex_draw_buffer: HostBuffer,
vertex_draw_data: []gpu_scene.VertexDrawData,
pixel_draw_buffer: HostBuffer,
pixel_draw_data: []gpu_scene.PixelDrawData,
vertex_count: u32,
index_count: u32,
draw_count: u32,

const Self = @This();

pub fn deinit(self: Self) void {
    self.vertex_buffer.device.context.allocator.free(self.draw_data);
    self.vertex_buffer.device.context.allocator.free(self.vertex_draw_data);
    self.vertex_buffer.device.context.allocator.free(self.pixel_draw_data);
    self.pixel_draw_buffer.deinit();
    self.vertex_draw_buffer.deinit();
    self.draw_buffer.deinit();
    self.index_buffer.deinit();
    self.vertex_buffer.deinit();
}

pub fn mutableVertexDraws(self: *Self) []gpu_scene.VertexDrawData {
    return self.vertex_draw_data;
}

pub fn mutablePixelDraws(self: *Self) []gpu_scene.PixelDrawData {
    return self.pixel_draw_data;
}

pub fn uploadFrameData(self: Self) !void {
    try self.vertex_draw_buffer.write(gpu_scene.VertexDrawData, self.vertex_draw_data);
    try self.pixel_draw_buffer.write(gpu_scene.PixelDrawData, self.pixel_draw_data);
}

pub fn apiIndexedVertexData(self: *Self) *Api.GpuIndexedVertexData {
    return @ptrCast(self);
}

pub fn apiVertexDrawData(self: *Self, draw_index: u32) *Api.GpuVertexDrawData {
    return @ptrCast(&self.vertex_draw_data[draw_index]);
}

pub fn apiPixelDrawData(self: *Self, draw_index: u32) *Api.GpuPixelDrawData {
    return @ptrCast(&self.pixel_draw_data[draw_index]);
}
