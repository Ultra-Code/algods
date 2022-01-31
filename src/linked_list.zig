const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;
const print = std.debug.print;

///A singly linked list
pub fn SinglyList(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            data: T,
            next: ?*Node,
        };

        pub const Iterator = struct {
            head: ?*Node,
            cursor: ?*Node,
            size: usize,

            pub fn next(it: *Iterator) ?T {
                if (it.cursor) |current_node| {
                    it.advancePointer();
                    return current_node.data;
                }
                return null;
            }

            pub fn reset(it: *Iterator) void {
                it.cursor = it.head;
            }

            fn advancePointer(it: *Iterator) void {
                // self.cursor = self.cursor.?.next;
                it.cursor = it.cursor.?.next;
            }

            ///position returns the Node at a given index.
            ///The index parameter is an integer value greater than 0 .ie index >= 1
            fn position(it: *Iterator, index: usize) ?*Node {
                //it.size + 1 to account for the end .ie null case
                const end = it.size + 1;
                assert(index > 0 and index <= end);
                var count: usize = 0;
                //index - 1 because we're are zero counting
                while (count < index - 1) : (count += 1) {
                    it.advancePointer();
                }
                if (it.cursor) |cursor| {
                    //reset it.cursor so that next call to position() starts from cursor
                    it.reset();
                    return cursor;
                } else {
                    return null;
                }
            }
        };

        head: ?*Node = null,
        allocator: std.mem.Allocator,
        size: usize = 0,

        ///iterator takes const Self so that it doesn't modify the actual data structure
        ///when changes are made to the data structure you need to call iterator again
        ///for a new Iterator that contains the canges made to the data structure
        pub fn iterator(self: Self) Iterator {
            return .{ .head = self.head, .cursor = self.head, .size = self.size };
        }

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

        fn increaseSize(self: *Self) void {
            self.size += 1;
        }

        fn decreaseSize(self: *Self) void {
            self.size -= 1;
        }

        ///Traverse list in linear time to the end and append value
        pub fn append(self: *Self, value: T) !void {
            var new_node = try self.createNode(value);
            //if head alread has some nodes traverse to insert position
            if (self.head) |node| {
                var head_node = node;
                while (head_node.next) |next_head| : (head_node = next_head) {} else {
                    //add new_node as the next node of the last node
                    head_node.next = new_node;
                    new_node.next = null;
                }
            } else {
                //if new_node is the first node then head points to the new_node
                self.head = new_node;
                new_node.next = null;
            }
            self.increaseSize();
        }

        pub fn appendAfter(self: *Self, index: usize, value: T) !void {
            assert(!self.isEmpty());

            var it = self.iterator();
            var node_at_index = it.position(index).?;

            var new_node = try self.createNode(value);

            new_node.next = node_at_index.next orelse null;
            node_at_index.next = new_node;
            self.increaseSize();
        }

        pub fn prepend(self: *Self, value: T) !void {
            var new_node = try self.createNode(value);
            if (self.head) |head| {
                //put new node before head
                new_node.next = head;
                //if a node goes before head ,then head has to be updated to point to the beginning of the list
                //let head point to new_node since new_node is at the beginning of the list
                self.head = new_node;
            } else {
                //when list is empty
                new_node.next = null;
                self.head = new_node;
            }
            self.increaseSize();
        }

        pub fn prependBefore(self: *Self, index: usize, value: T) !void {
            assert(!self.isEmpty());
            var it = self.iterator();
            var node_before_index = it.position(index - 1).?;

            var new_node = try self.createNode(value);

            new_node.next = node_before_index.next;
            node_before_index.next = new_node;

            self.increaseSize();
        }

        pub fn removeFirst(self: *Self) void {
            assert(!self.isEmpty());
            var current_head = self.head.?;
            var new_head = current_head.next orelse null;
            self.head = new_head;
            self.freeNode(current_head);
            self.decreaseSize();
        }

        pub fn remove(self: *Self, index: usize) void {
            assert(!self.isEmpty());
            var it = self.iterator();
            var node_before_delete_node = it.position(index - 1).?;
            const delete_node = node_before_delete_node.next.?;

            node_before_delete_node.next = delete_node.next;
            self.freeNode(delete_node);
            self.decreaseSize();
        }

        pub fn deinit(self: *Self) void {
            while (self.head) |delete_head| {
                self.head = delete_head.next;
                self.allocator.destroy(delete_head);
            }
            self.head = undefined;
            self.size = 0;
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
    try singlylist.prependBefore(2, 2);
    try expect(singlylist.head.?.next.?.data == 2);
    try singlylist.appendAfter(3, 4);
    try expect(singlylist.head.?.next.?.next.?.next.?.data == 4);
    singlylist.removeFirst();
    try expect(singlylist.head.?.data == 2);
    singlylist.remove(5);
    try expect(singlylist.head.?.next.?.next.?.next.?.data == 6);

    //test iterator

    var it = singlylist.iterator();
    // debugPrint("SinglyList{}", .{});
    // while (it.next()) |node| {
    //     debugPrint("node -> {}", .{node.data});
    // }

    // display(singlylist);
    try expect(it.position(2).?.data == 3);
    try singlylist.prepend(0);
    it = singlylist.iterator();
    try expect(it.position(1).?.data == 0);
    try expect(it.position(6) == null);
}

