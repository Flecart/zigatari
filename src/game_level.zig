const std = @import("std");
const zlm = @import("zlm");

const GameObject = @import("game_object.zig");
const SpriteRenderer = @import("sprite_renderer.zig");
const ResourceManager = @import("resource_manager.zig");

const Self = @This();

bricks: std.ArrayList(GameObject),


pub fn init() Self {

}

pub fn load(self: Self, filename: []const u8, levelWidth: usize, levelHeight: usize) !void {
    self.bricks.deinit();
    self.bricks.init(std.heap.page_allocator);

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    // actually run the init
    const tileData = try Self.readTileData(&in_stream);

    const height = tileData.items.len;
    const width = tileData.items[0].items.len;

    const unit_width = levelWidth / width;
    const unit_height = levelHeight / height;

    // initialize level tiles based on tileData
    var y: usize = 0;
    var x: usize = 0;

    while (y < height) : (y += 1) {
        while (x < width) : (x += 1) {
            const tile = tileData.items[y].items[x];
            // check block type from level data (2D level array)
            if (tile == 1) {
                const pos = zlm.vec2(unit_width * x, unit_height * y);
                const size = zlm.vec2(unit_width, unit_height);
                const obj = GameObject.init(
                    pos, 
                    size, 
                    ResourceManager.getTexture("block_solid"),
                    zlm.vec3(0.8, 0.8, 0.7)
                );
                obj.isSolid = true;
                try self.bricks.append(obj);
            } else if (tile > 1) {
                var color = zlm.vec3(1.0, 1.0, 1.0); // original: white
                switch (tile) {
                    2 => color = zlm.vec3(0.2, 0.6, 1.0),
                    3 => color = zlm.vec3(0.0, 0.7, 0.0),
                    4 => color = zlm.vec3(0.8, 0.8, 0.4),
                    5 => color = zlm.vec3(1.0, 0.5, 0.0),
                }

                const pos = zlm.vec2(unit_width * x, unit_height * y);
                const size = zlm.vec2(unit_width, unit_height);
                const obj = GameObject.init(
                    pos, 
                    size, 
                    ResourceManager.getTexture("block"),
                    color
                );
                try self.bricks.append(obj);
            }
        }
    }

}

pub fn draw(self: Self, renderer: SpriteRenderer) void {
    for (self.bricks.items) |brick| {
        if (!brick.destroyed) {
            brick.draw(renderer);
        }
    }
}

/// check if the level is completed (all non-solid tiles are destroyed)
pub fn isCompleted(self: Self) bool {
    for (self.bricks.items) |brick| {
        if (!brick.isSolid and !brick.destroyed) {
            return false;
        }
    }

    return true;
}

fn readTileData(stream: *std.io.FixedBufferStream([]const u8)) !std.ArrayList(std.ArrayList(usize)) {
    var tileData = std.ArrayList(std.ArrayList(usize)).init(std.heap.page_allocator);
    var line_buf: [20]u8 = undefined;

    while (true) {
        var writeStream = std.io.fixedBufferStream(&line_buf);
        stream.reader().streamUntilDelimiter(writeStream.writer(), '\n', null) catch |err| {
            if (err == error.EndOfStream) {
                return tileData;
            } else {
                return err;
            }
        };
        // TODO: in theory this should work even if the file is not terminated with a newline

        var tileRow = std.ArrayList(usize).init(std.heap.page_allocator);
        var tile: usize = undefined;
        var i: usize = 0;
        while (i < line_buf.len) : (i += 1) {
            switch (line_buf[i]) {
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
                else => continue,
            }
            try tileRow.append(tile);
        }
        try tileData.append(tileRow);
    }
}

test "reads tile data correctly" {
    const data =
        \\ 1 2 3
        \\ 4 5 6
        \\ 7 8 9
        \\
    ;
    var stream = std.io.fixedBufferStream(data);

    var tileData = try readTileData(&stream);
    defer tileData.deinit();

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