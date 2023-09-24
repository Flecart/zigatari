const zgl = @import("zgl");
const zlm = @import("zlm");
const glfw = @import("maach-glfw");

const ResourceManager = @import("./resource_manager.zig");
const SpriteRenderer = @import("./sprite_renderer.zig");

const GameState = enum { 
    game_active, 
    game_menu, 
    game_win
};

const Self = @This();

state: GameState,
keys: [1024]bool,
width: u32,
height: u32,
renderer: SpriteRenderer,

pub fn init(width: u32, height: u32) Self {
    return Self {
        .state = GameState.game_active,
        .keys = undefined,
        .width = width,
        .height = height,
        .renderer = undefined,
    };
}

pub fn start(self: *Self) !void {
    ResourceManager.init();

    // load shaders
    _ = try ResourceManager.loadShader("shaders/sprite.vs", "shaders/sprite.fs", "", "sprite");

    // configure shaders
    const projection = zlm.Mat4.createOrthogonal(
        0, 
        @floatFromInt(self.width), 
        @floatFromInt(self.height), 
        0, -1, 1
    );

    const shader = try ResourceManager.getShader("sprite");
    shader.use();
    shader.setInt("image", 0);
    shader.setMat4("projection", projection);

    // set-renderer-specific controls
    self.renderer = SpriteRenderer.init(shader);

    // load texture
    _ = try ResourceManager.loadTexture("textures/awesomeface.png", false, "face");
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

pub fn render(self: Self) void {
    self.renderer.drawSprite(
        ResourceManager.getTexture("face"),
        zlm.vec2(200.0, 200.0),
        zlm.vec2(300.0, 400.0),
        45.0,
        zlm.vec3(0.0, 1.0, 0.0),
    );
}
