
const std = @import("std");

const zlm = @import("zlm");
const GameObject = @import("game_object.zig");
const Texture = @import("texture.zig");
const Renderer = @import("sprite_renderer.zig");

const Self = @This();

gameObject: GameObject,
radius: f32,
stuck: bool,

pub const default = Self {
    .gameObject = GameObject.default,
    .radius = 12.0,
    .stuck = true,
};

pub fn object(self: Self) GameObject {
    return self.gameObject;
}

pub fn init(pos: zlm.Vec2, radius: f32, velocity: zlm.Vec2, sprite: Texture) Self {
    return Self {
        .gameObject = GameObject.init(pos, 
            zlm.vec2(radius * 2, radius * 2), 
            sprite, 
            GameObject.defaultColor,
            velocity
        ),
        .radius = radius,
        .stuck = true,
    };
}

pub fn move(self: *Self, dt: f32, window_width: usize) void {
    const position = &self.gameObject.position;
    if (self.stuck) {
        return;
    }

    // move the ball
    position.* = position.add(self.gameObject.velocity.scale(dt));

    // check if outside of window bounds
    if (position.x <= 0) {
        position.x = self.radius;
        self.gameObject.velocity.x *= -1.0;
        self.gameObject.position.x = 0;
    } else if (position.x + self.radius > @as(f32, @floatFromInt(window_width))) {
        self.gameObject.velocity.x *= -1.0;
        self.gameObject.position.x = @as(f32, @floatFromInt(window_width)) - self.radius;
    }

    if (position.y <= 0.0) {
        self.gameObject.velocity.y *= -1.0;
        self.gameObject.position.y = 0.0;
    }
}

pub fn draw(self: Self, renderer: Renderer) void {
    self.gameObject.draw(renderer);
}
