import processing.sound.*;

float pitchColor;

Amplitude amp;

AudioIn in;
Sound s; //initialization for sampleRate

Waveform waveform;
int samples = 512;
int numTrails = 3; //waveform history data
float[][] waveHistory = new float[numTrails][samples];
int writeIndex = 0;

FFT fft;
int bands = 8;
float[] spectrum = new float[bands];

BeatDetector beat;
long lastBeat = 0;
int beatLeng = 1000;

PitchDetector pitch;
float smoothPitch;
float pitchMap;
int numReadings = 10; //Frames to average
float[] readings = new float[numReadings]; //creates array
int readIndex = 0;
float total = 0;
float averagePitch = 0;

color pc;

ParticleSystem ps;
ArrayList<ParticleSystem> systems;

PShape logo;
float ry;

float xoff = 0.0;
float yoff = 0.0;

PShader edgeShader;

void setup() {
  pixelDensity(1);
  //fullScreen(P2D); //multiscreen
  size(960, 540, P3D);
  //windowResize(width/2, height/2);
  //background(255);
  frameRate(60);

  logo = loadShape("West Hues Logo.svg");
  edgeShader = loadShader("shader.frag");

  s = new Sound(this);
  //s.sampleRate(22050); //Cuts CPU usage in half

  waveform = new Waveform(this, samples); //creates waveform analysis

  amp = new Amplitude(this);

  // Create an Input stream which is routed into the Amplitude analyzer
  fft = new FFT(this, bands);
  in = new AudioIn(this, 0);

  beat = new BeatDetector(this); //Creates beatdetector
  beat.sensitivity(10); //sets sensitivity in ms, busier tracks are less reactive

  pitch = new PitchDetector(this, 0.6); //sets pitch detection with minimum confidence
  for (int i = 0; i < numReadings; i++) { //initializes array
    readings[i] = 0;
  }

  //in.play();
  Sound.list(); //shows input list

  in.start();

  // patch the AudioIn
  fft.input(in);
  waveform.input(in);
  beat.input(in);
  pitch.input(in);
  amp.input(in);

  colorMode(HSB);

  systems = new ArrayList<ParticleSystem>(); //creates systems of particles systems
}

void draw() {
  background(0);
  drawBackground();
  waveformAnalyze();
  beatDetection();
  
    //Dancing globes (boring and distracting, stopped showing for some reason, need movement)
  //drawShp(spectrum[0]*height*2, width/4, height/2, 0, 0);
  //drawShp(spectrum[1]*height*2, width/2, height/4, 0, 75);
  //drawShp(spectrum[2]*height*8, width/3, height/2, 0, 150);
  //drawShp(spectrum[3]*height*16, width/3, height/3, 0, 255);

  //Creates a smooth pitch tracking variable
  float newPitch = map(pitch.analyze(), 50, 5000, 0, 100); //maps value to smaller function
  total = total - readings[readIndex];//subtract oldest reading from running total
  readings[readIndex] = newPitch;//add new reading to array
  total = total + readings[readIndex];//add new to running total
  readIndex = readIndex +1; //moves to next position in array
  if (readIndex >= numReadings) {//starts over again
    readIndex = 0;
  }
  averagePitch = total/numReadings; //calculates average
  smoothPitch = lerp(smoothPitch, averagePitch, 0.05);//lerps
  float pitchMap = map(smoothPitch, 50, 5000, 0.5, 1.0);
  
  //float rnorm = map(spectrum[1], 0.0, 0.07, 0.0, pitchMap); //pitch variables for shader
  //float gnorm = map(spectrum[2], 0.0, 0.02, 0.0, pitchMap);
  //float bnorm = map(spectrum[2], 0.0, 0.01, 0.0, pitchMap);

  for (ParticleSystem ps : systems) { //draws systems
    ps.run(spectrum);
    //ps.applyForce(new PVector(smoothPitch, newPitch)); //wind function
  }

  push();
    logo.enableStyle();
    logo.setFill(color(255));
    logo.setStroke(color(0));
    translate(width/4, height/6);
    //rotateZ(PI);
    rotateX(ry);
    shape(logo, 0, 0, width/2, height/2);
    //ry += 0.02;
  pop();

  edgeShader.set("texOffset", 1.0/width, 1.0/height);
  float glowThresh = map(amp.analyze(), 0.001, 0.1, 6.0, 1.1); //sets amp threshold! (INVERSE)
  edgeShader.set("edgeThreshold", glowThresh);
  //Adjusts color seperation
  float splitFreq = spectrum[2];
  float splitAmount = 0.00;
  splitAmount = map(splitFreq, 0.1, 0.2, 0.0, 10.0); //sets bass split amount
  edgeShader.set("chromaSeparation", splitAmount);
  edgeShader.set("backgroundDim", 0.9); 
  edgeShader.set("glowIntensity", 5.55);

  filter(edgeShader);

  //println(pitch.analyze());
}

