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

const Direction = enum(usize) {
    up = 0,
    right = 1,
    down = 2,
    left = 3
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

    try self.resetPlayer();
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
    self.doCollisions();

    if (self.ball.gameObject.position.y >= @as(f32, @floatFromInt(self.height))) {
        self.resetLevel() catch unreachable;
        self.resetPlayer() catch unreachable;
    }
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

pub fn doCollisions(self: *Self) void {
    for (self.levels.items[self.level].bricks.items) |*brick| {
        if (brick.destroyed) {
            continue;
        }
        const collisionVector = getCollisionVector(self.ball, brick.*);
        if (collisionVector.length() >= self.ball.radius) {
            continue;
        }
        if (!brick.isSolid) {
            brick.destroyed = true;
        }

        std.debug.print("velocity before update {}\n", .{self.ball.gameObject.velocity});

        // now we know there is a collision with a living block
        const direction = getVectorDirection(collisionVector);
        switch (direction) {
            Direction.left, Direction.right => {
                self.ball.gameObject.velocity.x = -self.ball.gameObject.velocity.x;
                // relocate
                const penetration = self.ball.radius - @abs(collisionVector.x);
                if (direction == Direction.left) {
                    self.ball.gameObject.position.x += penetration;
                } else {
                    self.ball.gameObject.position.x -= penetration;
                }
            },
            Direction.up, Direction.down => {
                self.ball.gameObject.velocity.y = -self.ball.gameObject.velocity.y;
                // relocate
                const penetration = self.ball.radius - @abs(collisionVector.y);
                if (direction == Direction.up) {
                    self.ball.gameObject.position.y -= penetration;
                } else {
                    self.ball.gameObject.position.y += penetration;
                }
            },
        }

        std.debug.print("Got collision: {}, direction is {}, velocity {}\n", 
        .{collisionVector, direction, self.ball.gameObject.velocity.y});

    }
    const playerCollisionVector = getCollisionVector(self.ball, self.player);
    if (!self.ball.stuck and playerCollisionVector.length() < self.ball.radius) {
        const centerBoard = self.player.position.x + self.player.size.x / 2.0;
        const distance = self.ball.gameObject.position.x + self.ball.radius - centerBoard;
        const percentage = distance / (self.player.size.x / 2.0);

        const strength = 2.0;
        const oldVelocity = self.ball.gameObject.velocity;
        self.ball.gameObject.velocity.x = INITIAL_BALL_VELOCITY.x * percentage * strength;
        self.ball.gameObject.velocity.y = -@abs(self.ball.gameObject.velocity.y);
        self.ball.gameObject.velocity = self.ball.gameObject.velocity.normalize().scale(oldVelocity.length());
    }
}

fn checkCollisionRect(one: GameObject, two: GameObject) bool {
    // collision x-axis?
    const collisionX = one.position.x + one.size.x >= two.position.x and two.position.x + two.size.x >= one.position.x;
    // collision y-axis?
    const collisionY = one.position.y + one.size.y >= two.position.y and two.position.y + two.size.y >= one.position.y;
    // collision only if on both axes
    return collisionX and collisionY;
}

/// returns the smallest ditance between the ball border and rect AABB
fn getCollisionVector(ball: BallObject, rect: GameObject) zlm.Vec2 {
    const ballCenter = ball.gameObject.position.add(zlm.Vec2.all(ball.radius));

    const halfExtents = rect.size.scale(1.0 / 2.0);
    const center = rect.position.add(halfExtents);

    const difference = ballCenter.sub(center);
    const clamped = difference.componentClamp(halfExtents.neg(), halfExtents);

    const closest = center.add(clamped);

    return ballCenter.sub(closest);
}

fn checkCollisionCirclerect(ball: BallObject, rect: GameObject) bool {
    return getCollisionVector(ball, rect).length() < ball.radius;
}

fn getVectorDirection(vector: zlm.Vec2) Direction {
    const compass = [_]zlm.Vec2 {
        zlm.vec2(0.0, 1.0), // up
        zlm.vec2(1.0, 0.0), // right
        zlm.vec2(0.0, -1.0), // down
        zlm.vec2(-1.0, 0.0) // left
    };

    var max: f32 = 0;
    var best_match = Direction.up;

    for (0..4) |i| {
        const dotProduct = compass[i].dot(vector);
        if (dotProduct > max) {
            max = dotProduct;
            best_match = @enumFromInt(i);
        }
    }

    return best_match;
}

fn resetLevel(self: *Self) !void {
    self.levels.items[self.level].deinit();

    var level: GameLevel = undefined;
    switch (self.level) {
        0 => level = try GameLevel.init("levels/one.lvl", self.width, self.height / 2),
        1 => level = try GameLevel.init("levels/two.lvl", self.width, self.height / 2),
        2 => level = try GameLevel.init("levels/three.lvl", self.width, self.height / 2),
        3 => level = try GameLevel.init("levels/four.lvl", self.width, self.height / 2),
        else => unreachable
    }

    self.levels.items[self.level] = level;
}

fn resetPlayer(self: *Self) !void {
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