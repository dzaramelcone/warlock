const std = @import("std");
const cook = @import("src/cook/buildlib.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const enable_hot_reload = b.option(bool, "hot-reload", "Enable development hot reload") orelse (optimize == .Debug);
    const project_dir = b.option([]const u8, "project-dir", "Project directory containing src/ and assets/") orelse "project";
    const project_src_dir = b.fmt("{s}/src", .{project_dir});
    const project_assets_dir = b.fmt("{s}/assets", .{project_dir});
    const glslang = b.option([]const u8, "glslang", "Path to glslangValidator executable") orelse
        b.findProgram(&.{ "glslangValidator.exe", "glslangValidator" }, &.{
            "C:\\VulkanSDK\\1.4.341.1\\Bin",
        }) catch @panic("glslangValidator not found; install the Vulkan SDK or pass -Dglslang=path\\to\\glslangValidator.exe");

    const options = b.addOptions();
    options.addOption(bool, "enable_hot_reload", enable_hot_reload);

    const engine_module = b.createModule(.{
        .root_source_file = b.path("src/engine/runtime.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    engine_module.linkSystemLibrary("user32", .{});

    const project_module = b.createModule(.{
        .root_source_file = b.path(b.fmt("{s}/mod.zig", .{project_src_dir})),
        .target = target,
        .optimize = optimize,
    });
    project_module.addImport("engine", engine_module);

    const cook_steps = cook.addSteps(b, .{
        .target = target,
        .optimize = optimize,
        .engine_module = engine_module,
        .project_assets_dir = project_assets_dir,
        .glslang = glslang,
    });

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    root_module.addOptions("build_options", options);
    root_module.addImport("engine", engine_module);
    root_module.addImport("project", project_module);
    root_module.linkSystemLibrary("user32", .{});

    const exe = b.addExecutable(.{
        .name = "warlock",
        .root_module = root_module,
    });

    b.installArtifact(exe);
    b.installDirectory(.{
        .source_dir = b.path(project_assets_dir),
        .install_dir = .prefix,
        .install_subdir = "assets",
        .exclude_extensions = &.{ ".spv", ".png", ".psd", ".tga", ".exr", ".tif", ".tiff" },
    });

    const test_module = b.createModule(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    test_module.addOptions("build_options", options);
    test_module.addImport("engine", engine_module);
    test_module.addImport("project", project_module);
    test_module.addImport("cook", cook_steps.module);
    test_module.linkSystemLibrary("user32", .{});

    const tests = b.addTest(.{
        .name = "warlock-tests",
        .root_module = test_module,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.setCwd(.{ .cwd_relative = b.install_path });
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run Warlock");
    run_step.dependOn(&run_cmd.step);
}
