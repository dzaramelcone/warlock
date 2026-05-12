const std = @import("std");

pub const SUCCESS: i32 = 0;
pub const SUBOPTIMAL_KHR: i32 = 1000001003;
pub const ERROR_OUT_OF_DATE_KHR: i32 = -1000001004;
pub const MAX_MEMORY_TYPES = 32;
pub const MAX_MEMORY_HEAPS = 16;
pub const PHYSICAL_DEVICE_TYPE_OTHER: u32 = 0;
pub const PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU: u32 = 1;
pub const PHYSICAL_DEVICE_TYPE_DISCRETE_GPU: u32 = 2;
pub const QUEUE_GRAPHICS_BIT: u32 = 0x00000001;
pub const MEMORY_PROPERTY_DEVICE_LOCAL_BIT: u32 = 0x00000001;
pub const MEMORY_PROPERTY_HOST_VISIBLE_BIT: u32 = 0x00000002;
pub const MEMORY_PROPERTY_HOST_COHERENT_BIT: u32 = 0x00000004;
pub const MEMORY_PROPERTY_HOST_CACHED_BIT: u32 = 0x00000008;

pub const Instance = *opaque {};
pub const PhysicalDevice = *opaque {};
pub const Device = *opaque {};
pub const Queue = *opaque {};
pub const SurfaceKHR = *opaque {};
pub const SwapchainKHR = *opaque {};
pub const DebugUtilsMessengerEXT = *opaque {};
pub const Image = *opaque {};
pub const ImageView = *opaque {};
pub const CommandPool = *opaque {};
pub const CommandBuffer = *opaque {};
pub const Fence = *opaque {};
pub const Semaphore = *opaque {};
pub const Buffer = *opaque {};
pub const DeviceMemory = *opaque {};
pub const ShaderModule = *opaque {};
pub const RenderPass = *opaque {};
pub const Framebuffer = *opaque {};
pub const PipelineLayout = *opaque {};
pub const Pipeline = *opaque {};
pub const Sampler = *opaque {};
pub const DescriptorSetLayout = *opaque {};
pub const DescriptorPool = *opaque {};
pub const DescriptorSet = *opaque {};
pub const PipelineStageFlags = u32;
pub const AccessFlags = u32;
pub const ImageLayout = u32;
pub const Result = i32;
pub const Bool32 = u32;
pub const DeviceSize = u64;
pub const QueueFlags = u32;

pub const ApplicationInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    pApplicationName: ?[*:0]const u8 = null,
    applicationVersion: u32 = 0,
    pEngineName: ?[*:0]const u8 = null,
    engineVersion: u32 = 0,
    apiVersion: u32,
};

pub const InstanceCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    pApplicationInfo: ?*const ApplicationInfo = null,
    enabledLayerCount: u32 = 0,
    ppEnabledLayerNames: ?[*]const [*:0]const u8 = null,
    enabledExtensionCount: u32 = 0,
    ppEnabledExtensionNames: ?[*]const [*:0]const u8 = null,
};

pub const LayerProperties = extern struct {
    layerName: [256]u8,
    specVersion: u32,
    implementationVersion: u32,
    description: [256]u8,
};

pub const ExtensionProperties = extern struct {
    extensionName: [256]u8,
    specVersion: u32,
};

pub const DebugUtilsMessengerCallbackDataEXT = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32,
    pMessageIdName: ?[*:0]const u8,
    messageIdNumber: i32,
    pMessage: [*:0]const u8,
    queueLabelCount: u32,
    pQueueLabels: ?*const anyopaque,
    cmdBufLabelCount: u32,
    pCmdBufLabels: ?*const anyopaque,
    objectCount: u32,
    pObjects: ?*const anyopaque,
};

pub const DebugUtilsMessengerCreateInfoEXT = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    messageSeverity: u32,
    messageType: u32,
    pfnUserCallback: *const fn (u32, u32, *const DebugUtilsMessengerCallbackDataEXT, ?*anyopaque) callconv(.c) Bool32,
    pUserData: ?*anyopaque = null,
};

pub const DeviceQueueCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    queueFamilyIndex: u32,
    queueCount: u32,
    pQueuePriorities: [*]const f32,
};

pub const DeviceCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    queueCreateInfoCount: u32,
    pQueueCreateInfos: [*]const DeviceQueueCreateInfo,
    enabledLayerCount: u32 = 0,
    ppEnabledLayerNames: ?[*]const [*:0]const u8 = null,
    enabledExtensionCount: u32 = 0,
    ppEnabledExtensionNames: ?[*]const [*:0]const u8 = null,
    pEnabledFeatures: ?*const anyopaque = null,
};

pub const PhysicalDeviceProperties = extern struct {
    apiVersion: u32,
    driverVersion: u32,
    vendorID: u32,
    deviceID: u32,
    deviceType: u32,
    deviceName: [256]u8,
    pipelineCacheUUID: [16]u8,
    limits: [520]u8,
    sparseProperties: [20]u8,
};

pub const MemoryHeap = extern struct {
    size: DeviceSize,
    flags: u32,
};

pub const MemoryType = extern struct {
    propertyFlags: u32,
    heapIndex: u32,
};

pub const PhysicalDeviceMemoryProperties = extern struct {
    memoryTypeCount: u32,
    memoryTypes: [MAX_MEMORY_TYPES]MemoryType,
    memoryHeapCount: u32,
    memoryHeaps: [MAX_MEMORY_HEAPS]MemoryHeap,
};

pub const Extent3D = extern struct {
    width: u32,
    height: u32,
    depth: u32,
};

pub const Extent2D = extern struct {
    width: u32,
    height: u32,
};

pub const Offset2D = extern struct { x: i32, y: i32 };
pub const Rect2D = extern struct { offset: Offset2D, extent: Extent2D };
pub const Viewport = extern struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    minDepth: f32,
    maxDepth: f32,
};

