import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

Minim minim;
AudioPlayer player;
FFT fft;
AnchorList anchorlist;
float rotation = 0;
int sensibility = 3;
boolean anchor_flag = false;

void setup() {
  //size(1920, 1080);
  fullScreen(P3D);
  anchorlist = new AnchorList();
  
  for(int i = 0; i < 75; i = i+1) 
    anchorlist.add_anchor(new Anchor(random(0,width),random(0,height), random(-600,600)));
    
  minim = new Minim(this);
  player = minim.loadFile("music_examples/music6.mp3", 1024);
  fft = new FFT( player.bufferSize(), player.sampleRate() );
  fft.linAverages( 30 );
  player.play();
}

void draw() {
  fft.forward( player.mix );
  background(55,1,58);
  lights();
  anchorlist.run();

  /*stroke(255, 0, 0);
  line(0, 0, 0, 1000, 0, 0);
  stroke(0, 255, 0);
  line(0, 0, 0, 0, 1000, 0);
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, 1000);*/
  


  float ypos= height/2;
  float xpos= cos(radians(rotation))*width+(width/2);
  float zpos= sin(radians(rotation))*width;

  camera(xpos, ypos, zpos, width/2, height/2,0, 0, 1, 0);
  rotation=rotation+0.25;
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      sensibility++;
    }else if(keyCode == DOWN){
      sensibility--;
    }
  }
  if(key == 'p' || key == 'P'){
    if(anchor_flag){
      anchor_flag = false;
    }else{
      anchor_flag = true;
    }
  }
}

void mousePressed() {
  anchorlist.add_anchor(new Anchor(random(0,width),random(0,height), random(-600,600)));
}

class AnchorList {
  ArrayList<Anchor> anchors; 

  AnchorList() {
    anchors = new ArrayList<Anchor>();
  }
  
  void run(){
    for (Anchor a : anchors) {
      a.run(anchors);  
    }
  }

  void add_anchor(Anchor a) {
    anchors.add(a);
  }

}

class Anchor{
  PVector position;
  PVector velocity;
  PVector acceleration;
  ArrayList<Anchor> anchors_connected; 
  color anchor_c;
  float size = 0;
  float atract_r = 0;
  float repulsion_r = 0;
  float maxspeed = 5;
  float minSize = 7;
  float maxSize = 80;
  int self_freq = 0;
  float depth;
  
  Anchor(float x, float y, float z){
    position = new PVector(x, y, z);
    anchors_connected = new ArrayList<Anchor>();
    acceleration = new PVector(0, 0, 0);
    velocity = new PVector(0, 0, 0);
    size = 0;
    atract_r = 0;
    repulsion_r = 0;
    self_freq  = (int)random(2,20);
  }
  
  void run(ArrayList<Anchor> anchors){
    update_size();
    check_connected(anchors);
    applyForce(apply_atraction());
    applyForce(apply_repulsion());
    applyForce(borders());
    update();
    render();
  }
  
  void render(){
    //original color for the lines 255,59,148
    
    strokeWeight(map(maxspeed,2,10,1,3));
    //stroke(255,59,map(size,minSize,maxSize,0,255));

    pushMatrix();
    for (Anchor a : anchors_connected) {
      stroke(255,59,map(dist(position.x, position.y, position.z, a.position.x, a.position.y, a.position.z), minSize*5, maxSize*5, 0, 255));
      line(a.position.x, a.position.y, a.position.z, position.x, position.y, position.z);
    }
    popMatrix();
    if(anchor_flag){
      noStroke();    
      update_color();
      fill(anchor_c);
      pushMatrix();
        noStroke();
        translate(position.x, position.y, position.z);
        sphere(size);
      popMatrix();
    }
  }
  
  void check_connected(ArrayList<Anchor> anchors){
    float d;
    for (Anchor a : anchors) {
      d= dist(position.x, position.y, position.z, a.position.x, a.position.y, a.position.z);
      if(d < atract_r || d < a.atract_r){
        if(a!=this && !anchors_connected.contains(a)){
          anchors_connected.add(a);
          a.anchors_connected.add(this);
        }
      }
      else if(anchors_connected.contains(a)){
        anchors_connected.remove(a);
        a.anchors_connected.remove(this);
      }
    }
  }
  
