const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("zgl");
const math = @import("zlm");
const zigimg = @import("zigimg");

const log = std.log.scoped(.Engine);

const Shader = @import("shader.zig").Shader;
const Game = @import("game.zig");

const SCR_WIDTH = 800;
const SCR_HEIGHT = 600;

var gBreakout = Game.init(SCR_WIDTH, SCR_HEIGHT);

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.binding.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

pub fn main() !void {
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();


    // Create our window
    const window = glfw.Window.create(SCR_WIDTH, SCR_HEIGHT, "Breakout", null, null, .{
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

    window.setKeyCallback(key_callback);
    gl.enable(gl.Capabilities.blend);
    gl.blendFunc(gl.BlendFactor.src_alpha, gl.BlendFactor.one_minus_constant_alpha);
    
    gBreakout.start();

    // render loop
    // -----------
    var deltaTime: f32 = 0.0;
    var lastFrame: f32 = 0.0;
    while (!window.shouldClose()) {
        const currentFrame: f32 = @floatCast(glfw.getTime());
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;
        glfw.pollEvents();

        gBreakout.processInput(deltaTime);
        gBreakout.update(deltaTime);

        window.swapBuffers();
        gBreakout.render();
    }
}

fn key_callback(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
    _ = scancode;
    _ = mods;
    if (key == glfw.Key.escape and action == glfw.Action.press) {
        window.setShouldClose(true);
    }

    const key_code: i32 = @intFromEnum(key);
    if (key_code >= 0 and key_code < 1024) {
        if (action == glfw.Action.press) {
            gBreakout.keys[@intCast(key_code)] = true;
        } else if (action == glfw.Action.release) {
            gBreakout.keys[@intCast(key_code)] = false;
        }
    }
}
