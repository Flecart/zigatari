const std = @import("std");
const zlm = @import("zlm");

const GameObject = @import("game_object.zig");
const SpriteRenderer = @import("sprite_renderer.zig");
const ResourceManager = @import("resource_manager.zig");

const Self = @This();

bricks: std.ArrayList(GameObject),

pub fn deinit(self: *Self) Self {
    self.bricks.deinit();
}

pub fn init(filename: []const u8, levelWidth: usize, levelHeight: usize) !Self {
    var bricks = std.ArrayList(GameObject).init(std.heap.page_allocator);

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const buf = try buf_reader.reader().readAllAlloc(std.heap.page_allocator, 4096);

    var in_stream = std.io.fixedBufferStream(buf);

    // actually run the init
    const tileData = try Self.readTileData([] u8, &in_stream);

    const height = tileData.items.len;
    const width = tileData.items[0].items.len;

    const unit_width = @as(f32, @floatFromInt(levelWidth)) / @as(f32, @floatFromInt(width));
    const unit_height = @as(f32, @floatFromInt(levelHeight)) / @as(f32, @floatFromInt(height));

    // initialize level tiles based on tileData
    var y: usize = 0;
    var x: usize = 0;

    while (y < height) : (y += 1) {
        while (x < width) : (x += 1) {
            const tile = tileData.items[y].items[x];
            // check block type from level data (2D level array)
            if (tile == 1) {
                const pos = zlm.vec2(unit_width * @as(f32, @floatFromInt(x)), unit_height * @as(f32, @floatFromInt(y)));
                const size = zlm.vec2(unit_width, unit_height);
                var obj = GameObject.init(
                    pos, 
                    size, 
                    try ResourceManager.getTexture("block_solid"),
                    zlm.vec3(0.8, 0.8, 0.7), zlm.vec2(0.0, 0.0)
                );
                obj.isSolid = true;
                try bricks.append(obj);
            } else if (tile > 1) {
                var color = zlm.vec3(1.0, 1.0, 1.0); // original: white
                switch (tile) {
                    2 => color = zlm.vec3(0.2, 0.6, 1.0),
                    3 => color = zlm.vec3(0.0, 0.7, 0.0),
                    4 => color = zlm.vec3(0.8, 0.8, 0.4),
                    5 => color = zlm.vec3(1.0, 0.5, 0.0),
                    else => {},
                }

                const pos = zlm.vec2(unit_width * @as(f32, @floatFromInt(x)), unit_height * @as(f32, @floatFromInt(y)));
                const size = zlm.vec2(unit_width, unit_height);
                const obj = GameObject.init(
                    pos, 
                    size, 
                    try ResourceManager.getTexture("block"),
                    color, zlm.vec2(0.0, 0.0)
                );
                try bricks.append(obj);
            }
        }
    }

    return Self {
        .bricks = bricks,
    };
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

fn readTileData(comptime Buffer: type, stream: *std.io.FixedBufferStream(Buffer)) !std.ArrayList(std.ArrayList(usize)) {
    var tileData = std.ArrayList(std.ArrayList(usize)).init(std.heap.page_allocator);
    var line_buf: [128]u8 = undefined;

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

    var tileData = try readTileData([]const u8, &stream);
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