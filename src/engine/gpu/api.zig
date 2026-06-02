const std = @import("std");

pub const GpuPtr = enum(u64) {
    none = 0,
    _,

    pub fn fromToken(raw_token: u64) GpuPtr {
        std.debug.assert(raw_token != 0);
        return @enumFromInt(raw_token);
    }

    pub fn token(self: GpuPtr) u64 {
        return @intFromEnum(self);
    }

    pub fn isNone(self: GpuPtr) bool {
        return self == .none;
    }

    pub fn offsetBytes(self: GpuPtr, byte_offset: usize) GpuPtr {
        const base = self.token();
        const offset: u64 = @intCast(byte_offset);
        std.debug.assert(base != 0);
        std.debug.assert(std.math.maxInt(u64) - base >= offset);
        return @enumFromInt(base + offset);
    }
};

pub fn GpuSlice(comptime T: type) type {
    return struct {
        ptr: GpuPtr = .none,
        len: usize = 0,

        const Self = @This();

        pub fn byteLen(self: Self) usize {
            return std.math.mul(usize, self.len, @sizeOf(T)) catch unreachable;
        }

        pub fn slice(self: Self, start: usize, len: usize) Self {
            std.debug.assert(start <= self.len);
            std.debug.assert(len <= self.len - start);
            return .{
                .ptr = if (start == 0) self.ptr else self.ptr.offsetBytes(start * @sizeOf(T)),
                .len = len,
            };
        }

        pub fn ptrAt(self: Self, index: usize) GpuPtr {
            std.debug.assert(index < self.len);
            return self.ptr.offsetBytes(index * @sizeOf(T));
        }
    };
}

pub const GpuByteSlice = GpuSlice(u8);

pub const GpuPipeline = opaque {};
pub const GpuTexture = opaque {};
pub const GpuDepthStencilState = opaque {};
pub const GpuBlendState = opaque {};
pub const GpuQueue = opaque {};
pub const GpuCommandBuffer = opaque {};
pub const GpuSemaphore = opaque {};

pub const Memory = enum(u32) {
    default,
    gpu,
    readback,
};

pub const Cull = enum(u32) {
    ccw,
    cw,
    all,
    none,
};

pub const DepthFlags = packed struct(u32) {
    read: bool = false,
    write: bool = false,
    _reserved: u30 = 0,
};

pub const Op = enum(u32) {
    never,
    less,
    equal,
    less_equal,
    greater,
    not_equal,
    greater_equal,
    always,
};

pub const Blend = enum(u32) {
    add,
    subtract,
    reverse_subtract,
    min,
    max,
};

pub const Factor = enum(u32) {
    zero,
    one,
    src_color,
    dst_color,
    src_alpha,
    dst_alpha,
    one_minus_src_color,
    one_minus_dst_color,
    one_minus_src_alpha,
    one_minus_dst_alpha,
};

pub const Topology = enum(u32) {
    triangle_list,
    triangle_strip,
    triangle_fan,
};

pub const TextureType = enum(u32) {
    @"1d",
    @"2d",
    @"3d",
    cube,
    @"2d_array",
    cube_array,
};

pub const Format = enum(u32) {
    none,
    rgba8_unorm,
    d32_float,
    rg11b10_float,
    rgb10_a2_unorm,
    bgra8_unorm,
    r32_float,
};

pub const UsageFlags = packed struct(u32) {
    sampled: bool = false,
    storage: bool = false,
    color_attachment: bool = false,
    depth_stencil_attachment: bool = false,
    transfer_src: bool = false,
    transfer_dst: bool = false,
    _reserved: u26 = 0,
};

pub const Stage = enum(u32) {
    transfer,
    compute,
    raster_color_out,
    pixel_shader,
    vertex_shader,
};

pub const HazardFlags = packed struct(u32) {
    draw_arguments: bool = false,
    descriptors: bool = false,
    depth_stencil: bool = false,
    _reserved: u29 = 0,
};

