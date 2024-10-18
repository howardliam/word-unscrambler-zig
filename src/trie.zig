const std = @import("std");
const Allocator = std.mem.Allocator;

pub const TrieNode = struct {
    const Self = @This();

    char: ?u8,
    is_word: bool,
    children: [26]?*Self,

    pub fn init(char: ?u8) Self {
        return Self{
            .char = char,
            .is_word = false,
            .children = [1]?*Self{null} ** 26,
        };
    }
};

pub const Trie = struct {
    const Self = @This();

    root: *TrieNode,
    arena: std.heap.ArenaAllocator,

    pub fn init(allocator: Allocator) !Self {
        var arena = std.heap.ArenaAllocator.init(allocator);
        var alloc = arena.allocator();

        const root = try alloc.create(TrieNode);
        root.* = TrieNode.init(null);

        return Self{
            .root = root,
            .arena = arena,
        };
    }

    pub fn deinit(self: *Self) void {
        defer self.arena.deinit();
    }

    pub fn insert(self: *Self, word: []const u8) !void {
        var allocator = self.arena.allocator();

        var current_node = self.root;

        for (word) |char| {
            const ch = std.ascii.toLower(char);
            const index: usize = ch - 'a';
            if (current_node.children[index]) |child| {
                current_node = child;
            } else {
                const node = try allocator.create(TrieNode);
                node.* = TrieNode.init(ch);
                current_node.children[index] = node;
                current_node = node;
            }
        }
        current_node.is_word = true;
    }

    pub fn search(self: *const Self, word: []const u8) bool {
        var current_node = self.root;

        for (word) |char| {
            const ch = std.ascii.toLower(char);
            const index: usize = ch - 'a';

            if (current_node.children[index]) |child| {
                current_node = child;
            } else {
                return false;
            }
        }
        return current_node.is_word;
    }

    pub fn getRoot(self: *Self) *TrieNode {
        return self.root;
    }
};
