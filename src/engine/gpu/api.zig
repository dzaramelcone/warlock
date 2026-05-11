const std = @import("std");

pub const GpuPipeline = opaque {};
pub const GpuRenderPass = opaque {};
pub const GpuTexture = opaque {};
pub const GpuIndexedVertexData = opaque {};
pub const GpuVertexDrawData = opaque {};
pub const GpuPixelDrawData = opaque {};
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

pub const UVec3 = extern struct {
    x: u32 = 1,
    y: u32 = 1,
    z: u32 = 1,
};

pub const Stencil = extern struct {
    test_op: Op = .always,
    fail_op: Op = .always,
    pass_op: Op = .always,
    depth_fail_op: Op = .always,
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
    clear_color: [4]f32 = .{ 0, 0, 0, 1 },
    clear_depth: f32 = 1,
    render_pass: ?*GpuRenderPass = null,
};

pub const ByteSpan = []const u8;

pub const all_mips: u8 = std.math.maxInt(u8);
pub const all_layers: u16 = std.math.maxInt(u16);

pub const CommandBuffer = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        gpuBeginRenderPass: *const fn (*anyopaque, GpuRenderPassDesc) anyerror!void,
        gpuEndRenderPass: *const fn (*anyopaque) anyerror!void,
        gpuSetPipeline: *const fn (*anyopaque, *GpuPipeline) anyerror!void,
        gpuSetIndexedVertexData: *const fn (*anyopaque, *GpuIndexedVertexData) anyerror!void,
        gpuSetVertexDrawData: *const fn (*anyopaque, *GpuVertexDrawData) anyerror!void,
        gpuSetPixelDrawData: *const fn (*anyopaque, *GpuPixelDrawData) anyerror!void,
        gpuDrawIndexedInstanced: *const fn (*anyopaque, u32, u32, i32, u32) anyerror!void,
    };

    pub fn gpuBeginRenderPass(self: CommandBuffer, desc: GpuRenderPassDesc) !void {
        try self.vtable.gpuBeginRenderPass(self.ptr, desc);
    }

    pub fn gpuEndRenderPass(self: CommandBuffer) !void {
        try self.vtable.gpuEndRenderPass(self.ptr);
    }

    pub fn gpuSetPipeline(self: CommandBuffer, pipeline: *GpuPipeline) !void {
        try self.vtable.gpuSetPipeline(self.ptr, pipeline);
    }

    pub fn gpuSetIndexedVertexData(self: CommandBuffer, vertex_data_gpu: *GpuIndexedVertexData) !void {
        try self.vtable.gpuSetIndexedVertexData(self.ptr, vertex_data_gpu);
    }

    pub fn gpuSetVertexDrawData(self: CommandBuffer, data: *GpuVertexDrawData) !void {
        try self.vtable.gpuSetVertexDrawData(self.ptr, data);
    }

    pub fn gpuSetPixelDrawData(self: CommandBuffer, data: *GpuPixelDrawData) !void {
        try self.vtable.gpuSetPixelDrawData(self.ptr, data);
    }

    pub fn gpuDrawIndexedInstanced(self: CommandBuffer, first_index: u32, index_count: u32, vertex_offset: i32, instance_count: u32) !void {
        try self.vtable.gpuDrawIndexedInstanced(self.ptr, first_index, index_count, vertex_offset, instance_count);
    }
};