pub const SurfaceCapabilitiesKHR = extern struct {
    minImageCount: u32,
    maxImageCount: u32,
    currentExtent: Extent2D,
    minImageExtent: Extent2D,
    maxImageExtent: Extent2D,
    maxImageArrayLayers: u32,
    supportedTransforms: u32,
    currentTransform: u32,
    supportedCompositeAlpha: u32,
    supportedUsageFlags: u32,
};

pub const SurfaceFormatKHR = extern struct {
    format: u32,
    colorSpace: u32,
};

pub const SwapchainCreateInfoKHR = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    surface: SurfaceKHR,
    minImageCount: u32,
    imageFormat: u32,
    imageColorSpace: u32,
    imageExtent: Extent2D,
    imageArrayLayers: u32,
    imageUsage: u32,
    imageSharingMode: u32,
    queueFamilyIndexCount: u32 = 0,
    pQueueFamilyIndices: ?[*]const u32 = null,
    preTransform: u32,
    compositeAlpha: u32,
    presentMode: u32,
    clipped: Bool32,
    oldSwapchain: ?SwapchainKHR = null,
};

pub const ComponentMapping = extern struct {
    r: u32 = COMPONENT_SWIZZLE_IDENTITY,
    g: u32 = COMPONENT_SWIZZLE_IDENTITY,
    b: u32 = COMPONENT_SWIZZLE_IDENTITY,
    a: u32 = COMPONENT_SWIZZLE_IDENTITY,
};

pub const ImageSubresourceRange = extern struct {
    aspectMask: u32,
    baseMipLevel: u32,
    levelCount: u32,
    baseArrayLayer: u32,
    layerCount: u32,
};

pub const ImageViewCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    image: Image,
    viewType: u32,
    format: u32,
    components: ComponentMapping = .{},
    subresourceRange: ImageSubresourceRange,
};

pub const ImageCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    imageType: u32,
    format: u32,
    extent: Extent3D,
    mipLevels: u32,
    arrayLayers: u32,
    samples: u32,
    tiling: u32,
    usage: u32,
    sharingMode: u32,
    queueFamilyIndexCount: u32 = 0,
    pQueueFamilyIndices: ?[*]const u32 = null,
    initialLayout: ImageLayout,
};

pub const CommandPoolCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    queueFamilyIndex: u32,
};

pub const CommandBufferAllocateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    commandPool: CommandPool,
    level: u32,
    commandBufferCount: u32,
};

pub const FenceCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
};

pub const SemaphoreCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
};

pub const CommandBufferBeginInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    pInheritanceInfo: ?*const anyopaque = null,
};

pub const SubmitInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    waitSemaphoreCount: u32 = 0,
    pWaitSemaphores: ?[*]const Semaphore = null,
    pWaitDstStageMask: ?[*]const PipelineStageFlags = null,
    commandBufferCount: u32 = 0,
    pCommandBuffers: ?[*]const CommandBuffer = null,
    signalSemaphoreCount: u32 = 0,
    pSignalSemaphores: ?[*]const Semaphore = null,
};

pub const PresentInfoKHR = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    waitSemaphoreCount: u32 = 0,
    pWaitSemaphores: ?[*]const Semaphore = null,
    swapchainCount: u32 = 0,
    pSwapchains: ?[*]const SwapchainKHR = null,
    pImageIndices: ?[*]const u32 = null,
    pResults: ?[*]Result = null,
};

pub const ClearColorValue = extern union {
    float32: [4]f32,
    int32: [4]i32,
    uint32: [4]u32,
};

pub const ImageSubresourceRangeMutable = extern struct {
    aspectMask: u32,
    baseMipLevel: u32,
    levelCount: u32,
    baseArrayLayer: u32,
    layerCount: u32,
};

pub const ImageMemoryBarrier = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    srcAccessMask: AccessFlags,
    dstAccessMask: AccessFlags,
    oldLayout: ImageLayout,
    newLayout: ImageLayout,
    srcQueueFamilyIndex: u32,
    dstQueueFamilyIndex: u32,
    image: Image,
    subresourceRange: ImageSubresourceRangeMutable,
};

pub const ShaderModuleCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    codeSize: usize,
    pCode: [*]const u32,
};

pub const AttachmentDescription = extern struct {
    flags: u32 = 0,
    format: u32,
    samples: u32,
    loadOp: u32,
    storeOp: u32,
    stencilLoadOp: u32,
    stencilStoreOp: u32,
    initialLayout: ImageLayout,
    finalLayout: ImageLayout,
};

pub const AttachmentReference = extern struct {
    attachment: u32,
    layout: ImageLayout,
};

pub const SubpassDescription = extern struct {
    flags: u32 = 0,
    pipelineBindPoint: u32,
    inputAttachmentCount: u32 = 0,
    pInputAttachments: ?*const anyopaque = null,
    colorAttachmentCount: u32,
    pColorAttachments: [*]const AttachmentReference,
    pResolveAttachments: ?*const anyopaque = null,
    pDepthStencilAttachment: ?*const AttachmentReference = null,
    preserveAttachmentCount: u32 = 0,
    pPreserveAttachments: ?*const u32 = null,
};

pub const SubpassDependency = extern struct {
    srcSubpass: u32,
    dstSubpass: u32,
    srcStageMask: PipelineStageFlags,
    dstStageMask: PipelineStageFlags,
    srcAccessMask: AccessFlags,
    dstAccessMask: AccessFlags,
    dependencyFlags: u32 = 0,
};

pub const RenderPassCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    attachmentCount: u32,
    pAttachments: [*]const AttachmentDescription,
    subpassCount: u32,
    pSubpasses: [*]const SubpassDescription,
    dependencyCount: u32 = 0,
    pDependencies: ?[*]const SubpassDependency = null,
};

