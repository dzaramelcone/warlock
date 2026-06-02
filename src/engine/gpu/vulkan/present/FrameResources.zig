const Context = @import("../core/Context.zig");
const Swapchain = @import("Swapchain.zig");
const vk = @import("../c.zig");

context: *Context,
device: vk.Device,
graphics_queue: vk.Queue,
present_queue: vk.Queue,
command_pool: vk.CommandPool,
frames: []Resource,

const Self = @This();

pub const Resource = struct {
    command_buffer: vk.CommandBuffer,
    in_flight: vk.Fence,
    image_available: vk.Semaphore,
    render_finished: vk.Semaphore,
};

pub const Frame = struct {
    resource: Resource,
    image_index: u32,
    acquire_result: vk.Result,
};

pub const PresentResult = enum {
    presented,
    suboptimal,
    out_of_date,
};

pub fn deinit(self: Self) void {
    if (self.context.fns.vkDeviceWaitIdle) |wait_idle| _ = wait_idle(self.device);
    if (self.context.fns.vkDestroyFence) |destroy_fence| {
        for (self.frames) |frame| destroy_fence(self.device, frame.in_flight, null);
    }
    if (self.context.fns.vkDestroySemaphore) |destroy_semaphore| {
        for (self.frames) |frame| {
            destroy_semaphore(self.device, frame.image_available, null);
            destroy_semaphore(self.device, frame.render_finished, null);
        }
    }
    self.context.allocator.free(self.frames);
    if (self.context.fns.vkDestroyCommandPool) |destroy_command_pool| {
        destroy_command_pool(self.device, self.command_pool, null);
    }
}

pub fn beginFrame(self: Self, swapchain: *Swapchain, frame_index: usize) !Frame {
    const resource = self.frames[frame_index % self.frames.len];
    const wait_for_fences = self.context.fns.vkWaitForFences orelse return error.VulkanSymbolMissing;
    const reset_fences = self.context.fns.vkResetFences orelse return error.VulkanSymbolMissing;
    const acquire_next_image = self.context.fns.vkAcquireNextImageKHR orelse return error.VulkanSymbolMissing;
    const reset_command_buffer = self.context.fns.vkResetCommandBuffer orelse return error.VulkanSymbolMissing;
    const begin_command_buffer = self.context.fns.vkBeginCommandBuffer orelse return error.VulkanSymbolMissing;

    const fences = [_]vk.Fence{resource.in_flight};
    if (wait_for_fences(self.device, 1, &fences, vk.TRUE, vk.UINT64_MAX) != vk.SUCCESS) return error.VulkanWaitForFrameFenceFailed;

    var image_index: u32 = 0;
    const acquire_result = acquire_next_image(self.device, swapchain.swapchain, vk.UINT64_MAX, resource.image_available, null, &image_index);
    if (acquire_result == vk.ERROR_OUT_OF_DATE_KHR) return error.VulkanSwapchainOutOfDate;
    if (acquire_result != vk.SUCCESS and acquire_result != vk.SUBOPTIMAL_KHR) return error.VulkanAcquireSwapchainImageFailed;
    if (reset_fences(self.device, 1, &fences) != vk.SUCCESS) return error.VulkanResetFrameFenceFailed;
    if (reset_command_buffer(resource.command_buffer, 0) != vk.SUCCESS) return error.VulkanResetCommandBufferFailed;

    var begin_info = vk.CommandBufferBeginInfo{
        .sType = vk.STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
    };
    if (begin_command_buffer(resource.command_buffer, &begin_info) != vk.SUCCESS) return error.VulkanBeginCommandBufferFailed;
    return .{
        .resource = resource,
        .image_index = image_index,
        .acquire_result = acquire_result,
    };
}

pub fn endFrame(
    self: Self,
    swapchain: *Swapchain,
    frame: Frame,
    wait_stage: vk.PipelineStageFlags,
) !PresentResult {
    const end_command_buffer = self.context.fns.vkEndCommandBuffer orelse return error.VulkanSymbolMissing;
    const queue_submit = self.context.fns.vkQueueSubmit orelse return error.VulkanSymbolMissing;
    const queue_present = self.context.fns.vkQueuePresentKHR orelse return error.VulkanSymbolMissing;

    if (end_command_buffer(frame.resource.command_buffer) != vk.SUCCESS) return error.VulkanEndCommandBufferFailed;

    const wait_semaphores = [_]vk.Semaphore{frame.resource.image_available};
    const wait_stages = [_]vk.PipelineStageFlags{wait_stage};
    const command_buffers = [_]vk.CommandBuffer{frame.resource.command_buffer};
    const signal_semaphores = [_]vk.Semaphore{frame.resource.render_finished};
    var submit_info = vk.SubmitInfo{
        .sType = vk.STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &wait_semaphores,
        .pWaitDstStageMask = &wait_stages,
        .commandBufferCount = 1,
        .pCommandBuffers = &command_buffers,
        .signalSemaphoreCount = 1,
        .pSignalSemaphores = &signal_semaphores,
    };
    if (queue_submit(self.graphics_queue, 1, @ptrCast(&submit_info), frame.resource.in_flight) != vk.SUCCESS) return error.VulkanSubmitFrameFailed;

    const swapchains = [_]vk.SwapchainKHR{swapchain.swapchain};
    var present_info = vk.PresentInfoKHR{
        .sType = vk.STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &signal_semaphores,
        .swapchainCount = 1,
        .pSwapchains = &swapchains,
        .pImageIndices = @ptrCast(&frame.image_index),
    };
    const present_result = queue_present(self.present_queue, &present_info);
    if (present_result == vk.ERROR_OUT_OF_DATE_KHR) return .out_of_date;
    if (present_result == vk.SUBOPTIMAL_KHR or frame.acquire_result == vk.SUBOPTIMAL_KHR) return .suboptimal;
    if (present_result != vk.SUCCESS) return error.VulkanPresentFrameFailed;
    return .presented;
}
