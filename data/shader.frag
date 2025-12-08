#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture;
uniform vec2 texOffset; 

varying vec4 vertTexCoord;
varying vec4 vertColor;

uniform float edgeThreshold; 
uniform float glowIntensity; 
uniform float chromaSeparation; 
uniform float backgroundDim;

// 1. Helper function for luminance
float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

// 2. The Edge Detection Logic (Moved to a function)
float getEdge(vec2 centerUV) {
  // Sample the 3x3 grid around the specific coordinate passed in
  float sample00 = luma(texture(texture, centerUV + vec2(-texOffset.x, -texOffset.y)).rgb);
  float sample10 = luma(texture(texture, centerUV + vec2(0.0,         -texOffset.y)).rgb);
  float sample20 = luma(texture(texture, centerUV + vec2(texOffset.x,  -texOffset.y)).rgb);
  
  float sample01 = luma(texture(texture, centerUV + vec2(-texOffset.x, 0.0)).rgb);
  float sample21 = luma(texture(texture, centerUV + vec2(texOffset.x,  0.0)).rgb);
  
  float sample02 = luma(texture(texture, centerUV + vec2(-texOffset.x, texOffset.y)).rgb);
  float sample12 = luma(texture(texture, centerUV + vec2(0.0,          texOffset.y)).rgb);
  float sample22 = luma(texture(texture, centerUV + vec2(texOffset.x,  texOffset.y)).rgb);

  float horizEdge = (sample00 + 2.0 * sample01 + sample02) - 
                    (sample20 + 2.0 * sample21 + sample22);
  float vertEdge = (sample00 + 2.0 * sample10 + sample20) - 
                   (sample02 + 2.0 * sample12 + sample22);

  float edge = sqrt((horizEdge * horizEdge) + (vertEdge * vertEdge));
  
  // Apply threshold
  return smoothstep(edgeThreshold, edgeThreshold + 0.1, edge);
}

void main() {
  vec2 uv = vertTexCoord.xy;
  vec4 originalColor = texture(texture, uv);

  // 3. SEPARATE THE CHANNELS
  // We calculate the edge 3 times at slightly different positions
  
  // CYAN (Shifted Negative X)
  float edgeCyan = getEdge(uv - vec2(chromaSeparation * texOffset.x, 0.0));
  
  // MAGENTA (Center)
  float edgeMag = getEdge(uv);
  
  // YELLOW (Shifted Positive X)
  float edgeYel = getEdge(uv + vec2(chromaSeparation * texOffset.x, 0.0));

  // 4. DEFINE COLORS
  // CMY Colors (Cyan = G+B, Magenta = R+B, Yellow = R+G)
  vec3 cColor = vec3(0.0, 0.9, 0.9);
  vec3 mColor = vec3(0.9, 0.0, 0.9);
  vec3 yColor = vec3(0.9, 0.9, 0.0);

  // 5. COMBINE
  // Add the three edge results together
  vec3 finalGlow = (cColor * edgeCyan) + (mColor * edgeMag) + (yColor * edgeYel);
  
  finalGlow *= glowIntensity;

  vec3 finalComposition = (originalColor.rgb * backgroundDim) + finalGlow;

  // Add to original
  gl_FragColor = vec4(originalColor.rgb + finalGlow, originalColor.a);
}