pub const FramebufferCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    renderPass: RenderPass,
    attachmentCount: u32,
    pAttachments: [*]const ImageView,
    width: u32,
    height: u32,
    layers: u32,
};

pub const VertexInputBindingDescription = extern struct {
    binding: u32,
    stride: u32,
    inputRate: u32,
};

pub const VertexInputAttributeDescription = extern struct {
    location: u32,
    binding: u32,
    format: u32,
    offset: u32,
};

pub const PipelineShaderStageCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    stage: u32,
    module: ShaderModule,
    pName: [*:0]const u8,
    pSpecializationInfo: ?*const anyopaque = null,
};

pub const PipelineVertexInputStateCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    vertexBindingDescriptionCount: u32,
    pVertexBindingDescriptions: ?[*]const VertexInputBindingDescription,
    vertexAttributeDescriptionCount: u32,
    pVertexAttributeDescriptions: ?[*]const VertexInputAttributeDescription,
};

pub const PipelineInputAssemblyStateCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    topology: u32,
    primitiveRestartEnable: Bool32 = 0,
};

pub const PipelineViewportStateCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    viewportCount: u32,
    pViewports: [*]const Viewport,
    scissorCount: u32,
    pScissors: [*]const Rect2D,
};

pub const PipelineRasterizationStateCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    depthClampEnable: Bool32 = 0,
    rasterizerDiscardEnable: Bool32 = 0,
    polygonMode: u32,
    cullMode: u32,
    frontFace: u32,
    depthBiasEnable: Bool32 = 0,
    depthBiasConstantFactor: f32 = 0,
    depthBiasClamp: f32 = 0,
    depthBiasSlopeFactor: f32 = 0,
    lineWidth: f32,
};

pub const PipelineMultisampleStateCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    rasterizationSamples: u32,
    sampleShadingEnable: Bool32 = 0,
    minSampleShading: f32 = 0,
    pSampleMask: ?*const u32 = null,
    alphaToCoverageEnable: Bool32 = 0,
    alphaToOneEnable: Bool32 = 0,
};

pub const PipelineColorBlendAttachmentState = extern struct {
    blendEnable: Bool32 = 0,
    srcColorBlendFactor: u32 = 0,
    dstColorBlendFactor: u32 = 0,
    colorBlendOp: u32 = 0,
    srcAlphaBlendFactor: u32 = 0,
    dstAlphaBlendFactor: u32 = 0,
    alphaBlendOp: u32 = 0,
    colorWriteMask: u32,
};

pub const PipelineColorBlendStateCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    logicOpEnable: Bool32 = 0,
    logicOp: u32 = 0,
    attachmentCount: u32,
    pAttachments: [*]const PipelineColorBlendAttachmentState,
    blendConstants: [4]f32 = .{ 0, 0, 0, 0 },
};

pub const PushConstantRange = extern struct {
    stageFlags: u32,
    offset: u32,
    size: u32,
};

pub const PipelineLayoutCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    setLayoutCount: u32 = 0,
    pSetLayouts: ?*const anyopaque = null,
    pushConstantRangeCount: u32 = 0,
    pPushConstantRanges: ?[*]const PushConstantRange = null,
};

pub const SamplerCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    magFilter: u32,
    minFilter: u32,
    mipmapMode: u32,
    addressModeU: u32,
    addressModeV: u32,
    addressModeW: u32,
    mipLodBias: f32 = 0,
    anisotropyEnable: Bool32 = 0,
    maxAnisotropy: f32 = 1,
    compareEnable: Bool32 = 0,
    compareOp: u32 = 0,
    minLod: f32 = 0,
    maxLod: f32 = 0,
    borderColor: u32 = 0,
    unnormalizedCoordinates: Bool32 = 0,
};

pub const DescriptorSetLayoutBinding = extern struct {
    binding: u32,
    descriptorType: u32,
    descriptorCount: u32,
    stageFlags: u32,
    pImmutableSamplers: ?[*]const Sampler = null,
};

pub const DescriptorSetLayoutCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    bindingCount: u32,
    pBindings: [*]const DescriptorSetLayoutBinding,
};

pub const DescriptorPoolSize = extern struct {
    type: u32,
    descriptorCount: u32,
};

pub const DescriptorPoolCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    maxSets: u32,
    poolSizeCount: u32,
    pPoolSizes: [*]const DescriptorPoolSize,
};

pub const DescriptorSetAllocateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    descriptorPool: DescriptorPool,
    descriptorSetCount: u32,
    pSetLayouts: [*]const DescriptorSetLayout,
};

pub const DescriptorImageInfo = extern struct {
    sampler: Sampler,
    imageView: ImageView,
    imageLayout: ImageLayout,
};

pub const WriteDescriptorSet = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    dstSet: DescriptorSet,
    dstBinding: u32,
    dstArrayElement: u32 = 0,
    descriptorCount: u32,
    descriptorType: u32,
    pImageInfo: ?[*]const DescriptorImageInfo = null,
    pBufferInfo: ?*const anyopaque = null,
    pTexelBufferView: ?*const anyopaque = null,
};

pub const ImageSubresource = extern struct {
    aspectMask: u32,
    mipLevel: u32,
    arrayLayer: u32,
};

pub const SubresourceLayout = extern struct {
    offset: DeviceSize,
    size: DeviceSize,
    rowPitch: DeviceSize,
    arrayPitch: DeviceSize,
    depthPitch: DeviceSize,
};

