const std = @import("std");
pub const linked_list = @import("linked_list.zig");
pub const stack = @import("stack.zig");
pub const queue = @import("queue.zig");

test {
    std.testing.refAllDecls(@This());
}
