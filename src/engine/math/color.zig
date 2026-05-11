pub const Rgb8 = struct {
    r: u32,
    g: u32,
    b: u32,

    pub fn fromPacked(value: u32) Rgb8 {
        return .{
            .r = (value >> 16) & 0xff,
            .g = (value >> 8) & 0xff,
            .b = value & 0xff,
        };
    }

    pub fn toPacked(self: Rgb8) u32 {
        return ((self.r & 0xff) << 16) | ((self.g & 0xff) << 8) | (self.b & 0xff);
    }
};

pub fn averagePackedRgb(a: u32, b: u32, c: u32) u32 {
    const ar = Rgb8.fromPacked(a);
    const br = Rgb8.fromPacked(b);
    const cr = Rgb8.fromPacked(c);
    return (Rgb8{
        .r = (ar.r + br.r + cr.r) / 3,
        .g = (ar.g + br.g + cr.g) / 3,
        .b = (ar.b + br.b + cr.b) / 3,
    }).toPacked();
}

pub fn averageAccumulatedPackedRgb(r: u32, g: u32, b: u32, count: u32) u32 {
    if (count == 0) return 0;
    return (Rgb8{
        .r = r / count,
        .g = g / count,
        .b = b / count,
    }).toPacked();
}