pub const GraphicsPipelineCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    stageCount: u32,
    pStages: [*]const PipelineShaderStageCreateInfo,
    pVertexInputState: *const PipelineVertexInputStateCreateInfo,
    pInputAssemblyState: *const PipelineInputAssemblyStateCreateInfo,
    pTessellationState: ?*const anyopaque = null,
    pViewportState: *const PipelineViewportStateCreateInfo,
    pRasterizationState: *const PipelineRasterizationStateCreateInfo,
    pMultisampleState: *const PipelineMultisampleStateCreateInfo,
    pDepthStencilState: ?*const anyopaque = null,
    pColorBlendState: *const PipelineColorBlendStateCreateInfo,
    pDynamicState: ?*const anyopaque = null,
    layout: PipelineLayout,
    renderPass: RenderPass,
    subpass: u32 = 0,
    basePipelineHandle: ?Pipeline = null,
    basePipelineIndex: i32 = -1,
};

pub const StencilOpState = extern struct {
    failOp: u32 = 0,
    passOp: u32 = 0,
    depthFailOp: u32 = 0,
    compareOp: u32 = 0,
    compareMask: u32 = 0,
    writeMask: u32 = 0,
    reference: u32 = 0,
};

pub const PipelineDepthStencilStateCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    depthTestEnable: Bool32,
    depthWriteEnable: Bool32,
    depthCompareOp: u32,
    depthBoundsTestEnable: Bool32 = 0,
    stencilTestEnable: Bool32 = 0,
    front: StencilOpState = .{},
    back: StencilOpState = .{},
    minDepthBounds: f32 = 0,
    maxDepthBounds: f32 = 1,
};

pub const ClearValue = extern union {
    color: ClearColorValue,
    depthStencil: extern struct {
        depth: f32,
        stencil: u32,
    },
};

pub const RenderPassBeginInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    renderPass: RenderPass,
    framebuffer: Framebuffer,
    renderArea: Rect2D,
    clearValueCount: u32 = 0,
    pClearValues: ?[*]const ClearValue = null,
};

pub const BufferCreateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    size: DeviceSize,
    usage: u32,
    sharingMode: u32,
    queueFamilyIndexCount: u32 = 0,
    pQueueFamilyIndices: ?[*]const u32 = null,
};

pub const MemoryRequirements = extern struct {
    size: DeviceSize,
    alignment: DeviceSize,
    memoryTypeBits: u32,
};

pub const MemoryAllocateInfo = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    allocationSize: DeviceSize,
    memoryTypeIndex: u32,
};

pub const QueueFamilyProperties = extern struct {
    queueFlags: QueueFlags,
    queueCount: u32,
    timestampValidBits: u32,
    minImageTransferGranularity: Extent3D,
};

