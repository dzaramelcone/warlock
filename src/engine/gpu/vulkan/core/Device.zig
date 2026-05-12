const std = @import("std");
const Context = @import("Context.zig");
const Surface = @import("Surface.zig");
const QueueFamilySelection = @import("queues.zig").Selection;
const Swapchain = @import("../present/Swapchain.zig");
const FrameResources = @import("../present/FrameResources.zig");
const FrameResource = FrameResources.Resource;
const gpu_scene = @import("../../scene_data.zig");
const render_resources = @import("../../../render/resources.zig");
const util = @import("../util.zig");
const vk = @import("../c.zig");

context: *Context,
device: vk.Device,
graphics_queue: vk.Queue,
present_queue: vk.Queue,
queue_families: QueueFamilySelection,

const Self = @This();

pub fn create(context: *Context, queues: QueueFamilySelection) !Self {
    const priority = [_]f32{1.0};
    var queue_create_infos: [2]vk.DeviceQueueCreateInfo = undefined;
    queue_create_infos[0] = .{
        .sType = vk.STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .queueFamilyIndex = queues.graphics,
        .queueCount = 1,
        .pQueuePriorities = &priority,
    };

    var queue_create_info_count: u32 = 1;
    if (!queues.shared()) {
        queue_create_infos[1] = .{
            .sType = vk.STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .queueFamilyIndex = queues.present,
            .queueCount = 1,
            .pQueuePriorities = &priority,
        };
        queue_create_info_count = 2;
    }

    const device_extensions = [_][*:0]const u8{
        "VK_KHR_swapchain",
    };
    var create_info = vk.DeviceCreateInfo{
        .sType = vk.STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = queue_create_info_count,
        .pQueueCreateInfos = &queue_create_infos,
        .enabledExtensionCount = device_extensions.len,
        .ppEnabledExtensionNames = &device_extensions,
    };

    var device: vk.Device = undefined;
    if (context.fns.vkCreateDevice(context.physical_device, &create_info, null, &device) != vk.SUCCESS) return error.VulkanCreateLogicalDeviceFailed;

    context.fns.vkDestroyDevice = @ptrCast(context.fns.vkGetInstanceProcAddr(context.instance, "vkDestroyDevice") orelse return error.VulkanSymbolMissing);
    context.fns.vkDeviceWaitIdle = @ptrCast(context.fns.vkGetInstanceProcAddr(context.instance, "vkDeviceWaitIdle") orelse return error.VulkanSymbolMissing);
    context.fns.vkGetDeviceQueue = @ptrCast(context.fns.vkGetInstanceProcAddr(context.instance, "vkGetDeviceQueue") orelse return error.VulkanSymbolMissing);
    context.fns.vkGetDeviceProcAddr = @ptrCast(context.fns.vkGetInstanceProcAddr(context.instance, "vkGetDeviceProcAddr") orelse return error.VulkanSymbolMissing);
    const get_device_proc_addr = context.fns.vkGetDeviceProcAddr orelse return error.VulkanSymbolMissing;
    context.fns.vkCreateSwapchainKHR = @ptrCast(get_device_proc_addr(device, "vkCreateSwapchainKHR") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroySwapchainKHR = @ptrCast(get_device_proc_addr(device, "vkDestroySwapchainKHR") orelse return error.VulkanSymbolMissing);
    context.fns.vkGetSwapchainImagesKHR = @ptrCast(get_device_proc_addr(device, "vkGetSwapchainImagesKHR") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateImageView = @ptrCast(get_device_proc_addr(device, "vkCreateImageView") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyImageView = @ptrCast(get_device_proc_addr(device, "vkDestroyImageView") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateImage = @ptrCast(get_device_proc_addr(device, "vkCreateImage") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyImage = @ptrCast(get_device_proc_addr(device, "vkDestroyImage") orelse return error.VulkanSymbolMissing);
    context.fns.vkGetImageMemoryRequirements = @ptrCast(get_device_proc_addr(device, "vkGetImageMemoryRequirements") orelse return error.VulkanSymbolMissing);
    context.fns.vkBindImageMemory = @ptrCast(get_device_proc_addr(device, "vkBindImageMemory") orelse return error.VulkanSymbolMissing);
    context.fns.vkGetImageSubresourceLayout = @ptrCast(get_device_proc_addr(device, "vkGetImageSubresourceLayout") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateCommandPool = @ptrCast(get_device_proc_addr(device, "vkCreateCommandPool") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyCommandPool = @ptrCast(get_device_proc_addr(device, "vkDestroyCommandPool") orelse return error.VulkanSymbolMissing);
    context.fns.vkAllocateCommandBuffers = @ptrCast(get_device_proc_addr(device, "vkAllocateCommandBuffers") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateFence = @ptrCast(get_device_proc_addr(device, "vkCreateFence") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyFence = @ptrCast(get_device_proc_addr(device, "vkDestroyFence") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateSemaphore = @ptrCast(get_device_proc_addr(device, "vkCreateSemaphore") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroySemaphore = @ptrCast(get_device_proc_addr(device, "vkDestroySemaphore") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateBuffer = @ptrCast(get_device_proc_addr(device, "vkCreateBuffer") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyBuffer = @ptrCast(get_device_proc_addr(device, "vkDestroyBuffer") orelse return error.VulkanSymbolMissing);
    context.fns.vkGetBufferMemoryRequirements = @ptrCast(get_device_proc_addr(device, "vkGetBufferMemoryRequirements") orelse return error.VulkanSymbolMissing);
    context.fns.vkAllocateMemory = @ptrCast(get_device_proc_addr(device, "vkAllocateMemory") orelse return error.VulkanSymbolMissing);
    context.fns.vkFreeMemory = @ptrCast(get_device_proc_addr(device, "vkFreeMemory") orelse return error.VulkanSymbolMissing);
    context.fns.vkBindBufferMemory = @ptrCast(get_device_proc_addr(device, "vkBindBufferMemory") orelse return error.VulkanSymbolMissing);
    context.fns.vkMapMemory = @ptrCast(get_device_proc_addr(device, "vkMapMemory") orelse return error.VulkanSymbolMissing);
    context.fns.vkUnmapMemory = @ptrCast(get_device_proc_addr(device, "vkUnmapMemory") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateShaderModule = @ptrCast(get_device_proc_addr(device, "vkCreateShaderModule") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyShaderModule = @ptrCast(get_device_proc_addr(device, "vkDestroyShaderModule") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateRenderPass = @ptrCast(get_device_proc_addr(device, "vkCreateRenderPass") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyRenderPass = @ptrCast(get_device_proc_addr(device, "vkDestroyRenderPass") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateFramebuffer = @ptrCast(get_device_proc_addr(device, "vkCreateFramebuffer") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyFramebuffer = @ptrCast(get_device_proc_addr(device, "vkDestroyFramebuffer") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreatePipelineLayout = @ptrCast(get_device_proc_addr(device, "vkCreatePipelineLayout") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyPipelineLayout = @ptrCast(get_device_proc_addr(device, "vkDestroyPipelineLayout") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateGraphicsPipelines = @ptrCast(get_device_proc_addr(device, "vkCreateGraphicsPipelines") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyPipeline = @ptrCast(get_device_proc_addr(device, "vkDestroyPipeline") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateSampler = @ptrCast(get_device_proc_addr(device, "vkCreateSampler") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroySampler = @ptrCast(get_device_proc_addr(device, "vkDestroySampler") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateDescriptorSetLayout = @ptrCast(get_device_proc_addr(device, "vkCreateDescriptorSetLayout") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyDescriptorSetLayout = @ptrCast(get_device_proc_addr(device, "vkDestroyDescriptorSetLayout") orelse return error.VulkanSymbolMissing);
    context.fns.vkCreateDescriptorPool = @ptrCast(get_device_proc_addr(device, "vkCreateDescriptorPool") orelse return error.VulkanSymbolMissing);
    context.fns.vkDestroyDescriptorPool = @ptrCast(get_device_proc_addr(device, "vkDestroyDescriptorPool") orelse return error.VulkanSymbolMissing);
    context.fns.vkAllocateDescriptorSets = @ptrCast(get_device_proc_addr(device, "vkAllocateDescriptorSets") orelse return error.VulkanSymbolMissing);
    context.fns.vkUpdateDescriptorSets = @ptrCast(get_device_proc_addr(device, "vkUpdateDescriptorSets") orelse return error.VulkanSymbolMissing);
    context.fns.vkCmdBindDescriptorSets = @ptrCast(get_device_proc_addr(device, "vkCmdBindDescriptorSets") orelse return error.VulkanSymbolMissing);
    context.fns.vkWaitForFences = @ptrCast(get_device_proc_addr(device, "vkWaitForFences") orelse return error.VulkanSymbolMissing);
    context.fns.vkResetFences = @ptrCast(get_device_proc_addr(device, "vkResetFences") orelse return error.VulkanSymbolMissing);
    context.fns.vkResetCommandBuffer = @ptrCast(get_device_proc_addr(device, "vkResetCommandBuffer") orelse return error.VulkanSymbolMissing);
    context.fns.vkBeginCommandBuffer = @ptrCast(get_device_proc_addr(device, "vkBeginCommandBuffer") orelse return error.VulkanSymbolMissing);
    context.fns.vkEndCommandBuffer = @ptrCast(get_device_proc_addr(device, "vkEndCommandBuffer") orelse return error.VulkanSymbolMissing);
    context.fns.vkCmdPipelineBarrier = @ptrCast(get_device_proc_addr(device, "vkCmdPipelineBarrier") orelse return error.VulkanSymbolMissing);
    context.fns.vkCmdBeginRenderPass = @ptrCast(get_device_proc_addr(device, "vkCmdBeginRenderPass") orelse return error.VulkanSymbolMissing);
    context.fns.vkCmdEndRenderPass = @ptrCast(get_device_proc_addr(device, "vkCmdEndRenderPass") orelse return error.VulkanSymbolMissing);
    context.fns.vkCmdBindPipeline = @ptrCast(get_device_proc_addr(device, "vkCmdBindPipeline") orelse return error.VulkanSymbolMissing);
    context.fns.vkCmdBindVertexBuffers = @ptrCast(get_device_proc_addr(device, "vkCmdBindVertexBuffers") orelse return error.VulkanSymbolMissing);
    context.fns.vkCmdBindIndexBuffer = @ptrCast(get_device_proc_addr(device, "vkCmdBindIndexBuffer") orelse return error.VulkanSymbolMissing);
    context.fns.vkCmdPushConstants = @ptrCast(get_device_proc_addr(device, "vkCmdPushConstants") orelse return error.VulkanSymbolMissing);
    context.fns.vkCmdDrawIndexed = @ptrCast(get_device_proc_addr(device, "vkCmdDrawIndexed") orelse return error.VulkanSymbolMissing);
    context.fns.vkQueueSubmit = @ptrCast(get_device_proc_addr(device, "vkQueueSubmit") orelse return error.VulkanSymbolMissing);
    context.fns.vkAcquireNextImageKHR = @ptrCast(get_device_proc_addr(device, "vkAcquireNextImageKHR") orelse return error.VulkanSymbolMissing);
    context.fns.vkQueuePresentKHR = @ptrCast(get_device_proc_addr(device, "vkQueuePresentKHR") orelse return error.VulkanSymbolMissing);

    const get_device_queue = context.fns.vkGetDeviceQueue orelse return error.VulkanSymbolMissing;
    var graphics_queue: vk.Queue = undefined;
    var present_queue: vk.Queue = undefined;
    get_device_queue(device, queues.graphics, 0, &graphics_queue);
    get_device_queue(device, queues.present, 0, &present_queue);

    return .{
        .context = context,
        .device = device,
        .graphics_queue = graphics_queue,
        .present_queue = present_queue,
        .queue_families = queues,
    };
}

pub fn deinit(self: Self) void {
    self.waitIdle() catch {};
    if (self.context.fns.vkDestroyDevice) |destroy_device| {
        destroy_device(self.device, null);
    }
}

pub fn waitIdle(self: Self) !void {
    const device_wait_idle = self.context.fns.vkDeviceWaitIdle orelse return error.VulkanSymbolMissing;
    if (device_wait_idle(self.device) != vk.SUCCESS) return error.VulkanDeviceWaitIdleFailed;
}

pub fn createSwapchain(self: Self, surface: Surface) !Swapchain {
    return try self.createSwapchainReplacing(surface, null);
}

pub fn createSwapchainReplacing(self: Self, surface: Surface, old_swapchain: ?vk.SwapchainKHR) !Swapchain {
    const caps_fn = self.context.fns.vkGetPhysicalDeviceSurfaceCapabilitiesKHR orelse return error.VulkanSymbolMissing;
    const formats_fn = self.context.fns.vkGetPhysicalDeviceSurfaceFormatsKHR orelse return error.VulkanSymbolMissing;
    const present_modes_fn = self.context.fns.vkGetPhysicalDeviceSurfacePresentModesKHR orelse return error.VulkanSymbolMissing;
    const create_swapchain = self.context.fns.vkCreateSwapchainKHR orelse return error.VulkanSymbolMissing;
    const get_swapchain_images = self.context.fns.vkGetSwapchainImagesKHR orelse return error.VulkanSymbolMissing;
    const create_image_view = self.context.fns.vkCreateImageView orelse return error.VulkanSymbolMissing;

    var capabilities: vk.SurfaceCapabilitiesKHR = undefined;
    if (caps_fn(self.context.physical_device, surface.surface, &capabilities) != vk.SUCCESS) return error.VulkanQuerySurfaceCapabilitiesFailed;

    var format_count: u32 = 0;
    if (formats_fn(self.context.physical_device, surface.surface, &format_count, null) != vk.SUCCESS) return error.VulkanQuerySurfaceFormatCountFailed;
    if (format_count == 0) return error.NoVulkanSurfaceFormats;
    const formats = try self.context.allocator.alloc(vk.SurfaceFormatKHR, format_count);
    defer self.context.allocator.free(formats);
    if (formats_fn(self.context.physical_device, surface.surface, &format_count, formats.ptr) != vk.SUCCESS) return error.VulkanQuerySurfaceFormatsFailed;

    var present_mode_count: u32 = 0;
    if (present_modes_fn(self.context.physical_device, surface.surface, &present_mode_count, null) != vk.SUCCESS) return error.VulkanQueryPresentModeCountFailed;
    if (present_mode_count == 0) return error.NoVulkanPresentModes;
    const present_modes = try self.context.allocator.alloc(u32, present_mode_count);
    defer self.context.allocator.free(present_modes);
    if (present_modes_fn(self.context.physical_device, surface.surface, &present_mode_count, present_modes.ptr) != vk.SUCCESS) return error.VulkanQueryPresentModesFailed;

    const surface_format = util.chooseSurfaceFormat(formats);
    const present_mode = util.choosePresentMode(present_modes);
    const extent = util.chooseExtent(capabilities);
    const image_count = util.chooseImageCount(capabilities);
    const image_usage = vk.IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
    if ((capabilities.supportedUsageFlags & image_usage) != image_usage) return error.UnsupportedSwapchainTransferDst;

    var queue_family_indices = [_]u32{ self.queue_families.graphics, self.queue_families.present };
    var create_info = vk.SwapchainCreateInfoKHR{
        .sType = vk.STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .surface = surface.surface,
        .minImageCount = image_count,
        .imageFormat = surface_format.format,
        .imageColorSpace = surface_format.colorSpace,
        .imageExtent = extent,
        .imageArrayLayers = 1,
        .imageUsage = image_usage,
        .imageSharingMode = if (self.queue_families.shared()) vk.SHARING_MODE_EXCLUSIVE else vk.SHARING_MODE_CONCURRENT,
        .queueFamilyIndexCount = if (self.queue_families.shared()) 0 else 2,
        .pQueueFamilyIndices = if (self.queue_families.shared()) null else &queue_family_indices,
        .preTransform = capabilities.currentTransform,
        .compositeAlpha = vk.COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .presentMode = present_mode,
        .clipped = vk.TRUE,
        .oldSwapchain = old_swapchain,
    };

    var swapchain: vk.SwapchainKHR = undefined;
    const create_result = create_swapchain(self.device, &create_info, null, &swapchain);
    if (create_result != vk.SUCCESS) {
        std.debug.print("vkCreateSwapchainKHR failed result={} extent={}x{} old_swapchain={}\n", .{
            create_result,
            extent.width,
            extent.height,
            old_swapchain != null,
        });
        return error.VulkanCreateSwapchainFailed;
    }

    var actual_image_count: u32 = 0;
    if (get_swapchain_images(self.device, swapchain, &actual_image_count, null) != vk.SUCCESS) return error.VulkanQuerySwapchainImageCountFailed;
    const images = try self.context.allocator.alloc(vk.Image, actual_image_count);
    errdefer self.context.allocator.free(images);
    if (get_swapchain_images(self.device, swapchain, &actual_image_count, images.ptr) != vk.SUCCESS) return error.VulkanQuerySwapchainImagesFailed;
    const image_views = try self.context.allocator.alloc(vk.ImageView, actual_image_count);
    errdefer self.context.allocator.free(image_views);
    const image_layouts = try self.context.allocator.alloc(vk.ImageLayout, actual_image_count);
    errdefer self.context.allocator.free(image_layouts);
    @memset(image_layouts, vk.IMAGE_LAYOUT_UNDEFINED);
    for (images, image_views) |image, *image_view| {
        var image_view_info = vk.ImageViewCreateInfo{
            .sType = vk.STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .image = image,
            .viewType = vk.IMAGE_VIEW_TYPE_2D,
            .format = surface_format.format,
            .subresourceRange = .{
                .aspectMask = vk.IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
        };
        if (create_image_view(self.device, &image_view_info, null, image_view) != vk.SUCCESS) return error.VulkanCreateSwapchainImageViewFailed;
    }

    return .{
        .context = self.context,
        .device = self.device,
        .swapchain = swapchain,
        .images = images,
        .image_views = image_views,
        .image_layouts = image_layouts,
        .info = .{
            .format = surface_format.format,
            .color_space = surface_format.colorSpace,
            .present_mode = present_mode,
            .extent = extent,
            .image_count = actual_image_count,
        },
    };
}

pub fn createFrameResources(self: Self, count: u32) !FrameResources {
    const create_command_pool = self.context.fns.vkCreateCommandPool orelse return error.VulkanSymbolMissing;
    const allocate_command_buffers = self.context.fns.vkAllocateCommandBuffers orelse return error.VulkanSymbolMissing;
    const create_fence = self.context.fns.vkCreateFence orelse return error.VulkanSymbolMissing;
    const create_semaphore = self.context.fns.vkCreateSemaphore orelse return error.VulkanSymbolMissing;

    var command_pool_info = vk.CommandPoolCreateInfo{
        .sType = vk.STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = vk.COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = self.queue_families.graphics,
    };
    var command_pool: vk.CommandPool = undefined;
    if (create_command_pool(self.device, &command_pool_info, null, &command_pool) != vk.SUCCESS) return error.VulkanCreateCommandPoolFailed;

    const frames = try self.context.allocator.alloc(FrameResource, count);
    errdefer self.context.allocator.free(frames);

    var command_buffer_info = vk.CommandBufferAllocateInfo{
        .sType = vk.STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = command_pool,
        .level = vk.COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = count,
    };

    const command_buffers = try self.context.allocator.alloc(vk.CommandBuffer, count);
    defer self.context.allocator.free(command_buffers);
    if (allocate_command_buffers(self.device, &command_buffer_info, command_buffers.ptr) != vk.SUCCESS) return error.VulkanAllocateCommandBuffersFailed;

    var fence_info = vk.FenceCreateInfo{
        .sType = vk.STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .flags = vk.FENCE_CREATE_SIGNALED_BIT,
    };
    var semaphore_info = vk.SemaphoreCreateInfo{
        .sType = vk.STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    for (frames, 0..) |*frame, i| {
        frame.command_buffer = command_buffers[i];
        if (create_fence(self.device, &fence_info, null, &frame.in_flight) != vk.SUCCESS) return error.VulkanCreateFrameFenceFailed;
        if (create_semaphore(self.device, &semaphore_info, null, &frame.image_available) != vk.SUCCESS) return error.VulkanCreateImageAvailableSemaphoreFailed;
        if (create_semaphore(self.device, &semaphore_info, null, &frame.render_finished) != vk.SUCCESS) return error.VulkanCreateRenderFinishedSemaphoreFailed;
    }

    return .{
        .context = self.context,
        .device = self.device,
        .graphics_queue = self.graphics_queue,
        .present_queue = self.present_queue,
        .command_pool = command_pool,
        .frames = frames,
    };
}
