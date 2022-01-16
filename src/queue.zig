const std = @import("std");
const list = @import("linked_list.zig");

//TODO: If need by implement Deque

pub fn Queue(comptime T: type) type {
    return struct {
        const ListType = list.SinglyList(T);
        const Self = @This();
        data: ListType,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .data = ListType.init(allocator) };
        }

        pub fn enqueue(self: *Self, value: T) !void {
            try self.data.append(value);
        }

        pub fn dequeue(self: *Self) !void {
            self.data.removeFirst() catch return error.ErrorCannotDequeueAnEmptyQueue;
        }

        pub fn peek(self: Self) ?T {
            const front = self.data.head orelse return null;
            return front.data;
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit();
        }
    };
}

test "Queue" {
    var queue = Queue(u8).init(std.testing.allocator);
    defer queue.deinit();

    try queue.enqueue(0);
    try std.testing.expect(queue.peek().? == 0);
    try queue.dequeue();
    try std.testing.expectError(error.ErrorCannotDequeueAnEmptyQueue, queue.dequeue());
    try std.testing.expect(queue.peek() == null);
}

//REFERENCE_IMPLE: https://towardsdatascience.com/circular-queue-or-ring-buffer-92c7b0193326
///A circular queue or ring buffer is essentially a queue with a maximum size or
///capacity which will continue to loop back over itself in a circular motion
//NOTE: RingBuffer could also use a circular linkded list as it backing container
fn RingBuffer(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();
        allocator: std.mem.Allocator,
        data: []T,
        rear_index: usize = std.math.maxInt(usize), // maxInt conpensates for +1 so that first insertion is at 0
        front_index: usize = 0,
        size: usize = 0,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .data = allocator.alloc(T, capacity) catch std.debug.panic("cannot allocate RingBuffer of size {},allocator is out of memory", .{capacity}),
            };
        }

        pub fn enqueue(self: *Self, value: T) !void {
            if (self.size == capacity) {
                return error.RingBufferOverflow;
            }

            self.size += 1;
            //wrap around to index 0 after reaching capacity
            self.rear_index = (self.rear_index +% 1) % capacity;
            self.data[self.rear_index] = value;
        }

        pub fn dequeue(self: *Self) !T {
            if (self.size == 0) {
                return error.RingBufferEmpty;
            }
            const current_front = self.data[self.front_index];
            self.front_index = (self.front_index + 1) % capacity;
            self.size -= 1;
            return current_front;
        }

        pub fn peekFront(self: Self) T {
            return self.data[self.front_index];
        }

        pub fn peekEnd(self: Self) T {
            return self.data[self.rear_index];
        }

        pub fn display(self: Self) void {
            std.debug.assert(self.size != 0);
            var index = self.front_index;
            var counter: usize = 0;
            std.debug.print("\n-->", .{});
            while (counter < capacity) : ({
                counter += 1;
                index = (index + 1) % capacity;
            }) {
                std.debug.print("|{}", .{self.data[index]});
            }
            std.debug.print("|<--\n", .{});
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.data);
        }
    };
}

test "RingBuffer" {
    var ringbuffer = RingBuffer(u8, 6).init(std.testing.allocator);
    defer ringbuffer.deinit();

    try ringbuffer.enqueue(1);
    try ringbuffer.enqueue(2);
    try ringbuffer.enqueue(3);
    try ringbuffer.enqueue(4);
    try ringbuffer.enqueue(5);
    try ringbuffer.enqueue(6);
    try std.testing.expectError(error.RingBufferOverflow, ringbuffer.enqueue(7));
    const dequeue = try ringbuffer.dequeue();
    try std.testing.expect(dequeue == 1);
    _ = try ringbuffer.dequeue();
    try ringbuffer.enqueue(7);
    try ringbuffer.enqueue(8);
    try std.testing.expect(ringbuffer.peekFront() == 3);
    try std.testing.expect(ringbuffer.peekEnd() == 8);
}