pub const PfnCreateInstance = *const fn (*const InstanceCreateInfo, ?*const anyopaque, *Instance) callconv(.c) Result;
pub const PfnEnumerateInstanceLayerProperties = *const fn (*u32, ?[*]LayerProperties) callconv(.c) Result;
pub const PfnEnumerateInstanceExtensionProperties = *const fn (?[*:0]const u8, *u32, ?[*]ExtensionProperties) callconv(.c) Result;
pub const PfnGetInstanceProcAddr = *const fn (?Instance, [*:0]const u8) callconv(.c) ?*const anyopaque;
pub const PfnDestroyInstance = *const fn (Instance, ?*const anyopaque) callconv(.c) void;
pub const PfnEnumeratePhysicalDevices = *const fn (Instance, *u32, ?[*]PhysicalDevice) callconv(.c) Result;
pub const PfnGetPhysicalDeviceProperties = *const fn (PhysicalDevice, *PhysicalDeviceProperties) callconv(.c) void;
pub const PfnGetPhysicalDeviceMemoryProperties = *const fn (PhysicalDevice, *PhysicalDeviceMemoryProperties) callconv(.c) void;
pub const PfnGetPhysicalDeviceQueueFamilyProperties = *const fn (PhysicalDevice, *u32, ?[*]QueueFamilyProperties) callconv(.c) void;
pub const PfnCreateDevice = *const fn (PhysicalDevice, *const DeviceCreateInfo, ?*const anyopaque, *Device) callconv(.c) Result;
pub const PfnGetDeviceProcAddr = *const fn (Device, [*:0]const u8) callconv(.c) ?*const anyopaque;
pub const PfnDestroyDevice = *const fn (Device, ?*const anyopaque) callconv(.c) void;
pub const PfnDeviceWaitIdle = *const fn (Device) callconv(.c) Result;
pub const PfnGetDeviceQueue = *const fn (Device, u32, u32, *Queue) callconv(.c) void;
pub const PfnCreateWin32SurfaceKHR = *const fn (Instance, *const Win32SurfaceCreateInfoKHR, ?*const anyopaque, *SurfaceKHR) callconv(.c) Result;
pub const PfnDestroySurfaceKHR = *const fn (Instance, SurfaceKHR, ?*const anyopaque) callconv(.c) void;
pub const PfnGetPhysicalDeviceSurfaceSupportKHR = *const fn (PhysicalDevice, u32, SurfaceKHR, *Bool32) callconv(.c) Result;
pub const PfnGetPhysicalDeviceSurfaceCapabilitiesKHR = *const fn (PhysicalDevice, SurfaceKHR, *SurfaceCapabilitiesKHR) callconv(.c) Result;
pub const PfnGetPhysicalDeviceSurfaceFormatsKHR = *const fn (PhysicalDevice, SurfaceKHR, *u32, ?[*]SurfaceFormatKHR) callconv(.c) Result;
pub const PfnGetPhysicalDeviceSurfacePresentModesKHR = *const fn (PhysicalDevice, SurfaceKHR, *u32, ?[*]u32) callconv(.c) Result;
pub const PfnCreateSwapchainKHR = *const fn (Device, *const SwapchainCreateInfoKHR, ?*const anyopaque, *SwapchainKHR) callconv(.c) Result;
pub const PfnDestroySwapchainKHR = *const fn (Device, SwapchainKHR, ?*const anyopaque) callconv(.c) void;
pub const PfnGetSwapchainImagesKHR = *const fn (Device, SwapchainKHR, *u32, ?[*]Image) callconv(.c) Result;
pub const PfnCreateImageView = *const fn (Device, *const ImageViewCreateInfo, ?*const anyopaque, *ImageView) callconv(.c) Result;
pub const PfnDestroyImageView = *const fn (Device, ImageView, ?*const anyopaque) callconv(.c) void;
pub const PfnCreateImage = *const fn (Device, *const ImageCreateInfo, ?*const anyopaque, *Image) callconv(.c) Result;
pub const PfnDestroyImage = *const fn (Device, Image, ?*const anyopaque) callconv(.c) void;
pub const PfnGetImageMemoryRequirements = *const fn (Device, Image, *MemoryRequirements) callconv(.c) void;
pub const PfnBindImageMemory = *const fn (Device, Image, DeviceMemory, DeviceSize) callconv(.c) Result;
pub const PfnGetImageSubresourceLayout = *const fn (Device, Image, *const ImageSubresource, *SubresourceLayout) callconv(.c) void;
pub const PfnCreateCommandPool = *const fn (Device, *const CommandPoolCreateInfo, ?*const anyopaque, *CommandPool) callconv(.c) Result;
pub const PfnDestroyCommandPool = *const fn (Device, CommandPool, ?*const anyopaque) callconv(.c) void;
pub const PfnAllocateCommandBuffers = *const fn (Device, *const CommandBufferAllocateInfo, [*]CommandBuffer) callconv(.c) Result;
pub const PfnCreateFence = *const fn (Device, *const FenceCreateInfo, ?*const anyopaque, *Fence) callconv(.c) Result;
pub const PfnDestroyFence = *const fn (Device, Fence, ?*const anyopaque) callconv(.c) void;
pub const PfnCreateSemaphore = *const fn (Device, *const SemaphoreCreateInfo, ?*const anyopaque, *Semaphore) callconv(.c) Result;
pub const PfnDestroySemaphore = *const fn (Device, Semaphore, ?*const anyopaque) callconv(.c) void;
pub const PfnCreateBuffer = *const fn (Device, *const BufferCreateInfo, ?*const anyopaque, *Buffer) callconv(.c) Result;
pub const PfnDestroyBuffer = *const fn (Device, Buffer, ?*const anyopaque) callconv(.c) void;
pub const PfnGetBufferMemoryRequirements = *const fn (Device, Buffer, *MemoryRequirements) callconv(.c) void;
pub const PfnAllocateMemory = *const fn (Device, *const MemoryAllocateInfo, ?*const anyopaque, *DeviceMemory) callconv(.c) Result;
pub const PfnFreeMemory = *const fn (Device, DeviceMemory, ?*const anyopaque) callconv(.c) void;
pub const PfnBindBufferMemory = *const fn (Device, Buffer, DeviceMemory, DeviceSize) callconv(.c) Result;
pub const PfnMapMemory = *const fn (Device, DeviceMemory, DeviceSize, DeviceSize, u32, *?*anyopaque) callconv(.c) Result;
pub const PfnUnmapMemory = *const fn (Device, DeviceMemory) callconv(.c) void;
pub const PfnCreateShaderModule = *const fn (Device, *const ShaderModuleCreateInfo, ?*const anyopaque, *ShaderModule) callconv(.c) Result;
pub const PfnDestroyShaderModule = *const fn (Device, ShaderModule, ?*const anyopaque) callconv(.c) void;
pub const PfnCreateRenderPass = *const fn (Device, *const RenderPassCreateInfo, ?*const anyopaque, *RenderPass) callconv(.c) Result;
pub const PfnDestroyRenderPass = *const fn (Device, RenderPass, ?*const anyopaque) callconv(.c) void;
pub const PfnCreateFramebuffer = *const fn (Device, *const FramebufferCreateInfo, ?*const anyopaque, *Framebuffer) callconv(.c) Result;
pub const PfnDestroyFramebuffer = *const fn (Device, Framebuffer, ?*const anyopaque) callconv(.c) void;
pub const PfnCreatePipelineLayout = *const fn (Device, *const PipelineLayoutCreateInfo, ?*const anyopaque, *PipelineLayout) callconv(.c) Result;
pub const PfnDestroyPipelineLayout = *const fn (Device, PipelineLayout, ?*const anyopaque) callconv(.c) void;
pub const PfnCreateGraphicsPipelines = *const fn (Device, ?*const anyopaque, u32, [*]const GraphicsPipelineCreateInfo, ?*const anyopaque, [*]Pipeline) callconv(.c) Result;
pub const PfnDestroyPipeline = *const fn (Device, Pipeline, ?*const anyopaque) callconv(.c) void;
pub const PfnCreateSampler = *const fn (Device, *const SamplerCreateInfo, ?*const anyopaque, *Sampler) callconv(.c) Result;
pub const PfnDestroySampler = *const fn (Device, Sampler, ?*const anyopaque) callconv(.c) void;
pub const PfnCreateDescriptorSetLayout = *const fn (Device, *const DescriptorSetLayoutCreateInfo, ?*const anyopaque, *DescriptorSetLayout) callconv(.c) Result;
pub const PfnDestroyDescriptorSetLayout = *const fn (Device, DescriptorSetLayout, ?*const anyopaque) callconv(.c) void;
pub const PfnCreateDescriptorPool = *const fn (Device, *const DescriptorPoolCreateInfo, ?*const anyopaque, *DescriptorPool) callconv(.c) Result;
pub const PfnDestroyDescriptorPool = *const fn (Device, DescriptorPool, ?*const anyopaque) callconv(.c) void;
pub const PfnAllocateDescriptorSets = *const fn (Device, *const DescriptorSetAllocateInfo, [*]DescriptorSet) callconv(.c) Result;
pub const PfnUpdateDescriptorSets = *const fn (Device, u32, [*]const WriteDescriptorSet, u32, ?*const anyopaque) callconv(.c) void;
pub const PfnCmdBindDescriptorSets = *const fn (CommandBuffer, u32, PipelineLayout, u32, u32, [*]const DescriptorSet, u32, ?*const u32) callconv(.c) void;
pub const PfnWaitForFences = *const fn (Device, u32, [*]const Fence, Bool32, u64) callconv(.c) Result;
pub const PfnResetFences = *const fn (Device, u32, [*]const Fence) callconv(.c) Result;
pub const PfnResetCommandBuffer = *const fn (CommandBuffer, u32) callconv(.c) Result;
pub const PfnBeginCommandBuffer = *const fn (CommandBuffer, *const CommandBufferBeginInfo) callconv(.c) Result;
pub const PfnEndCommandBuffer = *const fn (CommandBuffer) callconv(.c) Result;
pub const PfnCmdPipelineBarrier = *const fn (CommandBuffer, PipelineStageFlags, PipelineStageFlags, u32, u32, ?*const anyopaque, u32, ?*const anyopaque, u32, [*]const ImageMemoryBarrier) callconv(.c) void;
pub const PfnCmdBeginRenderPass = *const fn (CommandBuffer, *const RenderPassBeginInfo, u32) callconv(.c) void;
pub const PfnCmdEndRenderPass = *const fn (CommandBuffer) callconv(.c) void;
pub const PfnCmdBindPipeline = *const fn (CommandBuffer, u32, Pipeline) callconv(.c) void;
pub const PfnCmdBindVertexBuffers = *const fn (CommandBuffer, u32, u32, [*]const Buffer, [*]const DeviceSize) callconv(.c) void;
pub const PfnCmdBindIndexBuffer = *const fn (CommandBuffer, Buffer, DeviceSize, u32) callconv(.c) void;
pub const PfnCmdPushConstants = *const fn (CommandBuffer, PipelineLayout, u32, u32, u32, *const anyopaque) callconv(.c) void;
pub const PfnCmdDrawIndexed = *const fn (CommandBuffer, u32, u32, u32, i32, u32) callconv(.c) void;
pub const PfnQueueSubmit = *const fn (Queue, u32, [*]const SubmitInfo, Fence) callconv(.c) Result;
pub const PfnAcquireNextImageKHR = *const fn (Device, SwapchainKHR, u64, Semaphore, ?Fence, *u32) callconv(.c) Result;
pub const PfnQueuePresentKHR = *const fn (Queue, *const PresentInfoKHR) callconv(.c) Result;
pub const PfnCreateDebugUtilsMessengerEXT = *const fn (Instance, *const DebugUtilsMessengerCreateInfoEXT, ?*const anyopaque, *DebugUtilsMessengerEXT) callconv(.c) Result;
pub const PfnDestroyDebugUtilsMessengerEXT = *const fn (Instance, DebugUtilsMessengerEXT, ?*const anyopaque) callconv(.c) void;

