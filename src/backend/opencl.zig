const std = @import("std");
const backend_mod = @import("mod.zig");
const config = @import("../config.zig");
const game = @import("../game.zig");
const win32 = @import("../win32.zig");

const cl_int = i32;
const cl_uint = u32;
const cl_ulong = u64;
const cl_bool = cl_uint;
const cl_platform_id = *opaque {};
const cl_device_id = *opaque {};
const cl_context = *opaque {};
const cl_command_queue = *opaque {};
const cl_mem = *opaque {};
const cl_program = *opaque {};
const cl_kernel = *opaque {};
const cl_context_properties = isize;

const CL_SUCCESS: cl_int = 0;
const CL_TRUE: cl_bool = 1;
const CL_DEVICE_TYPE_GPU: cl_ulong = 1 << 2;
const CL_MEM_WRITE_ONLY: cl_ulong = 1 << 1;
const CL_PROGRAM_BUILD_LOG: cl_uint = 0x1183;

const WIN32_FILE_ATTRIBUTE_DATA = extern struct {
    dwFileAttributes: u32,
    ftCreationTime: FILETIME,
    ftLastAccessTime: FILETIME,
    ftLastWriteTime: FILETIME,
    nFileSizeHigh: u32,
    nFileSizeLow: u32,
};

const FILETIME = extern struct {
    dwLowDateTime: u32,
    dwHighDateTime: u32,

    fn asU64(self: FILETIME) u64 {
        return (@as(u64, self.dwHighDateTime) << 32) | self.dwLowDateTime;
    }
};

extern "kernel32" fn GetFileAttributesExA(lpFileName: [*:0]const u8, fInfoLevelId: u32, lpFileInformation: *WIN32_FILE_ATTRIBUTE_DATA) callconv(.winapi) i32;

const ClGetPlatformIDs = *const fn (cl_uint, ?[*]cl_platform_id, ?*cl_uint) callconv(.c) cl_int;
const ClGetDeviceIDs = *const fn (cl_platform_id, cl_ulong, cl_uint, ?[*]cl_device_id, ?*cl_uint) callconv(.c) cl_int;
const ClCreateContext = *const fn (?[*]const cl_context_properties, cl_uint, [*]const cl_device_id, ?*const fn ([*:0]const u8, ?*const anyopaque, usize, ?*anyopaque) callconv(.c) void, ?*anyopaque, ?*cl_int) callconv(.c) ?cl_context;
const ClCreateCommandQueue = *const fn (cl_context, cl_device_id, cl_ulong, ?*cl_int) callconv(.c) ?cl_command_queue;
const ClCreateBuffer = *const fn (cl_context, cl_ulong, usize, ?*anyopaque, ?*cl_int) callconv(.c) ?cl_mem;
const ClCreateProgramWithSource = *const fn (cl_context, cl_uint, [*]const [*]const u8, ?[*]const usize, ?*cl_int) callconv(.c) ?cl_program;
const ClBuildProgram = *const fn (cl_program, cl_uint, ?[*]const cl_device_id, ?[*:0]const u8, ?*const fn (cl_program, ?*anyopaque) callconv(.c) void, ?*anyopaque) callconv(.c) cl_int;
const ClGetProgramBuildInfo = *const fn (cl_program, cl_device_id, cl_uint, usize, ?*anyopaque, ?*usize) callconv(.c) cl_int;
const ClCreateKernel = *const fn (cl_program, [*:0]const u8, ?*cl_int) callconv(.c) ?cl_kernel;
const ClSetKernelArg = *const fn (cl_kernel, cl_uint, usize, ?*const anyopaque) callconv(.c) cl_int;
const ClEnqueueNDRangeKernel = *const fn (cl_command_queue, cl_kernel, cl_uint, ?[*]const usize, [*]const usize, ?[*]const usize, cl_uint, ?*const anyopaque, ?*anyopaque) callconv(.c) cl_int;
const ClEnqueueReadBuffer = *const fn (cl_command_queue, cl_mem, cl_bool, usize, usize, *anyopaque, cl_uint, ?*const anyopaque, ?*anyopaque) callconv(.c) cl_int;
const ClReleaseMemObject = *const fn (cl_mem) callconv(.c) cl_int;
const ClReleaseKernel = *const fn (cl_kernel) callconv(.c) cl_int;
const ClReleaseProgram = *const fn (cl_program) callconv(.c) cl_int;
const ClReleaseCommandQueue = *const fn (cl_command_queue) callconv(.c) cl_int;
const ClReleaseContext = *const fn (cl_context) callconv(.c) cl_int;

