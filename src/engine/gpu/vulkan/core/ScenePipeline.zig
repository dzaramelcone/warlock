const Api = @import("../../api.zig");
const Device = @import("Device.zig");
const DepthImage = @import("DepthImage.zig");
const ShaderModule = @import("ShaderModule.zig");
const Swapchain = @import("../present/Swapchain.zig");
const gpu_scene = @import("../../scene_data.zig");
const render_resources = @import("../../../render/resources.zig");
const vk = @import("../c.zig");

device: Device,
render_pass: vk.RenderPass,
pipeline_layout: vk.PipelineLayout,
pipeline: vk.Pipeline,
texture_set: vk.DescriptorSet,
framebuffers: []vk.Framebuffer,
depth_images: []DepthImage,

const Self = @This();

pub fn apiRenderPass(self: *Self) *Api.GpuRenderPass {
    return @ptrCast(self);
}

pub fn apiPipeline(self: *Self) *Api.GpuPipeline {
    return @ptrCast(self);
}

pub fn create(device: Device, swapchain: Swapchain, shaders: render_resources.ShaderBytes, texture_layout: vk.DescriptorSetLayout, texture_set: vk.DescriptorSet) !Self {
    const create_render_pass = device.context.fns.vkCreateRenderPass orelse return error.VulkanSymbolMissing;
    const create_framebuffer = device.context.fns.vkCreateFramebuffer orelse return error.VulkanSymbolMissing;
    const create_pipeline_layout = device.context.fns.vkCreatePipelineLayout orelse return error.VulkanSymbolMissing;
    const create_graphics_pipelines = device.context.fns.vkCreateGraphicsPipelines orelse return error.VulkanSymbolMissing;

    const depth_images = try device.context.allocator.alloc(DepthImage, swapchain.image_views.len);
    errdefer device.context.allocator.free(depth_images);
    var depth_image_count: usize = 0;
    errdefer {
        for (depth_images[0..depth_image_count]) |depth_image| {
            depth_image.deinit();
        }
    }
    for (depth_images) |*depth_image| {
        depth_image.* = try DepthImage.create(device, swapchain.info.extent);
        depth_image_count += 1;
    }

    const attachments = [_]vk.AttachmentDescription{
        .{
            .format = swapchain.info.format,
            .samples = vk.SAMPLE_COUNT_1_BIT,
            .loadOp = vk.ATTACHMENT_LOAD_OP_CLEAR,
            .storeOp = vk.ATTACHMENT_STORE_OP_STORE,
            .stencilLoadOp = vk.ATTACHMENT_LOAD_OP_DONT_CARE,
            .stencilStoreOp = vk.ATTACHMENT_STORE_OP_DONT_CARE,
            .initialLayout = vk.IMAGE_LAYOUT_UNDEFINED,
            .finalLayout = vk.IMAGE_LAYOUT_PRESENT_SRC_KHR,
        },
        .{
            .format = vk.FORMAT_D32_SFLOAT,
            .samples = vk.SAMPLE_COUNT_1_BIT,
            .loadOp = vk.ATTACHMENT_LOAD_OP_CLEAR,
            .storeOp = vk.ATTACHMENT_STORE_OP_DONT_CARE,
            .stencilLoadOp = vk.ATTACHMENT_LOAD_OP_DONT_CARE,
            .stencilStoreOp = vk.ATTACHMENT_STORE_OP_DONT_CARE,
            .initialLayout = vk.IMAGE_LAYOUT_UNDEFINED,
            .finalLayout = vk.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        },
    };
    const color_ref = vk.AttachmentReference{
        .attachment = 0,
        .layout = vk.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };
    const depth_ref = vk.AttachmentReference{
        .attachment = 1,
        .layout = vk.IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    };
    const subpass = vk.SubpassDescription{
        .pipelineBindPoint = vk.PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = @ptrCast(&color_ref),
        .pDepthStencilAttachment = &depth_ref,
    };
    const dependency = vk.SubpassDependency{
        .srcSubpass = vk.SUBPASS_EXTERNAL,
        .dstSubpass = 0,
        .srcStageMask = vk.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | vk.PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        .dstStageMask = vk.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | vk.PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        .srcAccessMask = 0,
        .dstAccessMask = vk.ACCESS_COLOR_ATTACHMENT_WRITE_BIT | vk.ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
    };
    var render_pass_info = vk.RenderPassCreateInfo{
        .sType = vk.STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = attachments.len,
        .pAttachments = &attachments,
        .subpassCount = 1,
        .pSubpasses = @ptrCast(&subpass),
        .dependencyCount = 1,
        .pDependencies = @ptrCast(&dependency),
    };
    var render_pass: vk.RenderPass = undefined;
    if (create_render_pass(device.device, &render_pass_info, null, &render_pass) != vk.SUCCESS) return error.VulkanCreateSceneRenderPassFailed;
    errdefer if (device.context.fns.vkDestroyRenderPass) |destroy_render_pass| destroy_render_pass(device.device, render_pass, null);

    const framebuffers = try device.context.allocator.alloc(vk.Framebuffer, swapchain.image_views.len);
    errdefer device.context.allocator.free(framebuffers);
    for (swapchain.image_views, depth_images, framebuffers) |image_view, depth_image, *framebuffer| {
        const framebuffer_attachments = [_]vk.ImageView{ image_view, depth_image.view };
        var framebuffer_info = vk.FramebufferCreateInfo{
            .sType = vk.STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = render_pass,
            .attachmentCount = framebuffer_attachments.len,
            .pAttachments = &framebuffer_attachments,
            .width = swapchain.info.extent.width,
            .height = swapchain.info.extent.height,
            .layers = 1,
        };
        if (create_framebuffer(device.device, &framebuffer_info, null, framebuffer) != vk.SUCCESS) return error.VulkanCreateSceneFramebufferFailed;
    }
    errdefer if (device.context.fns.vkDestroyFramebuffer) |destroy_framebuffer| {
        for (framebuffers) |framebuffer| destroy_framebuffer(device.device, framebuffer, null);
    };

    const push_range = vk.PushConstantRange{
        .stageFlags = vk.SHADER_STAGE_VERTEX_BIT | vk.SHADER_STAGE_FRAGMENT_BIT,
        .offset = 0,
        .size = @sizeOf(gpu_scene.VertexDrawData) + @sizeOf(gpu_scene.PixelDrawData),
    };
    var layout_info = vk.PipelineLayoutCreateInfo{
        .sType = vk.STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .setLayoutCount = 1,
        .pSetLayouts = @ptrCast(&texture_layout),
        .pushConstantRangeCount = 1,
        .pPushConstantRanges = @ptrCast(&push_range),
    };
    var pipeline_layout: vk.PipelineLayout = undefined;
    if (create_pipeline_layout(device.device, &layout_info, null, &pipeline_layout) != vk.SUCCESS) return error.VulkanCreateScenePipelineLayoutFailed;
    errdefer if (device.context.fns.vkDestroyPipelineLayout) |destroy_layout| destroy_layout(device.device, pipeline_layout, null);

    var vertex_shader = try ShaderModule.create(device, shaders.vertex);
    defer vertex_shader.deinit();
    var fragment_shader = try ShaderModule.create(device, shaders.fragment);
    defer fragment_shader.deinit();

    const stages = [_]vk.PipelineShaderStageCreateInfo{
        .{
            .sType = vk.STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = vk.SHADER_STAGE_VERTEX_BIT,
            .module = vertex_shader.module,
            .pName = "main",
        },
        .{
            .sType = vk.STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .stage = vk.SHADER_STAGE_FRAGMENT_BIT,
            .module = fragment_shader.module,
            .pName = "main",
        },
    };
    const binding = vk.VertexInputBindingDescription{
        .binding = 0,
        .stride = @sizeOf(gpu_scene.Vertex),
        .inputRate = vk.VERTEX_INPUT_RATE_VERTEX,
    };
    const attributes = [_]vk.VertexInputAttributeDescription{
        .{
            .location = 0,
            .binding = 0,
            .format = vk.FORMAT_R32G32B32_SFLOAT,
            .offset = @offsetOf(gpu_scene.Vertex, "position"),
        },
        .{
            .location = 1,
            .binding = 0,
            .format = vk.FORMAT_R32G32_SFLOAT,
            .offset = @offsetOf(gpu_scene.Vertex, "uv"),
        },
        .{
            .location = 2,
            .binding = 0,
            .format = vk.FORMAT_R32_UINT,
            .offset = @offsetOf(gpu_scene.Vertex, "color"),
        },
        .{
            .location = 3,
            .binding = 0,
            .format = vk.FORMAT_R32G32B32_SFLOAT,
            .offset = @offsetOf(gpu_scene.Vertex, "barycentric"),
        },
        .{
            .location = 4,
            .binding = 0,
            .format = vk.FORMAT_R32G32B32_SFLOAT,
            .offset = @offsetOf(gpu_scene.Vertex, "edge_mask"),
        },
    };
    var vertex_input = vk.PipelineVertexInputStateCreateInfo{
        .sType = vk.STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .vertexBindingDescriptionCount = 1,
        .pVertexBindingDescriptions = @ptrCast(&binding),
        .vertexAttributeDescriptionCount = attributes.len,
        .pVertexAttributeDescriptions = &attributes,
    };
    var input_assembly = vk.PipelineInputAssemblyStateCreateInfo{
        .sType = vk.STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .topology = vk.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    };
    const viewport = vk.Viewport{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(swapchain.info.extent.width),
        .height = @floatFromInt(swapchain.info.extent.height),
        .minDepth = 0,
        .maxDepth = 1,
    };
    const scissor = vk.Rect2D{
        .offset = .{ .x = 0, .y = 0 },
        .extent = swapchain.info.extent,
    };
    var viewport_state = vk.PipelineViewportStateCreateInfo{
        .sType = vk.STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .viewportCount = 1,
        .pViewports = @ptrCast(&viewport),
        .scissorCount = 1,
        .pScissors = @ptrCast(&scissor),
    };
    var raster = vk.PipelineRasterizationStateCreateInfo{
        .sType = vk.STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .polygonMode = vk.POLYGON_MODE_FILL,
        .cullMode = vk.CULL_MODE_NONE,
        .frontFace = vk.FRONT_FACE_COUNTER_CLOCKWISE,
        .lineWidth = 1,
    };
    var multisample = vk.PipelineMultisampleStateCreateInfo{
        .sType = vk.STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        .rasterizationSamples = vk.SAMPLE_COUNT_1_BIT,
    };
    var depth_stencil = vk.PipelineDepthStencilStateCreateInfo{
        .sType = vk.STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
        .depthTestEnable = vk.TRUE,
        .depthWriteEnable = vk.TRUE,
        .depthCompareOp = vk.COMPARE_OP_LESS,
    };
    const color_blend_attachment = vk.PipelineColorBlendAttachmentState{
        .colorWriteMask = vk.COLOR_COMPONENT_R_BIT | vk.COLOR_COMPONENT_G_BIT | vk.COLOR_COMPONENT_B_BIT | vk.COLOR_COMPONENT_A_BIT,
    };
    var color_blend = vk.PipelineColorBlendStateCreateInfo{
        .sType = vk.STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .attachmentCount = 1,
        .pAttachments = @ptrCast(&color_blend_attachment),
    };
    var pipeline_info = vk.GraphicsPipelineCreateInfo{
        .sType = vk.STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
        .stageCount = stages.len,
        .pStages = &stages,
        .pVertexInputState = &vertex_input,
        .pInputAssemblyState = &input_assembly,
        .pViewportState = &viewport_state,
        .pRasterizationState = &raster,
        .pMultisampleState = &multisample,
        .pDepthStencilState = &depth_stencil,
        .pColorBlendState = &color_blend,
        .layout = pipeline_layout,
        .renderPass = render_pass,
    };
    var pipeline: vk.Pipeline = undefined;
    if (create_graphics_pipelines(device.device, null, 1, @ptrCast(&pipeline_info), null, @ptrCast(&pipeline)) != vk.SUCCESS) return error.VulkanCreateSceneGraphicsPipelineFailed;

    return .{
        .device = device,
        .render_pass = render_pass,
        .pipeline_layout = pipeline_layout,
        .pipeline = pipeline,
        .texture_set = texture_set,
        .framebuffers = framebuffers,
        .depth_images = depth_images,
    };
}

pub fn deinit(self: Self) void {
    if (self.device.context.fns.vkDestroyPipeline) |destroy_pipeline| destroy_pipeline(self.device.device, self.pipeline, null);
    if (self.device.context.fns.vkDestroyPipelineLayout) |destroy_layout| destroy_layout(self.device.device, self.pipeline_layout, null);
    if (self.device.context.fns.vkDestroyFramebuffer) |destroy_framebuffer| {
        for (self.framebuffers) |framebuffer| destroy_framebuffer(self.device.device, framebuffer, null);
    }
    self.device.context.allocator.free(self.framebuffers);
    for (self.depth_images) |depth_image| {
        depth_image.deinit();
    }
    self.device.context.allocator.free(self.depth_images);
    if (self.device.context.fns.vkDestroyRenderPass) |destroy_render_pass| destroy_render_pass(self.device.device, self.render_pass, null);
}
