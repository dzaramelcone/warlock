const std = @import("std");
pub const Api = @import("../api.zig");
const config = @import("../../config.zig");
const platform = @import("../../platform/mod.zig");
const gpu_scene = @import("../scene_data.zig");
const render_resources = @import("../../render/resources.zig");
const commands = @import("commands.zig");
const memory_core = @import("core/memory.zig");
const queue_core = @import("core/queues.zig");
const swapchain_info = @import("core/swapchain_info.zig");
const vk = @import("c.zig");
const util = @import("util.zig");
const loader = @import("loader.zig");

pub const MemoryTypeInfo = memory_core.TypeInfo;
pub const QueueFamilySelection = queue_core.Selection;
pub const SwapchainInfo = swapchain_info.Info;

pub const Context = @import("core/Context.zig");
pub const Surface = @import("core/Surface.zig");

pub const Device = @import("core/Device.zig");
pub const SceneBuffers = @import("core/SceneBuffers.zig");

const TextureBinding = @import("core/TextureBinding.zig");
pub const SceneResources = @import("core/SceneResources.zig");
pub const GraphicsCommands = commands.Commands;

pub const ScenePipeline = @import("core/ScenePipeline.zig");
const DepthImage = @import("core/DepthImage.zig");

const ShaderModule = @import("core/ShaderModule.zig");

pub const HostBuffer = @import("core/HostBuffer.zig");

pub const Presenter = @import("present/Presenter.zig");