pub const Signal = enum(u32) {
    atomic_set,
    atomic_max,
    atomic_or,
};

pub const StencilOp = enum(u32) {
    keep,
    zero,
    replace,
    increment_clamp,
    decrement_clamp,
    invert,
    increment_wrap,
    decrement_wrap,
};

pub const UVec3 = extern struct {
    x: u32 = 1,
    y: u32 = 1,
    z: u32 = 1,
};

pub const Stencil = extern struct {
    test_op: Op = .always,
    fail_op: StencilOp = .keep,
    pass_op: StencilOp = .keep,
    depth_fail_op: StencilOp = .keep,
    reference: u8 = 0,
};

pub const GpuDepthStencilDesc = extern struct {
    depth_mode: DepthFlags = .{},
    depth_test: Op = .always,
    depth_bias: f32 = 0.0,
    depth_bias_slope_factor: f32 = 0.0,
    depth_bias_clamp: f32 = 0.0,
    stencil_read_mask: u8 = 0xff,
    stencil_write_mask: u8 = 0xff,
    stencil_front: Stencil = .{},
    stencil_back: Stencil = .{},
};

pub const GpuBlendDesc = extern struct {
    color_op: Blend = .add,
    src_color_factor: Factor = .one,
    dst_color_factor: Factor = .zero,
    alpha_op: Blend = .add,
    src_alpha_factor: Factor = .one,
    dst_alpha_factor: Factor = .zero,
    color_write_mask: u8 = 0xf,
};

pub const ColorTarget = extern struct {
    format: Format = .none,
    write_mask: u8 = 0xf,
};

pub const ColorTargetSpan = extern struct {
    ptr: ?[*]const ColorTarget = null,
    len: usize = 0,
};

pub const GpuRasterDesc = extern struct {
    topology: Topology = .triangle_list,
    cull: Cull = .none,
    alpha_to_coverage: bool = false,
    support_dual_source_blending: bool = false,
    sample_count: u8 = 1,
    depth_format: Format = .none,
    stencil_format: Format = .none,
    color_targets: ColorTargetSpan = .{},
    blend_state: ?*const GpuBlendDesc = null,
};

pub const GpuTextureDesc = extern struct {
    type: TextureType = .@"2d",
    dimensions: UVec3 = .{},
    mip_count: u32 = 1,
    layer_count: u32 = 1,
    sample_count: u32 = 1,
    format: Format = .none,
    usage: UsageFlags = .{},
};

pub const GpuViewDesc = extern struct {
    format: Format = .none,
    base_mip: u8 = 0,
    mip_count: u8 = all_mips,
    base_layer: u16 = 0,
    layer_count: u16 = all_layers,
};

pub const GpuTextureSizeAlign = extern struct {
    size: usize,
    alignment: usize,
};

pub const GpuTextureDescriptor = extern struct {
    data: [4]u64,
};

pub const GpuRenderPassDesc = extern struct {
    color_targets: ColorTargetSpan = .{},
    depth_target: Format = .none,
    depth_texture: ?*GpuTexture = null,
    clear_color: [4]f32 = .{ 0, 0, 0, 1 },
    clear_depth: f32 = 1,
};

pub const ByteSpan = []const u8;

pub const all_mips: u8 = std.math.maxInt(u8);
pub const all_layers: u16 = std.math.maxInt(u16);

