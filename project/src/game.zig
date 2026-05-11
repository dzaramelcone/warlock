const engine = @import("engine");
const Seconds = engine.time.Seconds;

pub const State = struct {
    running: bool = true,
    t: Seconds = 0,
    cube_angle: Seconds = 0,
    pyramid_angle: Seconds = 0,
};

pub fn update(state: *State, dt: Seconds) void {
    state.t += dt;
    state.cube_angle += dt * 0.9;
    state.pyramid_angle -= dt * 1.3;
}
