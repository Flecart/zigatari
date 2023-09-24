const gl = @import("zgl");

const Self = @This();

const WrapType = gl.TextureParameterType(gl.TextureParameter.wrap_s);
const FilterMinType = gl.TextureParameterType(gl.TextureParameter.min_filter);
const FilterMaxType = gl.TextureParameterType(gl.TextureParameter.max_filter);

width: u32,
height: u32,
id: gl.Texture,
internal_format: gl.TextureInternalFormat,
image_format: gl.PixelFormat,
wrap_s: WrapType,
wrap_t: WrapType,
filter_min: FilterMinType,
filter_max: FilterMaxType,

pub fn init() Self {
    return Self {
        .width = 0,
        .height = 0,
        .id = gl.genTexture(),
        .internal_format = gl.TextureInternalFormat.rgb,
        .image_format = gl.PixelFormat.rgb,
        .wrap_s = WrapType.repeat,
        .wrap_t = WrapType.repeat,
        .filter_min = FilterMinType.linear,
        .filter_max = FilterMaxType.linear,
    };
}

pub fn generate(self: *Self, width: u32, height: u32, data: []const u8) void {
    self.width = width;
    self.height = height;

    // create Texture
    gl.bindTexture(gl.TextureTarget.@"2d", self.id);
    gl.textureImage2D(gl.TextureTarget.@"2d", 
        0, 
        self.internal_format, 
        width, height, 
        self.image_format, 
        gl.PixelType.unsigned_byte, 
        data.ptr
    );

    // set Texture wrap and filter modes
    gl.textureParameter(gl.TextureTarget.@"2d", gl.TextureParameter.wrap_s, self.wrap_s);
    gl.textureParameter(gl.TextureTarget.@"2d", gl.TextureParameter.wrap_t, self.wrap_t);
    gl.textureParameter(gl.TextureTarget.@"2d", gl.TextureParameter.min_filter, self.filter_min);
    gl.textureParameter(gl.TextureTarget.@"2d", gl.TextureParameter.max_filter, self.filter_max);

    // unbind texture
    gl.bindTexture(gl.TextureTarget.@"2d", 0);
}

pub fn bind(self: Self) void {
    gl.bindTexture(gl.TextureTarget.@"2d", self.id);
}