  void update() {
    velocity.add(acceleration);
    velocity.limit(maxspeed);
    position.add(velocity);
    acceleration.mult(0);
    if(anchors_connected.size()==0){
      velocity.mult(0.99);
    }
  }
  
  void applyForce(PVector force) {
    acceleration.add(force.div((size/2)));
  }

  PVector apply_atraction(){
    PVector desired;
    PVector atraction_force = new PVector(0,0,0);
    float d = 0;

    for (Anchor a : anchors_connected){
      d = PVector.dist(position, a.position);
      if(d>repulsion_r || d>a.repulsion_r){
        desired = PVector.sub(a.position, position); 
        desired.normalize();
        desired.mult(maxspeed);
        desired.div(d/1.5);
        atraction_force.add(desired);
      }
    }
     return atraction_force;
  }
  
   PVector apply_repulsion(){
    PVector desired;
    PVector repulsiton_force = new PVector(0,0,0);
    float d = 0;
    for (Anchor a : anchors_connected){
      d = PVector.dist(position, a.position);
      if(d<repulsion_r || d<a.repulsion_r){
        desired = PVector.sub(position, a.position); 
        desired.normalize();
        desired.mult(maxspeed*1.75);
        desired.div(d/2);
        repulsiton_force.add(desired);
      }
    }
     return repulsiton_force;
    
   }
   
   void update_size(){
     float freqLevel = exp(fft.getAvg(self_freq)*sensibility);
     float oldSize=size;
     size = (oldSize*9 + constrain(freqLevel, minSize, maxSize)) / 10;

     float leftLevel = norm(player.mix.level()*100, 0, 10);
     leftLevel = constrain(leftLevel, 1, 5);
     atract_r = size * 5;
     repulsion_r = size * leftLevel;
     maxspeed = leftLevel*2;
   }
   
   void update_color(){
     float c1 = (int)map(position.x, 0, width, 1,254);
     float c2 = (int)map(position.y, 0, height, 0,30);
     anchor_c = color(c1, c2, 250);
   }
   
  PVector borders() {
    PVector desired = new PVector(0,0,0);
    PVector borders_force = new PVector(0,0,0);
    float d = 0.5;
    int r = 40;
    
    
    if (position.x < r){
      desired = PVector.sub(position, new PVector(0, position.y,position.z)); 
      d = PVector.dist(position, new PVector(0, position.y,position.z));
    }
    else if (position.x > width-r){
      desired = PVector.sub(position, new PVector(width, position.y,position.z)); 
      d = PVector.dist(position, new PVector(width, position.y,position.z));
    }
    desired.normalize();
    desired.mult(maxspeed*4);
    desired.div(d*2);
    borders_force.add(desired);
    
    if (position.y < r){ 
      desired = PVector.sub(position, new PVector(position.x, 0,position.z)); 
      d = PVector.dist(position, new PVector(position.x, 0,position.z));
    }
    else if (position.y > height-r){
      desired = PVector.sub(position, new PVector(position.x, height, position.z)); 
      d = PVector.dist(position, new PVector(position.x, height, position.z));
    }
    desired.normalize();
    desired.mult(maxspeed*4);
    desired.div(d/2);
    borders_force.add(desired);
    
    int maxZ = 600;
    int minZ = -600;
    
    if (position.z <= minZ+r){ 
      desired = PVector.sub(position, new PVector(position.x, position.y, minZ)); 
      d = PVector.dist(position, new PVector(position.x, position.y, minZ));
    }
    else if (position.z >= maxZ-r){
      desired = PVector.sub(position, new PVector(position.x, position.y, maxZ)); 
      d = PVector.dist(position, new PVector(position.x, position.y, maxZ));
    }
    desired.normalize();
    desired.mult(maxspeed*4);
    desired.div(d/2);
    borders_force.add(desired);
    
    return borders_force;
  }
   

}
