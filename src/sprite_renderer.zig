const glm = @import("zlm");
const gl = @import("zgl");

const Shader = @import("./shader.zig");
const Texture = @import("./texture.zig");

const Self = @This();

quadVAO: gl.VertexArray,
shader: Shader,

pub fn init(shader: Shader) Self {
    var self = Self {
        .quadVAO = gl.VertexArray.invalid,
        .shader = shader,
    };
    self.initRenderData();
    return self;
}

pub fn drawSprite(
    self: Self,
    texture: Texture, 
    position: glm.Vec2,
    size: glm.Vec2,
    rotate: f32,
    color: glm.Vec3,
) void {
    self.shader.use();

    var model = glm.Mat4.createTranslationXYZ(position.x, position.y, 0.0);
    model = glm.Mat4.createTranslationXYZ(0.5 * size.x, 0.5 * size.y, 0.0).mul(model);
    model = glm.Mat4.createAngleAxis(glm.vec3(0.0, 0.0, 1.0), glm.toRadians(rotate)).mul(model);
    model = glm.Mat4.createTranslationXYZ(-0.5 * size.x, -0.5 * size.y, 0.0).mul(model);
    model = glm.Mat4.createScale(size.x, size.y, 1.0).mul(model);

    self.shader.setMat4("model", model);
    self.shader.setVec3("spriteColor", color);

    gl.activeTexture(gl.TextureUnit.texture_0);
    texture.bind();

    gl.bindVertexArray(self.quadVAO);

    gl.drawArrays(gl.PrimitiveType.triangles, 0, 6);

    gl.bindVertexArray(gl.VertexArray.invalid);
}

fn initRenderData(self: *Self) void {
    const vbo = gl.genBuffer();
    defer gl.deleteBuffer(vbo);

    const vertices = [_]f32{
        // pos      // tex
        0.0, 1.0, 0.0, 1.0,
        1.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 
    
        0.0, 1.0, 0.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 0.0, 1.0, 0.0
    };

    self.quadVAO = gl.genVertexArray();
    gl.bindVertexArray(self.quadVAO);
    gl.bindBuffer(vbo, gl.BufferTarget.array_buffer);
    gl.bufferData(gl.BufferTarget.array_buffer, f32, &vertices, gl.BufferUsage.static_draw);

    gl.vertexAttribPointer(0, 4, gl.Type.float, false, 4 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(0);
    gl.bindBuffer(gl.Buffer.invalid, gl.BufferTarget.array_buffer);
    gl.bindVertexArray(gl.VertexArray.invalid);
}