var clGetPlatformIDs: ClGetPlatformIDs = undefined;
var clGetDeviceIDs: ClGetDeviceIDs = undefined;
var clCreateContext: ClCreateContext = undefined;
var clCreateCommandQueue: ClCreateCommandQueue = undefined;
var clCreateBuffer: ClCreateBuffer = undefined;
var clCreateProgramWithSource: ClCreateProgramWithSource = undefined;
var clBuildProgram: ClBuildProgram = undefined;
var clGetProgramBuildInfo: ClGetProgramBuildInfo = undefined;
var clCreateKernel: ClCreateKernel = undefined;
var clSetKernelArg: ClSetKernelArg = undefined;
var clEnqueueNDRangeKernel: ClEnqueueNDRangeKernel = undefined;
var clEnqueueReadBuffer: ClEnqueueReadBuffer = undefined;
var clReleaseMemObject: ClReleaseMemObject = undefined;
var clReleaseKernel: ClReleaseKernel = undefined;
var clReleaseProgram: ClReleaseProgram = undefined;
var clReleaseCommandQueue: ClReleaseCommandQueue = undefined;
var clReleaseContext: ClReleaseContext = undefined;

const ProgramKernel = struct {
    program: cl_program,
    kernel: cl_kernel,
};

pub const Renderer = struct {
    allocator: std.mem.Allocator,
    lib: win32.HMODULE,
    device: cl_device_id,
    context: cl_context,
    queue: cl_command_queue,
    pixels_buffer: cl_mem,
    program: cl_program,
    kernel: cl_kernel,
    source_mtime: u64,
    reload_check_t: f32 = -1.0,

    pub fn backend(self: *Renderer) backend_mod.Backend {
        return .{ .ptr = self, .vtable = &vtable };
    }

    pub fn init(allocator: std.mem.Allocator) !Renderer {
        const lib = win32.LoadLibraryA("OpenCL.dll") orelse return error.OpenCLDllNotFound;
        errdefer _ = win32.FreeLibrary(lib);
        try loadOpenCL(lib);

        var err: cl_int = CL_SUCCESS;
        var platform_count: cl_uint = 0;
        try check(clGetPlatformIDs(0, null, &platform_count));
        if (platform_count == 0) return error.NoOpenCLPlatform;

        var platform: cl_platform_id = undefined;
        try check(clGetPlatformIDs(1, @ptrCast(&platform), null));

        var device_count: cl_uint = 0;
        try check(clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 0, null, &device_count));
        if (device_count == 0) return error.NoOpenCLGpu;

        var device: cl_device_id = undefined;
        try check(clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, @ptrCast(&device), null));

        const context = clCreateContext(null, 1, @ptrCast(&device), null, null, &err) orelse return error.OpenCLCreateContextFailed;
        try check(err);
        errdefer _ = clReleaseContext(context);
        err = CL_SUCCESS;

        const queue = clCreateCommandQueue(context, device, 0, &err) orelse return error.OpenCLCreateQueueFailed;
        try check(err);
        errdefer _ = clReleaseCommandQueue(queue);
        err = CL_SUCCESS;

        const pixels_buffer = clCreateBuffer(context, CL_MEM_WRITE_ONLY, @sizeOf([config.WIDTH * config.HEIGHT]u32), null, &err) orelse return error.OpenCLCreateBufferFailed;
        try check(err);
        errdefer _ = clReleaseMemObject(pixels_buffer);

        const compiled = try compileKernel(allocator, context, device);
        errdefer _ = clReleaseKernel(compiled.kernel);
        errdefer _ = clReleaseProgram(compiled.program);
        const source_mtime = try kernelMtime();

        std.debug.print("OpenCL renderer ready: {s} compiled. Edit it while the app runs to hot reload.\n", .{config.KERNEL_PATH});
        return .{
            .allocator = allocator,
            .lib = lib,
            .device = device,
            .context = context,
            .queue = queue,
            .pixels_buffer = pixels_buffer,
            .program = compiled.program,
            .kernel = compiled.kernel,
            .source_mtime = source_mtime,
        };
    }

    pub fn deinit(self: *Renderer) void {
        _ = clReleaseKernel(self.kernel);
        _ = clReleaseProgram(self.program);
        _ = clReleaseMemObject(self.pixels_buffer);
        _ = clReleaseCommandQueue(self.queue);
        _ = clReleaseContext(self.context);
        _ = win32.FreeLibrary(self.lib);
    }

    pub fn render(self: *Renderer, pixels: *[config.WIDTH * config.HEIGHT]u32, time: f32) !void {
        self.reloadIfChanged(time) catch |err| {
            std.debug.print("OpenCL hot reload skipped: {}\n", .{err});
        };

        var width: i32 = config.WIDTH;
        var height: i32 = config.HEIGHT;
        var t = time;
        try check(clSetKernelArg(self.kernel, 0, @sizeOf(cl_mem), @ptrCast(&self.pixels_buffer)));
        try check(clSetKernelArg(self.kernel, 1, @sizeOf(i32), @ptrCast(&width)));
        try check(clSetKernelArg(self.kernel, 2, @sizeOf(i32), @ptrCast(&height)));
        try check(clSetKernelArg(self.kernel, 3, @sizeOf(f32), @ptrCast(&t)));

        const global = [_]usize{ config.WIDTH, config.HEIGHT };
        try check(clEnqueueNDRangeKernel(self.queue, self.kernel, 2, null, &global, null, 0, null, null));
        try check(clEnqueueReadBuffer(self.queue, self.pixels_buffer, CL_TRUE, 0, @sizeOf([config.WIDTH * config.HEIGHT]u32), @ptrCast(pixels), 0, null, null));
    }

    fn reloadIfChanged(self: *Renderer, time: f32) !void {
        if (self.reload_check_t >= 0.0 and time - self.reload_check_t < 0.25) return;
        self.reload_check_t = time;

        const mtime = try kernelMtime();
        if (mtime == self.source_mtime) return;

        const compiled = compileKernel(self.allocator, self.context, self.device) catch |err| {
            std.debug.print("OpenCL hot reload failed; keeping previous kernel: {}\n", .{err});
            self.source_mtime = mtime;
            return;
        };

        _ = clReleaseKernel(self.kernel);
        _ = clReleaseProgram(self.program);
        self.kernel = compiled.kernel;
        self.program = compiled.program;
        self.source_mtime = mtime;
        std.debug.print("OpenCL hot reload succeeded: {s}\n", .{config.KERNEL_PATH});
    }
};

