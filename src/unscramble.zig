const std = @import("std");
const trie = @import("trie.zig");

pub const Unscrambler = struct {
    const Self = @This();

    dict: *trie.Trie,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Self {
        const dict = try allocator.create(trie.Trie);
        dict.* = try trie.Trie.init(allocator);

        return Self{
            .dict = dict,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.dict.deinit();
    }

    pub fn loadDictionary(self: *Self, file: *std.fs.File) !void {
        var buffered = std.io.bufferedReader(file.reader());
        var reader = buffered.reader();

        var buf: [256]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            try self.dict.insert(line);
        }
    }

    pub fn unscramble(self: *Self, matches: *std.ArrayList([]u8), letters: []const u8) !void {
        matches.clearAndFree();

        try self.recursiveUnscramble(self.dict.getRoot(), matches, "", letters);
    }

    fn recursiveUnscramble(self: *Self, current_node: *trie.TrieNode, matches: *std.ArrayList([]u8), building: []u8, letters: []const u8) !void {
        if (current_node.is_word) {
            try matches.append(building);
        }

        var i: usize = 0;
        while (i < letters.len) : (i += 1) {
            const char = std.ascii.toLower(letters[i]);
            const index: usize = char - 'a';

            const next_node = current_node.children[index];
            if (next_node == null) {
                continue;
            }

            var new_building = std.ArrayList(u8).init(self.allocator);
            defer new_building.deinit();
            try new_building.appendSlice(building);
            try new_building.append(char);

            var new_letters = std.ArrayList(u8).init(self.allocator);
            defer new_letters.deinit();
            try new_letters.appendSlice(letters);
            _ = new_letters.orderedRemove(i);

            const new_building_slice = try new_building.toOwnedSlice();
            const new_letters_slice = try new_letters.toOwnedSlice();

            try self.recursiveUnscramble(next_node.?, matches, new_building_slice, new_letters_slice);
        }
    }
};
