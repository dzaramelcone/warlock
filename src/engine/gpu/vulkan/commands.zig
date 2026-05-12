const Context = @import("core/Context.zig");
const FrameResources = @import("present/FrameResources.zig");
const SceneBuffers = @import("core/SceneBuffers.zig");
const ScenePipeline = @import("core/ScenePipeline.zig");
const Swapchain = @import("present/Swapchain.zig");
const vk = @import("c.zig");
const gpu_scene = @import("../scene_data.zig");

pub const Commands = @This();
const Frame = FrameResources.Frame;

context: *Context,
device: vk.Device,
frame: *Frame,
swapchain: *Swapchain,
pipeline_layout: ?vk.PipelineLayout = null,

const Self = @This();

pub fn beginRenderPass(self: *Self, scene_pipeline: *ScenePipeline, clear_color: [4]f32) !void {
    const cmd_begin_render_pass = self.context.fns.vkCmdBeginRenderPass orelse return error.VulkanSymbolMissing;
    const clear_values = [_]vk.ClearValue{
        .{ .color = .{ .float32 = clear_color } },
        .{ .depthStencil = .{ .depth = 1.0, .stencil = 0 } },
    };
    var render_pass_begin = vk.RenderPassBeginInfo{
        .sType = vk.STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = scene_pipeline.render_pass,
        .framebuffer = scene_pipeline.framebuffers[self.frame.image_index],
        .renderArea = .{
            .offset = .{ .x = 0, .y = 0 },
            .extent = self.swapchain.info.extent,
        },
        .clearValueCount = clear_values.len,
        .pClearValues = &clear_values,
    };
    cmd_begin_render_pass(self.frame.resource.command_buffer, &render_pass_begin, vk.SUBPASS_CONTENTS_INLINE);
}

pub fn endRenderPass(self: *Self) !void {
    const cmd_end_render_pass = self.context.fns.vkCmdEndRenderPass orelse return error.VulkanSymbolMissing;
    cmd_end_render_pass(self.frame.resource.command_buffer);
    self.swapchain.image_layouts[self.frame.image_index] = vk.IMAGE_LAYOUT_PRESENT_SRC_KHR;
}

pub fn setPipeline(self: *Self, scene_pipeline: *ScenePipeline) !void {
    const cmd_bind_pipeline = self.context.fns.vkCmdBindPipeline orelse return error.VulkanSymbolMissing;
    const cmd_bind_descriptor_sets = self.context.fns.vkCmdBindDescriptorSets orelse return error.VulkanSymbolMissing;
    cmd_bind_pipeline(self.frame.resource.command_buffer, vk.PIPELINE_BIND_POINT_GRAPHICS, scene_pipeline.pipeline);
    const sets = [_]vk.DescriptorSet{scene_pipeline.texture_set};
    cmd_bind_descriptor_sets(self.frame.resource.command_buffer, vk.PIPELINE_BIND_POINT_GRAPHICS, scene_pipeline.pipeline_layout, 0, 1, &sets, 0, null);
    self.pipeline_layout = scene_pipeline.pipeline_layout;
}

pub fn setIndexedVertexData(self: *Self, scene_buffers: *SceneBuffers) !void {
    const cmd_bind_vertex_buffers = self.context.fns.vkCmdBindVertexBuffers orelse return error.VulkanSymbolMissing;
    const cmd_bind_index_buffer = self.context.fns.vkCmdBindIndexBuffer orelse return error.VulkanSymbolMissing;
    const vertex_buffers = [_]vk.Buffer{scene_buffers.vertex_buffer.buffer};
    const vertex_offsets = [_]vk.DeviceSize{0};
    cmd_bind_vertex_buffers(self.frame.resource.command_buffer, 0, 1, &vertex_buffers, &vertex_offsets);
    cmd_bind_index_buffer(self.frame.resource.command_buffer, scene_buffers.index_buffer.buffer, 0, vk.INDEX_TYPE_UINT32);
}

pub fn setVertexDrawData(self: *Self, data: *const gpu_scene.VertexDrawData) !void {
    const layout = self.pipeline_layout orelse return error.VulkanPipelineNotBound;
    const cmd_push_constants = self.context.fns.vkCmdPushConstants orelse return error.VulkanSymbolMissing;
    cmd_push_constants(self.frame.resource.command_buffer, layout, vk.SHADER_STAGE_VERTEX_BIT, 0, @sizeOf(gpu_scene.VertexDrawData), data);
}

pub fn setPixelDrawData(self: *Self, data: *const gpu_scene.PixelDrawData) !void {
    const layout = self.pipeline_layout orelse return error.VulkanPipelineNotBound;
    const cmd_push_constants = self.context.fns.vkCmdPushConstants orelse return error.VulkanSymbolMissing;
    cmd_push_constants(self.frame.resource.command_buffer, layout, vk.SHADER_STAGE_FRAGMENT_BIT, @sizeOf(gpu_scene.VertexDrawData), @sizeOf(gpu_scene.PixelDrawData), data);
}

pub fn drawIndexedInstanced(self: *Self, first_index: u32, index_count: u32, vertex_offset: i32, instance_count: u32) !void {
    const cmd_draw_indexed = self.context.fns.vkCmdDrawIndexed orelse return error.VulkanSymbolMissing;
    cmd_draw_indexed(self.frame.resource.command_buffer, index_count, instance_count, first_index, vertex_offset, 0);
}
