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


    // // loads (and generates) a shader program from file loading vertex, fragment (and geometry) shader's source code. If gShaderFile is not nullptr, it also loads a geometry shader
    // static Shader    LoadShader(const char *vShaderFile, const char *fShaderFile, const char *gShaderFile, std::string name);
    // // retrieves a stored sader
    // static Shader    GetShader(std::string name);
    // // loads (and generates) a texture from file
    // static Texture2D LoadTexture(const char *file, bool alpha, std::string name);
    // // retrieves a stored texture
    // static Texture2D GetTexture(std::string name);
    // // properly de-allocates all loaded resources