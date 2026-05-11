const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const engine = @import("engine");
const project = @import("project");

const asset_io = engine.asset.io;
const AssetWatcher = engine.asset.Watcher;
const config = engine.config;
const gpu = engine.gpu;
const game = project.game;
const time = engine.time;

const SCENE_PATH = "assets/scene/default.zon";
const SCENE_RELOAD_DEBOUNCE_SECONDS = 0.25;
const SceneBundle = project.SceneBundle;
const use_debug_allocator = builtin.mode == .Debug;

pub fn main() !void {
    if (comptime use_debug_allocator) {
        var debug_allocator: std.heap.DebugAllocator(.{}) = .{};
        defer if (debug_allocator.deinit() == .leak) {
            std.debug.print("memory leaks detected\n", .{});
        };

        const allocator = debug_allocator.allocator();
        var threaded = std.Io.Threaded.init(allocator, .{});
        defer threaded.deinit();
        try run(allocator, threaded.io());
    } else {
        const allocator = std.heap.smp_allocator;
        var threaded = std.Io.Threaded.init(allocator, .{});
        defer threaded.deinit();
        try run(allocator, threaded.io());
    }
}

fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const assets = asset_io.AssetIo{ .io = io };

    var app_window = try engine.platform.createWindow();
    defer app_window.deinit();

    var graphics = try gpu.Graphics.init(allocator, app_window);
    defer graphics.deinit();
    var presenter = graphics.presenter();
    const scene_renderer = engine.render.Renderer{};

    var scene_bundle = try SceneBundle.load(allocator, &assets, &graphics);
    defer scene_bundle.deinit();
    var scene_watcher: ?AssetWatcher = if (build_options.enable_hot_reload)
        try AssetWatcher.init(allocator, &assets, SCENE_PATH, SCENE_RELOAD_DEBOUNCE_SECONDS)
    else
        null;

    std.debug.print("Active presenter: {s}\n", .{graphics.deviceName()});
    std.debug.print("Uploaded scene packet: vertices={} indices={} draws={}\n", .{
        scene_bundle.resources.vertexCount(),
        scene_bundle.resources.indexCount(),
        scene_bundle.resources.drawCount(),
    });

    var state = game.State{};
    var frame_timer = try time.Timer.start();
    var fixed_step = time.FixedStep.init(config.FIXED_DT);
    var frame_metrics = time.FrameMetrics{};

    while (state.running) {
        const pump = app_window.pump();
        state.running = pump.should_run;
        if (pump.resized) {
            std.debug.print("WM_SIZE client={}x{}\n", .{ pump.size.width, pump.size.height });
            if (pump.size.width > 0 and pump.size.height > 0) {
                engine.render.presentation.recreate(SceneBundle, asset_io.AssetIo, gpu.Graphics, allocator, &assets, &graphics, &scene_bundle) catch |recreate_err| {
                    std.debug.print("Presentation recreate failed after WM_SIZE: {}\n", .{recreate_err});
                    state.running = false;
                };
                presenter = graphics.presenter();
                continue;
            }
        }

        const frame_dt = frame_timer.lap();
        if (build_options.enable_hot_reload) {
            if (scene_watcher.?.update(frame_dt) catch |err| blk: {
                std.debug.print("Scene reload watch failed: {}\n", .{err});
                break :blk false;
            }) {
                graphics.waitIdle() catch |err| {
                    std.debug.print("Scene reload skipped; device wait failed: {}\n", .{err});
                    continue;
                };
                const next_scene_bundle = SceneBundle.load(allocator, &assets, &graphics) catch |err| {
                    std.debug.print("Scene reload failed; keeping previous scene: {}\n", .{err});
                    continue;
                };
                scene_bundle.deinit();
                scene_bundle = next_scene_bundle;
                std.debug.print("Scene reloaded: vertices={} indices={} draws={}\n", .{
                    scene_bundle.resources.vertexCount(),
                    scene_bundle.resources.indexCount(),
                    scene_bundle.resources.drawCount(),
                });
            }
        }

        fixed_step.beginFrame(frame_dt);
        while (fixed_step.consumeUpdate()) {
            game.update(&state, fixed_step.step());
            frame_metrics.recordUpdate();
        }
        scene_bundle.scene.syncFromGame(&state);

        const clear_color = engine.math.color.animatedClear(scene_bundle.scene.render.time);
        var frame = presenter.beginFrame() catch |err| switch (err) {
            error.PresentationOutOfDate => {
                engine.render.presentation.recreate(SceneBundle, asset_io.AssetIo, gpu.Graphics, allocator, &assets, &graphics, &scene_bundle) catch |recreate_err| {
                    std.debug.print("Presentation recreate failed: {}\n", .{recreate_err});
                    state.running = false;
                };
                presenter = graphics.presenter();
                continue;
            },
            else => return err,
        };
        try scene_renderer.renderFrame(
            frame.commandBuffer(),
            &scene_bundle.resources,
            &scene_bundle.scene.render,
            frame.width,
            frame.height,
            clear_color,
        );
        const result = try presenter.endFrame(frame);
        switch (result) {
            .presented => {},
            .suboptimal => {
                engine.render.presentation.recreate(SceneBundle, asset_io.AssetIo, gpu.Graphics, allocator, &assets, &graphics, &scene_bundle) catch |recreate_err| {
                    std.debug.print("Presentation recreate failed: {}\n", .{recreate_err});
                    state.running = false;
                };
                presenter = graphics.presenter();
            },
            .out_of_date => {
                engine.render.presentation.recreate(SceneBundle, asset_io.AssetIo, gpu.Graphics, allocator, &assets, &graphics, &scene_bundle) catch |recreate_err| {
                    std.debug.print("Presentation recreate failed: {}\n", .{recreate_err});
                    state.running = false;
                };
                presenter = graphics.presenter();
            },
        }

        frame_metrics.recordFrame(frame_dt);
        frame_metrics.reportIfDue();
    }
}
