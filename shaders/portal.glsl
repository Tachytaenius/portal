// The following code is not mine, mine is below

/* https://www.shadertoy.com/view/XsX3zB
 *
 * The MIT License
 * Copyright © 2013 Nikita Miropolskiy
 * 
 * ( license has been changed from CCA-NC-SA 3.0 to MIT
 *
 *   but thanks for attributing your source code when deriving from this sample 
 *   with a following link: https://www.shadertoy.com/view/XsX3zB )
 *
 * ~
 * ~ if you're looking for procedural noise implementation examples you might 
 * ~ also want to look at the following shaders:
 * ~ 
 * ~ Noise Lab shader by candycat: https://www.shadertoy.com/view/4sc3z2
 * ~
 * ~ Noise shaders by iq:
 * ~     Value    Noise 2D, Derivatives: https://www.shadertoy.com/view/4dXBRH
 * ~     Gradient Noise 2D, Derivatives: https://www.shadertoy.com/view/XdXBRH
 * ~     Value    Noise 3D, Derivatives: https://www.shadertoy.com/view/XsXfRH
 * ~     Gradient Noise 3D, Derivatives: https://www.shadertoy.com/view/4dffRH
 * ~     Value    Noise 2D             : https://www.shadertoy.com/view/lsf3WH
 * ~     Value    Noise 3D             : https://www.shadertoy.com/view/4sfGzS
 * ~     Gradient Noise 2D             : https://www.shadertoy.com/view/XdXGW8
 * ~     Gradient Noise 3D             : https://www.shadertoy.com/view/Xsl3Dl
 * ~     Simplex  Noise 2D             : https://www.shadertoy.com/view/Msf3WH
 * ~     Voronoise: https://www.shadertoy.com/view/Xd23Dh
 * ~ 
 *
 */

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
	float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}

/* skew constants for 3d simplex functions */
const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
	 /* 1. find current tetrahedron T and it's four vertices */
	 /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
	 /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
	 
	 /* calculate s and x */
	 vec3 s = floor(p + dot(p, vec3(F3)));
	 vec3 x = p - s + dot(s, vec3(G3));
	 
	 /* calculate i1 and i2 */
	 vec3 e = step(vec3(0.0), x - x.yzx);
	 vec3 i1 = e*(1.0 - e.zxy);
	 vec3 i2 = 1.0 - e.zxy*(1.0 - e);
	 	
	 /* x1, x2, x3 */
	 vec3 x1 = x - i1 + G3;
	 vec3 x2 = x - i2 + 2.0*G3;
	 vec3 x3 = x - 1.0 + 3.0*G3;
	 
	 /* 2. find four surflets and store them in d */
	 vec4 w, d;
	 
	 /* calculate surflet weights */
	 w.x = dot(x, x);
	 w.y = dot(x1, x1);
	 w.z = dot(x2, x2);
	 w.w = dot(x3, x3);
	 
	 /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
	 w = max(0.6 - w, 0.0);
	 
	 /* calculate surflet components */
	 d.x = dot(random3(s), x);
	 d.y = dot(random3(s + i1), x1);
	 d.z = dot(random3(s + i2), x2);
	 d.w = dot(random3(s + 1.0), x3);
	 
	 /* multiply d by w^4 */
	 w *= w;
	 w *= w;
	 d *= w;
	 
	 /* 3. return the sum of the four surflets */
	 return dot(d, vec4(52.0));
}

/* const matrices for 3d rotation */
const mat3 rot1 = mat3(-0.37, 0.36, 0.85,-0.14,-0.93, 0.34,0.92, 0.01,0.4);
const mat3 rot2 = mat3(-0.55,-0.39, 0.74, 0.33,-0.91,-0.24,0.77, 0.12,0.63);
const mat3 rot3 = mat3(-0.71, 0.52,-0.47,-0.08,-0.72,-0.68,-0.7,-0.45,0.56);

/* directional artifacts can be reduced by rotating each octave */
float simplex3d_fractal(vec3 m) {
    return   0.5333333*simplex3d(m*rot1)
			+0.2666667*simplex3d(2.0*m*rot2)
			+0.1333333*simplex3d(4.0*m*rot3)
			+0.0666667*simplex3d(8.0*m);
}

// My code:

varying vec3 fragmentNormal;
varying vec3 fragmentPosition;

#ifdef VERTEX

uniform mat4 modelToWorld;
uniform mat3 modelToWorldNormal;
uniform mat4 modelToScreen;

attribute vec3 VertexNormal;

vec4 position(mat4 loveTransform, vec4 homogenVertexPosition) {
	fragmentNormal = modelToWorldNormal * VertexNormal;
	vec4 ret = modelToScreen * homogenVertexPosition;
	ret.y *= -1.0;
	fragmentPosition = (modelToWorld * homogenVertexPosition).xyz; // Probably needs -y as well
	return ret;
}

