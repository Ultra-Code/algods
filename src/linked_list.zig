const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn SinglyList(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            data: T,
            next: ?*Node,
        };

        head: ?*Node = null,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        fn createNode(self: *Self, value: T) !*Node {
            var new_node = try self.allocator.create(Node);
            new_node.data = value;
            new_node.next = null;
            return new_node;
        }

        fn isEmpty(self: Self) bool {
            return if (self.head == null) true else false;
        }

        pub fn append(self: *Self, value: T) !void {
            var new_node = try self.createNode(value);
            //if head alread has some nodes traverse to insert position
            if (self.head) |node| {
                var head_node = node;
                while (head_node.next) |next_head| : (head_node = next_head) {} else {
                    head_node.next = new_node;
                }
            } else {
                //if new_node is the first node then head points to the new_node
                self.head = new_node;
            }
        }

        pub fn appendAfter(self: *Self, after: T, value: T) !void {
            assert(!self.isEmpty());
            const node = self.head.?;
            var current_head = node;
            if (node.data == after) {
                var new_node = try self.createNode(value);
                new_node.next = current_head.next orelse null;
                current_head.next = new_node;
                return;
            }
            while (current_head.next) |next_node| : (current_head = next_node) {
                if (next_node.data == after) {
                    var new_node = try self.createNode(value);
                    new_node.next = next_node.next orelse null;
                    var current_node = next_node;
                    current_node.next = new_node;
                    break;
                }
            } else {
                std.log.err("The value of after {} doesn't exist in the list", .{after});
                return error.ValueNotInList;
            }
        }

        pub fn prepend(self: *Self, value: T) !void {
            var new_node = try self.createNode(value);
            var head = self.head orelse {
                return try self.append(value);
            };
            //put new node before head
            new_node.next = head;
            //if a node goes before head ,then head has to be updated to point to the beginning of the list
            //let head point to new_node since new_node is at the beginning of the list
            self.head = new_node;
        }

        pub fn prependBefore(self: *Self, before: T, value: T) !void {
            assert(!self.isEmpty());
            const node = self.head.?;
            if (node.data == before) {
                try self.prepend(value);
                return;
            }
            var current_head = node;
            while (current_head.next) |next_node| : (current_head = next_node) {
                if (next_node.data == before) {
                    var new_node = try self.createNode(value);
                    new_node.next = next_node;
                    current_head.next = new_node;
                    break;
                }
            } else {
                std.log.err("The value of before {} doesn't exist in the list", .{before});
                return error.ValueNotInList;
            }
        }

        pub fn removeFirst(self: *Self) void {
            assert(!self.isEmpty());
            const node = self.head.?;
            var current_head = node;
            var new_head = current_head.next orelse null;
            self.head = new_head;
            self.freeNode(current_head);
        }

        pub fn removeLast(self: *Self) void {
            assert(!self.isEmpty());
            const node = self.head.?;
            var current_head = node;
            while (current_head.next) |next_node| : (current_head = next_node) {
                if (next_node.next == null) {
                    //becuase the current_head's next is going to be the new end
                    //and we don't want it refering to the deleted node which is next_node
                    current_head.next = null;
                }
            } else {
                self.freeNode(current_head);
            }
        }

        pub fn remove(self: *Self, value: T) !void {
            assert(!self.isEmpty());
            const node = self.head.?;
            if (node.data == value) {
                self.removeFirst();
                return;
            }
            var current_head = node;
            while (current_head.next) |next_node| : (current_head = next_node) {
                if (next_node.data == value) {
                    current_head.next = next_node.next orelse null;
                    var delete_node = next_node;
                    self.freeNode(delete_node);
                    break;
                }
            } else {
                return error.ValueNotInList;
            }
        }

        pub fn find(self: *const Self, value: T) ?*Node {
            assert(!self.isEmpty());
            const node = self.head.?;
            if (node.data == value) {
                return node;
            }
            var current_node = node;
            while (current_node.next) |next_node| : (current_node = next_node) {
                if (next_node.data == value) {
                    return next_node;
                }
            }
            return null;
        }

        pub fn deinit(self: *Self) void {
            while (self.head) |delete_head| {
                self.head = delete_head.next;
                self.allocator.destroy(delete_head);
            }
            self.head = undefined;
        }

        fn freeNode(self: *Self, node: *Node) void {
            self.allocator.destroy(node);
        }
    };
}

