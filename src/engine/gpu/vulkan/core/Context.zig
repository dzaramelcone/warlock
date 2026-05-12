const std = @import("std");
const Surface = @import("Surface.zig");
const MemoryTypeInfo = @import("memory.zig").TypeInfo;
const QueueFamilySelection = @import("queues.zig").Selection;
const loader = @import("../loader.zig");
const util = @import("../util.zig");
const vk = @import("../c.zig");

allocator: std.mem.Allocator,
lib: loader.HMODULE,
fns: vk.VulkanFns,
instance: vk.Instance,
debug_messenger: ?vk.DebugUtilsMessengerEXT,
validation_enabled: bool,
physical_device: vk.PhysicalDevice,
device_name: []u8,
memory_types: []MemoryTypeInfo,

const Self = @This();

pub fn init(allocator: std.mem.Allocator) !Self {
    const lib = loader.loadVulkanLibrary() orelse return error.VulkanDllNotFound;
    errdefer loader.freeLibrary(lib);

    var fns = try loader.loadFns(lib);
    var app_info = vk.ApplicationInfo{
        .sType = vk.STRUCTURE_TYPE_APPLICATION_INFO,
        .pApplicationName = "warlock",
        .pEngineName = "warlock",
        .apiVersion = vk.API_VERSION_1_0,
    };
    const extensions = [_][*:0]const u8{
        "VK_KHR_surface",
        "VK_KHR_win32_surface",
    };
    const validation_layers = [_][*:0]const u8{
        "VK_LAYER_KHRONOS_validation",
    };
    const debug_extensions = [_][*:0]const u8{
        "VK_KHR_surface",
        "VK_KHR_win32_surface",
        "VK_EXT_debug_utils",
    };
    const validation_requested = loader.isEnvSet("WARLOCK_VK_VALIDATION");
    const validation_enabled = validation_requested and
        try util.hasInstanceLayer(allocator, fns, validation_layers[0]) and
        try util.hasInstanceExtension(allocator, fns, debug_extensions[2]);
    var create_info = vk.InstanceCreateInfo{
        .sType = vk.STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &app_info,
        .enabledLayerCount = if (validation_enabled) validation_layers.len else 0,
        .ppEnabledLayerNames = if (validation_enabled) &validation_layers else null,
        .enabledExtensionCount = if (validation_enabled) debug_extensions.len else extensions.len,
        .ppEnabledExtensionNames = if (validation_enabled) &debug_extensions else &extensions,
    };

    var instance: vk.Instance = undefined;
    if (fns.vkCreateInstance(&create_info, null, &instance) != vk.SUCCESS) return error.VulkanCreateInstanceFailed;
    errdefer fns.vkDestroyInstance(instance, null);
    fns.vkCreateDebugUtilsMessengerEXT = @ptrCast(fns.vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT"));
    fns.vkDestroyDebugUtilsMessengerEXT = @ptrCast(fns.vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT"));
    const debug_messenger = if (validation_enabled and fns.vkCreateDebugUtilsMessengerEXT != null)
        try util.createDebugMessenger(instance, fns, util.debugMessengerCreateInfo())
    else
        null;
    errdefer if (debug_messenger) |messenger| {
        if (fns.vkDestroyDebugUtilsMessengerEXT) |destroy_debug| destroy_debug(instance, messenger, null);
    };
    fns.vkCreateWin32SurfaceKHR = @ptrCast(fns.vkGetInstanceProcAddr(instance, "vkCreateWin32SurfaceKHR") orelse return error.VulkanSymbolMissing);
    fns.vkDestroySurfaceKHR = @ptrCast(fns.vkGetInstanceProcAddr(instance, "vkDestroySurfaceKHR") orelse return error.VulkanSymbolMissing);
    fns.vkGetPhysicalDeviceSurfaceSupportKHR = @ptrCast(fns.vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceSupportKHR") orelse return error.VulkanSymbolMissing);
    fns.vkGetPhysicalDeviceSurfaceCapabilitiesKHR = @ptrCast(fns.vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR") orelse return error.VulkanSymbolMissing);
    fns.vkGetPhysicalDeviceSurfaceFormatsKHR = @ptrCast(fns.vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceFormatsKHR") orelse return error.VulkanSymbolMissing);
    fns.vkGetPhysicalDeviceSurfacePresentModesKHR = @ptrCast(fns.vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfacePresentModesKHR") orelse return error.VulkanSymbolMissing);

    var device_count: u32 = 0;
    if (fns.vkEnumeratePhysicalDevices(instance, &device_count, null) != vk.SUCCESS) return error.VulkanEnumeratePhysicalDeviceCountFailed;
    if (device_count == 0) return error.NoVulkanPhysicalDevice;

    const devices = try allocator.alloc(vk.PhysicalDevice, device_count);
    defer allocator.free(devices);
    if (fns.vkEnumeratePhysicalDevices(instance, &device_count, devices.ptr) != vk.SUCCESS) return error.VulkanEnumeratePhysicalDevicesFailed;

    const physical_device = util.pickPhysicalDevice(fns, devices);
    var properties: vk.PhysicalDeviceProperties = undefined;
    fns.vkGetPhysicalDeviceProperties(physical_device, &properties);

    var memory_properties: vk.PhysicalDeviceMemoryProperties = undefined;
    fns.vkGetPhysicalDeviceMemoryProperties(physical_device, &memory_properties);

    const device_name_len = std.mem.indexOfScalar(u8, &properties.deviceName, 0) orelse properties.deviceName.len;
    const device_name = try allocator.dupe(u8, properties.deviceName[0..device_name_len]);
    errdefer allocator.free(device_name);

    const memory_types = try allocator.alloc(MemoryTypeInfo, memory_properties.memoryTypeCount);
    errdefer allocator.free(memory_types);
    for (memory_types, 0..) |*memory_type, i| {
        const source = memory_properties.memoryTypes[i];
        memory_type.* = .{
            .index = @intCast(i),
            .flags = source.propertyFlags,
        };
    }

    return .{
        .allocator = allocator,
        .lib = lib,
        .fns = fns,
        .instance = instance,
        .debug_messenger = debug_messenger,
        .validation_enabled = validation_enabled,
        .physical_device = physical_device,
        .device_name = device_name,
        .memory_types = memory_types,
    };
}

pub fn deinit(self: *Self) void {
    if (self.debug_messenger) |messenger| {
        if (self.fns.vkDestroyDebugUtilsMessengerEXT) |destroy_debug| {
            destroy_debug(self.instance, messenger, null);
        }
    }
    self.allocator.free(self.memory_types);
    self.allocator.free(self.device_name);
    self.fns.vkDestroyInstance(self.instance, null);
    loader.freeLibrary(self.lib);
}

pub fn createWin32Surface(self: *Self, hinstance: *anyopaque, hwnd: *anyopaque) !Surface {
    var create_info = vk.Win32SurfaceCreateInfoKHR{
        .sType = vk.STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR,
        .hinstance = hinstance,
        .hwnd = hwnd,
    };
    var surface: vk.SurfaceKHR = undefined;
    const create_surface = self.fns.vkCreateWin32SurfaceKHR orelse return error.VulkanSymbolMissing;
    if (create_surface(self.instance, &create_info, null, &surface) != vk.SUCCESS) return error.VulkanCreateWin32SurfaceFailed;
    return .{
        .instance = self.instance,
        .surface = surface,
        .destroy_surface = self.fns.vkDestroySurfaceKHR,
    };
}

pub fn findQueueFamilies(self: *Self, surface: Surface) !QueueFamilySelection {
    var queue_family_count: u32 = 0;
    self.fns.vkGetPhysicalDeviceQueueFamilyProperties(self.physical_device, &queue_family_count, null);
    if (queue_family_count == 0) return error.NoVulkanQueueFamilies;

    const queue_families = try self.allocator.alloc(vk.QueueFamilyProperties, queue_family_count);
    defer self.allocator.free(queue_families);
    self.fns.vkGetPhysicalDeviceQueueFamilyProperties(self.physical_device, &queue_family_count, queue_families.ptr);

    const surface_support = self.fns.vkGetPhysicalDeviceSurfaceSupportKHR orelse return error.VulkanSymbolMissing;
    var graphics: ?u32 = null;
    var present: ?u32 = null;

    for (queue_families, 0..) |queue_family, i| {
        const index: u32 = @intCast(i);
        if (queue_family.queueCount == 0) continue;
        if (graphics == null and (queue_family.queueFlags & vk.QUEUE_GRAPHICS_BIT) != 0) {
            graphics = index;
        }

        var supports_present: vk.Bool32 = 0;
        if (surface_support(self.physical_device, index, surface.surface, &supports_present) != vk.SUCCESS) return error.VulkanQuerySurfaceSupportFailed;
        if (present == null and supports_present != 0) {
            present = index;
        }

        if (graphics == index and supports_present != 0) {
            return .{ .graphics = index, .present = index };
        }
    }

    return .{
        .graphics = graphics orelse return error.NoVulkanGraphicsQueue,
        .present = present orelse return error.NoVulkanPresentQueue,
    };
}