pub fn For(comptime Backend: type) type {
    return struct {
        pub const Graphics = Backend.Graphics;

        pub fn malloc(graphics: *Graphics, bytes: usize, memory: Memory) !GpuPtr {
            return try graphics.malloc(bytes, memory);
        }

        pub fn mallocAligned(graphics: *Graphics, bytes: usize, alignment: usize, memory: Memory) !GpuPtr {
            return try graphics.mallocAligned(bytes, alignment, memory);
        }

        pub fn free(graphics: *Graphics, ptr: GpuPtr) void {
            graphics.free(ptr) catch {};
        }

        pub fn hostToDevicePointer(graphics: *Graphics, ptr: *anyopaque) GpuPtr {
            return graphics.hostToDevicePointer(ptr);
        }

        pub fn textureSizeAlign(graphics: *Graphics, desc: GpuTextureDesc) GpuTextureSizeAlign {
            return graphics.textureSizeAlign(desc);
        }

        pub fn createTexture(graphics: *Graphics, desc: GpuTextureDesc, ptr_gpu: GpuPtr) !*GpuTexture {
            return try graphics.createTexture(desc, ptr_gpu);
        }

        pub fn textureViewDescriptor(graphics: *Graphics, texture: *GpuTexture, desc: GpuViewDesc) GpuTextureDescriptor {
            return graphics.textureViewDescriptor(texture, desc);
        }

        pub fn rwTextureViewDescriptor(graphics: *Graphics, texture: *GpuTexture, desc: GpuViewDesc) GpuTextureDescriptor {
            return graphics.rwTextureViewDescriptor(texture, desc);
        }

        pub fn createComputePipeline(graphics: *Graphics, compute_ir: ByteSpan) !*GpuPipeline {
            return try graphics.createComputePipeline(compute_ir);
        }

        pub fn createGraphicsPipeline(graphics: *Graphics, vertex_ir: ByteSpan, pixel_ir: ByteSpan, desc: GpuRasterDesc) !*GpuPipeline {
            return try graphics.createGraphicsPipeline(vertex_ir, pixel_ir, desc);
        }

        pub fn createGraphicsMeshletPipeline(graphics: *Graphics, meshlet_ir: ByteSpan, pixel_ir: ByteSpan, desc: GpuRasterDesc) !*GpuPipeline {
            return try graphics.createGraphicsMeshletPipeline(meshlet_ir, pixel_ir, desc);
        }

        pub fn freePipeline(graphics: *Graphics, pipeline: *GpuPipeline) void {
            graphics.freePipeline(pipeline);
        }

        pub fn createDepthStencilState(graphics: *Graphics, desc: GpuDepthStencilDesc) !*GpuDepthStencilState {
            return try graphics.createDepthStencilState(desc);
        }

        pub fn createBlendState(graphics: *Graphics, desc: GpuBlendDesc) !*GpuBlendState {
            return try graphics.createBlendState(desc);
        }

        pub fn freeDepthStencilState(graphics: *Graphics, state: *GpuDepthStencilState) void {
            graphics.freeDepthStencilState(state);
        }

        pub fn freeBlendState(graphics: *Graphics, state: *GpuBlendState) void {
            graphics.freeBlendState(state);
        }

        pub fn createQueue(graphics: *Graphics) !*GpuQueue {
            return try graphics.createQueue();
        }

        pub fn startCommandRecording(graphics: *Graphics, queue: *GpuQueue) !*GpuCommandBuffer {
            return try graphics.startCommandRecording(queue);
        }

        pub fn submit(graphics: *Graphics, queue: *GpuQueue, command_buffers: []const *GpuCommandBuffer) !void {
            try graphics.submit(queue, command_buffers);
        }

        pub fn createSemaphore(graphics: *Graphics, init_value: u64) !*GpuSemaphore {
            return try graphics.createSemaphore(init_value);
        }

        pub fn waitSemaphore(graphics: *Graphics, semaphore: *GpuSemaphore, value: u64) !void {
            try graphics.waitSemaphore(semaphore, value);
        }

        pub fn destroySemaphore(graphics: *Graphics, semaphore: *GpuSemaphore) void {
            graphics.destroySemaphore(semaphore);
        }

        pub fn memCpy(graphics: *Graphics, command_buffer: *GpuCommandBuffer, dest_gpu: GpuPtr, src_gpu: GpuPtr, bytes: usize) !void {
            try graphics.memCpy(command_buffer, dest_gpu, src_gpu, bytes);
        }

        pub fn copyToTexture(graphics: *Graphics, command_buffer: *GpuCommandBuffer, dest_gpu: GpuPtr, src_gpu: GpuPtr, texture: *GpuTexture) !void {
            try graphics.copyToTexture(command_buffer, dest_gpu, src_gpu, texture);
        }

        pub fn copyFromTexture(graphics: *Graphics, command_buffer: *GpuCommandBuffer, dest_gpu: GpuPtr, src_gpu: GpuPtr, texture: *GpuTexture) !void {
            try graphics.copyFromTexture(command_buffer, dest_gpu, src_gpu, texture);
        }

        pub fn setActiveTextureHeapPtr(graphics: *Graphics, command_buffer: *GpuCommandBuffer, ptr_gpu: GpuPtr) !void {
            try graphics.setActiveTextureHeapPtr(command_buffer, ptr_gpu);
        }

        pub fn barrier(graphics: *Graphics, command_buffer: *GpuCommandBuffer, before: Stage, after: Stage, hazards: HazardFlags) !void {
            try graphics.barrier(command_buffer, before, after, hazards);
        }

        pub fn signalAfter(graphics: *Graphics, command_buffer: *GpuCommandBuffer, before: Stage, ptr_gpu: GpuPtr, value: u64, signal: Signal) !void {
            try graphics.signalAfter(command_buffer, before, ptr_gpu, value, signal);
        }

        pub fn waitBefore(graphics: *Graphics, command_buffer: *GpuCommandBuffer, after: Stage, ptr_gpu: GpuPtr, value: u64, op: Op, hazards: HazardFlags, mask: u64) !void {
            try graphics.waitBefore(command_buffer, after, ptr_gpu, value, op, hazards, mask);
        }

        pub fn setPipeline(graphics: *Graphics, command_buffer: *GpuCommandBuffer, pipeline: *GpuPipeline) !void {
            try graphics.setPipeline(command_buffer, pipeline);
        }

        pub fn setDepthStencilState(graphics: *Graphics, command_buffer: *GpuCommandBuffer, state: *GpuDepthStencilState) !void {
            try graphics.setDepthStencilState(command_buffer, state);
        }

        pub fn setBlendState(graphics: *Graphics, command_buffer: *GpuCommandBuffer, state: *GpuBlendState) !void {
            try graphics.setBlendState(command_buffer, state);
        }

        pub fn dispatch(graphics: *Graphics, command_buffer: *GpuCommandBuffer, data_gpu: GpuPtr, grid_dimensions: UVec3) !void {
            try graphics.dispatch(command_buffer, data_gpu, grid_dimensions);
        }

        pub fn dispatchIndirect(graphics: *Graphics, command_buffer: *GpuCommandBuffer, data_gpu: GpuPtr, grid_dimensions_gpu: GpuPtr) !void {
            try graphics.dispatchIndirect(command_buffer, data_gpu, grid_dimensions_gpu);
        }

        pub fn beginRenderPass(graphics: *Graphics, command_buffer: *GpuCommandBuffer, desc: GpuRenderPassDesc) !void {
            try graphics.beginRenderPass(command_buffer, desc);
        }

        pub fn endRenderPass(graphics: *Graphics, command_buffer: *GpuCommandBuffer) !void {
            try graphics.endRenderPass(command_buffer);
        }

        pub fn drawIndexedInstanced(graphics: *Graphics, command_buffer: *GpuCommandBuffer, vertex_data_gpu: GpuPtr, pixel_data_gpu: GpuPtr, indices_gpu: GpuPtr, index_count: u32, instance_count: u32) !void {
            try graphics.drawIndexedInstanced(command_buffer, vertex_data_gpu, pixel_data_gpu, indices_gpu, index_count, instance_count);
        }

        pub fn drawIndexedInstancedIndirect(graphics: *Graphics, command_buffer: *GpuCommandBuffer, vertex_data_gpu: GpuPtr, pixel_data_gpu: GpuPtr, indices_gpu: GpuPtr, args_gpu: GpuPtr) !void {
            try graphics.drawIndexedInstancedIndirect(command_buffer, vertex_data_gpu, pixel_data_gpu, indices_gpu, args_gpu);
        }

        pub fn drawIndexedInstancedIndirectMulti(graphics: *Graphics, command_buffer: *GpuCommandBuffer, vertex_data_gpu: GpuPtr, vertex_stride: u32, pixel_data_gpu: GpuPtr, pixel_stride: u32, args_gpu: GpuPtr, draw_count_gpu: GpuPtr) !void {
            try graphics.drawIndexedInstancedIndirectMulti(command_buffer, vertex_data_gpu, vertex_stride, pixel_data_gpu, pixel_stride, args_gpu, draw_count_gpu);
        }

        pub fn drawMeshlets(graphics: *Graphics, command_buffer: *GpuCommandBuffer, meshlet_data_gpu: GpuPtr, pixel_data_gpu: GpuPtr, dimensions: UVec3) !void {
            try graphics.drawMeshlets(command_buffer, meshlet_data_gpu, pixel_data_gpu, dimensions);
        }

        pub fn drawMeshletsIndirect(graphics: *Graphics, command_buffer: *GpuCommandBuffer, meshlet_data_gpu: GpuPtr, pixel_data_gpu: GpuPtr, dimensions_gpu: GpuPtr) !void {
            try graphics.drawMeshletsIndirect(command_buffer, meshlet_data_gpu, pixel_data_gpu, dimensions_gpu);
        }
    };
}

