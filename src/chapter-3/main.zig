const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("zgl");

const log = std.log.scoped(.Engine);

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.binding.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

pub fn main() !void {
    // glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(640, 480, "Learn opengl", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 4,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();
    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.loadExtensions(proc, glGetProcAddress);

    const prova = gl.getInteger(gl.Parameter.max_vertex_attribs);
    std.log.info("max_vertex_attribs: {}", .{prova});
}