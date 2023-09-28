const zlm = @import("zlm");
const Texture = @import("texture.zig");
const Renderer = @import("sprite_renderer.zig");

const Self = @This();

position: zlm.Vec2,
size: zlm.Vec2,
velocity: zlm.Vec2,
color: zlm.Vec3,
rotation: f32,
isSolid: bool,
destroyed: bool,
sprite: Texture,

pub const default = Self {
    .position = zlm.vec2{0.0, 0.0},
    .size = zlm.vec2{10.0, 10.0},
    .velocity = zlm.vec2{0.0, 0.0},
    .color = zlm.vec3{1.0, 1.0, 1.0},
    .rotation = 0.0,
    .isSolid = false,
    .destroyed = false,
    .sprite = undefined,
};

pub fn init(position: zlm.Vec2, size: zlm.Vec2, sprite: Texture, color: zlm.Vec3, velocity: zlm.Vec2) Self {
    return Self {
        .position = position,
        .size = size,
        .velocity = velocity,
        .color = color,
        .rotation = 0.0,
        .isSolid = false,
        .destroyed = false,
        .sprite = sprite,
    };
}

pub fn draw(self: Self, renderer: Renderer) void {
    renderer.drawSprite(self.sprite, self.sprite, self.position, self.size, self.rotation, self.color);
}
