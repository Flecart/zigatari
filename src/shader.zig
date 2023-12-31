const std = @import("std");
const gl = @import("zgl");
const math = @import("zlm");

const ErrorType = enum {
    Vertex,
    Fragment,
    Program
};

const Self = @This();

id: gl.Program,

// constructor generates the shader on the fly (
// "as they are source files, they should be known
// at compile time").
// ------------------------------------------------------------------------
pub fn init(comptime vertexPath: []const u8, comptime fragmentPath: []const u8, comptime geometricPath: []const u8) Self {
    _ = geometricPath; // TODO: use me too
    // 1. retrieve the vertex/fragment source code from filePath
    const vertexCode = [_][] const u8 {
        @embedFile(vertexPath)
    };

    const fragmentCode = [_][] const u8 {
        @embedFile(fragmentPath)
    };

    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const vertexShader = gl.createShader(gl.ShaderType.vertex);
    defer gl.deleteShader(vertexShader);
    gl.shaderSource(vertexShader, 1, &vertexCode);
    gl.compileShader(vertexShader);
    if (gl.getShader(vertexShader, gl.ShaderParameter.compile_status) == 0) {
        std.log.err("ERROR::SHADER_COMPILATION_ERROR of type: Vertex\n {!s} \n", .{
            gl.getShaderInfoLog(vertexShader, allocator),
        });
    }

    const fragmentShader = gl.createShader(gl.ShaderType.fragment);
    defer gl.deleteShader(fragmentShader);
    gl.shaderSource(fragmentShader, 1, &fragmentCode);
    gl.compileShader(fragmentShader);
    if (gl.getShader(fragmentShader, gl.ShaderParameter.compile_status) == 0) {
        std.log.err("ERROR::SHADER_COMPILATION_ERROR of type: Fragment\n {!s} \n", .{
            gl.getShaderInfoLog(fragmentShader, allocator),
        });
    }

    // shader Program
    const id = gl.createProgram();
    gl.attachShader(id, vertexShader);
    gl.attachShader(id, fragmentShader);
    gl.linkProgram(id);
    if (gl.getProgram(id, gl.ProgramParameter.link_status) == 0) {
        std.log.err("ERROR::PROGRAM_LINKING_ERROR of type: program\n {!s} \n", .{
            gl.getProgramInfoLog(id, allocator),
        });
    }
    
    return Self { .id = id };
}

pub fn use(self: Self) void {
    gl.useProgram(self.id);
}

pub fn getUniformLocation(self: Self, name: [:0]const u8) ?u32 {
    return gl.getUniformLocation(self.id, name);
}

// utility uniform functions
// ------------------------------------------------------------------------
pub fn setBool(self: Self, name: [:0]const u8, value: bool) void {
    gl.uniform1i(gl.getUniformLocation(self.id, name), @intCast(value));
}

pub fn setInt(self: Self, name: [:0]const u8, value: i32) void {
    gl.uniform1i(gl.getUniformLocation(self.id, name), value);
}

pub fn setFloat(self: Self, name: [:0]const u8, value: f32) void {
    gl.uniform1f(gl.getUniformLocation(self.id, name), value);
}

pub fn setVec2(self: Self, name: [:0]const u8, value: math.Vec2) void {
    gl.uniform2f(gl.getUniformLocation(self.id, name), value.x, value.y);
}

pub fn setVec3(self: Self, name: [:0]const u8, value: math.Vec3) void {
    gl.uniform3f(gl.getUniformLocation(self.id, name), value.x, value.y, value.z);
}

pub fn setVec4(self: Self, name: [:0]const u8, value: math.Vec4) void {
    gl.uniform4f(gl.getUniformLocation(self.id, name), value.x, value.y, value.z, value.w);
}

pub fn setMat2(self: Self, name: [:0]const u8, value: math.Mat2) void {
    gl.uniformMatrix2fv(gl.getUniformLocation(self.id, name), false, &.{value.fields});
}

pub fn setMat3(self: Self, name: [:0]const u8, value: math.Mat3) void {
    gl.uniformMatrix3fv(gl.getUniformLocation(self.id, name), false, &.{value.fields});
}

pub fn setMat4(self: Self, name: [:0]const u8, value: math.Mat4) void {
    gl.uniformMatrix4fv(gl.getUniformLocation(self.id, name), false, &.{value.fields});
}

pub fn deinit(self: Self) void {
    gl.deleteProgram(self.id);
}