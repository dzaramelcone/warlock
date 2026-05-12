const memory_core = @import("memory.zig");
const Device = @import("Device.zig");
const vk = @import("../c.zig");

device: Device,
image: vk.Image,
memory: vk.DeviceMemory,
view: vk.ImageView,

const Self = @This();

pub fn create(device: Device, extent: vk.Extent2D) !Self {
    const create_image = device.context.fns.vkCreateImage orelse return error.VulkanSymbolMissing;
    const get_requirements = device.context.fns.vkGetImageMemoryRequirements orelse return error.VulkanSymbolMissing;
    const allocate_memory = device.context.fns.vkAllocateMemory orelse return error.VulkanSymbolMissing;
    const bind_image_memory = device.context.fns.vkBindImageMemory orelse return error.VulkanSymbolMissing;
    const create_image_view = device.context.fns.vkCreateImageView orelse return error.VulkanSymbolMissing;

    var image_info = vk.ImageCreateInfo{
        .sType = vk.STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .imageType = vk.IMAGE_TYPE_2D,
        .format = vk.FORMAT_D32_SFLOAT,
        .extent = .{ .width = extent.width, .height = extent.height, .depth = 1 },
        .mipLevels = 1,
        .arrayLayers = 1,
        .samples = vk.SAMPLE_COUNT_1_BIT,
        .tiling = vk.IMAGE_TILING_OPTIMAL,
        .usage = vk.IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,
        .sharingMode = vk.SHARING_MODE_EXCLUSIVE,
        .initialLayout = vk.IMAGE_LAYOUT_UNDEFINED,
    };
    var image: vk.Image = undefined;
    if (create_image(device.device, &image_info, null, &image) != vk.SUCCESS) return error.VulkanCreateDepthImageFailed;
    errdefer if (device.context.fns.vkDestroyImage) |destroy_image| destroy_image(device.device, image, null);

    var requirements: vk.MemoryRequirements = undefined;
    get_requirements(device.device, image, &requirements);
    const memory_type_index = memory_core.findType(device.context.memory_types, requirements.memoryTypeBits, vk.MEMORY_PROPERTY_DEVICE_LOCAL_BIT) orelse return error.NoSuitableMemoryType;
    var allocate_info = vk.MemoryAllocateInfo{
        .sType = vk.STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = requirements.size,
        .memoryTypeIndex = memory_type_index,
    };
    var memory: vk.DeviceMemory = undefined;
    if (allocate_memory(device.device, &allocate_info, null, &memory) != vk.SUCCESS) return error.VulkanAllocateDepthImageMemoryFailed;
    errdefer if (device.context.fns.vkFreeMemory) |free_memory| free_memory(device.device, memory, null);

    if (bind_image_memory(device.device, image, memory, 0) != vk.SUCCESS) return error.VulkanBindDepthImageMemoryFailed;

    var view_info = vk.ImageViewCreateInfo{
        .sType = vk.STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        .image = image,
        .viewType = vk.IMAGE_VIEW_TYPE_2D,
        .format = vk.FORMAT_D32_SFLOAT,
        .subresourceRange = .{
            .aspectMask = vk.IMAGE_ASPECT_DEPTH_BIT,
            .baseMipLevel = 0,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
    };
    var view: vk.ImageView = undefined;
    if (create_image_view(device.device, &view_info, null, &view) != vk.SUCCESS) return error.VulkanCreateDepthImageViewFailed;

    return .{
        .device = device,
        .image = image,
        .memory = memory,
        .view = view,
    };
}

pub fn deinit(self: Self) void {
    if (self.device.context.fns.vkDestroyImageView) |destroy_image_view| destroy_image_view(self.device.device, self.view, null);
    if (self.device.context.fns.vkDestroyImage) |destroy_image| destroy_image(self.device.device, self.image, null);
    if (self.device.context.fns.vkFreeMemory) |free_memory| free_memory(self.device.device, self.memory, null);
}
