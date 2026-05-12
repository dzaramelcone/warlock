const Device = @import("Device.zig");
const render_resources = @import("../../../render/resources.zig");
const memory_core = @import("memory.zig");
const vk = @import("../c.zig");
    device: Device,
    image: vk.Image,
    memory: vk.DeviceMemory,
    view: vk.ImageView,
    sampler: vk.Sampler,
    layout: vk.DescriptorSetLayout,
    pool: vk.DescriptorPool,
    set: vk.DescriptorSet,

    const Self = @This();

    pub fn create(device: Device, texture: render_resources.TextureBytes) !Self {
        if (texture.width == 0 or texture.height == 0) return error.VulkanTextureInvalidDimensions;
        if (texture.levels.len == 0) return error.VulkanTextureMissingMipLevels;
        if (texture.levels[0].width != texture.width or texture.levels[0].height != texture.height) return error.VulkanTextureBaseMipMismatch;
        if (!validateTextureMipLevels(texture)) return error.VulkanTextureInvalidMipLevel;
        const create_image = device.context.fns.vkCreateImage orelse return error.VulkanSymbolMissing;
        const destroy_image = device.context.fns.vkDestroyImage orelse return error.VulkanSymbolMissing;
        const get_requirements = device.context.fns.vkGetImageMemoryRequirements orelse return error.VulkanSymbolMissing;
        const allocate_memory = device.context.fns.vkAllocateMemory orelse return error.VulkanSymbolMissing;
        const free_memory = device.context.fns.vkFreeMemory orelse return error.VulkanSymbolMissing;
        const bind_image_memory = device.context.fns.vkBindImageMemory orelse return error.VulkanSymbolMissing;
        const get_subresource_layout = device.context.fns.vkGetImageSubresourceLayout orelse return error.VulkanSymbolMissing;
        const map_memory = device.context.fns.vkMapMemory orelse return error.VulkanSymbolMissing;
        const unmap_memory = device.context.fns.vkUnmapMemory orelse return error.VulkanSymbolMissing;
        const create_image_view = device.context.fns.vkCreateImageView orelse return error.VulkanSymbolMissing;
        const destroy_image_view = device.context.fns.vkDestroyImageView orelse return error.VulkanSymbolMissing;
        const create_sampler = device.context.fns.vkCreateSampler orelse return error.VulkanSymbolMissing;
        const destroy_sampler = device.context.fns.vkDestroySampler orelse return error.VulkanSymbolMissing;
        const create_layout = device.context.fns.vkCreateDescriptorSetLayout orelse return error.VulkanSymbolMissing;
        const destroy_layout = device.context.fns.vkDestroyDescriptorSetLayout orelse return error.VulkanSymbolMissing;
        const create_pool = device.context.fns.vkCreateDescriptorPool orelse return error.VulkanSymbolMissing;
        const destroy_pool = device.context.fns.vkDestroyDescriptorPool orelse return error.VulkanSymbolMissing;
        const allocate_sets = device.context.fns.vkAllocateDescriptorSets orelse return error.VulkanSymbolMissing;
        const update_sets = device.context.fns.vkUpdateDescriptorSets orelse return error.VulkanSymbolMissing;

        var image_info = vk.ImageCreateInfo{
            .sType = vk.STRUCTURE_TYPE_IMAGE_CREATE_INFO,
            .imageType = vk.IMAGE_TYPE_2D,
            .format = vk.FORMAT_R8G8B8A8_UNORM,
            .extent = .{ .width = texture.width, .height = texture.height, .depth = 1 },
            .mipLevels = @intCast(texture.levels.len),
            .arrayLayers = 1,
            .samples = vk.SAMPLE_COUNT_1_BIT,
            .tiling = vk.IMAGE_TILING_LINEAR,
            .usage = vk.IMAGE_USAGE_SAMPLED_BIT,
            .sharingMode = vk.SHARING_MODE_EXCLUSIVE,
            .initialLayout = vk.IMAGE_LAYOUT_PREINITIALIZED,
        };
        var image: vk.Image = undefined;
        if (create_image(device.device, &image_info, null, &image) != vk.SUCCESS) return error.VulkanCreateTextureImageFailed;
        errdefer destroy_image(device.device, image, null);

        var requirements: vk.MemoryRequirements = undefined;
        get_requirements(device.device, image, &requirements);
        const memory_type_index = memory_core.findType(device.context.memory_types, requirements.memoryTypeBits, vk.MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.MEMORY_PROPERTY_HOST_COHERENT_BIT) orelse return error.NoSuitableVulkanTextureMemoryType;
        var allocate_info = vk.MemoryAllocateInfo{
            .sType = vk.STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
            .allocationSize = requirements.size,
            .memoryTypeIndex = memory_type_index,
        };
        var memory: vk.DeviceMemory = undefined;
        if (allocate_memory(device.device, &allocate_info, null, &memory) != vk.SUCCESS) return error.VulkanAllocateTextureMemoryFailed;
        errdefer free_memory(device.device, memory, null);
        if (bind_image_memory(device.device, image, memory, 0) != vk.SUCCESS) return error.VulkanBindTextureMemoryFailed;

        var mapped: ?*anyopaque = null;
        if (map_memory(device.device, memory, 0, requirements.size, 0, &mapped) != vk.SUCCESS) return error.VulkanMapTextureMemoryFailed;
        {
            defer unmap_memory(device.device, memory);
            const bytes: [*]u8 = @ptrCast(mapped orelse return error.VulkanMappedTextureMemoryNull);
            for (texture.levels, 0..) |level, mip_index| {
                const subresource = vk.ImageSubresource{
                    .aspectMask = vk.IMAGE_ASPECT_COLOR_BIT,
                    .mipLevel = @intCast(mip_index),
                    .arrayLayer = 0,
                };
                var layout_info: vk.SubresourceLayout = undefined;
                get_subresource_layout(device.device, image, &subresource, &layout_info);
                copyTextureLevelRows(bytes + @as(usize, @intCast(layout_info.offset)), layout_info.rowPitch, texture, level);
            }
        }

        var view_info = vk.ImageViewCreateInfo{
            .sType = vk.STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .image = image,
            .viewType = vk.IMAGE_VIEW_TYPE_2D,
            .format = vk.FORMAT_R8G8B8A8_UNORM,
            .subresourceRange = .{
                .aspectMask = vk.IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = @intCast(texture.levels.len),
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
        };
        var view: vk.ImageView = undefined;
        if (create_image_view(device.device, &view_info, null, &view) != vk.SUCCESS) return error.VulkanCreateTextureImageViewFailed;
        errdefer destroy_image_view(device.device, view, null);

        var sampler_info = vk.SamplerCreateInfo{
            .sType = vk.STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
            .magFilter = textureFilter(texture.mag_filter),
            .minFilter = textureFilter(texture.min_filter),
            .mipmapMode = textureMipmapMode(texture.mipmap_mode),
            .addressModeU = textureAddressMode(texture.address_mode),
            .addressModeV = textureAddressMode(texture.address_mode),
            .addressModeW = textureAddressMode(texture.address_mode),
            .maxLod = @floatFromInt(texture.levels.len - 1),
        };
        var sampler: vk.Sampler = undefined;
        if (create_sampler(device.device, &sampler_info, null, &sampler) != vk.SUCCESS) return error.VulkanCreateTextureSamplerFailed;
        errdefer destroy_sampler(device.device, sampler, null);

        const binding = vk.DescriptorSetLayoutBinding{
            .binding = 0,
            .descriptorType = vk.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .descriptorCount = 1,
            .stageFlags = vk.SHADER_STAGE_FRAGMENT_BIT,
        };
        var descriptor_layout_info = vk.DescriptorSetLayoutCreateInfo{
            .sType = vk.STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
            .bindingCount = 1,
            .pBindings = @ptrCast(&binding),
        };
        var descriptor_layout: vk.DescriptorSetLayout = undefined;
        if (create_layout(device.device, &descriptor_layout_info, null, &descriptor_layout) != vk.SUCCESS) return error.VulkanCreateTextureDescriptorSetLayoutFailed;
        errdefer destroy_layout(device.device, descriptor_layout, null);

        const pool_size = vk.DescriptorPoolSize{ .type = vk.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1 };
        var pool_info = vk.DescriptorPoolCreateInfo{
            .sType = vk.STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .maxSets = 1,
            .poolSizeCount = 1,
            .pPoolSizes = @ptrCast(&pool_size),
        };
        var pool: vk.DescriptorPool = undefined;
        if (create_pool(device.device, &pool_info, null, &pool) != vk.SUCCESS) return error.VulkanCreateTextureDescriptorPoolFailed;
        errdefer destroy_pool(device.device, pool, null);

        var set_allocate_info = vk.DescriptorSetAllocateInfo{
            .sType = vk.STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = pool,
            .descriptorSetCount = 1,
            .pSetLayouts = @ptrCast(&descriptor_layout),
        };
        var set: vk.DescriptorSet = undefined;
        if (allocate_sets(device.device, &set_allocate_info, @ptrCast(&set)) != vk.SUCCESS) return error.VulkanAllocateTextureDescriptorSetFailed;

        const image_descriptor = vk.DescriptorImageInfo{
            .sampler = sampler,
            .imageView = view,
            .imageLayout = vk.IMAGE_LAYOUT_GENERAL,
        };
        const write = vk.WriteDescriptorSet{
            .sType = vk.STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = set,
            .dstBinding = 0,
            .descriptorCount = 1,
            .descriptorType = vk.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .pImageInfo = @ptrCast(&image_descriptor),
        };
        update_sets(device.device, 1, @ptrCast(&write), 0, null);

        return .{
            .device = device,
            .image = image,
            .memory = memory,
            .view = view,
            .sampler = sampler,
            .layout = descriptor_layout,
            .pool = pool,
            .set = set,
        };
    }

    pub fn deinit(self: Self) void {
        if (self.device.context.fns.vkDestroyDescriptorPool) |destroy_pool| destroy_pool(self.device.device, self.pool, null);
        if (self.device.context.fns.vkDestroyDescriptorSetLayout) |destroy_layout| destroy_layout(self.device.device, self.layout, null);
        if (self.device.context.fns.vkDestroySampler) |destroy_sampler| destroy_sampler(self.device.device, self.sampler, null);
        if (self.device.context.fns.vkDestroyImageView) |destroy_view| destroy_view(self.device.device, self.view, null);
        if (self.device.context.fns.vkDestroyImage) |destroy_image| destroy_image(self.device.device, self.image, null);
        if (self.device.context.fns.vkFreeMemory) |free_memory| free_memory(self.device.device, self.memory, null);
    }

    fn validateTextureMipLevels(texture: render_resources.TextureBytes) bool {
        for (texture.levels, 0..) |level, i| {
            const expected_width = @max(@as(u32, 1), texture.width >> @intCast(i));
            const expected_height = @max(@as(u32, 1), texture.height >> @intCast(i));
            if (level.width != expected_width or level.height != expected_height) return false;
            if (level.len != @as(usize, level.width) * @as(usize, level.height) * 4) return false;
            if (level.offset > texture.rgba.len or level.len > texture.rgba.len - level.offset) return false;
        }
        return true;
    }

    fn copyTextureLevelRows(bytes: [*]u8, row_pitch: u64, texture: render_resources.TextureBytes, level: render_resources.TextureBytes.Level) void {
        const width: usize = @intCast(level.width);
        const height: usize = @intCast(level.height);
        const row_len = width * 4;
        const level_bytes = texture.rgba[level.offset..][0..level.len];
        for (0..height) |y| {
            const row = bytes[y * @as(usize, @intCast(row_pitch)) ..];
            const source = level_bytes[y * row_len ..][0..row_len];
            @memcpy(row[0..row_len], source);
        }
    }

    fn textureFilter(filter: render_resources.TextureBytes.Filter) u32 {
        return switch (filter) {
            .nearest => vk.FILTER_NEAREST,
            .linear => vk.FILTER_LINEAR,
        };
    }

    fn textureMipmapMode(mode: render_resources.TextureBytes.MipmapMode) u32 {
        return switch (mode) {
            .nearest => vk.SAMPLER_MIPMAP_MODE_NEAREST,
            .linear => vk.SAMPLER_MIPMAP_MODE_LINEAR,
        };
    }

    fn textureAddressMode(mode: render_resources.TextureBytes.AddressMode) u32 {
        return switch (mode) {
            .repeat => vk.SAMPLER_ADDRESS_MODE_REPEAT,
            .clamp_to_edge => vk.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
        };
    }
