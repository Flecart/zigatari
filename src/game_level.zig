const std = @import("std");
const GameObject = @import("game_object.zig");
const SpriteRenderer = @import("sprite_renderer.zig");

const Self = @This();

bricks: std.ArrayList(GameObject),


pub fn init() Self {

}

pub fn load(self: Self, file: []const u8, levelWidth: usize, levelHeight: usize) !void {
    self.bricks.deinit();
    self.bricks.init(std.heap.page_allocator);

    // brickCode: usize = undefined;
    // level: Self = undefined;

    // var file = try std.fs.cwd().openFile(file, .{});
    // defer file.close();

    // var buf_reader = std.io.bufferedReader(file.reader());
    // var in_stream = buf_reader.reader();

    _ = levelWidth;
    _ = levelHeight;
    _ = file;
}

pub fn draw(renderer: SpriteRenderer) void {
    _ = renderer;

}

/// check if the level is completed (all non-solid tiles are destroyed)
pub fn isCompleted() bool {

}

fn start(tileData: std.ArrayList(std.ArrayList(usize)), levelWidth: usize, levelHeight: usize) void {
    _ = tileData;
    _ = levelWidth;
    _ = levelHeight;
}

fn readTileData(stream: *std.io.FixedBufferStream([]const u8)) !std.ArrayList(std.ArrayList(usize)) {
    var tileData = std.ArrayList(std.ArrayList(usize)).init(std.heap.page_allocator);
    var line_buf: [20]u8 = undefined;
    var writeStream = std.io.fixedBufferStream(&line_buf);

    while (true) |_| {
        try stream.reader().streamUntilDelimiter(writeStream.writer(), '\n', null) catch |err| {
            if (err == std.io.StreamError.EndOfFile) {
                return tileData;
            } else {
                return err;
            }
        };

        std.debug.warn("line: {}\n", .{line_buf});
        var tileRow = std.ArrayList(usize).init(std.heap.page_allocator);
        var tile: usize = undefined;
        var i: usize = 0;
        while (i < line_buf.len) : (i += 1) {
            switch (line[i]) {
                '0' => tile = 0,
                '1' => tile = 1,
                '2' => tile = 2,
                '3' => tile = 3,
                '4' => tile = 4,
                '5' => tile = 5,
                '6' => tile = 6,
                '7' => tile = 7,
                '8' => tile = 8,
                '9' => tile = 9,
                _ => continue,
            }
            tileRow.append(tile);
        }
    }
}

test "reads tile data correctly" {
    const data =
        \\ 1 2 3
        \\ 4 5 6
        \\ 7 8 9
    ;
    var stream = std.io.fixedBufferStream(data);

    var tileData = try readTileData(&stream);
    try std.testing.expect(tileData.items.len == 3);
    try std.testing.expect(tileData.items[0].items.len == 3);
    try std.testing.expect(tileData.items[1].items.len == 3);
    try std.testing.expect(tileData.items[2].items.len == 3);
    try std.testing.expect(tileData.items[0].items[0] == 1);
    try std.testing.expect(tileData.items[0].items[1] == 2);
    try std.testing.expect(tileData.items[0].items[2] == 3);
    try std.testing.expect(tileData.items[1].items[0] == 4);
    try std.testing.expect(tileData.items[1].items[1] == 5);
    try std.testing.expect(tileData.items[1].items[2] == 6);
    try std.testing.expect(tileData.items[2].items[0] == 7);
    try std.testing.expect(tileData.items[2].items[1] == 8);
    try std.testing.expect(tileData.items[2].items[2] == 9);
}