pub const Interface = struct {
    gpuMalloc: *const fn (bytes: usize, alignment: usize, memory: Memory) ?*anyopaque,
    gpuFree: *const fn (ptr: *anyopaque) void,
    gpuHostToDevicePointer: *const fn (ptr: *anyopaque) ?*anyopaque,

    gpuTextureSizeAlign: *const fn (desc: GpuTextureDesc) GpuTextureSizeAlign,
    gpuCreateTexture: *const fn (desc: GpuTextureDesc, ptr_gpu: *anyopaque) ?*GpuTexture,
    gpuTextureViewDescriptor: *const fn (texture: *GpuTexture, desc: GpuViewDesc) GpuTextureDescriptor,
    gpuRWTextureViewDescriptor: *const fn (texture: *GpuTexture, desc: GpuViewDesc) GpuTextureDescriptor,

    gpuCreateComputePipeline: *const fn (compute_ir: ByteSpan) ?*GpuPipeline,
    gpuCreateGraphicsPipeline: *const fn (vertex_ir: ByteSpan, pixel_ir: ByteSpan, desc: GpuRasterDesc) ?*GpuPipeline,
    gpuCreateGraphicsMeshletPipeline: *const fn (meshlet_ir: ByteSpan, pixel_ir: ByteSpan, desc: GpuRasterDesc) ?*GpuPipeline,
    gpuFreePipeline: *const fn (pipeline: *GpuPipeline) void,

    gpuCreateDepthStencilState: *const fn (desc: GpuDepthStencilDesc) ?*GpuDepthStencilState,
    gpuCreateBlendState: *const fn (desc: GpuBlendDesc) ?*GpuBlendState,
    gpuFreeDepthStencilState: *const fn (state: *GpuDepthStencilState) void,
    gpuFreeBlendState: *const fn (state: *GpuBlendState) void,

    gpuCreateQueue: *const fn () ?*GpuQueue,
    gpuStartCommandRecording: *const fn (queue: *GpuQueue) ?*GpuCommandBuffer,
    gpuSubmit: *const fn (queue: *GpuQueue, command_buffers: []const *GpuCommandBuffer) void,

    gpuCreateSemaphore: *const fn (init_value: u64) ?*GpuSemaphore,
    gpuWaitSemaphore: *const fn (sema: *GpuSemaphore, value: u64) void,
    gpuDestroySemaphore: *const fn (sema: *GpuSemaphore) void,

    gpuMemCpy: *const fn (cb: *GpuCommandBuffer, dest_gpu: *anyopaque, src_gpu: *anyopaque) void,
    gpuCopyToTexture: *const fn (cb: *GpuCommandBuffer, dest_gpu: *anyopaque, src_gpu: *anyopaque, texture: *GpuTexture) void,
    gpuCopyFromTexture: *const fn (cb: *GpuCommandBuffer, dest_gpu: *anyopaque, src_gpu: *anyopaque, texture: *GpuTexture) void,
    gpuSetActiveTextureHeapPtr: *const fn (cb: *GpuCommandBuffer, ptr_gpu: *anyopaque) void,

    gpuBarrier: *const fn (cb: *GpuCommandBuffer, before: Stage, after: Stage, hazards: HazardFlags) void,
    gpuSignalAfter: *const fn (cb: *GpuCommandBuffer, before: Stage, ptr_gpu: *anyopaque, value: u64, signal: Signal) void,
    gpuWaitBefore: *const fn (cb: *GpuCommandBuffer, after: Stage, ptr_gpu: *anyopaque, value: u64, op: Op, hazards: HazardFlags, mask: u64) void,

    gpuSetPipeline: *const fn (cb: *GpuCommandBuffer, pipeline: *GpuPipeline) void,
    gpuSetDepthStencilState: *const fn (cb: *GpuCommandBuffer, state: *GpuDepthStencilState) void,
    gpuSetBlendState: *const fn (cb: *GpuCommandBuffer, state: *GpuBlendState) void,

    gpuDispatch: *const fn (cb: *GpuCommandBuffer, data_gpu: *anyopaque, grid_dimensions: UVec3) void,
    gpuDispatchIndirect: *const fn (cb: *GpuCommandBuffer, data_gpu: *anyopaque, grid_dimensions_gpu: *anyopaque) void,

    gpuBeginRenderPass: *const fn (cb: *GpuCommandBuffer, desc: GpuRenderPassDesc) void,
    gpuEndRenderPass: *const fn (cb: *GpuCommandBuffer) void,

    gpuDrawIndexedInstanced: *const fn (cb: *GpuCommandBuffer, vertex_data_gpu: *anyopaque, pixel_data_gpu: *anyopaque, indices_gpu: *anyopaque, index_count: u32, instance_count: u32) void,
    gpuDrawIndexedInstancedIndirect: *const fn (cb: *GpuCommandBuffer, vertex_data_gpu: *anyopaque, pixel_data_gpu: *anyopaque, indices_gpu: *anyopaque, args_gpu: *anyopaque) void,
    gpuDrawIndexedInstancedIndirectMulti: *const fn (cb: *GpuCommandBuffer, data_vx_gpu: *anyopaque, vx_stride: u32, data_px_gpu: *anyopaque, px_stride: u32, args_gpu: *anyopaque, draw_count_gpu: *anyopaque) void,

    gpuDrawMeshlets: *const fn (cb: *GpuCommandBuffer, meshlet_data_gpu: *anyopaque, pixel_data_gpu: *anyopaque, dim: UVec3) void,
    gpuDrawMeshletsIndirect: *const fn (cb: *GpuCommandBuffer, meshlet_data_gpu: *anyopaque, pixel_data_gpu: *anyopaque, dim_gpu: *anyopaque) void,
};
