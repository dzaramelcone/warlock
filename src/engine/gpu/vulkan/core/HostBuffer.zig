const std = @import("std");
const memory_core = @import("memory.zig");
const Device = @import("Device.zig");
const vk = @import("../c.zig");

device: Device,
buffer: vk.Buffer,
memory: vk.DeviceMemory,
size: usize,

const Self = @This();

pub fn create(device: Device, size: usize, usage: u32) !Self {
    const create_buffer = device.context.fns.vkCreateBuffer orelse return error.VulkanSymbolMissing;
    const get_requirements = device.context.fns.vkGetBufferMemoryRequirements orelse return error.VulkanSymbolMissing;
    const allocate_memory = device.context.fns.vkAllocateMemory orelse return error.VulkanSymbolMissing;
    const bind_buffer_memory = device.context.fns.vkBindBufferMemory orelse return error.VulkanSymbolMissing;

    var buffer_info = vk.BufferCreateInfo{
        .sType = vk.STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = size,
        .usage = usage,
        .sharingMode = vk.SHARING_MODE_EXCLUSIVE,
    };
    var buffer: vk.Buffer = undefined;
    if (create_buffer(device.device, &buffer_info, null, &buffer) != vk.SUCCESS) return error.VulkanCreateBufferFailed;
    errdefer if (device.context.fns.vkDestroyBuffer) |destroy_buffer| destroy_buffer(device.device, buffer, null);

    var requirements: vk.MemoryRequirements = undefined;
    get_requirements(device.device, buffer, &requirements);
    const memory_type_index = memory_core.findType(
        device.context.memory_types,
        requirements.memoryTypeBits,
        vk.MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.MEMORY_PROPERTY_HOST_COHERENT_BIT,
    ) orelse return error.NoSuitableVulkanMemoryType;

    var allocate_info = vk.MemoryAllocateInfo{
        .sType = vk.STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = requirements.size,
        .memoryTypeIndex = memory_type_index,
    };
    var memory: vk.DeviceMemory = undefined;
    if (allocate_memory(device.device, &allocate_info, null, &memory) != vk.SUCCESS) return error.VulkanAllocateBufferMemoryFailed;
    errdefer if (device.context.fns.vkFreeMemory) |free_memory| free_memory(device.device, memory, null);

    if (bind_buffer_memory(device.device, buffer, memory, 0) != vk.SUCCESS) return error.VulkanBindBufferMemoryFailed;
    return .{
        .device = device,
        .buffer = buffer,
        .memory = memory,
        .size = size,
    };
}

pub fn deinit(self: Self) void {
    if (self.device.context.fns.vkDestroyBuffer) |destroy_buffer| destroy_buffer(self.device.device, self.buffer, null);
    if (self.device.context.fns.vkFreeMemory) |free_memory| free_memory(self.device.device, self.memory, null);
}

pub fn write(self: Self, comptime T: type, data: []const T) !void {
    const byte_len = std.mem.sliceAsBytes(data).len;
    if (byte_len > self.size) return error.VulkanBufferTooSmall;
    const map_memory = self.device.context.fns.vkMapMemory orelse return error.VulkanSymbolMissing;
    const unmap_memory = self.device.context.fns.vkUnmapMemory orelse return error.VulkanSymbolMissing;
    var mapped: ?*anyopaque = null;
    if (map_memory(self.device.device, self.memory, 0, byte_len, 0, &mapped) != vk.SUCCESS) return error.VulkanMapBufferMemoryFailed;
    defer unmap_memory(self.device.device, self.memory);
    const bytes: [*]u8 = @ptrCast(mapped orelse return error.VulkanMapMemoryFailed);
    @memcpy(bytes[0..byte_len], std.mem.sliceAsBytes(data));
}
