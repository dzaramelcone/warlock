const std = @import("std");
const engine = @import("engine");
const project = @import("project");
const cook = @import("cook");

test {
    std.testing.refAllDecls(engine.images);
    std.testing.refAllDecls(engine.asset.mesh);
    std.testing.refAllDecls(engine.gpu.api);
    std.testing.refAllDecls(engine.gpu.Api);
    std.testing.refAllDecls(engine.render.gpu_scene);
    std.testing.refAllDecls(project.scene);
    std.testing.refAllDecls(cook.images);
}
