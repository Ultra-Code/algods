const std = @import("std");
const linked_list = @import("linked_list.zig");
const stack = @import("stack.zig");
const queue = @import("queue.zig");

test {
    std.testing.refAllDecls(@This());
}