//TODO: if and when needed implement appendAfter/prependBefore/remove
///A circular singly linked list
pub fn SinglyCircularList(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            data: T,
            next: *Node,
        };

        pub const Iterator = struct {
            cursor: ?*Node,
            end: ?*Node,
            state: enum { stop, move } = .move,

            pub fn next(it: *Iterator) ?T {
                if (it.state == .stop or it.cursor == null) {
                    //reset Iterator so the next call to next() works .ie begin a new iteration
                    it.reset();
                    return null;
                }

                it.advanceCursor();
                if (it.cursor == it.end) {
                    //stop looping because we started at the end and have gotten there again
                    it.stop();
                    return it.end.?.data;
                }
                return it.cursor.?.data;
            }

            pub fn stop(it: *Iterator) void {
                it.state = .stop;
            }

            pub fn reset(it: *Iterator) void {
                it.cursor = it.end;
                it.state = .move;
            }

            ///rotate/circulate the circular list endlessly
            ///call stop() if you want to stop rotating
            pub fn rotate(it: *Iterator) ?T {
                if (it.state == .stop or it.cursor == null) {
                    //reset Iterator so the next call to rotate works
                    it.reset();
                    return null;
                }
                //Since cursor starst at the end move to the head before retreiving cursor
                it.advanceCursor();
                return it.cursor.?.data;
            }

            fn advanceCursor(it: *Iterator) void {
                it.cursor = it.cursor.?.next;
            }

            fn position(it: *Iterator, index: usize) ?*Node {
                //circular doesn't need to assert index <= end because there is no end
                var count: usize = 0;
                while (count < index) : (count += 1) {
                    it.advanceCursor();
                }
                if (it.cursor) |cursor| {
                    //reset it.cursor so that next call to position() starts from cursor
                    it.reset();
                    return cursor;
                } else {
                    return null;
                }
            }
        };

        allocator: std.mem.Allocator,
        cursor: ?*Node = null, //cursor points to the last node so that the next is the frist node

        ///iterator takes const Self so that it doesn't modify the actual data structure
        ///when changes are made to the data structure you need to call iterator again
        ///for a new Iterator that contains the canges made to the data structure
        pub fn iterator(self: Self) Iterator {
            return .{ .cursor = self.cursor, .end = self.cursor };
        }

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .allocator = allocator };
        }

        pub fn isEmpty(self: Self) bool {
            return if (self.cursor == null) true else false;
        }

        pub fn first(self: Self) T {
            assert(!self.isEmpty());
            return self.cursor.?.next.data;
        }

        pub fn last(self: Self) T {
            assert(!self.isEmpty());
            return self.cursor.?.data;
        }

        pub fn advanceCursor(it: *Self) void {
            it.cursor = it.cursor.?.next;
        }

        pub fn prepend(self: *Self, value: T) !void {
            var new_node = try self.allocator.create(Node);
            new_node.data = value;

            if (self.cursor) |cursor| {
                var current_cursor = cursor;
                new_node.next = current_cursor.next;
                current_cursor.next = new_node;
            } else {
                //If there is no node in the list
                new_node.next = new_node;
                self.cursor = new_node;
            }
        }

        pub fn append(self: *Self, value: T) !void {
            if (self.cursor) |cursor| {
                var new_node = try self.allocator.create(Node);
                new_node.data = value;

                var current_node = cursor;
                new_node.next = current_node.next;
                current_node.next = new_node;
                //cursor should point to the last node
                self.cursor = new_node;
            } else {
                try self.prepend(value);
            }
        }

        pub fn removeFirst(self: *Self) void {
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
            print("\n[ first ==> ", .{});
            while (itr.next()) |next_node| {
                print(" |{}| ", .{next_node});
            }
            print(" <== rear ]\n", .{});
        }

        pub fn deinit(self: *Self) void {
            while (!self.isEmpty()) {
                self.removeFirst();
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
    try expect(circularlist.first() == 2);
    try expect(circularlist.last() == 0);
    circularlist.advanceCursor();
    try expect(circularlist.first() == 1);
    try expect(circularlist.last() == 2);
    circularlist.advanceCursor();
    try circularlist.prepend(3);
    try expect(circularlist.first() == 3);
    try expect(circularlist.last() == 1);
    try circularlist.append(9);
    try expect(circularlist.last() == 9);

    //test displaying and iterating over SinglyCircularList

    // circularlist.display();
    var it = circularlist.iterator();
    try expect(it.position(2).?.data == 0);
    try expect(it.position(4).?.data == 1);

    // var count: usize = 0;
    // while (it.rotate()) |node| : (count += 1) {
    //     debugPrint("node {}", .{node.data});
    //     if (count == 10) break;
    // }
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
