const std = @import("std");
const api = @import("api.zig");

pub const binding_alignment = 256;

pub fn allocBytes(graphics: anytype, bytes: usize, alignment: usize, memory: api.Memory) !api.GpuByteSlice {
    if (bytes == 0) return .{};
    const ptr = try graphics.mallocAligned(bytes, alignment, memory);
    return .{
        .ptr = ptr,
        .len = bytes,
    };
}

pub fn allocSlice(graphics: anytype, comptime T: type, len: usize, memory: api.Memory) !api.GpuSlice(T) {
    if (len == 0) return .{};
    const bytes = try std.math.mul(usize, len, @sizeOf(T));
    const ptr = try graphics.mallocAligned(bytes, @max(@alignOf(T), binding_alignment), memory);
    return .{
        .ptr = ptr,
        .len = len,
    };
}

pub fn allocValue(graphics: anytype, comptime T: type, memory: api.Memory) !api.GpuPtr {
    const ptr = try graphics.mallocAligned(@sizeOf(T), @max(@alignOf(T), binding_alignment), memory);
    return ptr;
}

pub fn allocAndWriteBytes(graphics: anytype, bytes: []const u8, alignment: usize, memory: api.Memory) !api.GpuByteSlice {
    const allocation = try allocBytes(graphics, bytes.len, alignment, memory);
    errdefer free(graphics, allocation.ptr);
    try writeBytes(graphics, allocation, bytes);
    return allocation;
}

pub fn allocAndWriteSlice(graphics: anytype, comptime T: type, values: []const T, memory: api.Memory) !api.GpuSlice(T) {
    const allocation = try allocSlice(graphics, T, values.len, memory);
    errdefer free(graphics, allocation.ptr);
    try writeSlice(graphics, T, allocation, values);
    return allocation;
}

pub fn allocAndWriteValue(graphics: anytype, comptime T: type, value: T, memory: api.Memory) !api.GpuPtr {
    const ptr = try allocValue(graphics, T, memory);
    errdefer free(graphics, ptr);
    try writeValue(graphics, T, ptr, value);
    return ptr;
}

pub fn writeBytes(graphics: anytype, dest: api.GpuByteSlice, bytes: []const u8) !void {
    if (bytes.len > dest.len) return error.GpuWriteOutOfBounds;
    if (bytes.len == 0) return;
    try graphics.writeBytes(dest.ptr, bytes);
}

pub fn writeSlice(graphics: anytype, comptime T: type, dest: api.GpuSlice(T), values: []const T) !void {
    if (values.len > dest.len) return error.GpuWriteOutOfBounds;
    if (values.len == 0) return;
    try graphics.writeSlice(T, dest.ptr, values);
}

pub fn writeValue(graphics: anytype, comptime T: type, ptr: api.GpuPtr, value: T) !void {
    const values = [_]T{value};
    try graphics.writeSlice(T, ptr, values[0..]);
}

pub fn free(graphics: anytype, ptr: api.GpuPtr) void {
    if (!ptr.isNone()) graphics.free(ptr) catch {};
}

test "typed gpu helpers allocate aligned slices" {
    const fake = @import("fake.zig");
    var graphics = try fake.Graphics.init(std.testing.allocator, {});
    defer graphics.deinit();

    const values = [_]u32{ 1, 2, 3, 4 };
    const slice = try allocAndWriteSlice(&graphics, u32, values[0..], .default);
    defer free(&graphics, slice.ptr);

    try std.testing.expectEqual(@as(usize, values.len), slice.len);
    try std.testing.expect(!slice.ptr.isNone());
}
