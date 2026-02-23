import processing.video.*;

//Fusée
PVector rocketPos;
PVector rocketVel;

//Flux optique
Capture cam;
boolean hasCam = false;
PImage previousFrame;
float flowX = 0, flowY = 0, flowIntensity = 0;

//Background étoiles
int numStars = 200;
float[][] stars;

void setup() {
  size(700, 700);

  // Fusée
  rocketPos = new PVector(width/2, height/2);
  rocketVel = new PVector(2, 0); // vitesse initiale plus douce

  // Webcam
  String[] cams = Capture.list();
  if (cams != null && cams.length > 0) {
    hasCam = true;
    cam = new Capture(this, 640, 480);
    cam.start();
  }

  // Étoiles
  stars = new float[numStars][3];
  for (int i=0; i<numStars; i++) {
    stars[i][0] = random(width);
    stars[i][1] = random(height);
    stars[i][2] = random(1, 3);
  }
}

void captureEvent(Capture cam) {
  if (hasCam) cam.read();
}

void draw() {
  //Background
  background(0);
  drawStars();

  //Flux optique
  computeOpticalFlow();

  //Mouvement fusée
  PVector targetVel = rocketVel.copy().normalize();
  targetVel.add(flowX, flowY);
  targetVel.normalize();

  // vitesse
  float speed = 1.5 + flowIntensity*5;
  targetVel.mult(speed);

  // interpolation pour mouvement fluide et prévisible
  rocketVel.lerp(targetVel, 0.08); 
  rocketPos.add(rocketVel);

  // Boucle sur les bords
  if (rocketPos.x > width) rocketPos.x = 0;
  if (rocketPos.x < 0) rocketPos.x = width;
  if (rocketPos.y > height) rocketPos.y = 0;
  if (rocketPos.y < 0) rocketPos.y = height;

  // -------------------- Dessiner fusée --------------------
  drawRocket(rocketPos, rocketVel);

  // -------------------- Cadran vitesse --------------------
  drawSpeedometer();
}

// -------------------- Fonctions --------------------
void drawStars() {
  stroke(255);
  for (int i=0; i<numStars; i++) {
    strokeWeight(stars[i][2]);
    point(stars[i][0], stars[i][1]);
  }
}

void computeOpticalFlow() {
  flowX = 0;
  flowY = 0;
  flowIntensity = 0;

  if (!hasCam) return;

  if (previousFrame == null) {
    previousFrame = cam.get();
    return;
  }

  cam.loadPixels();
  previousFrame.loadPixels();

  int step = 10;
  for (int y=0; y<cam.height; y+=step) {
    for (int x=0; x<cam.width; x+=step) {
      int i = x + y*cam.width;
      float current = brightness(cam.pixels[i]);
      float previous = brightness(previousFrame.pixels[i]);
      float diff = current - previous;
      if (abs(diff) > 25) {
        flowX += x - cam.width/2;
        flowY += y - cam.height/2;
        flowIntensity += abs(diff);
      }
    }
  }

  //
  flowX *= 0.00003;
  flowY *= 0.00003;
  flowIntensity *= 0.00015;

  previousFrame = cam.get();
}

void drawRocket(PVector pos, PVector vel) {
  pushMatrix();
  translate(pos.x, pos.y);
  rotate(vel.heading());

  // Corps
  fill(0, 0, 255);
  stroke(0, 0, 200);
  rect(0, -4, 20, 8);

  // Nez
  fill(255, 0, 0);
  stroke(200, 0, 0);
  triangle(20, -5, 20, 5, 28, 0);

  // Ailettes
  triangle(4, -4, -4, -8, 4, 0);
  triangle(4, 4, -4, 8, 4, 0);

  // Flamme animée selon vitesse
  float flameLength = map(rocketVel.mag(), 0, 10, 3, 20);
  float flameRed = 255;
  float flameGreen = map(rocketVel.mag(), 0, 10, 150, 50);
  float flameBlue = 0;

  fill(flameRed, flameGreen, flameBlue, 200);
  noStroke();
  triangle(-2, -3, -flameLength, 0, -2, 3);

  popMatrix();
}

void drawSpeedometer() {
  float speedNorm = constrain(rocketVel.mag()/12.0, 0, 1); // normalisation plus douce
  float angle = map(speedNorm, 0, 1, -PI/2, PI/2);

  // Cercle cadran
  fill(50, 50, 50, 200);
  stroke(200);
  strokeWeight(2);
  ellipse(100, 100, 80, 80);

  // Aiguille
  stroke(lerpColor(color(0, 255, 0), color(255, 0, 0), speedNorm)); // vert -> rouge
  strokeWeight(3);
  line(100, 100, 100 + cos(angle)*35, 100 + sin(angle)*35);

  // Texte
  noStroke();
  fill(255);
  textAlign(CENTER);
  textSize(12);
  text("Vitesse", 100, 85);
}
