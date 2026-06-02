const std = @import("std");
const api = @import("api.zig");

pub const Graphics = struct {
    allocator: std.mem.Allocator,
    memory: std.ArrayList(u8) = .empty,
    frees: usize = 0,

    pub fn init(allocator: std.mem.Allocator, _: anytype) !Graphics {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Graphics) void {
        self.memory.deinit(self.allocator);
        self.* = undefined;
    }

    pub fn malloc(self: *Graphics, bytes: usize, memory_class: api.Memory) !api.GpuPtr {
        return try self.mallocAligned(bytes, 1, memory_class);
    }

    pub fn mallocAligned(self: *Graphics, bytes: usize, alignment: usize, _: api.Memory) !api.GpuPtr {
        const start = std.mem.alignForward(usize, self.memory.items.len, alignment);
        try self.memory.resize(self.allocator, start + bytes);
        return api.GpuPtr.fromToken(@intCast(start + 1));
    }

    pub fn mallocBufferAligned(self: *Graphics, bytes: usize, alignment: usize, memory_class: api.Memory) !api.GpuPtr {
        return try self.mallocAligned(bytes, alignment, memory_class);
    }

    pub fn free(self: *Graphics, _: api.GpuPtr) !void {
        self.frees += 1;
    }

    pub fn hostToDevicePointer(_: *Graphics, ptr: *anyopaque) api.GpuPtr {
        return api.GpuPtr.fromToken(@intFromPtr(ptr));
    }

    pub fn textureSizeAlign(_: *Graphics, desc: api.GpuTextureDesc) api.GpuTextureSizeAlign {
        return .{
            .size = @max(@as(usize, desc.dimensions.x) * @as(usize, desc.dimensions.y) * @as(usize, 4), 1),
            .alignment = 16,
        };
    }

    pub fn createTexture(_: *Graphics, _: api.GpuTextureDesc, ptr: api.GpuPtr) !*api.GpuTexture {
        return @ptrFromInt(@max(ptr.token(), 1));
    }

    pub fn textureViewDescriptor(_: *Graphics, texture: *api.GpuTexture, desc: api.GpuViewDesc) api.GpuTextureDescriptor {
        return descriptor(texture, desc, false);
    }

    pub fn rwTextureViewDescriptor(_: *Graphics, texture: *api.GpuTexture, desc: api.GpuViewDesc) api.GpuTextureDescriptor {
        return descriptor(texture, desc, true);
    }

    pub fn createComputePipeline(_: *Graphics, _: api.ByteSpan) !*api.GpuPipeline {
        return handle(api.GpuPipeline, 1);
    }

    pub fn createGraphicsPipeline(_: *Graphics, _: api.ByteSpan, _: api.ByteSpan, _: api.GpuRasterDesc) !*api.GpuPipeline {
        return handle(api.GpuPipeline, 1);
    }

    pub fn createGraphicsMeshletPipeline(_: *Graphics, _: api.ByteSpan, _: api.ByteSpan, _: api.GpuRasterDesc) !*api.GpuPipeline {
        return handle(api.GpuPipeline, 1);
    }

    pub fn freePipeline(_: *Graphics, _: *api.GpuPipeline) void {}

    pub fn createDepthStencilState(_: *Graphics, _: api.GpuDepthStencilDesc) !*api.GpuDepthStencilState {
        return handle(api.GpuDepthStencilState, 1);
    }

    pub fn createBlendState(_: *Graphics, _: api.GpuBlendDesc) !*api.GpuBlendState {
        return handle(api.GpuBlendState, 1);
    }

    pub fn freeDepthStencilState(_: *Graphics, _: *api.GpuDepthStencilState) void {}
    pub fn freeBlendState(_: *Graphics, _: *api.GpuBlendState) void {}

    pub fn createQueue(_: *Graphics) !*api.GpuQueue {
        return handle(api.GpuQueue, 1);
    }

    pub fn startCommandRecording(_: *Graphics, _: *api.GpuQueue) !*api.GpuCommandBuffer {
        return handle(api.GpuCommandBuffer, 1);
    }

    pub fn submit(_: *Graphics, _: *api.GpuQueue, _: []const *api.GpuCommandBuffer) !void {}

    pub fn createSemaphore(_: *Graphics, _: u64) !*api.GpuSemaphore {
        return handle(api.GpuSemaphore, 1);
    }

    pub fn waitSemaphore(_: *Graphics, _: *api.GpuSemaphore, _: u64) !void {}
    pub fn destroySemaphore(_: *Graphics, _: *api.GpuSemaphore) void {}

    pub fn memCpy(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr, _: api.GpuPtr, _: usize) !void {}
    pub fn copyToTexture(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr, _: api.GpuPtr, _: *api.GpuTexture) !void {}
    pub fn copyFromTexture(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr, _: api.GpuPtr, _: *api.GpuTexture) !void {}
    pub fn setActiveTextureHeapPtr(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr) !void {}
    pub fn barrier(_: *Graphics, _: *api.GpuCommandBuffer, _: api.Stage, _: api.Stage, _: api.HazardFlags) !void {}
    pub fn signalAfter(_: *Graphics, _: *api.GpuCommandBuffer, _: api.Stage, _: api.GpuPtr, _: u64, _: api.Signal) !void {}
    pub fn waitBefore(_: *Graphics, _: *api.GpuCommandBuffer, _: api.Stage, _: api.GpuPtr, _: u64, _: api.Op, _: api.HazardFlags, _: u64) !void {}
    pub fn setPipeline(_: *Graphics, _: *api.GpuCommandBuffer, _: *api.GpuPipeline) !void {}
    pub fn setDepthStencilState(_: *Graphics, _: *api.GpuCommandBuffer, _: *api.GpuDepthStencilState) !void {}
    pub fn setBlendState(_: *Graphics, _: *api.GpuCommandBuffer, _: *api.GpuBlendState) !void {}
    pub fn dispatch(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr, _: api.UVec3) !void {}
    pub fn dispatchIndirect(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr, _: api.GpuPtr) !void {}
    pub fn beginRenderPass(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuRenderPassDesc) !void {}
    pub fn endRenderPass(_: *Graphics, _: *api.GpuCommandBuffer) !void {}
    pub fn drawIndexedInstanced(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr, _: api.GpuPtr, _: api.GpuPtr, _: u32, _: u32) !void {}
    pub fn drawIndexedInstancedIndirect(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr, _: api.GpuPtr, _: api.GpuPtr, _: api.GpuPtr) !void {}
    pub fn drawIndexedInstancedIndirectMulti(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr, _: u32, _: api.GpuPtr, _: u32, _: api.GpuPtr, _: api.GpuPtr) !void {}
    pub fn drawMeshlets(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr, _: api.GpuPtr, _: api.UVec3) !void {}
    pub fn drawMeshletsIndirect(_: *Graphics, _: *api.GpuCommandBuffer, _: api.GpuPtr, _: api.GpuPtr, _: api.GpuPtr) !void {}

    pub fn writeBytes(self: *Graphics, ptr: api.GpuPtr, bytes: []const u8) !void {
        const start: usize = @intCast(ptr.token() - 1);
        if (bytes.len > self.memory.items.len - start) return error.FakeGpuWriteOutOfBounds;
        @memcpy(self.memory.items[start..][0..bytes.len], bytes);
    }

    pub fn writeSlice(self: *Graphics, comptime T: type, ptr: api.GpuPtr, values: []const T) !void {
        try self.writeBytes(ptr, std.mem.sliceAsBytes(values));
    }

    pub fn readBytes(self: *Graphics, ptr: api.GpuPtr, dest: []u8) !void {
        const start: usize = @intCast(ptr.token() - 1);
        if (dest.len > self.memory.items.len - start) return error.FakeGpuReadOutOfBounds;
        @memcpy(dest, self.memory.items[start..][0..dest.len]);
    }
};

fn descriptor(texture: *api.GpuTexture, desc: api.GpuViewDesc, writable: bool) api.GpuTextureDescriptor {
    return .{
        .data = .{
            @intFromPtr(texture),
            (@as(u64, desc.base_layer) << 48) |
                (@as(u64, desc.layer_count) << 32) |
                (@as(u64, desc.base_mip) << 16) |
                @as(u64, desc.mip_count),
            @intFromEnum(desc.format),
            @intFromBool(writable),
        },
    };
}

fn handle(comptime T: type, value: usize) *T {
    return @ptrFromInt(value);
}
