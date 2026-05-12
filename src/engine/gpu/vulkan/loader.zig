const vk = @import("c.zig");

pub fn loadVulkanLibrary() ?HMODULE {
    return LoadLibraryA("vulkan-1.dll");
}

pub fn freeLibrary(lib: HMODULE) void {
    _ = FreeLibrary(lib);
}

pub fn loadFns(lib: HMODULE) !vk.VulkanFns {
    const vkGetInstanceProcAddr = try loadSymbol(vk.PfnGetInstanceProcAddr, lib, "vkGetInstanceProcAddr");
    const vkCreateInstance = try loadSymbol(vk.PfnCreateInstance, lib, "vkCreateInstance");
    return .{
        .vkCreateInstance = vkCreateInstance,
        .vkEnumerateInstanceLayerProperties = try loadSymbol(vk.PfnEnumerateInstanceLayerProperties, lib, "vkEnumerateInstanceLayerProperties"),
        .vkEnumerateInstanceExtensionProperties = try loadSymbol(vk.PfnEnumerateInstanceExtensionProperties, lib, "vkEnumerateInstanceExtensionProperties"),
        .vkGetInstanceProcAddr = vkGetInstanceProcAddr,
        .vkDestroyInstance = try loadGlobalOrInstance(vk.PfnDestroyInstance, lib, vkGetInstanceProcAddr, "vkDestroyInstance"),
        .vkEnumeratePhysicalDevices = try loadGlobalOrInstance(vk.PfnEnumeratePhysicalDevices, lib, vkGetInstanceProcAddr, "vkEnumeratePhysicalDevices"),
        .vkGetPhysicalDeviceProperties = try loadGlobalOrInstance(vk.PfnGetPhysicalDeviceProperties, lib, vkGetInstanceProcAddr, "vkGetPhysicalDeviceProperties"),
        .vkGetPhysicalDeviceMemoryProperties = try loadGlobalOrInstance(vk.PfnGetPhysicalDeviceMemoryProperties, lib, vkGetInstanceProcAddr, "vkGetPhysicalDeviceMemoryProperties"),
        .vkGetPhysicalDeviceQueueFamilyProperties = try loadGlobalOrInstance(vk.PfnGetPhysicalDeviceQueueFamilyProperties, lib, vkGetInstanceProcAddr, "vkGetPhysicalDeviceQueueFamilyProperties"),
        .vkCreateDevice = try loadGlobalOrInstance(vk.PfnCreateDevice, lib, vkGetInstanceProcAddr, "vkCreateDevice"),
        .vkGetDeviceProcAddr = null,
        .vkDestroyDevice = null,
        .vkDeviceWaitIdle = null,
        .vkGetDeviceQueue = null,
        .vkCreateWin32SurfaceKHR = null,
        .vkDestroySurfaceKHR = null,
        .vkGetPhysicalDeviceSurfaceSupportKHR = null,
        .vkGetPhysicalDeviceSurfaceCapabilitiesKHR = null,
        .vkGetPhysicalDeviceSurfaceFormatsKHR = null,
        .vkGetPhysicalDeviceSurfacePresentModesKHR = null,
        .vkCreateSwapchainKHR = null,
        .vkDestroySwapchainKHR = null,
        .vkGetSwapchainImagesKHR = null,
        .vkCreateImageView = null,
        .vkDestroyImageView = null,
        .vkCreateImage = null,
        .vkDestroyImage = null,
        .vkGetImageMemoryRequirements = null,
        .vkBindImageMemory = null,
        .vkGetImageSubresourceLayout = null,
        .vkCreateCommandPool = null,
        .vkDestroyCommandPool = null,
        .vkAllocateCommandBuffers = null,
        .vkCreateFence = null,
        .vkDestroyFence = null,
        .vkCreateSemaphore = null,
        .vkDestroySemaphore = null,
        .vkCreateBuffer = null,
        .vkDestroyBuffer = null,
        .vkGetBufferMemoryRequirements = null,
        .vkAllocateMemory = null,
        .vkFreeMemory = null,
        .vkBindBufferMemory = null,
        .vkMapMemory = null,
        .vkUnmapMemory = null,
        .vkCreateShaderModule = null,
        .vkDestroyShaderModule = null,
        .vkCreateRenderPass = null,
        .vkDestroyRenderPass = null,
        .vkCreateFramebuffer = null,
        .vkDestroyFramebuffer = null,
        .vkCreatePipelineLayout = null,
        .vkDestroyPipelineLayout = null,
        .vkCreateGraphicsPipelines = null,
        .vkDestroyPipeline = null,
        .vkCreateSampler = null,
        .vkDestroySampler = null,
        .vkCreateDescriptorSetLayout = null,
        .vkDestroyDescriptorSetLayout = null,
        .vkCreateDescriptorPool = null,
        .vkDestroyDescriptorPool = null,
        .vkAllocateDescriptorSets = null,
        .vkUpdateDescriptorSets = null,
        .vkCmdBindDescriptorSets = null,
        .vkWaitForFences = null,
        .vkResetFences = null,
        .vkResetCommandBuffer = null,
        .vkBeginCommandBuffer = null,
        .vkEndCommandBuffer = null,
        .vkCmdPipelineBarrier = null,
        .vkCmdBeginRenderPass = null,
        .vkCmdEndRenderPass = null,
        .vkCmdBindPipeline = null,
        .vkCmdBindVertexBuffers = null,
        .vkCmdBindIndexBuffer = null,
        .vkCmdPushConstants = null,
        .vkCmdDrawIndexed = null,
        .vkQueueSubmit = null,
        .vkAcquireNextImageKHR = null,
        .vkQueuePresentKHR = null,
        .vkCreateDebugUtilsMessengerEXT = null,
        .vkDestroyDebugUtilsMessengerEXT = null,
    };
}

pub const HMODULE = *opaque {};

extern "kernel32" fn LoadLibraryA(lpLibFileName: [*:0]const u8) callconv(.winapi) ?HMODULE;
extern "kernel32" fn GetProcAddress(hModule: HMODULE, lpProcName: [*:0]const u8) callconv(.winapi) ?*const anyopaque;
extern "kernel32" fn FreeLibrary(hLibModule: HMODULE) callconv(.winapi) i32;
extern "kernel32" fn GetEnvironmentVariableA(lpName: [*:0]const u8, lpBuffer: ?[*]u8, nSize: u32) callconv(.winapi) u32;

pub fn isEnvSet(name: [*:0]const u8) bool {
    return GetEnvironmentVariableA(name, null, 0) != 0;
}

fn loadSymbol(comptime T: type, lib: HMODULE, name: [*:0]const u8) !T {
    const raw = GetProcAddress(lib, name) orelse return error.VulkanSymbolMissing;
    return @ptrCast(raw);
}

fn loadGlobalOrInstance(comptime T: type, lib: HMODULE, get_proc_addr: vk.PfnGetInstanceProcAddr, name: [*:0]const u8) !T {
    if (GetProcAddress(lib, name)) |raw| return @ptrCast(raw);
    return @ptrCast(get_proc_addr(null, name) orelse return error.VulkanSymbolMissing);
}
