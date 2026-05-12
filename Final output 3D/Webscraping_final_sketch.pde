PImage[] imgs = new PImage[5];

int totalFrames = 1500;        // ~50 seconds @30fps
int sceneDuration = 150;       // 5 seconds per scene
int baseSamples = 240;

color paper = color(246, 241, 226);

color[] palette = {
  color(220,48,36,210),
  color(238,145,36,210),
  color(78,150,165,190),
  color(40,160,95,170),
  color(135,95,160,170),
  color(235,205,60,180),
  color(20,20,20,220),
  color(130,135,125,160)
};

void setup() {
  size(1920, 1080, P3D);
  frameRate(30);
  smooth(8);

  for (int i = 0; i < 5; i++) {
    imgs[i] = loadImage("c" + i + ".png");
    imgs[i].resize(width, height);
    imgs[i].loadPixels();
  }
}

void draw() {
  background(paper);

  int sceneA = (frameCount / sceneDuration) % 5;
  int sceneB = (sceneA + 1) % 5;

  float t = (frameCount % sceneDuration) / float(sceneDuration);
  float blend = smoothstep(0.6, 1.0, t);

  lights();

  translate(width/2, height/2, -400);
  rotateX(radians(6) + sin(frameCount * 0.01) * 0.04);
  rotateY(sin(frameCount * 0.008) * 0.08);
  translate(-width/2, -height/2);

  drawBackgroundGrid();

  drawScene(imgs[sceneA], sceneA, 1.0 - blend);
  drawScene(imgs[sceneB], sceneB, blend);

  saveFrame("frames_hd/frame_####.png");

  if (frameCount >= totalFrames) exit();
}

// ---------------- GRID ----------------

void drawBackgroundGrid() {
  stroke(0, 18);
  strokeWeight(1);

  int step = 110;

  for (int x = -600; x < width + 600; x += step) {
    line(x, -400, -300, x, height + 400, -300);
  }
  for (int y = -600; y < height + 600; y += step) {
    line(-600, y, -300, width + 600, y, -300);
  }

  stroke(0, 10);
  for (int x = -600; x < width + 600; x += step * 2) {
    line(x, -400, 50, x, height + 400, 50);
  }
  for (int y = -600; y < height + 600; y += step * 2) {
    line(-600, y, 50, width + 600, y, 50);
  }

  stroke(0, 8);
  for (int i = -800; i < width + 800; i += 180) {
    line(i, -400, -100, i + 800, height + 400, 120);
    line(i + 800, -400, -100, i, height + 400, 120);
  }
}

// ---------------- MAIN SCENE ----------------

void drawScene(PImage img, int scene, float alphaMult) {

  int samples = baseSamples;
  if (scene == 0) samples = 200;
  if (scene == 1) samples = 230;
  if (scene == 2) samples = 280;
  if (scene == 3) samples = 250;
  if (scene == 4) samples = 300;

  float spread = 1.2 + 0.3 * sin(frameCount * 0.012);
  float breathe = 0.8 + 0.4 * sin(frameCount * 0.018 + scene);

  for (int i = 0; i < samples; i++) {

    float seed = scene * 1000 + i * 23.7;

    float x = map(noise(seed, 0), 0, 1, -300, width + 300);
    float y = map(noise(seed, 10), 0, 1, -300, height + 300);

    int sx = constrain(int(x), 0, width - 1);
    int sy = constrain(int(y), 0, height - 1);

    color c = img.get(sx, sy);
    float b = brightness(c);
    float sat = saturation(c);

    if (b > 250) continue;

    float cx = width/2;
    float cy = height/2;

    float px = cx + (x - cx) * spread;
    float py = cy + (y - cy) * spread;

    float time = frameCount * 0.02;

    px += sin(time + i) * 60;
    py += cos(time * 0.8 + i) * 50;

    float z = map(255 - b, 0, 255, -200, 320);
    z += sin(time + i) * 140;

    float size = map(255 - b, 0, 255, 6, 90);
    size *= map(sat, 0, 255, 0.7, 1.6);
    size *= breathe;

    color col = palette[(scene * 2 + i) % palette.length];
    float a = alpha(col) * alphaMult;

    pushMatrix();
    translate(px, py, z);
    rotateX(time * 0.5 + i);
    rotateY(time * 0.3 + i);
    rotateZ(time * 0.2 + i);

    noStroke();
    fill(red(col), green(col), blue(col), a);

    if (i % 5 == 0) sphere(size * 0.35);
    else if (i % 5 == 1) box(size * 1.3, size * 0.18, size * 0.18);
    else if (i % 5 == 2) ellipse(0, 0, size * 1.4, size * 0.5);
    else if (i % 5 == 3) box(size * 0.2, size * 1.1, size * 0.2);
    else ellipse(0, 0, size, size);

    if (i % 4 == 0) {
      noFill();
      stroke(0, 70 * alphaMult);
      ellipse(0, 0, size * 1.8, size * 1.8);
    }

    popMatrix();
  }

  drawConnections(img, scene, alphaMult);
}

// ---------------- CONNECTIONS ----------------

void drawConnections(PImage img, int scene, float alphaMult) {

  int count = (scene == 2) ? 70 : 40;
  float time = frameCount * 0.02;

  for (int i = 0; i < count; i++) {

    float seed = scene * 2000 + i * 11.5;

    float x1 = map(noise(seed, 20), 0, 1, -200, width + 200);
    float y1 = map(noise(seed, 30), 0, 1, -200, height + 200);

    int sx = constrain(int(x1), 0, width - 1);
    int sy = constrain(int(y1), 0, height - 1);

    color c = img.get(sx, sy);
    float b = brightness(c);
    if (b > 240) continue;

    float z1 = map(255 - b, 0, 255, -100, 250);
    z1 += sin(time + i) * 100;

    float angle = noise(seed, 40) * TWO_PI + time;
    float len = 150 + noise(seed, 50) * 350;

    float x2 = x1 + cos(angle) * len;
    float y2 = y1 + sin(angle) * len;
    float z2 = z1 + sin(time * 2 + i) * 150;

    color cc = palette[(scene + i) % palette.length];

    stroke(red(cc), green(cc), blue(cc), 90 * alphaMult);
    strokeWeight(1);

    line(x1, y1, z1, x2, y2, z2);
  }
}

// ---------------- SMOOTH TRANSITION ----------------

float smoothstep(float a, float b, float x) {
  x = constrain((x - a) / (b - a), 0, 1);
  return x * x * (3 - 2 * x);
}
