//! This file is used to try OpenGL and GLFW with zig
const std = @import("std");
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub fn main() void {
    // Initialize GLFW
    if (c.glfwInit() != c.GL_TRUE) {
        std.debug.print("Failed to initialize GLFW\n", .{});
        return;
    }

    // Create a windowed mode window and its OpenGL context
    const window = c.glfwCreateWindow(640, 480, "Hello Zig GLFW", null, null);
    if (window == null) {
        std.debug.print("Failed to create GLFW window\n", .{});
        c.glfwTerminate();
        return;
    }

    // Make the window's context current
    c.glfwMakeContextCurrent(window);

    // Loop until the user closes the window
    while (c.glfwWindowShouldClose(window) == 0) {
        // Render here

        // Swap front and back buffers
        c.glfwSwapBuffers(window);

        // Poll for and process events
        c.glfwPollEvents();
    }

    // Terminate GLFW
    c.glfwTerminate();
}
