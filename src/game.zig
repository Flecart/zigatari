const std = @import("std");
const zgl = @import("zgl");
const zlm = @import("zlm");
const glfw = @import("mach-glfw");

const ResourceManager = @import("./resource_manager.zig");
const SpriteRenderer = @import("./sprite_renderer.zig");
const GameLevel = @import("./game_level.zig");
const GameObject = @import("./game_object.zig");
const BallObject = @import("./ball_object.zig");

const GameState = enum { 
    game_active, 
    game_menu, 
    game_win
};

// Initial size of the player paddle
const PLAYER_SIZE: zlm.Vec2 = zlm.vec2(100.0, 20.0);
// Initial velocity of the player paddle
const PLAYER_VELOCITY: f32 = 500.0;


// Initial velocity of the Ball
const INITIAL_BALL_VELOCITY: zlm.Vec2 = zlm.vec2(100.0, -350.0);
// Radius of the ball object
const BALL_RADIUS: f32 = 12.5;

const Self = @This();

state: GameState,
keys: [1024]bool,
width: u32,
height: u32,
renderer: SpriteRenderer,
levels: std.ArrayList(GameLevel),
level: u32,
player: GameObject,
ball: BallObject,

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
        .ball = undefined,
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
    const playerPos = zlm.vec2(
        @as(f32, @floatFromInt(self.width)) / 2.0 - PLAYER_SIZE.x / 2.0,
        @as(f32, @floatFromInt(self.height)) - PLAYER_SIZE.y
    );
    self.player = GameObject.init(playerPos, 
        PLAYER_SIZE, 
        try ResourceManager.getTexture("paddle"),
        GameObject.defaultColor,
        GameObject.defaultVelocity
    );

    const ballPos = zlm.vec2(
        playerPos.x + PLAYER_SIZE.x / 2.0 - 12.5,
        playerPos.y - 25.0
    );
    self.ball = BallObject.init(
        ballPos,
        BALL_RADIUS,
        INITIAL_BALL_VELOCITY,
        try ResourceManager.getTexture("face")
    );
}

pub fn processInput(self: *Self, dt: f32) void {
    if (self.state == GameState.game_active) {
        const velocity = PLAYER_VELOCITY * dt;

        // move playerboard
        if (self.keys[@intFromEnum(glfw.Key.a)]) {
            if (self.player.position.x >= 0.0) {
                self.player.position.x -= velocity;
                if (self.ball.stuck) {
                    self.ball.gameObject.position.x -= velocity;
                }
            }
        }
        if (self.keys[@intFromEnum(glfw.Key.d)]) {
            if (self.player.position.x <= @as(f32, @floatFromInt(self.width)) - self.player.size.x) {
                self.player.position.x += velocity;
                if (self.ball.stuck) {
                    self.ball.gameObject.position.x += velocity;
                }
            }
        }

        if (self.keys[@intFromEnum(glfw.Key.space)]) {
            self.ball.stuck = false;
        }
    }
}

pub fn update(self: *Self, dt: f32) void {
    self.ball.move(dt, self.width);
}

pub fn render(self: Self) !void {
    if (self.state == GameState.game_active) {
        // draw background
        self.renderer.drawSprite(
            try ResourceManager.getTexture("background"),
            zlm.vec2(0.0, 0.0),
            zlm.vec2(@floatFromInt(self.width), @floatFromInt(self.height)),
            0.0,
            zlm.vec3(1.0, 1.0, 1.0)
        );

        // draw level
        self.levels.items[self.level].draw(self.renderer);
        self.player.draw(self.renderer);
        self.ball.draw(self.renderer);
    }
}
