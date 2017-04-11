#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// takes input texture, applies desaturation, interlacing effect, doubled image, deterministic noise and optional tint (currently set internally)

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;

uniform int imgHeight;
uniform vec2 overlayOffset;
uniform float time;

uniform vec4 tint = vec4(1, 1, 1, 1);

varying vec4 vertColor;
varying vec4 vertTexCoord;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main() {
  vec4 oddColor = vec4(0.5,0.5,0.5, 1.0);
  vec4 quarterColor = vec4(0.25, 0.25, 0.25, 1.0);
  vec4 tempColor = vec4(0,0,0,1.0);
  
  // interlace
  if( int(vertTexCoord.t*imgHeight) % 2 == 0) {
	tempColor = (texture2D(texture, vertTexCoord.st) + (texture2D(texture, vertTexCoord.st + overlayOffset) * quarterColor))  * vertColor;
  }
  else {
	tempColor = (texture2D(texture, vertTexCoord.st) + (texture2D(texture, vertTexCoord.st + overlayOffset) * quarterColor))  * vertColor * oddColor;
  }
  
  // noise
  float noise = rand( vec2( floor(vertTexCoord.s * imgHeight)/imgHeight + time , floor(vertTexCoord.t * imgHeight)/imgHeight + time ));
  noise = mod(noise, 0.2);
  tempColor = tempColor + vec4(noise, noise, noise, 1.0);
  // desaturate and tint
  float lum = (0.299 * tempColor.r) + (0.587 * tempColor.g) + (0.144 * tempColor.b);
  vec4 finalColor = vec4(lum * tint.r, lum * tint.g, lum * tint.b, tempColor.a);
  gl_FragColor = finalColor;
}