fn debugPrint(comptime message: []const u8, args: anytype) void {
    print("\n" ++ message ++ "\n", .{args});
}

fn display(self: anytype) void {
    // const Fields = comptime std.meta.fieldNames(@TypeOf(self));
    // if (!std.mem.eql(u8, Fields[0], "head")) { //and !(Fields.field_type == ?*Node)
    //     @compileError("Display expects a head field as the second file in " ++ @typeName(@TypeOf(self)) ++ " but found " ++ Fields[0]);
    // }
    // @compileLog("declarations in self are ", @typeInfo(@TypeOf(std.meta.declarations(@TypeOf(self))[1].data)));
    // @compileLog("declarations in self are ", std.meta.fieldInfo(@TypeOf(self), .head).field_type);
    if (!@hasDecl(@TypeOf(self), "Node")) {
        @compileError("self must be a doubly or singly linked list with a private Node data type");
    }
    if (!@hasField(@TypeOf(self), "head")) {
        @compileError("display expects a head field in " ++ @typeName(@TypeOf(self)) ++ " but found none");
    }
    // const self_head_field_info = std.meta.fieldInfo(@TypeOf(self), .head);
    // if (self_head_field_info.field_type ==
    //     std.meta.fieldInfo(@TypeOf(std.meta.declarations(@TypeOf(self))[1]), .head).field_type)
    // {
    //     @compileError("head field must be of type " ++ std.meta.declarations(@TypeOf(self))[1].data.Type);
    // }
    if (self.head) |node| {
        print("\n[ head ==> {} ", .{node.data});
        var current_head = node;
        while (current_head.next) |next_node| : (current_head = next_node) {
            print("next ==> {} ", .{next_node.data});
        } else {
            print("end ]\n", .{});
        }
    } else {
        print("\nList is empty []\n", .{});
    }
}

test "SinglyList" {
    var singlylist = SinglyList(u8).init(std.testing.allocator);
    defer singlylist.deinit();
    try singlylist.append(3);
    try expect(singlylist.head.?.data == 3);
    try singlylist.append(6);
    try singlylist.append(9);
    try expect(singlylist.head.?.next.?.next.?.data == 9);
    try singlylist.prepend(1);
    try expect(singlylist.head.?.data == 1);
    try singlylist.prependBefore(3, 2);
    try expect(singlylist.head.?.next.?.data == 2);
    try singlylist.appendAfter(3, 4);
    try expect(singlylist.head.?.next.?.next.?.next.?.data == 4);
    singlylist.removeFirst();
    try expect(singlylist.head.?.data == 2);
    singlylist.removeLast();
    try expect(singlylist.head.?.next.?.next.?.next.?.data == 6);
    try singlylist.remove(3);
    try expect(singlylist.head.?.next.?.data == 4);
    const found_2 = singlylist.find(2).?;
    try expect(found_2.data == 2);
}