pub const STRUCTURE_TYPE_APPLICATION_INFO = 0;
pub const STRUCTURE_TYPE_INSTANCE_CREATE_INFO = 1;
pub const STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO = 2;
pub const STRUCTURE_TYPE_DEVICE_CREATE_INFO = 3;
pub const STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR = 1000009000;
pub const STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR = 1000001000;
pub const STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO = 15;
pub const STRUCTURE_TYPE_IMAGE_CREATE_INFO = 14;
pub const STRUCTURE_TYPE_FENCE_CREATE_INFO = 8;
pub const STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO = 9;
pub const STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO = 39;
pub const STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO = 40;
pub const STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO = 42;
pub const STRUCTURE_TYPE_SUBMIT_INFO = 4;
pub const STRUCTURE_TYPE_BUFFER_CREATE_INFO = 12;
pub const STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO = 5;
pub const STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO = 16;
pub const STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO = 38;
pub const STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO = 37;
pub const STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO = 18;
pub const STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO = 19;
pub const STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO = 20;
pub const STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO = 22;
pub const STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO = 23;
pub const STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO = 24;
pub const STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO = 26;
pub const STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO = 25;
pub const STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO = 30;
pub const STRUCTURE_TYPE_SAMPLER_CREATE_INFO = 31;
pub const STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO = 32;
pub const STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO = 33;
pub const STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO = 34;
pub const STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET = 35;
pub const STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO = 28;
pub const STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO = 43;
pub const STRUCTURE_TYPE_PRESENT_INFO_KHR = 1000001001;
pub const STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER = 45;
pub const STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT = 1000128004;
pub const API_VERSION_1_0 = (1 << 22);
pub const FORMAT_B8G8R8A8_UNORM = 44;
pub const FORMAT_R8G8B8A8_UNORM = 37;
pub const FORMAT_D32_SFLOAT = 126;
pub const COLOR_SPACE_SRGB_NONLINEAR_KHR = 0;
pub const IMAGE_USAGE_COLOR_ATTACHMENT_BIT: u32 = 0x00000010;
pub const IMAGE_USAGE_SAMPLED_BIT: u32 = 0x00000004;
pub const IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT: u32 = 0x00000020;
pub const BUFFER_USAGE_VERTEX_BUFFER_BIT: u32 = 0x00000080;
pub const BUFFER_USAGE_INDEX_BUFFER_BIT: u32 = 0x00000040;
pub const BUFFER_USAGE_STORAGE_BUFFER_BIT: u32 = 0x00000020;
pub const SHARING_MODE_EXCLUSIVE = 0;
pub const SHARING_MODE_CONCURRENT = 1;
pub const COMPOSITE_ALPHA_OPAQUE_BIT_KHR: u32 = 0x00000001;
pub const PRESENT_MODE_FIFO_KHR = 2;
pub const IMAGE_VIEW_TYPE_2D = 1;
pub const COMPONENT_SWIZZLE_IDENTITY = 0;
pub const IMAGE_ASPECT_COLOR_BIT: u32 = 0x00000001;
pub const IMAGE_ASPECT_DEPTH_BIT: u32 = 0x00000002;
pub const COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT: u32 = 0x00000002;
pub const COMMAND_BUFFER_LEVEL_PRIMARY = 0;
pub const FENCE_CREATE_SIGNALED_BIT: u32 = 0x00000001;
pub const PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT: u32 = 0x00000400;
pub const PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT: u32 = 0x00000100;
pub const IMAGE_LAYOUT_UNDEFINED: u32 = 0;
pub const IMAGE_LAYOUT_GENERAL: u32 = 1;
pub const IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL: u32 = 2;
pub const IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL: u32 = 3;
pub const IMAGE_LAYOUT_PREINITIALIZED: u32 = 8;
pub const IMAGE_LAYOUT_PRESENT_SRC_KHR: u32 = 1000001002;
pub const ATTACHMENT_LOAD_OP_CLEAR: u32 = 1;
pub const ATTACHMENT_STORE_OP_STORE: u32 = 0;
pub const ATTACHMENT_LOAD_OP_DONT_CARE: u32 = 2;
pub const ATTACHMENT_STORE_OP_DONT_CARE: u32 = 1;
pub const SAMPLE_COUNT_1_BIT: u32 = 1;
pub const PIPELINE_BIND_POINT_GRAPHICS: u32 = 0;
pub const SUBPASS_EXTERNAL = std.math.maxInt(u32);
pub const ACCESS_COLOR_ATTACHMENT_WRITE_BIT: u32 = 0x00000100;
pub const ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT: u32 = 0x00000400;
pub const SHADER_STAGE_VERTEX_BIT: u32 = 0x00000001;
pub const SHADER_STAGE_FRAGMENT_BIT: u32 = 0x00000010;
pub const VERTEX_INPUT_RATE_VERTEX: u32 = 0;
pub const FORMAT_R32G32B32_SFLOAT: u32 = 106;
pub const FORMAT_R32G32_SFLOAT: u32 = 103;
pub const FORMAT_R32_UINT: u32 = 98;
pub const PRIMITIVE_TOPOLOGY_TRIANGLE_LIST: u32 = 3;
pub const POLYGON_MODE_FILL: u32 = 0;
pub const CULL_MODE_NONE: u32 = 0;
pub const FRONT_FACE_COUNTER_CLOCKWISE: u32 = 1;
pub const COLOR_COMPONENT_R_BIT: u32 = 0x1;
pub const COLOR_COMPONENT_G_BIT: u32 = 0x2;
pub const COLOR_COMPONENT_B_BIT: u32 = 0x4;
pub const COLOR_COMPONENT_A_BIT: u32 = 0x8;
pub const IMAGE_TYPE_2D: u32 = 1;
pub const IMAGE_TILING_OPTIMAL: u32 = 0;
pub const IMAGE_TILING_LINEAR: u32 = 1;
pub const COMPARE_OP_LESS: u32 = 1;
pub const FILTER_NEAREST: u32 = 0;
pub const FILTER_LINEAR: u32 = 1;
pub const SAMPLER_MIPMAP_MODE_NEAREST: u32 = 0;
pub const SAMPLER_MIPMAP_MODE_LINEAR: u32 = 1;
pub const SAMPLER_ADDRESS_MODE_REPEAT: u32 = 0;
pub const SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE: u32 = 2;
pub const DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER: u32 = 1;

