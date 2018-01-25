#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


const vec3 a = vec3(0.4, 0.5, 0.8);
const vec3 b = vec3(0.2, 0.4, 0.2);
const vec3 c = vec3(1.0, 1.0, 2.0);
const vec3 d = vec3(0.25, 0.25, 0.0);
const vec3 e = vec3(0.2, 0.5, 0.8);
const vec3 f = vec3(0.2, 0.25, 0.5);
const vec3 g = vec3(1.0, 1.0, 0.1);
const vec3 h = vec3(0.0, 0.8, 0.2);

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 6
float fbm (in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < 6; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

float dist (vec3 x, vec3 y) {
    return pow((x.x - y.x), 2.0) + pow((x.y - y.y), 2.0) + pow((x.z - y.z), 2.0);
}

float rand (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}
vec2 random2( vec2 p ) {
    return normalize(2.0 * fract(sin(vec2(dot(p,vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453) - 1.0);
}

vec3 Gradient(float t)
{
    return a + b * cos(6.2831 * (c * t + d));
}

vec3 Gradient2(float t)
{
    return e + f * cos(6.2831 * (g * t + h));
}

float surflet(vec2 P, vec2 gridPoint)
{
    // Compute falloff function by converting linear distance to a polynomial
    float distX = abs(P.x - gridPoint.x);
    float distY = abs(P.y - gridPoint.y);
    float tX = 1.0 - 6.0 * pow(distX, 5.0) + 15.0 * pow(distX, 4.0) - 10.0 * pow(distX, 3.0);
    float tY = 1.0 - 6.0 * pow(distY, 5.0) + 15.0 * pow(distY, 4.0) - 10.0 * pow(distY, 3.0);
    
    vec2 gradient = random2(gridPoint); // Get the random vector for the grid point
    vec2 diff = P - gridPoint;     // Get the vector from the grid point to P
    float height = dot(diff, gradient);     // Get the value of our height field by dotting grid->P with our gradient
    return height * tX * tY;     // Scale our height field (i.e. reduce it) by our polynomial falloff function
}

float PerlinNoise(vec2 uv)
{
    // Tile the space
    vec2 uvXLYL = floor(uv);
    vec2 uvXHYL = uvXLYL + vec2(1,0);
    vec2 uvXHYH = uvXLYL + vec2(1,1);
    vec2 uvXLYH = uvXLYL + vec2(0,1);

    return surflet(uv, uvXLYL) + surflet(uv, uvXHYL) + surflet(uv, uvXHYH) + surflet(uv, uvXLYH);
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;
        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec + vec4(sin(u_Time * 0.1))));

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

    float x1 = fs_Pos.x;
    float y1 = fs_Pos.y;
    float z1 = fs_Pos.z;

    vec2 uv = fs_Pos.xy;

    vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
    float dist = dist(vec3(x1, y1 + 2.0, z1 - 1.0), vec3(0.0, 2.0, 0.0));
    
    //create a mineral core
    if(dist > 0.35) {
        vec3 a = vec3(0.5,0.5,0.5);
        vec3 b = vec3(0.5,0.5,0.5);
        vec3 c = vec3(1.0,1.0,0.5);
        vec3 d = vec3(0.80,0.20,0.20);
        vec3 color = vec3(a + b * cos(2.0 * 3.14159 * (c * diffuseTerm + d)));
    }
    else {
        float fx = fbm(uv * sin(u_Time * 0.01));
        color = vec4(0.1 + 1.0 * fx, 0.6 * fx, 1.0 * fx, 1.0);
    }
    
    vec4 view_vec = fs_Pos * vec4(2.0, 2.0 , 8.0, 1.0);
    vec4 light_vec = fs_LightVec;
    vec4 average = normalize((view_vec + light_vec) / 2.0);
    vec4 normal = normalize(fs_Nor);
    float exp = 50.0;
    float SpecularIntensity = max(pow(dot(average, normal), exp), 0.0);

    diffuseColor = vec4(color.rgb * lightIntensity + SpecularIntensity, 1.0);

    vec4 colorIn = diffuseColor;

    if(diffuseColor.r > 0.9 && diffuseColor.g > 0.9 && diffuseColor.b> 0.9){
        colorIn.r = 1.0;
        colorIn.g = 1.0;
        colorIn.b = 1.0;
    }

    if(diffuseTerm > 0.99){
        color = colorIn * vec4(1.0, 1.0, 1.0, 1.0);
    }
    else if(diffuseTerm > 0.85){
        color = colorIn * vec4(0.9, 0.9, 0.9, 1.0);
    }
    else if(diffuseTerm > 0.5){
        color = colorIn * vec4(0.7, 0.7, 0.7, 1.0);
    }
    else{
        color = colorIn * vec4(0.1, 0.1, 0.1, 1.0);
    }
    out_Col = vec4(color.rgb, 1.0);

}