#endif

#ifdef PIXEL

uniform float aspectRatio;

uniform float time;

uniform float swirlChangeFrequency;
uniform float swirlChangeAmplitude;
uniform float swirlChangeSlope;
uniform float swirlSpeedMultiplier;

uniform float colour1ZShiftRate;
uniform float colour2ZShiftRate;
uniform float colour3ZShiftRate;

uniform float colour1SwirlTimeMultiplier;
uniform float colour1SwirlResetTime;
uniform float colour1SwirlResetLerpLength;

uniform float colour2SwirlResetTime;
uniform float colour2SwirlResetLerpLength;

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, s, -s, c);
	return m * v;
}

vec2 multiplyInDirection(vec2 v, float a, float m) {
	v = rotate(v, -a);
	v.x *= m;
	return rotate(v, a);
}

vec2 swirlSurfaceCoord(vec2 surfaceCoord, float time, float direction) {
	float swirlSpeed =
		cos(length(surfaceCoord) * swirlChangeFrequency) * swirlChangeAmplitude
		+ length(surfaceCoord) * swirlChangeSlope;
	return rotate(surfaceCoord, time * swirlSpeed * swirlSpeedMultiplier * direction);
}

vec3 getColour1(vec2 surfaceCoord, float time, float swirlDirection) {
	return vec3(simplex3d(vec3(swirlSurfaceCoord(surfaceCoord * 2.0, time * colour1SwirlTimeMultiplier, swirlDirection), time * colour1ZShiftRate + 0.0)));
}

vec3 getColour2(vec2 surfaceCoord, float time, float swirlDirection) {
	return vec3(
		simplex3d(vec3(swirlSurfaceCoord(surfaceCoord * 1.0, time, swirlDirection), time * colour2ZShiftRate + 10.0)),
		simplex3d(vec3(swirlSurfaceCoord(surfaceCoord * 1.1, time, swirlDirection), time * colour2ZShiftRate + 10.1)),
		simplex3d(vec3(swirlSurfaceCoord(surfaceCoord * 0.9, time, swirlDirection), time * colour2ZShiftRate + 10.2))
	);
}

vec3 lerp(vec3 a, vec3 b, float i) {
	return a + (b - a) * i;
}

// Using the word fog for these functions because they both can be used for fog, but here they aren't

float calculateFogFactor(float dist, float maxDist, float fogFadeLength) { // More fog the further you are
	if (fogFadeLength == 0.0) { // Avoid dividing by zero
		return dist < maxDist ? 0.0 : 1.0;
	}
	return clamp((dist - maxDist + fogFadeLength) / fogFadeLength, 0.0, 1.0);
}

float calculateFogFactor2(float dist, float fogFadeLength) { // More fog the closer you are
	if (fogFadeLength == 0.0) { // Avoid dividing by zero
		return 1.0; // Immediate fog
	}
	return clamp(1 - dist / fogFadeLength, 0.0, 1.0);
}

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	vec2 surfaceCoord = textureCoords * 2.0 - 1.0;

	float colour1Time = mod(time, colour1SwirlResetTime);
	float swirlDirection1 = mod(floor(time / colour1SwirlResetTime), 2.0) * 2.0 - 1.0;
	vec3 colour1 = lerp(
		getColour1(surfaceCoord, colour1Time, swirlDirection1),
		getColour1(surfaceCoord, colour1Time - colour1SwirlResetTime, -swirlDirection1),
		calculateFogFactor(colour1Time, colour1SwirlResetTime, colour1SwirlResetLerpLength)
	) / 2.0 + 0.5;

	float colour2Time = mod(time, colour2SwirlResetTime);
	float swirlDirection2 = mod(floor(time / colour2SwirlResetTime), 2.0) * 2.0 - 1.0;
	vec3 colour2 = lerp(
		getColour2(surfaceCoord, colour2Time, swirlDirection2),
		getColour2(surfaceCoord, colour2Time - colour2SwirlResetTime, -swirlDirection2),
		calculateFogFactor(colour2Time, colour2SwirlResetTime, colour2SwirlResetLerpLength)
	);

	vec3 colour3 = vec3(
		simplex3d(
			vec3(
				textureCoords / 2.0
					+ time * 0.125 * vec2(cos(1), sin(1)),
				time * colour3ZShiftRate + 20.0
			)
		)
	);

	float edgeFade = calculateFogFactor(
		length(surfaceCoord * vec2(1.0, aspectRatio)),
		1.0,
		0.125
	);

	return colour * vec4(
		vec3(
			colour1 * 0.4 + 0.2
			+ colour2
			* (colour3 * 0.5 + 0.5)
		),
		1.0 - pow(edgeFade, 2.0)
	);
}

#endif
