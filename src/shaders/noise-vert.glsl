#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.
// beat value, 0->1, 1->0
float beat(float x) {
	float temp = x-1.0;
	temp *= temp;
	temp *= temp;
	return temp*(cos(30.0*x)*.5+.5);
}

// point to background color value
vec3 backgroundColor(vec2 p) {
	vec3 color = vec3(.3, .05, .2);
	
	// add a star
	float t = atan(p.y, p.x) / PI;
	t *= 5.0;
	t += iTime*0.5;
	t = abs(fract(t)*2.0-1.0);
	float star = smoothstep(0.5, 0.6, t);
	color = mix(color, vec3(0.5, 0.2, 0.4), star);
	
	// add some flowers
	p.y+=3.3;
	p *= 0.2;
	for (float i = 0.0 ; i < 5.5 ; i++) {
		vec2 pp = p;
		pp *= rot(.05*sin(2.0*iTime+2.0*PI*rand(vec2(i,1.0))));
		pp.x += iTime*(rand(vec2(i,2.0))*2.0-1.0)*(i+3.0)*.12;
		pp.y += sin(iTime+2.0*PI*rand(vec2(i,3.0)))*.1;
		vec4 flowerValue = flower(pp, 5.0+floor(i*.5), i);
		p.y += 0.02;
		p /= 0.9;
		
		vec3 flowerColor = vec3(rand(vec2(i, 19.0))*1.0,
								rand(vec2(i, 18.0))*0.2,
								rand(vec2(i, 16.0))*0.8);
		
		flowerValue.rgb = flowerColor*flowerValue.rgb*3.0+flowerValue.rgb;
		color = mix(color, flowerValue.rgb, flowerValue.a);
	}
	
	return color;
}

// point to heart value
float heartFormula(vec2 p, bool time) {
	// heartbeat
	if (time) {
		float beatValue = beat(fract(0.824*iTime))*0.1;
		p.x *= 1.0 + beatValue * 2.0;
		p.y *= 1.0 - beatValue * 1.5;
	}
	// center the heart around the axis
	p.y -= 1.6;
	// see http://mathworld.wolfram.com/HeartCurve.html
	float t = atan(p.y, p.x);
	float si = sin(t);
	float r = 2.0 - 2.0 * si + si * (sqrt(abs(cos(t))) / (si + 1.4));
	return length(p)-r;
}

// heart value to heart color with alpha
vec4 heartColor(vec2 p) {
	float v = heartFormula(p, true);
	vec3 color = vec3(1.0, 0.5, 0.8);
	color -= smoothstep(-0.8, +0.5, v)*vec3(0.6);
	color += smoothstep(-0.0, -1.6, v)*vec3(.4);
	color -= smoothstep(-0.2, +0.2, v)*vec3(0.1);
	return vec4(color, smoothstep(0.2, 0.1, v));
}

// opening
float opening(vec2 p) {
	float mult = max(0.0, 5.0-iTime*1.5);
	p *= 3.0*mult*mult*mult;
	p *= rot(sin(iTime*6.0)*.2);
	float v = heartFormula(p, false);
	return smoothstep(-0.5, 0.5, v);
}

void main()
{
    vec2 uv = gl_Position.xy / vec2(640,480) * 2.0 - 1.0;
	uv.x *= 640 / 480;
	float mult = 3.0+4.0 * beat(min(1.0, 0.09* u_Time));
	uv *= mult;
	
	// get background
	vec3 color = backgroundColor(uv);
	// heart formula and color
	vec4 hcolor = heartColor(uv*mult*.32);
	// and blend with heart color
	color = mix(color, hcolor.rgb, hcolor.a);
	color = clamp(color, 0.0, 1.0);
	// set opening
	color -= opening(uv);
	
	fragColor.rgb = color;
	fragColor.a = 1.0;

    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

                                             	

}