pub const Graphics = struct {
    allocator: std.mem.Allocator,
    context: *Context,
    surface: Surface,
    device: Device,
    presenter_impl: Presenter,

    pub fn init(allocator: std.mem.Allocator, window: platform.Window) !Graphics {
        const context = try allocator.create(Context);
        errdefer allocator.destroy(context);
        context.* = try Context.init(allocator);
        errdefer context.deinit();

        const surface = try createSurface(context, window);
        errdefer surface.deinit();

        const queues = try context.findQueueFamilies(surface);
        const device = try Device.create(context, queues);
        errdefer device.deinit();

        var initial_swapchain = try device.createSwapchain(surface);
        errdefer initial_swapchain.deinit();
        const initial_frame_resources = try device.createFrameResources(initial_swapchain.info.image_count);
        var initial_presenter = Presenter{ .swapchain = initial_swapchain, .frame_resources = initial_frame_resources };
        errdefer initial_presenter.deinit();

        return .{
            .allocator = allocator,
            .context = context,
            .surface = surface,
            .device = device,
            .presenter_impl = initial_presenter,
        };
    }

    pub fn deinit(self: *Graphics) void {
        self.presenter_impl.deinit();
        self.device.deinit();
        self.surface.deinit();
        self.context.deinit();
        self.allocator.destroy(self.context);
    }

    pub fn waitIdle(self: *Graphics) !void {
        try self.device.waitIdle();
    }

    pub fn deviceName(self: *Graphics) []const u8 {
        return self.context.device_name;
    }

    pub fn presenter(self: *Graphics) *Presenter {
        return &self.presenter_impl;
    }

    pub fn recreatePresentation(self: *Graphics) !void {
        try self.device.waitIdle();
        var next_swapchain = try self.device.createSwapchainReplacing(self.surface, self.presenter_impl.swapchain.swapchain);
        errdefer next_swapchain.deinit();
        const next_frame_resources = try self.device.createFrameResources(next_swapchain.info.image_count);
        var next_presenter = Presenter{ .swapchain = next_swapchain, .frame_resources = next_frame_resources };
        errdefer next_presenter.deinit();
        self.presenter_impl.deinit();
        self.presenter_impl = next_presenter;
    }

    pub fn createSceneResources(
        self: *Graphics,
        packet: gpu_scene.Packet,
        shaders: []const render_resources.ShaderBytes,
        texture: render_resources.TextureBytes,
    ) !SceneResources {
        if (shaders.len == 0) return error.VulkanMissingSceneShader;
        var texture_binding = try TextureBinding.create(self.device, texture);
        errdefer texture_binding.deinit();

        const pipelines = try self.context.allocator.alloc(ScenePipeline, shaders.len);
        errdefer self.context.allocator.free(pipelines);
        var pipeline_count: usize = 0;
        errdefer {
            for (pipelines[0..pipeline_count]) |pipeline| pipeline.deinit();
        }
        for (shaders, pipelines) |shader, *pipeline| {
            pipeline.* = try ScenePipeline.create(self.device, self.presenter_impl.swapchain, shader, texture_binding.layout, texture_binding.set);
            pipeline_count += 1;
        }
        var buffers = try self.createSceneBuffers(packet);
        errdefer buffers.deinit();
        return .{
            .pipelines = pipelines,
            .buffers = buffers,
            .texture_binding = texture_binding,
        };
    }

    fn createSceneBuffers(self: *Graphics, packet: gpu_scene.Packet) !SceneBuffers {
        var vertex_buffer = try HostBuffer.create(self.device, @sizeOf(gpu_scene.Vertex) * packet.vertices.len, vk.BUFFER_USAGE_VERTEX_BUFFER_BIT);
        errdefer vertex_buffer.deinit();
        var index_buffer = try HostBuffer.create(self.device, @sizeOf(u32) * packet.indices.len, vk.BUFFER_USAGE_INDEX_BUFFER_BIT);
        errdefer index_buffer.deinit();
        var vertex_draw_buffer = try HostBuffer.create(self.device, @sizeOf(gpu_scene.VertexDrawData) * packet.vertex_draws.len, vk.BUFFER_USAGE_STORAGE_BUFFER_BIT);
        errdefer vertex_draw_buffer.deinit();
        var pixel_draw_buffer = try HostBuffer.create(self.device, @sizeOf(gpu_scene.PixelDrawData) * packet.pixel_draws.len, vk.BUFFER_USAGE_STORAGE_BUFFER_BIT);
        errdefer pixel_draw_buffer.deinit();
        var draw_buffer = try HostBuffer.create(self.device, @sizeOf(gpu_scene.Draw) * packet.draws.len, vk.BUFFER_USAGE_STORAGE_BUFFER_BIT);
        errdefer draw_buffer.deinit();
        const draw_data = try self.context.allocator.dupe(gpu_scene.Draw, packet.draws);
        errdefer self.context.allocator.free(draw_data);
        const vertex_draw_data = try self.context.allocator.dupe(gpu_scene.VertexDrawData, packet.vertex_draws);
        errdefer self.context.allocator.free(vertex_draw_data);
        const pixel_draw_data = try self.context.allocator.dupe(gpu_scene.PixelDrawData, packet.pixel_draws);
        errdefer self.context.allocator.free(pixel_draw_data);

        try vertex_buffer.write(gpu_scene.Vertex, packet.vertices);
        try index_buffer.write(u32, packet.indices);
        try draw_buffer.write(gpu_scene.Draw, draw_data);
        try vertex_draw_buffer.write(gpu_scene.VertexDrawData, vertex_draw_data);
        try pixel_draw_buffer.write(gpu_scene.PixelDrawData, pixel_draw_data);

        return .{
            .vertex_buffer = vertex_buffer,
            .index_buffer = index_buffer,
            .draw_buffer = draw_buffer,
            .draw_data = draw_data,
            .vertex_draw_buffer = vertex_draw_buffer,
            .vertex_draw_data = vertex_draw_data,
            .pixel_draw_buffer = pixel_draw_buffer,
            .pixel_draw_data = pixel_draw_data,
            .vertex_count = @intCast(packet.vertices.len),
            .index_count = @intCast(packet.indices.len),
            .draw_count = @intCast(packet.draws.len),
        };
    }

    fn createSurface(context: *Context, window: platform.Window) !Surface {
        const handle = window.nativeHandle();
        return try context.createWin32Surface(handle.hinstance, handle.hwnd);
    }
};

pub const Swapchain = @import("present/Swapchain.zig");
pub const FrameResources = @import("present/FrameResources.zig");
pub const FrameResource = FrameResources.Resource;
pub const Frame = FrameResources.Frame;
pub const ClearPresentResult = FrameResources.PresentResult;
