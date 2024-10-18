const std = @import("std");
const trie = @import("trie.zig");
const unscramble = @import("unscramble.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var unscrambler = try unscramble.Unscrambler.init(allocator);
    defer unscrambler.deinit();

    var file = try std.fs.cwd().openFile("dict", .{});
    defer file.close();

    try unscrambler.loadDictionary(&file);

    var matches = std.ArrayList([]u8).init(allocator);
    defer matches.deinit();

    var in_buf: [64]u8 = undefined;
    const stdin = std.io.getStdIn().reader();

    var accepting_input = true;
    while (accepting_input) {
        std.debug.print("Enter word to search: ", .{});
        const line = try stdin.readUntilDelimiter(&in_buf, '\n');
        if (std.mem.eql(u8, line, "q")) {
            accepting_input = false;
            std.debug.print("Exiting...\n", .{});
        }

        try unscrambler.unscramble(&matches, line);
        for (matches.items) |item| {
            std.debug.print("{s}\n", .{item});
        }
    }
}