const vtable = backend_mod.Backend.VTable{
    .name = "OpenCL GPU kernel",
    .deinit = deinitBackend,
    .render = renderBackend,
};

fn deinitBackend(ptr: *anyopaque) void {
    const self: *Renderer = @ptrCast(@alignCast(ptr));
    self.deinit();
}

fn renderBackend(ptr: *anyopaque, frame: *backend_mod.Frame, state: *const game.State) !void {
    const self: *Renderer = @ptrCast(@alignCast(ptr));
    try self.render(frame.pixels, state.t);
}

fn compileKernel(allocator: std.mem.Allocator, context: cl_context, device: cl_device_id) !ProgramKernel {
    const source = try readKernelSource(allocator);
    defer allocator.free(source);

    var err: cl_int = CL_SUCCESS;
    const source_ptrs = [_][*]const u8{source.ptr};
    const source_lens = [_]usize{source.len};
    const program = clCreateProgramWithSource(context, 1, &source_ptrs, &source_lens, &err) orelse return error.OpenCLCreateProgramFailed;
    try check(err);
    errdefer _ = clReleaseProgram(program);

    const build_err = clBuildProgram(program, 1, @ptrCast(&device), null, null, null);
    if (build_err != CL_SUCCESS) {
        printBuildLog(allocator, program, device);
        return error.OpenCLBuildProgramFailed;
    }

    err = CL_SUCCESS;
    const kernel = clCreateKernel(program, "render", &err) orelse return error.OpenCLCreateKernelFailed;
    errdefer _ = clReleaseKernel(kernel);
    try check(err);

    return .{ .program = program, .kernel = kernel };
}

