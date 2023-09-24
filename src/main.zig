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
        // .context_debug = true,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);
    const proc: glfw.GLProc = undefined;
    try gl.loadExtensions(proc, glGetProcAddress);

    // const flags = gl.getInteger(gl.Parameter.context_flags);
    // std.debug.print("OpenGL context flags: {x}\n", .{flags});

    // gl.enable(gl.Capabilities.debug_output);
    // gl.enable(gl.Capabilities.debug_output_synchronous);
    // gl.debugMessageCallback(void, debugHandler);

    window.setKeyCallback(key_callback);
    gl.enable(gl.Capabilities.blend);
    gl.blendFunc(gl.BlendFactor.src_alpha, gl.BlendFactor.one_minus_constant_alpha);
    
    try gBreakout.start();

    // render loop
    // -----------
    var deltaTime: f32 = 0.0;
    var lastFrame: f32 = 0.0;
    while (!window.shouldClose()) {
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(.{.color = true, .depth = true});

        const currentFrame: f32 = @floatCast(glfw.getTime());
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;
        glfw.pollEvents();

        gBreakout.processInput(deltaTime);
        gBreakout.update(deltaTime);

        window.swapBuffers();
        try gBreakout.render();
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

fn debugHandler (source: gl.DebugSource, msg_type: gl.DebugMessageType, id: usize, severity: gl.DebugSeverity, message: []const u8) void {
    // ignore non-significant error/warning codes
    if (id == 131169 or id == 131185 or id == 131218 or id == 131204) {
        return;
    }

    std.debug.print("---------------\n", .{});
    std.debug.print("Debug message ({d}): {s}\n", .{id, message});

    switch (source) {
        .api => std.debug.print("Source: API\n", .{}),
        .window_system => std.debug.print("Source: Window System\n", .{}),
        .shader_compiler => std.debug.print("Source: Shader Compiler\n", .{}),
        .third_party => std.debug.print("Source: Third Party\n", .{}),
        .application => std.debug.print("Source: Application\n", .{}),
        .other => std.debug.print("Source: Other\n", .{}),
    }

    switch (msg_type) {
        .@"error" => std.debug.print("Type: Error\n", .{}),
        .deprecated_behavior => std.debug.print("Type: Deprecated Behaviour\n", .{}),
        .undefined_behavior => std.debug.print("Type: Undefined Behaviour\n", .{}),
        .portability => std.debug.print("Type: Portability\n", .{}),
        .performance => std.debug.print("Type: Performance\n", .{}),
        .other => std.debug.print("Type: Other\n", .{}),
    }

    switch (severity) {
        .high => std.debug.print("Severity: high\n", .{}),
        .medium => std.debug.print("Severity: medium\n", .{}),
        .low => std.debug.print("Severity: low\n", .{}),
        .notification => std.debug.print("Severity: notification\n", .{}),
    }
    std.debug.print("\n", .{});
}