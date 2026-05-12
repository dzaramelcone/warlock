const std = @import("std");
const config = @import("../../config.zig");
const vk = @import("c.zig");

pub fn chooseSurfaceFormat(formats: []const vk.SurfaceFormatKHR) vk.SurfaceFormatKHR {
    for (formats) |format| {
        if (format.format == vk.FORMAT_B8G8R8A8_UNORM and format.colorSpace == vk.COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return format;
        }
    }
    for (formats) |format| {
        if (format.format == vk.FORMAT_R8G8B8A8_UNORM and format.colorSpace == vk.COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return format;
        }
    }
    return formats[0];
}

pub fn choosePresentMode(present_modes: []const u32) u32 {
    for (present_modes) |present_mode| {
        if (present_mode == vk.PRESENT_MODE_FIFO_KHR) return present_mode;
    }
    return vk.PRESENT_MODE_FIFO_KHR;
}

pub fn chooseExtent(capabilities: vk.SurfaceCapabilitiesKHR) vk.Extent2D {
    if (capabilities.currentExtent.width != vk.UINT32_MAX) return capabilities.currentExtent;
    return .{
        .width = std.math.clamp(@as(u32, config.WIDTH), capabilities.minImageExtent.width, capabilities.maxImageExtent.width),
        .height = std.math.clamp(@as(u32, config.HEIGHT), capabilities.minImageExtent.height, capabilities.maxImageExtent.height),
    };
}

pub fn chooseImageCount(capabilities: vk.SurfaceCapabilitiesKHR) u32 {
    var image_count = capabilities.minImageCount + 1;
    if (capabilities.maxImageCount > 0 and image_count > capabilities.maxImageCount) {
        image_count = capabilities.maxImageCount;
    }
    return image_count;
}

pub fn hasInstanceLayer(allocator: std.mem.Allocator, fns: vk.VulkanFns, name: [*:0]const u8) !bool {
    var count: u32 = 0;
    if (fns.vkEnumerateInstanceLayerProperties(&count, null) != vk.SUCCESS) return error.VulkanEnumerateInstanceLayerCountFailed;
    const layers = try allocator.alloc(vk.LayerProperties, count);
    defer allocator.free(layers);
    if (fns.vkEnumerateInstanceLayerProperties(&count, layers.ptr) != vk.SUCCESS) return error.VulkanEnumerateInstanceLayersFailed;
    for (layers) |layer| {
        const layer_name = std.mem.sliceTo(&layer.layerName, 0);
        if (std.mem.eql(u8, layer_name, std.mem.span(name))) return true;
    }
    return false;
}

pub fn hasInstanceExtension(allocator: std.mem.Allocator, fns: vk.VulkanFns, name: [*:0]const u8) !bool {
    var count: u32 = 0;
    if (fns.vkEnumerateInstanceExtensionProperties(null, &count, null) != vk.SUCCESS) return error.VulkanEnumerateInstanceExtensionCountFailed;
    const extensions = try allocator.alloc(vk.ExtensionProperties, count);
    defer allocator.free(extensions);
    if (fns.vkEnumerateInstanceExtensionProperties(null, &count, extensions.ptr) != vk.SUCCESS) return error.VulkanEnumerateInstanceExtensionsFailed;
    return hasExtensionName(extensions, std.mem.span(name));
}

fn hasExtensionName(extensions: []const vk.ExtensionProperties, name: []const u8) bool {
    for (extensions) |extension| {
        const extension_name = std.mem.sliceTo(&extension.extensionName, 0);
        if (std.mem.eql(u8, extension_name, name)) return true;
    }
    return false;
}

pub fn debugMessengerCreateInfo() vk.DebugUtilsMessengerCreateInfoEXT {
    return .{
        .sType = vk.STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
        .messageSeverity = vk.DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
            vk.DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
        .messageType = vk.DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
            vk.DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
            vk.DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
        .pfnUserCallback = debugMessengerCallback,
    };
}

pub fn createDebugMessenger(
    instance: vk.Instance,
    fns: vk.VulkanFns,
    create_info: vk.DebugUtilsMessengerCreateInfoEXT,
) !vk.DebugUtilsMessengerEXT {
    const create_debug = fns.vkCreateDebugUtilsMessengerEXT orelse return error.VulkanSymbolMissing;
    var messenger: vk.DebugUtilsMessengerEXT = undefined;
    if (create_debug(instance, &create_info, null, &messenger) != vk.SUCCESS) return error.VulkanCreateDebugMessengerFailed;
    return messenger;
}

fn debugMessengerCallback(
    message_severity: u32,
    message_type: u32,
    callback_data: *const vk.DebugUtilsMessengerCallbackDataEXT,
    user_data: ?*anyopaque,
) callconv(.c) vk.Bool32 {
    _ = message_type;
    _ = user_data;
    const level = if ((message_severity & vk.DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) != 0) "error" else "warning";
    std.debug.print("Vulkan validation {s}: {s}\n", .{ level, callback_data.pMessage });
    return vk.FALSE;
}

pub fn pickPhysicalDevice(fns: vk.VulkanFns, devices: []const vk.PhysicalDevice) vk.PhysicalDevice {
    for (devices) |device| {
        var properties: vk.PhysicalDeviceProperties = undefined;
        fns.vkGetPhysicalDeviceProperties(device, &properties);
        if (properties.deviceType == vk.PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) return device;
    }
    for (devices) |device| {
        var properties: vk.PhysicalDeviceProperties = undefined;
        fns.vkGetPhysicalDeviceProperties(device, &properties);
        if (properties.deviceType == vk.PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU) return device;
    }
    return devices[0];
}

