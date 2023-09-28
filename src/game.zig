const std = @import("std");
const zgl = @import("zgl");
const zlm = @import("zlm");
const glfw = @import("maach-glfw");

const ResourceManager = @import("./resource_manager.zig");
const SpriteRenderer = @import("./sprite_renderer.zig");
const GameLevel = @import("./game_level.zig");
const GameObject = @import("./game_object.zig");

const GameState = enum { 
    game_active, 
    game_menu, 
    game_win
};

// Initial size of the player paddle
const PLAYER_SIZE: zlm.Vec2 = zlm.vec2(100.0, 20.0);
// Initial velocity of the player paddle
const PLAYER_VELOCITY: f32 = 500.0;

const Self = @This();

state: GameState,
keys: [1024]bool,
width: u32,
height: u32,
renderer: SpriteRenderer,
levels: std.ArrayList(GameLevel),
level: u32,
player: GameObject,

pub fn init(width: u32, height: u32) Self {
    return Self {
        .state = GameState.game_active,
        .keys = undefined,
        .width = width,
        .height = height,
        .renderer = undefined,
        .levels = std.ArrayList(GameLevel).init(std.heap.page_allocator),
        .level = 0,
        .player = undefined,
    };
}


pub fn start(self: *Self) !void {
    // load shaders
    const shader = try ResourceManager.loadShader("shaders/sprite.vs", "shaders/sprite.fs", "", "sprite");

    // configure shaders
    const projection = zlm.Mat4.createOrthogonal(
        0, 
        @floatFromInt(self.width), 
        @floatFromInt(self.height), 
        0, -1, 1
    );

    shader.use();
    shader.setInt("image", 0);
    shader.setMat4("projection", projection);

    // set-renderer-specific controls
    self.renderer = SpriteRenderer.init(shader);

    // load texture
    _ = try ResourceManager.loadTexture("textures/background.png", false, "background");
    _ = try ResourceManager.loadTexture("textures/awesomeface.png", true, "face");
    _ = try ResourceManager.loadTexture("textures/block.png", false, "block");
    _ = try ResourceManager.loadTexture("textures/block_solid.png", false, "block_solid");
    _ = try ResourceManager.loadTexture("textures/paddle.png", true, "paddle");

    // load levels
    var level1 = try GameLevel.init("levels/one.lvl", self.width, self.height / 2);
    var level2 = try GameLevel.init("levels/two.lvl", self.width, self.height / 2);
    var level3 = try GameLevel.init("levels/three.lvl", self.width, self.height / 2);
    var level4 = try GameLevel.init("levels/four.lvl", self.width, self.height / 2);
    try self.levels.append(level1);
    try self.levels.append(level2);
    try self.levels.append(level3);
    try self.levels.append(level4);
    self.level = 0;

    // configure game objects
    // const playerPos = zlm.vec2(
    //     @as(f32, @floatFromInt(self.width)) / 2.0 - PLAYER_SIZE.x / 2.0,
    //     @as(f32, @floatFromInt(self.height)) - PLAYER_SIZE.y
    // );
    // self.player = GameObject.init(playerPos, PLAYER_SIZE, try ResourceManager.getTexture("paddle"));
}

pub fn processInput(self: *Self, dt: f32) void {
    if (self.state == GameState.game_active) {
        _ = dt;
        // const velocity = PLAYER_VELOCITY * dt;
        // if (self.keys[@intFromEnum(glfw.Keys.w)]) {
        //     self.player.position.y += velocity;
        // }
        // if (self.keys[GLFW_KEY_S]) {
        //     self.player.position.y -= velocity;
        // }
        // if (self.keys[GLFW_KEY_A]) {
        //     self.player.position.x -= velocity;
        // }
        // if (self.keys[GLFW_KEY_D]) {
        //     self.player.position.x += velocity;
        // }
    }
}

pub fn update(self: Self, dt: f32) void {
    _ = self;
    _ = dt;
}

pub fn render(self: Self) !void {
    if (self.state == GameState.game_active) {
        self.renderer.drawSprite(
            try ResourceManager.getTexture("background"),
            zlm.vec2(0.0, 0.0),
            zlm.vec2(@floatFromInt(self.width), @floatFromInt(self.height)),
            0.0,
            zlm.vec3(0.0, 0.0, 0.0)
        );
    }
}
