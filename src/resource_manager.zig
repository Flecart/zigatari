const std = @import("std");
const gl = @import("zgl");
const zigimg = @import("zigimg");

const Texture = @import("./texture.zig");
const Shader = @import("./shader.zig");

const Self = @This();

// instantiate static variables
var gTextures: std.AutoArrayHashMap([]const u8, Texture) = undefined;
var gShaders: std.AutoArrayHashMap([]const u8, Shader) = undefined;

pub fn init() void {
    gTextures.init(std.heap.page_allocator);
    gShaders.init(std.heap.page_allocator);
}

pub fn loadShader(
    comptime vShaderFile: []const u8, 
    comptime fShaderFile: []const u8, 
    comptime gShaderFile: []const u8, 
    comptime name: []const u8) !Shader 
{
    const shader = Shader(vShaderFile, fShaderFile, gShaderFile);
    gShaders.put(name, shader);
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

pub fn loadTexture(comptime file: []const u8, alpha: bool) !Texture {
    const texture = loadTextureFromFile(file, alpha);
    gTextures.put(file, texture);
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
        gl.deleteProgram(item.value.id);
    }

    for (gShaders.items) |item| {
        gl.deleteTexture(item.value.id);
    }

    gTextures.deinit();
    gShaders.deinit();
}


fn loadTextureFromFile(path: []const u8, comptime alpha: bool) !Texture {
    var texture = Texture.init();

    if (alpha) {
        texture.internal_format = gl.TextureInternalFormat.rgba;
        texture.image_format = gl.PixelFormat.rgba;
    }

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var image =  try zigimg.Image.fromFile(std.heap.page_allocator, &file);
    defer image.deinit();

    texture.generate(image.width, image.height, image.pixels.asBytes());

    return texture;
}
