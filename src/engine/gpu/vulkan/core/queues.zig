pub const Selection = struct {
    graphics: u32,
    present: u32,

    pub fn shared(self: Selection) bool {
        return self.graphics == self.present;
    }
};
