pub const State = struct {
    running: bool = true,
    t: f32 = 0,
    cube_angle: f32 = 0,
    pyramid_angle: f32 = 0,
};

pub fn update(state: *State, dt: f32) void {
    state.t += dt;
    state.cube_angle += dt * 0.9;
    state.pyramid_angle -= dt * 1.3;
}
