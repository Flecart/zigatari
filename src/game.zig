const zgl = @import("zgl");
const glfw = @import("maach-glfw");

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

pub fn init(width: u32, height: u32) Self {
    return Self {
        .state = GameState.game_active,
        .keys = undefined,
        .width = width,
        .height = height,
    };
}

pub fn start(self: Self) void {
    _ = self;
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
    _ = self;
}
