const std = @import("std");

pub fn recreate(
    comptime SceneBundle: type,
    comptime Assets: type,
    comptime Graphics: type,
    allocator: std.mem.Allocator,
    assets: *const Assets,
    graphics: *Graphics,
    scene_bundle: *SceneBundle,
) !void {
    std.debug.print("Recreate presentation: wait idle\n", .{});
    try graphics.waitIdle();

    std.debug.print("Recreate presentation: create presenter\n", .{});
    try graphics.recreatePresentation();

    std.debug.print("Recreate presentation: reload scene resources\n", .{});
    var next_scene_bundle = try SceneBundle.load(allocator, assets, graphics);
    errdefer next_scene_bundle.deinit();

    std.debug.print("Recreate presentation: swap resources\n", .{});
    scene_bundle.deinit();
    scene_bundle.* = next_scene_bundle;

    std.debug.print("Presentation recreated: vertices={} indices={} draws={}\n", .{
        scene_bundle.resources.vertexCount(),
        scene_bundle.resources.indexCount(),
        scene_bundle.resources.drawCount(),
    });
}