pub fn colorAttachmentOutputStage() PipelineStageFlags {
    return PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
}

pub const INDEX_TYPE_UINT32: u32 = 1;
pub const SUBPASS_CONTENTS_INLINE: u32 = 0;
pub const QUEUE_FAMILY_IGNORED = std.math.maxInt(u32);
pub const TRUE: Bool32 = 1;
pub const FALSE: Bool32 = 0;
pub const UINT64_MAX = std.math.maxInt(u64);
pub const UINT32_MAX = std.math.maxInt(u32);
pub const DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT: u32 = 0x00000001;
pub const DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT: u32 = 0x00000010;
pub const DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT: u32 = 0x00000100;
pub const DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT: u32 = 0x00001000;
pub const DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT: u32 = 0x00000001;
pub const DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT: u32 = 0x00000002;
pub const DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT: u32 = 0x00000004;

pub const VulkanFns = struct {
    vkCreateInstance: PfnCreateInstance,
    vkEnumerateInstanceLayerProperties: PfnEnumerateInstanceLayerProperties,
    vkEnumerateInstanceExtensionProperties: PfnEnumerateInstanceExtensionProperties,
    vkGetInstanceProcAddr: PfnGetInstanceProcAddr,
    vkDestroyInstance: PfnDestroyInstance,
    vkEnumeratePhysicalDevices: PfnEnumeratePhysicalDevices,
    vkGetPhysicalDeviceProperties: PfnGetPhysicalDeviceProperties,
    vkGetPhysicalDeviceMemoryProperties: PfnGetPhysicalDeviceMemoryProperties,
    vkGetPhysicalDeviceQueueFamilyProperties: PfnGetPhysicalDeviceQueueFamilyProperties,
    vkCreateDevice: PfnCreateDevice,
    vkGetDeviceProcAddr: ?PfnGetDeviceProcAddr,
    vkDestroyDevice: ?PfnDestroyDevice,
    vkDeviceWaitIdle: ?PfnDeviceWaitIdle,
    vkGetDeviceQueue: ?PfnGetDeviceQueue,
    vkCreateWin32SurfaceKHR: ?PfnCreateWin32SurfaceKHR,
    vkDestroySurfaceKHR: ?PfnDestroySurfaceKHR,
    vkGetPhysicalDeviceSurfaceSupportKHR: ?PfnGetPhysicalDeviceSurfaceSupportKHR,
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR: ?PfnGetPhysicalDeviceSurfaceCapabilitiesKHR,
    vkGetPhysicalDeviceSurfaceFormatsKHR: ?PfnGetPhysicalDeviceSurfaceFormatsKHR,
    vkGetPhysicalDeviceSurfacePresentModesKHR: ?PfnGetPhysicalDeviceSurfacePresentModesKHR,
    vkCreateSwapchainKHR: ?PfnCreateSwapchainKHR,
    vkDestroySwapchainKHR: ?PfnDestroySwapchainKHR,
    vkGetSwapchainImagesKHR: ?PfnGetSwapchainImagesKHR,
    vkCreateImageView: ?PfnCreateImageView,
    vkDestroyImageView: ?PfnDestroyImageView,
    vkCreateImage: ?PfnCreateImage,
    vkDestroyImage: ?PfnDestroyImage,
    vkGetImageMemoryRequirements: ?PfnGetImageMemoryRequirements,
    vkBindImageMemory: ?PfnBindImageMemory,
    vkGetImageSubresourceLayout: ?PfnGetImageSubresourceLayout,
    vkCreateCommandPool: ?PfnCreateCommandPool,
    vkDestroyCommandPool: ?PfnDestroyCommandPool,
    vkAllocateCommandBuffers: ?PfnAllocateCommandBuffers,
    vkCreateFence: ?PfnCreateFence,
    vkDestroyFence: ?PfnDestroyFence,
    vkCreateSemaphore: ?PfnCreateSemaphore,
    vkDestroySemaphore: ?PfnDestroySemaphore,
    vkCreateBuffer: ?PfnCreateBuffer,
    vkDestroyBuffer: ?PfnDestroyBuffer,
    vkGetBufferMemoryRequirements: ?PfnGetBufferMemoryRequirements,
    vkAllocateMemory: ?PfnAllocateMemory,
    vkFreeMemory: ?PfnFreeMemory,
    vkBindBufferMemory: ?PfnBindBufferMemory,
    vkMapMemory: ?PfnMapMemory,
    vkUnmapMemory: ?PfnUnmapMemory,
    vkCreateShaderModule: ?PfnCreateShaderModule,
    vkDestroyShaderModule: ?PfnDestroyShaderModule,
    vkCreateRenderPass: ?PfnCreateRenderPass,
    vkDestroyRenderPass: ?PfnDestroyRenderPass,
    vkCreateFramebuffer: ?PfnCreateFramebuffer,
    vkDestroyFramebuffer: ?PfnDestroyFramebuffer,
    vkCreatePipelineLayout: ?PfnCreatePipelineLayout,
    vkDestroyPipelineLayout: ?PfnDestroyPipelineLayout,
    vkCreateGraphicsPipelines: ?PfnCreateGraphicsPipelines,
    vkDestroyPipeline: ?PfnDestroyPipeline,
    vkCreateSampler: ?PfnCreateSampler,
    vkDestroySampler: ?PfnDestroySampler,
    vkCreateDescriptorSetLayout: ?PfnCreateDescriptorSetLayout,
    vkDestroyDescriptorSetLayout: ?PfnDestroyDescriptorSetLayout,
    vkCreateDescriptorPool: ?PfnCreateDescriptorPool,
    vkDestroyDescriptorPool: ?PfnDestroyDescriptorPool,
    vkAllocateDescriptorSets: ?PfnAllocateDescriptorSets,
    vkUpdateDescriptorSets: ?PfnUpdateDescriptorSets,
    vkCmdBindDescriptorSets: ?PfnCmdBindDescriptorSets,
    vkWaitForFences: ?PfnWaitForFences,
    vkResetFences: ?PfnResetFences,
    vkResetCommandBuffer: ?PfnResetCommandBuffer,
    vkBeginCommandBuffer: ?PfnBeginCommandBuffer,
    vkEndCommandBuffer: ?PfnEndCommandBuffer,
    vkCmdPipelineBarrier: ?PfnCmdPipelineBarrier,
    vkCmdBeginRenderPass: ?PfnCmdBeginRenderPass,
    vkCmdEndRenderPass: ?PfnCmdEndRenderPass,
    vkCmdBindPipeline: ?PfnCmdBindPipeline,
    vkCmdBindVertexBuffers: ?PfnCmdBindVertexBuffers,
    vkCmdBindIndexBuffer: ?PfnCmdBindIndexBuffer,
    vkCmdPushConstants: ?PfnCmdPushConstants,
    vkCmdDrawIndexed: ?PfnCmdDrawIndexed,
    vkQueueSubmit: ?PfnQueueSubmit,
    vkAcquireNextImageKHR: ?PfnAcquireNextImageKHR,
    vkQueuePresentKHR: ?PfnQueuePresentKHR,
    vkCreateDebugUtilsMessengerEXT: ?PfnCreateDebugUtilsMessengerEXT,
    vkDestroyDebugUtilsMessengerEXT: ?PfnDestroyDebugUtilsMessengerEXT,
};

pub const Win32SurfaceCreateInfoKHR = extern struct {
    sType: u32,
    pNext: ?*const anyopaque = null,
    flags: u32 = 0,
    hinstance: *anyopaque,
    hwnd: *anyopaque,
};
