class ParticleSystem {
  ArrayList<Particle> particles;
  PVector origin; //where they are birthed
  int bandIndex; 
  
  ParticleSystem(PVector position, int index) {
    origin = position.copy();
    bandIndex = index; //stores FFT index
    particles = new ArrayList<Particle>();
    //for (int i = 0; i < num; i++) {
      particles.add(new Particle(origin, (float)index));
    //}
  }
  
  void applyForce(PVector dir) {
    for (Particle p : particles){
      p.applyForce(dir);
    }
  }
  
  //void addParticle() {
  //  particles.add(new Particle(origin));
  //}
  
  void run(float[] spectrum){
    
    int safeIndex = bandIndex % spectrum.length;
    float currentAmp = spectrum[safeIndex];
    for (int i = particles.size()-1; i >=0; i--) {//iterates through arraylist
      Particle p = particles.get(i);
      p.run(currentAmp);
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }
  boolean isEmpty() {
    return particles.isEmpty();
  }
}
