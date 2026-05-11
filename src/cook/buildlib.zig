const std = @import("std");

pub const Options = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    engine_module: *std.Build.Module,
    project_assets_dir: []const u8,
    glslang: []const u8,
};

pub const Result = struct {
    module: *std.Build.Module,
    exe: *std.Build.Step.Compile,
};

const TextureJob = struct {
    source: []const u8,
    output: []const u8,
};

pub fn addSteps(b: *std.Build, options: Options) Result {
    const zigimg_dependency = b.dependency("zigimg", .{
        .target = options.target,
        .optimize = options.optimize,
    });

    const module = b.createModule(.{
        .root_source_file = b.path("src/cook/mod.zig"),
        .target = options.target,
        .optimize = options.optimize,
    });
    module.addImport("engine", options.engine_module);
    module.addImport("zigimg", zigimg_dependency.module("zigimg"));

    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/cook/main.zig"),
        .target = options.target,
        .optimize = options.optimize,
        .link_libc = true,
    });
    exe_module.addImport("engine", options.engine_module);
    exe_module.addImport("zigimg", zigimg_dependency.module("zigimg"));

    const exe = b.addExecutable(.{
        .name = "warlock-cook",
        .root_module = exe_module,
    });

    const texture_jobs = discoverTextureJobs(b, options.project_assets_dir);
    installCookedAssets(b, exe, options.project_assets_dir, texture_jobs);

    const shader_step = b.step("shaders", "Compile GLSL shaders to SPIR-V");
    installShader(b, shader_step, options.glslang, b.fmt("{s}/shaders/scene.vert", .{options.project_assets_dir}), "scene.vert.spv");
    installShader(b, shader_step, options.glslang, b.fmt("{s}/shaders/scene.frag", .{options.project_assets_dir}), "scene.frag.spv");

    return .{
        .module = module,
        .exe = exe,
    };
}

fn discoverTextureJobs(b: *std.Build, project_assets_dir: []const u8) []TextureJob {
    var threaded = std.Io.Threaded.init(b.allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const texture_source_dir = b.fmt("{s}/textures", .{project_assets_dir});
    var dir = std.Io.Dir.cwd().openDir(io, texture_source_dir, .{ .iterate = true }) catch |err|
        std.debug.panic("failed to open project texture directory '{s}': {s}", .{ texture_source_dir, @errorName(err) });
    defer dir.close(io);

    var walker = dir.walk(b.allocator) catch @panic("OOM");
    defer walker.deinit();

    var jobs = std.ArrayList(TextureJob).initCapacity(b.allocator, 0) catch @panic("OOM");
    while (walker.next(io) catch |err| std.debug.panic("failed to scan project texture directory '{s}': {s}", .{ texture_source_dir, @errorName(err) })) |entry| {
        if (entry.kind != .file or !isCookedTextureSource(entry.path)) continue;

        const texture_path = normalizeAssetPath(b, entry.path);
        const extension_start = std.mem.lastIndexOfScalar(u8, texture_path, '.') orelse texture_path.len;
        const stem = texture_path[0..extension_start];

        jobs.append(b.allocator, .{
            .source = b.fmt("textures/{s}", .{texture_path}),
            .output = b.fmt("textures/{s}.wtex", .{stem}),
        }) catch @panic("OOM");
    }

    return jobs.toOwnedSlice(b.allocator) catch @panic("OOM");
}

fn normalizeAssetPath(b: *std.Build, path: []const u8) []const u8 {
    const normalized = b.dupe(path);
    for (normalized) |*byte| {
        if (byte.* == '\\') {
            byte.* = '/';
        }
    }
    return normalized;
}

fn isCookedTextureSource(path: []const u8) bool {
    return std.mem.endsWith(u8, path, ".png") or
        std.mem.endsWith(u8, path, ".tga") or
        std.mem.endsWith(u8, path, ".exr") or
        std.mem.endsWith(u8, path, ".tif") or
        std.mem.endsWith(u8, path, ".tiff");
}

fn installCookedAssets(
    b: *std.Build,
    cook_exe: *std.Build.Step.Compile,
    project_assets_dir: []const u8,
    texture_jobs: []const TextureJob,
) void {
    const cook_step = b.step("cook", "Cook project assets");
    for (texture_jobs) |texture| {
        const run = b.addRunArtifact(cook_exe);
        run.addFileArg(b.path(b.fmt("{s}/{s}", .{ project_assets_dir, texture.source })));
        const cooked = run.addOutputFileArg(texture.output);

        const install_path = b.fmt("assets/{s}", .{texture.output});
        const install = b.addInstallFileWithDir(cooked, .prefix, install_path);
        cook_step.dependOn(&install.step);
        b.getInstallStep().dependOn(&install.step);
    }
}

fn installShader(
    b: *std.Build,
    shader_step: *std.Build.Step,
    glslang: []const u8,
    source_path: []const u8,
    output_name: []const u8,
) void {
    const compile = b.addSystemCommand(&.{ glslang, "-V" });
    compile.addFileArg(b.path(source_path));
    compile.addArg("-o");
    const spv = compile.addOutputFileArg(output_name);
    compile.addFileInput(b.path(source_path));

    const install_path = b.fmt("assets/shaders/{s}", .{output_name});
    const install = b.addInstallFileWithDir(spv, .prefix, install_path);
    shader_step.dependOn(&install.step);
    b.getInstallStep().dependOn(&install.step);
}
