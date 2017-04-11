import processing.video.*;

PShader sampleShader;

Capture cam;
PFont f;
PImage theImage;
PImage randImage;
boolean imageSet;
boolean imageSet2;

int frameRateLimiter = 2;

boolean desaturate = true;
color saturationColor = color(172,255,186);

boolean displayCam = false;

int updateCounter = 0;
int updateRate = 5;

boolean mirrorImage = false;

int noiseTimer = 0;
int noiseTimerModulo = 200;
int noiseFrameLimiter = 1;

float brightness2(color c) {
   return (red(c) + blue(c) + green(c))/3.0f; 
}

void drawCam() {
   noiseTimer = (noiseTimer + 1) % noiseTimerModulo; 
   background(0);
   // the overlay effect isn't great. Keep the offset at 0,0 as initialized
   //sampleShader.set("overlayOffset", (sin((float)noiseTimer/noiseTimerModulo)),  (sin((float)noiseTimer/noiseTimerModulo)));
   sampleShader.set("time", ((float)(noiseTimer/noiseFrameLimiter)/5000.0f));
   sampleShader.set("tint", red(saturationColor)/255.0, green(saturationColor)/255.0, blue(saturationColor)/255.0, 1.0);
   shader(sampleShader);
   beginShape();
   texture(theImage);
   if(!mirrorImage) {
    vertex(0, 0, 0, 0, 0);
    vertex(cam.width, 0, 0, theImage.width, 0);
    vertex(cam.width, cam.height, 0, theImage.width, theImage.height);
    vertex(0, cam.height, 0, 0, theImage.height);
   }
   else {
    vertex(0, 0, 0, theImage.width, 0);
    vertex(cam.width, 0, 0, 0, 0);
    vertex(cam.width, cam.height, 0, 0, theImage.height);
    vertex(0, cam.height, 0, theImage.width, theImage.height);
   }
   endShape();
}


void setup() {
  String[] cameras = Capture.list();
  int preferred_camera_index = 0;
  int preferred_cam_height = 0;
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
      if(cameras[i].toLowerCase().contains("640x") && cameras[i].toLowerCase().contains("fps=30")) {
          preferred_camera_index = i;
          break;
      }
    }
    println("Preferred camera " + preferred_camera_index + " : " + cameras[preferred_camera_index]);
    
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[preferred_camera_index]);
    String cam_str = cameras[preferred_camera_index];
    // extract dimensions
    String size_str = new String("size=");
    String fps_str = new String(",fps=");
    int size_index = cam_str.indexOf(size_str);
    int fps_index = cam_str.indexOf(fps_str);
    String size_substr = cam_str.substring(size_index + size_str.length(), fps_index);
    int wide = Integer.parseInt(size_substr.substring(0, size_substr.indexOf("x")));
    int tall = Integer.parseInt(size_substr.substring(size_substr.indexOf("x") + 1, size_substr.length()) );
    size(wide, tall, P3D);
    preferred_cam_height = tall;
    cam.start();     
  }
  imageSet = false;
  imageSet2 = false;
 
  sampleShader = loadShader("fragmentShader.glsl", "vertexShader.glsl");
  sampleShader.set("imgHeight", preferred_cam_height/2);
  sampleShader.set("overlayOffset", 0, 0);
}

void draw() {
  imageSet = false;
  int posterWidth = 0;
  int posterHeight = 0;
  if(millis() > updateCounter) {
      updateCounter = millis() + updateRate + (floor(random(0, updateRate)));
  }
  else {
     return; 
  }
  
  // sampling directly from the camera in GLSL seems to be unstable. Working with a texture copied to a buffer after
  // the cam indicates is ready works much better.
  if (cam.available() == true && imageSet == false) {
    frameRateLimiter = (frameRateLimiter + 1) % 5;
    if(frameRateLimiter != 0) {
      return;
    } 
    cam.read();
    imageSet = true;
    if(!imageSet2) {
      imageSet2 = true;
      theImage = createImage(cam.width/2, cam.height/2, RGB);
    }
    theImage.copy(cam, 0, 0, cam.width, cam.height, 0, 0, cam.width/2, cam.height/2);
    
  }
  else {
    background(0);
  }
  
  if(imageSet2 == true) {
     randomSeed(noiseTimer);
     drawCam();
  }
  else {
     background(0);
  }
}

void keyPressed() {
   if(key == 'q' || key == 'Q') {
       exit();
   }
   if(key == 'f') {
      mirrorImage = !mirrorImage; 
   }
}
