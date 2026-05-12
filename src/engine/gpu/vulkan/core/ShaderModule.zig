const Device = @import("Device.zig");
const vk = @import("../c.zig");

    device: Device,
    module: vk.ShaderModule,

    const Self = @This();

    pub fn create(device: Device, bytes: []const u8) !Self {
        const create_shader_module = device.context.fns.vkCreateShaderModule orelse return error.VulkanSymbolMissing;
        if (bytes.len % 4 != 0) return error.InvalidSpirvSize;
        var info = vk.ShaderModuleCreateInfo{
            .sType = vk.STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
            .codeSize = bytes.len,
            .pCode = @ptrCast(@alignCast(bytes.ptr)),
        };
        var module: vk.ShaderModule = undefined;
        if (create_shader_module(device.device, &info, null, &module) != vk.SUCCESS) return error.VulkanCreateShaderModuleFailed;
        return .{ .device = device, .module = module };
    }

    pub fn deinit(self: Self) void {
        if (self.device.context.fns.vkDestroyShaderModule) |destroy_shader_module| {
            destroy_shader_module(self.device.device, self.module, null);
        }
    }