fn readKernelSource(allocator: std.mem.Allocator) ![]u8 {
    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    return std.Io.Dir.cwd().readFileAlloc(io, config.KERNEL_PATH, allocator, .limited(1024 * 1024));
}

fn kernelMtime() !u64 {
    var data: WIN32_FILE_ATTRIBUTE_DATA = undefined;
    if (GetFileAttributesExA(config.KERNEL_PATH, 0, &data) == 0) return error.KernelFileStatFailed;
    return data.ftLastWriteTime.asU64();
}

fn check(code: cl_int) !void {
    if (code != CL_SUCCESS) return error.OpenCLError;
}

fn printBuildLog(allocator: std.mem.Allocator, program: cl_program, device: cl_device_id) void {
    var log_size: usize = 0;
    _ = clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, null, &log_size);
    if (log_size == 0) return;

    const log = allocator.alloc(u8, log_size) catch return;
    defer allocator.free(log);

    _ = clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, log.len, log.ptr, null);
    std.debug.print("OpenCL build log:\n{s}\n", .{log});
}

fn loadOpenCL(lib: win32.HMODULE) !void {
    clGetPlatformIDs = try loadOpenCLSymbol(ClGetPlatformIDs, lib, "clGetPlatformIDs");
    clGetDeviceIDs = try loadOpenCLSymbol(ClGetDeviceIDs, lib, "clGetDeviceIDs");
    clCreateContext = try loadOpenCLSymbol(ClCreateContext, lib, "clCreateContext");
    clCreateCommandQueue = try loadOpenCLSymbol(ClCreateCommandQueue, lib, "clCreateCommandQueue");
    clCreateBuffer = try loadOpenCLSymbol(ClCreateBuffer, lib, "clCreateBuffer");
    clCreateProgramWithSource = try loadOpenCLSymbol(ClCreateProgramWithSource, lib, "clCreateProgramWithSource");
    clBuildProgram = try loadOpenCLSymbol(ClBuildProgram, lib, "clBuildProgram");
    clGetProgramBuildInfo = try loadOpenCLSymbol(ClGetProgramBuildInfo, lib, "clGetProgramBuildInfo");
    clCreateKernel = try loadOpenCLSymbol(ClCreateKernel, lib, "clCreateKernel");
    clSetKernelArg = try loadOpenCLSymbol(ClSetKernelArg, lib, "clSetKernelArg");
    clEnqueueNDRangeKernel = try loadOpenCLSymbol(ClEnqueueNDRangeKernel, lib, "clEnqueueNDRangeKernel");
    clEnqueueReadBuffer = try loadOpenCLSymbol(ClEnqueueReadBuffer, lib, "clEnqueueReadBuffer");
    clReleaseMemObject = try loadOpenCLSymbol(ClReleaseMemObject, lib, "clReleaseMemObject");
    clReleaseKernel = try loadOpenCLSymbol(ClReleaseKernel, lib, "clReleaseKernel");
    clReleaseProgram = try loadOpenCLSymbol(ClReleaseProgram, lib, "clReleaseProgram");
    clReleaseCommandQueue = try loadOpenCLSymbol(ClReleaseCommandQueue, lib, "clReleaseCommandQueue");
    clReleaseContext = try loadOpenCLSymbol(ClReleaseContext, lib, "clReleaseContext");
}

fn loadOpenCLSymbol(comptime T: type, lib: win32.HMODULE, name: [*:0]const u8) !T {
    const raw = win32.GetProcAddress(lib, name) orelse return error.OpenCLSymbolMissing;
    return @ptrCast(raw);
}
