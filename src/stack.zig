const std = @import("std");

//NOTE: Also implement a ComptimeStack backed by a static array
///A stack .ie LIFO data structure
fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();
        data: std.ArrayList(T),
        size: usize = 0,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .data = std.ArrayList(T).init(allocator) };
        }

        pub fn push(self: *Self, value: T) void {
            self.data.append(value) catch |err| {
                std.debug.panic("{s} occured", .{@errorName(err)});
                std.process.exit(1);
            };
            self.size += 1;
        }

        pub fn pop(self: *Self) T {
            self.size -= 1;
            return self.data.pop();
        }

        pub fn isEmpty(self: Self) bool {
            return if (self.size == 0) true else false;
        }

        pub fn top(self: Self) !T {
            if (self.isEmpty()) {
                return error.StackIsEmpty;
            }
            return self.data.items[self.size - 1];
        }

        pub fn deinit(self: Self) void {
            self.data.deinit();
        }
    };
}

const expect = std.testing.expect;
test "Stack" {
    var stack = Stack(u8).init(std.testing.allocator);
    defer stack.deinit();

    stack.push(1);
    try expect((try stack.top()) == 1);
    stack.push(2);
    stack.push(3);
    try expect((try stack.top()) == 3);
    _ = stack.pop();
    try expect((try stack.top()) == 2);
    try expect(stack.size == 2);
    try expect(stack.isEmpty() == false);
}
