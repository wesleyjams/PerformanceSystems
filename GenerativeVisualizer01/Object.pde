class Particle {
  PVector position;
  PVector velocity;
  PVector acceleration;
  PVector target;
  float lifespan;
  float angle;
  float maxSpeed = 5;
  float maxForce = 1.9;//snapy return
  float intensity;
  
  Particle(PVector l, float val) {
    intensity = val;
    target = l.copy(); // Remember where we started!
    position = l.copy();
    lifespan = 255.0;
    
    acceleration = new PVector(0, 0);
    
    // Calculate vector from Center of screen to this particle
    PVector center = new PVector(width/2, height/2);
    PVector direction = PVector.sub(position, center);
    direction.normalize(); 
    direction.mult(random(5, 25)); // Random explosion speed
    
    velocity = direction; // Set initial speed outwards
    
    //ALT BEHAVIOR
    //acceleration = new PVector(0, 0); //sets speed of movement and direction
    //float vx = randomGaussian()*-10.0;
    //float vy = randomGaussian()* - 10.0;
    //velocity = new PVector(vx, vy + (sin(angle) * height/2)); //sets destination
    ////location = new PVector(100, 100); //sets starting location
    //position = l.copy();
    //lifespan = 255.0; //alpha
    //angle -= 20.02;
  }
  
  void run(float currentAmp) {
  arrive(target);//goes back
  update();
  display(currentAmp);
}

void arrive(PVector target) {
    PVector desired = PVector.sub(target, position); // Vector points home
    float d = desired.mag(); // Distance to home

    // If we are close, slow down
    if (d > 50) {
      float m = map(d, 0, 100, 0, maxSpeed);
      desired.setMag(m);
      desired.rotate(PI /2);
    } else {
      desired.setMag(maxSpeed);
    }

    // Steering = Desired - Velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxForce); 
    applyForce(steer);
  }
  
  //Apply force vector to particle
  void applyForce(PVector f){
    acceleration.add(f);
  }
  
  //Update position
  void update() {
    float angle = noise(position.x * 0.01, position.y * 0.01, frameCount * 0.01) * TWO_PI * 4;
    PVector wind = PVector.fromAngle(angle);
    wind.mult(0.1);
    applyForce(wind);
    
    velocity.add(acceleration);
    position.add(velocity);
    lifespan -= 5.0;
    acceleration.mult(0);
  }
  
  //Display
  void display(float amp){
// Color based on intensity (bands)
    stroke(0, lifespan); 
    float size = map(amp, 0, 0.02, 2, 5);
    strokeWeight(size);
    point(position.x, position.y);
  }
  
  //Still in Use?
  boolean isDead() {
    if (lifespan < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}
