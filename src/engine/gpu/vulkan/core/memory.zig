pub const TypeInfo = struct {
    index: u32,
    flags: u32,
};

pub fn findType(memory_types: []const TypeInfo, memory_type_bits: u32, required_flags: u32) ?u32 {
    for (memory_types) |memory_type| {
        const bit = @as(u32, 1) << @as(u5, @intCast(memory_type.index));
        if ((memory_type_bits & bit) != 0 and (memory_type.flags & required_flags) == required_flags) {
            return memory_type.index;
        }
    }
    return null;
}
