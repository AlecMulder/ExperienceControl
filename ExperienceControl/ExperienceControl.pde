import java.io.FileNotFoundException;
import java.util.NoSuchElementException;
import javax.swing.*;
import netP5.*;
import oscP5.*;

OscP5 oscNet;

MorseCode morse;
Sounder morseSounder;
Key morseKey;
Lock lock;
Phonograph phonograph;

PFont f;
int listeningPort = 12000;

String question = "sos";
String answer = "--...--.-.";

void setup() {
  //fullScreen();
  //noCursor();
  size(400, 400);
  background(0);

  smooth(8);
  pixelDensity(displayDensity());
  imageMode(CENTER);
  ellipseMode(CENTER);
  rectMode(CENTER);
  f = createFont("SegoeUI-Semibold-14.vlw", 14);
  textFont(f);
  textAlign(CENTER, CENTER);

  oscNet = new OscP5(this, listeningPort);
  morse = new MorseCode();
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
  fill(0);
  noStroke();
  rect(width/2, height*.05, width, height*.1);
  fill(255);
  text(formatTime(), width/2, height*.05);

  morseSounder.draw(width*.75, height*.25);
  morseKey.draw(width*.25, height*.25);
  lock.draw(width*.25, height*.75);
  phonograph.draw(width*.75, height*.75);
}
void mouseReleased() {
  loop();
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
      phonograph.setVolume(phonograph.getVolume()-1);
    }
    catch(Exception e) {
      println(e);
    }
  }
  if (key == '=') {
    try {
      phonograph.setVolume(phonograph.getVolume()+1);
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

/**
 Formats the current time
 @return formatted time
 */
String formatTime () {
  String t;
  if (hour() >12)
    t = hour()-12+":";
  else if (hour()==0)
    t = "12:";
  else 
  t = hour()+":"; 

  if (minute()<10)
    t+="0"+minute()+":";
  else
    t+=minute()+":";

  if (second()<10)
    t+="0"+second();
  else
    t+=second();

  return t;
}