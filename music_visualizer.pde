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
float rotation =0;
int sensibility = 2;



void setup() {
  //size(1920, 1080);
  fullScreen(P3D);
  anchorlist = new AnchorList();
  for(int i = 0; i < 25; i = i+1) 
    anchorlist.add_anchor(new Anchor(random(0,width),random(0,height)));
    
  minim = new Minim(this);
  player = minim.loadFile("music5.mp3", 1024);
  fft = new FFT( player.bufferSize(), player.sampleRate() );
  fft.linAverages( 30 );
  player.play();
  rotation = 0;
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
  


  float xpos= (width/2)+mouseX-(width/2);
  float ypos= height/2;
  float zpos=1250;
  camera(xpos, ypos, zpos, width/2, height/2,0, 0, 1, 0);
  rotateX(radians(180));
  rotation++;
  

  
}


void keyPressed() {
  
  if (key == CODED) {
    if (keyCode == UP) {
      sensibility++;
    }else if(keyCode == DOWN){
      sensibility--;
    }
  }
}

void mousePressed() {
  anchorlist.add_anchor(new Anchor(mouseX,mouseY));
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
  float size;
  float atract_r;
  float repulsion_r;
  ArrayList<Anchor> anchors_connected; 
  float maxspeed = 5;
  PVector velocity;
  PVector acceleration;
  float minSize = 7;
  float maxSize = 75;
  color anchor_c;
  int self_freq = (int)random(2,20);
  float depth;
  
  
  
  Anchor(float x, float y){
    position = new PVector(x, y);
    anchors_connected = new ArrayList<Anchor>();
    acceleration = new PVector(0, 0);
    velocity = new PVector(0, 0);
    size = 0;
    atract_r =0;
    repulsion_r = 0;
    depth = random(-500,500);
  }
  
  void run(ArrayList<Anchor> anchors){
    update_size();
    update_color();
    check_connected(anchors);
    PVector atraction_force = apply_atraction();
    applyForce(atraction_force);
    PVector repulsion_force = apply_repulsion();
    applyForce(repulsion_force);
    PVector borders_force = borders();
    applyForce(borders_force);
    update();
    render();
  }
  
  void render(){
    //stroke(255,59,148, 200);
    strokeWeight(3);
    stroke(255,59,map(size,minSize,maxSize,0,255));

    
    
    
    //translate(0,0,-100);
    for (Anchor a : anchors_connected) {
      line(a.position.x, a.position.y,a.depth, position.x, position.y, depth);

    }
    //translate(0,0,100);
    
    noStroke();
    /*for(int i = 0; i < 100; i = i+2){
      fill(anchor_c, 255-2*i);
      circle(position.x, position.y, size+i/4);
    }*/
    
    fill(anchor_c);
    //circle(position.x, position.y, size);
    pushMatrix();
      noStroke();
      translate(position.x, position.y, depth);
      sphere(size);
    popMatrix();
    
    //stroke(0);
    //noFill();
    //circle(position.x, position.y, atract_r*2);
    //circle(position.x, position.y, repulsion_r*2);
    
  }
  
  void check_connected(ArrayList<Anchor> anchors){
    float d;
    for (Anchor a : anchors) {
      d= dist(position.x, position.y, a.position.x, a.position.y);
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
    acceleration.add(force.div(2+(size/2)));
  }

  
  PVector apply_atraction(){
    int count = 0;
    PVector desired;
    PVector atraction_force = new PVector(0,0);
    float d =0;

    for (Anchor a : anchors_connected){
      d = PVector.dist(position, a.position);
      if(d>repulsion_r || d>a.repulsion_r){
        desired = PVector.sub(a.position, position); 
        desired.normalize();
        desired.mult(maxspeed);
        desired.div(d/1.5);
        atraction_force.add(desired);
        count++;
      }
    }
    
    if(count>0){
      //atraction_force.div(count);
    }else{
      return new PVector(0,0);
    }
     return atraction_force;
  }
  
   PVector apply_repulsion(){
    int count = 0;
    PVector desired;
    PVector repulsiton_force = new PVector(0,0);
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
      count++;
    }
    if(count>0){
      //repulsiton_force.div(count);
    }else{
      return new PVector(0,0);
    }
     return repulsiton_force;
    
   }
   
   void update_size(){
     float freqLevel = exp(fft.getAvg(self_freq)*sensibility);
     float oldSize=size;
     float newSize = (oldSize*9 + constrain(freqLevel, minSize, maxSize)) / 10;
     size = newSize;
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
    PVector desired = new PVector(0,0);
    PVector borders_force = new PVector(0,0);
    float d = 0.5;
    int r = 40;
    if (position.x < r){
      desired = PVector.sub(position, new PVector(0, position.y)); 
      d = PVector.dist(position, new PVector(0, position.y));
    }
    else if (position.x > width-r){
      desired = PVector.sub(position, new PVector(width, position.y)); 
      d = PVector.dist(position, new PVector(width, position.y));
    }
    desired.normalize();
    desired.mult(maxspeed*4);
    desired.div(d*2);
    borders_force.add(desired);
    if (position.y < r){ 
      desired = PVector.sub(position, new PVector(position.x, 0)); 
      d = PVector.dist(position, new PVector(position.x, 0));
    }
    else if (position.y > height-r){
      desired = PVector.sub(position, new PVector(position.x, height)); 
      d = PVector.dist(position, new PVector(position.x, height));
    }
    desired.normalize();
    desired.mult(maxspeed*2);
    desired.div(d/2);

    borders_force.add(desired);
    return borders_force;
  }
   

}