void drawBackground() {
  loadPixels();
  float rotationSpeed = 0.05;
  float spin = frameCount * rotationSpeed;
  float angle = 0;
  float a = 1;
  xoff = HALF_PI+sin(a);
  yoff = HALF_PI+sin(a);
  float n = (sin(angle) + smoothPitch*0.5);
  float w = 35.0;         // 2D space width
  float h = 35.0;         // 2D space height
  float dx = w / width;    // Increment x this amount per pixel
  float dy = h / height;   // Increment y this amount per pixel
  float x = -w/2;          // Start x at -1 * width / 2
  for (int i = 0; i < width; i++) {
    float y = -h/2;        // Start y at -1 * height / 2
    for (int j = 0; j < height; j++) {
      float r = sqrt((x*x*xoff) + (y*y*yoff));    // Convert cartesian to polar
      float theta = atan2(y, x);         // Convert cartesian to polar
      // Compute 2D polar coordinate function
      //float val = sin(n*cos(r) + 5 * theta);  // Results in a value between -1 and 1
      float val = sin(r*cos(n)+ 2 * -(theta-spin)); // Main function
      //float val = sin(r*cos(n));   //Alt function                      
      //float val = sin(theta);      //Alt function
      val += random(-0.05, 0.05); //adds noise to gradient, static like
      // Map resulting value to grayscale value
      pixels[i+j*width] = color((val + 1.0) * 255.0/2.0);     // Scale to between 0 and 255
      //pixels[i+j*width] = color(val * 255, 255, val * 200); //Alternative
      y += dy;              
      angle += 0.02;
    }
    x += dx;              
    a += TWO_PI;
  }
  updatePixels();
}


void beatDetection() { 
  boolean b = beat.isBeat(); 
  //beat.sensitivity(1);
  lastBeat = millis();

  if (b == true) {

    //push(); //could be interesting new direction...
      //logo.disableStyle();
      //logo.setFill(155);
      //translate(width/4, height/6);
      //rotateZ(PI);
      //rotateY(ry);
      //shape(logo, 0, 0, width/2, height/2);
      //ry += 0.02;
    //pop();

    int children = logo.getChildCount();
    float xOffset = width/2-width/7;
    float yOffset = height/2-height/4;
    float setW = width/2;
    float setH = height/2;
    float scaleX = setW / logo.width;
    float scaleY = setH / logo.height;
    for (int i = 0; i < children; i++) {

      PShape child = logo.getChild(i);
      int total = child.getVertexCount();
      int myBand = i % bands;

      for (int j = 0; j < total; j++) {
        PVector v = child.getVertex(j);
        systems.add(new ParticleSystem
          (new PVector((v.x*scaleX) + xOffset, (v.y*scaleY) + yOffset), myBand));
      }
    }
  } else {
    push();
    logo.disableStyle();
    logo.setFill(0);
    translate(width/4, height/6);
    //rotateZ(PI);
    //rotateY(ry);
    shape(logo, 0, 0, width/2, height/2);
    //ry += 0.02;
    pop();

    if (millis() - lastBeat > beatLeng) {
      systems.clear();
    }
  }
}

void waveformAnalyze() {
  waveform.analyze();
  stroke(0); //this is logo outline for some reason??
  strokeWeight(4);

  push();
  //Saves current raw audio data into history array, writeIndex overwrites cyclically
  for (int i = 0; i < samples; i++) {
    waveHistory[writeIndex][i] = waveform.data[i];
  }
  if (amp.analyze() > 0.05) {
    strokeWeight(2);
    noFill();
    //loops through history slots
    for (int i = 0; i < numTrails; i++) {
      int readIndex = (writeIndex - i + numTrails) % numTrails;//creates order for draw
      float alpha = map(i, 0, numTrails, 155, 0);
      stroke(0, alpha);

      beginShape();
      for (int s=0; s < samples; s++) {
        float x = map(s, 0, samples, 0, width);
        float y = map(waveHistory[readIndex][s], -1, 1, 0, height); //gets data from history
        vertex(x, y);
      }
      endShape();
    }
    writeIndex = (writeIndex +1) % numTrails; //moves to next slot for following frame
    //print(waveform.data);
  }
  pop();
}

void drawShp(float size, int xloc, int yloc, int zloc, int number) {
  pushMatrix();
  stroke(number);
  noFill();
  translate(xloc, yloc, zloc);
  sphere(size);
  popMatrix();
}