pub fn SinglyCircularList(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            data: T,
            next: *Node,
        };
        allocator: std.mem.Allocator,
        cursor: ?*Node = null, //cursor points to the last node so that the next is the frist node

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        fn isEmpty(self: Self) bool {
            return if (self.cursor == null) true else false;
        }

        pub fn front(self: Self) T {
            assert(!self.isEmpty());
            return self.cursor.?.next.data;
        }

        pub fn back(self: Self) T {
            assert(!self.isEmpty());
            return self.cursor.?.data;
        }

        pub const Iterator = struct {
            list: *SinglyCircularList(T),
            end: *Node,
            state: enum { stop, move } = .move,

            pub fn next(it: *Iterator) ?*Node {
                if (it.state == .stop) {
                    return null;
                }
                it.list.advanceCursor();
                if (it.end == it.list.cursor.?) {
                    //This is needed because cursor points to the end for facilitating getting both end and first
                    //circle around back to end then set the stop state so the next iteration is prevented
                    if (it.state == .move) {
                        it.state = .stop;
                        return it.list.cursor;
                    }
                }
                return it.list.cursor;
            }

            pub fn reset(it: *Iterator) void {
                it.list.cursor = it.end;
            }
        };

        pub fn iterator(self: *Self) Iterator {
            return .{ .list = self, .end = self.cursor.? };
        }

        fn advanceCursor(self: *Self) void {
            self.cursor = self.cursor.?.next;
        }

        pub fn prepend(self: *Self, value: T) !void {
            var new_node = try self.allocator.create(Node);
            new_node.data = value;

            if (!self.isEmpty()) {
                var current_cursor = self.cursor.?;
                new_node.next = current_cursor.next;
                current_cursor.next = new_node;
            } else {
                new_node.next = new_node;
                self.cursor = new_node;
            }
        }

        pub fn remove(self: *Self) void {
            var remove_node = self.cursor.?.next;
            if (remove_node == self.cursor) {
                // removing the only node so that list is empty
                self.cursor = null;
            } else {
                // link out the old node
                self.cursor.?.next = remove_node.next;
            }
            self.allocator.destroy(remove_node);
        }

        pub fn display(self: *Self) void {
            assert(!self.isEmpty());
            var itr = self.iterator();
            print("\n[ front ==> ", .{});
            while (itr.next()) |next_node| {
                print(" |{}| ", .{next_node.data});
            }
            print(" <== rear ]\n", .{});
        }

        pub fn deinit(self: *Self) void {
            while (!self.isEmpty()) {
                self.remove();
            }
        }
    };
}

test "SinglyCircularList" {
    var circularlist = SinglyCircularList(u8).init(std.testing.allocator);
    defer circularlist.deinit();

    try circularlist.prepend(0);
    try circularlist.prepend(1);
    try circularlist.prepend(2);
    try expect(circularlist.front() == 2);
    try expect(circularlist.back() == 0);
    circularlist.advanceCursor();
    try expect(circularlist.front() == 1);
    try expect(circularlist.back() == 2);
    circularlist.advanceCursor();
    try circularlist.prepend(3);
    try expect(circularlist.front() == 3);
}

pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            data: T,
            next: ?*Node,
            previous: ?*Node,
        };
        head: ?*Node = null,
        tail: ?*Node = null,
        size: usize = 0,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        fn createNode(self: *const Self, value: T) !*Node {
            var new_node = try self.allocator.create(Node);
            new_node.data = value;
            new_node.next = null;
            new_node.previous = null;
            return new_node;
        }

        fn traverseToEnd(current_head: *Node) *Node {
            var head = current_head;
            while (current_head.next) |next_head| : (head = next_head) {}
            return head;
        }

        pub fn append(self: *Self, value: T) !void {
            var new_node = try self.createNode(value);
            if (self.tail) |tail_node| {
                new_node.previous = tail_node;
                new_node.next = null;
                tail_node.next = new_node;
            } else {
                self.head = new_node;
            }
            self.tail = new_node;
            self.size += 1;
        }

        fn traverseTo(current_head: *Node, value: T) !*Node {
            var head = current_head;
            while (head.next) |next_head| : (head = next_head) {
                const node_with_value = next_head;
                if (node_with_value.data == value) {
                    return node_with_value;
                }
            } else {
                return error.NoNodeWithSpecifiedValue;
            }
        }

        pub fn appendAfter(self: *Self, after: T, value: T) !void {
            if (self.head) |node| {
                if (node.data == after) {
                    var current_head = node;
                    var new_node = try self.createNode(value);
                    new_node.next = current_head.next;
                    new_node.previous = current_head;
                    current_head.next = new_node;
                    return;
                }

                //if after is not the first node
                var node_with_value = try traverseTo(node, after);
                //if node_with_value next isn't the tail or end
                if (node_with_value.next) |node_after_node_with_value| {
                    var new_node = try self.createNode(value);
                    new_node.next = node_after_node_with_value;
                    new_node.previous = node_with_value;
                    node_after_node_with_value.previous = new_node;
                    node_with_value.next = new_node;
                } else {
                    try self.append(value);
                }
            }
        }

        fn isEmpty(self: Self) bool {
            return if (self.head == null) true else false;
        }

        pub fn prepend(self: *Self, value: T) !void {
            if (self.head) |node| {
                var new_node = try self.createNode(value);
                new_node.next = node;
                node.previous = new_node;
                self.head = new_node;
                self.size += 1;
            } else {
                try self.append(value);
            }
        }

        pub fn prependBefore(self: *Self, before: T, value: T) !void {
            assert(!self.isEmpty());
            const node = self.head.?;
            if (node.data == before) {
                try self.prepend(value);
            }
            var node_with_value = try traverseTo(node, before);
            var new_node = try self.createNode(value);
            new_node.next = node_with_value;
            new_node.previous = node_with_value.previous;
            node_with_value.previous.?.next = new_node;
            node_with_value.previous = new_node;
        }

        pub fn find(self: *Self, value: T) ?*Node {
            if (self.head) |node| {
                return traverseTo(node, value) catch null;
            }
            return null;
        }

        pub fn removeFirst(self: *Self) void {
            assert(!self.isEmpty());
            var current_head = self.head.?;
            if (current_head.next) |next_head| {
                var new_head = next_head;
                new_head.previous = null;
                self.head = new_head;
            } else {
                //if after removing the current_head there are no more nodes
                self.head = null;
                self.tail = null;
            }
            self.freeNode(current_head);
        }

        pub fn removeLast(self: *Self) void {
            var current_tail = self.tail.?;
            var new_tail = current_tail.previous;
            current_tail.previous.?.next = null;
            self.tail = new_tail;
            self.freeNode(current_tail);
        }

        pub fn remove(self: *Self, value: T) !void {
            assert(!self.isEmpty());
            const node = self.head.?;
            const remove_node = try traverseTo(node, value);
            var node_to_remove = remove_node;
            node_to_remove.previous.?.next = remove_node.next;
            node_to_remove.next.?.previous = remove_node.previous;
            self.freeNode(remove_node);
        }

        fn freeNode(self: *Self, memory: anytype) void {
            self.allocator.destroy(memory);
        }

        pub fn deinit(self: *Self) void {
            while (self.tail) |node| {
                self.tail = node.previous;
                self.allocator.destroy(node);
            }
            self.head = undefined;
            self.tail = undefined;
        }
    };
}

test "List" {
    var list = List(u8).init(std.testing.allocator);
    defer list.deinit();
    try list.append(2);
    try list.append(4);
    try expect(list.head.?.data == 2);
    try expect(list.tail.?.data == 4);
    try expect(list.size == 2);
    try list.prepend(1);
    try expect(list.head.?.data == 1);
    try expect(list.tail.?.data == 4 and list.size == 3);
    try list.prependBefore(4, 3);
    try expect(list.head.?.next.?.next.?.data == 3);
    try list.appendAfter(4, 5);
    try expect(list.head.?.next.?.next.?.next.?.next.?.data == 5);
    try list.append(6);
    try expect(list.tail.?.data == 6);
    const found_data = list.find(3);
    try expect(found_data.?.data == 3);
    list.removeFirst();
    try expect(list.head.?.data == 2);
    list.removeLast();
    try expect(list.tail.?.data == 5);
    try list.remove(4);
    const find_4 = list.find(4);
    try expect(find_4 == null);
    try list.prepend(1);
    try expect(list.head.?.data == 1);
    try expect(list.tail.?.data == 5);
}