comptime {
    assertLayout(@sizeOf(GpuPtr) == @sizeOf(u64), "GpuPtr must stay u64-sized");
    assertLayout(@sizeOf(DepthFlags) == @sizeOf(u32), "DepthFlags must stay u32-sized");
    assertLayout(@sizeOf(UsageFlags) == @sizeOf(u32), "UsageFlags must stay u32-sized");
    assertLayout(@sizeOf(HazardFlags) == @sizeOf(u32), "HazardFlags must stay u32-sized");

    assertLayout(@bitOffsetOf(DepthFlags, "read") == 0, "DepthFlags.read must stay bit 0");
    assertLayout(@bitOffsetOf(DepthFlags, "write") == 1, "DepthFlags.write must stay bit 1");

    assertLayout(@bitOffsetOf(UsageFlags, "sampled") == 0, "UsageFlags.sampled must stay bit 0");
    assertLayout(@bitOffsetOf(UsageFlags, "storage") == 1, "UsageFlags.storage must stay bit 1");
    assertLayout(@bitOffsetOf(UsageFlags, "color_attachment") == 2, "UsageFlags.color_attachment must stay bit 2");
    assertLayout(@bitOffsetOf(UsageFlags, "depth_stencil_attachment") == 3, "UsageFlags.depth_stencil_attachment must stay bit 3");
    assertLayout(@bitOffsetOf(UsageFlags, "transfer_src") == 4, "UsageFlags.transfer_src must stay bit 4");
    assertLayout(@bitOffsetOf(UsageFlags, "transfer_dst") == 5, "UsageFlags.transfer_dst must stay bit 5");

    assertLayout(@bitOffsetOf(HazardFlags, "draw_arguments") == 0, "HazardFlags.draw_arguments must stay bit 0");
    assertLayout(@bitOffsetOf(HazardFlags, "descriptors") == 1, "HazardFlags.descriptors must stay bit 1");
    assertLayout(@bitOffsetOf(HazardFlags, "depth_stencil") == 2, "HazardFlags.depth_stencil must stay bit 2");
}

fn assertLayout(comptime condition: bool, comptime message: []const u8) void {
    if (!condition) @compileError(message);
}
