//! ParticleGenerator acts as a container for rendering a large number of 
//! particles by repeatedly spawning and updating particles and killing 
//! them after a given amount of time.

const std = @import("std");
const zlm = @import("zlm");
const zgl = @import("zgl");

const Texture = @import("./texture.zig");
const Shader = @import("./shader.zig");
const GameObject = @import("./game_object.zig");

const Particle = struct {
    position: zlm.Vec2,
    velocity: zlm.Vec2,
    color: zlm.Vec4,
    life: f32,

    pub const default = Particle {
        .position = zlm.vec2(0, 0),
        .velocity = zlm.vec2(0, 0),
        .color = zlm.vec4(1, 1, 1, 1),
        .life = 0.0,
    };
};

const Self = @This();

// state
particles: std.ArrayList(Particle),
amount: usize,

// render state
shader: Shader,
texture: Texture,
vao: zgl.VertexArray,

var _lastUsedParticle: usize = 0;
var prng = std.rand.DefaultPrng.init(0);
const rand = prng.random();

pub fn init(shader: Shader, texture: Texture, amount: usize) !Self {
    const particle_quad = [_]f32 {
        0.0, 1.0, 0.0, 1.0,
        1.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 0.0,

        0.0, 1.0, 0.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 0.0, 1.0, 0.0
    };

    // set up mesh and attribute properties
    const vbo = zgl.genBuffer();
    defer zgl.deleteBuffer(vbo);
    const vao = zgl.genVertexArray();

    zgl.bindVertexArray(vao);

    // fill mesh buffer
    zgl.bindBuffer(vbo, zgl.BufferTarget.array_buffer);
    zgl.bufferData(zgl.BufferTarget.array_buffer, f32, &particle_quad, zgl.BufferUsage.static_draw);

    zgl.enableVertexAttribArray(0);
    zgl.vertexAttribPointer(0, 4, zgl.Type.float, false, 4 * @sizeOf(f32), 0);

    zgl.bindVertexArray(zgl.VertexArray.invalid);

    // create particles
    var particles = try std.ArrayList(Particle).initCapacity(std.heap.page_allocator, amount);
    for (0..amount) |_| {
        try particles.append(Particle.default);
    }

    return Self {
        .particles = particles,
        .amount = amount,
        .shader = shader,
        .texture = texture,
        .vao = vao,
    };
}

pub fn deinit(self: *Self) void {
    self.particles.deinit();
}

pub fn update(self: *Self, dt: f32, object: GameObject, newParticles: usize, offset: zlm.Vec2) void {
    for (0..newParticles) |_| {
        const index = firstUnusedParticle(self);
        const particle = &self.particles.items[index];
        respawnParticle(particle, object, offset);
    }

    // update all particles
    for (self.particles.items) |*particle| {
        particle.life -= dt;
        if (particle.life > 0.0) {
            particle.position = particle.position.sub(particle.velocity.scale(dt));
            particle.color.w -= dt * 2.5;
        }
    }
}

pub fn draw(self: Self) void {
    zgl.blendFunc(zgl.BlendFactor.src_alpha, zgl.BlendFactor.one);
    self.shader.use();

    for (self.particles.items) |particle| {
        if (particle.life > 0) {
            self.shader.setVec2("offset", particle.position);
            self.shader.setVec4("color", particle.color);
            self.texture.bind();
            zgl.bindVertexArray(self.vao);
            zgl.drawArrays(zgl.PrimitiveType.triangles, 0, 6);
            zgl.bindVertexArray(zgl.VertexArray.invalid);
        }
    }

    // don't forget to reset to default blending mode
    zgl.blendFunc(zgl.BlendFactor.src_alpha, zgl.BlendFactor.one_minus_src_alpha);
}

fn firstUnusedParticle(self: *Self) usize {
    for (_lastUsedParticle..self.amount) |i| {
        if (self.particles.items[i].life <= 0.0) {
            _lastUsedParticle = i;
            return i;
        }
    }

    for (0.._lastUsedParticle) |i| {
        if (self.particles.items[i].life <= 0.0) {
            _lastUsedParticle = i;
            return i;
        }
    }

    _lastUsedParticle = 0;
    return 0;
}

fn respawnParticle(particle: *Particle, object: GameObject, offset: zlm.Vec2) void { 
    const random = (@mod(rand.float(f32), 100) - 50 ) / 10.0;
    const rColor = 0.5 + (@mod(rand.float(f32), 100) / 100.0);
    particle.position = object.position.add(zlm.Vec2.all(random)).add(offset);
    particle.color = zlm.vec4(rColor, rColor, rColor, 1.0);
    particle.life = 1.0;
    particle.velocity = object.velocity.scale(0.1);
}