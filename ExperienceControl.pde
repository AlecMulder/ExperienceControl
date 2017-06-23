import java.io.FileNotFoundException;
import netP5.*;
import oscP5.*;

OscP5 oscNet;

Sounder morseSounder;
Key morseKey;
Lock lock;
Phonograph phonograph;

PFont f;
int listeningPort = 12000;

String question = "Test Question";
String answer = "abc";

void setup() {
  ellipseMode(CENTER);
  size(400, 400);
  //pixelDensity(2);
  imageMode(CENTER);

  oscNet = new OscP5(this, listeningPort);

  f = createFont("SegoeUI-Semibold-14.vlw", 14);
  textFont(f);
  textAlign(CENTER, CENTER);

  morseSounder = new Sounder(question);
  morseKey = new Key(answer);
  lock = new Lock();
  phonograph = new Phonograph();
  phonograph.loadCylinders();
}

void draw() {
  background(0);
  stroke(50);
  line(width/2, 0, width/2, height);
  line(0, height/2, width, height/2);
  morseSounder.draw(width*.75, height*.25);
  morseKey.draw(width*.25, height*.25);
  lock.draw(width*.25, height*.75);
  phonograph.draw(width*.75, height*.75);
}

void keyPressed() {
  if (key == 'l') {
    try {
      lock.lock();
    }
    catch(Exception e) {
      println(e);
    }
  }
  if (key == 'u') {
    try {
      lock.unlock();
    }
    catch(Exception e) {
      println(e);
    }
  }
  if (key == '-') {
    try {
      phonograph.setvolume(phonograph.getVolume()-1);
    }
    catch(Exception e) {
      println(e);
    }
  }
  if (key == '=') {
    try {
      phonograph.setvolume(phonograph.getVolume()+1);
    }
    catch(Exception e) {
      println(e);
    }
  }
  if (key == '1') {
    try {
      phonograph.playFile(1);
    }
    catch(Exception e) {
      println(e);
    }
  }
  if (key == '2') {
    try {
      phonograph.playFile(2);
    }
    catch(Exception e) {
      println(e);
    }
  }
  if (key == 's') {
    try {
      phonograph.stopPlaying();
    }
    catch(Exception e) {
      println(e);
    }
  }
}

void oscEvent(OscMessage incoming) {
  //println(incoming);
  if (incoming.checkAddrPattern(lock.getAddrPattern())==true) {
    lock.update(incoming);
  } else if (incoming.checkAddrPattern(morseSounder.getAddrPattern())==true) {
    morseSounder.update(incoming);
  } else if (incoming.checkAddrPattern(morseKey.getAddrPattern())==true) {
    morseKey.update(incoming);
  } else if (incoming.checkAddrPattern(phonograph.getAddrPattern())==true) {
    phonograph.update(incoming);
  }
}
