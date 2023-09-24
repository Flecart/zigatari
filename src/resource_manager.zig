const std = @import("std");
const gl = @import("zgl");
const zigimg = @import("zigimg");

const Texture = @import("./texture.zig");
const Shader = @import("./shader.zig");

const Self = @This();

// instantiate static variables
var gTextures = std.StringArrayHashMap(Texture).init(std.heap.page_allocator);
var gShaders = std.StringArrayHashMap(Shader).init(std.heap.page_allocator);

pub fn loadShader(
    comptime vShaderFile: []const u8, 
    comptime fShaderFile: []const u8, 
    comptime gShaderFile: []const u8, 
    name: []const u8) !Shader 
{
    const shader = Shader.init(vShaderFile, fShaderFile, gShaderFile);
    try gShaders.put(name, shader);
    return shader;
}

pub fn getShader(comptime name: []const u8) !Shader {
    const shaderFound = gShaders.get(name);
    if (shaderFound) |shader| {
        return shader;
    } else {
        return error.Unreachable;
    }
}

pub fn loadTexture(comptime file: []const u8, alpha: bool, name: []const u8) !Texture {
    const texture = try loadTextureFromFile(file, alpha);
    try gTextures.put(name, texture);
    return texture;
}

pub fn getTexture(comptime name: []const u8) !Texture {
    const textureFound = gTextures.get(name);
    if (textureFound) |texture| {
        return texture;
    } else {
        return error.Unreachable;
    }
}

pub fn deinit() void {
    for (gTextures.items) |item| {
        item.value.deinit();
    }

    for (gShaders.items) |item| {
        item.value.deinit();
    }

    gTextures.deinit();
    gShaders.deinit();
}


fn loadTextureFromFile(path: []const u8, alpha: bool) !Texture {
    var texture = Texture.init();

    if (alpha) {
        texture.internal_format = gl.TextureInternalFormat.rgba;
        texture.image_format = gl.PixelFormat.rgba;
    }

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var image =  try zigimg.Image.fromFile(std.heap.page_allocator, &file);
    defer image.deinit();

    texture.generate(
        @intCast(image.width), 
        @intCast(image.height), 
        image.pixels.asBytes()
    );

    return texture;
}
