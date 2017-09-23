#include <OscUDPwifi.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <OSCMessage.h>
#include <OSCData.h>
#include <SoftwareSerial.h>
#include "DFRobotDFPlayerMini.h"

SoftwareSerial mp3(13, 12); // TX, RX - on the mp3
SoftwareSerial rfid(4, 3); //RX,TX
DFRobotDFPlayerMini myDFPlayer;

WiFiUDP wifiUDP;
unsigned int listeningPort = 9999;

OscUDPwifi oscUDPwifi;
NetAddress destination;

const char ssid[] = "Cottage";//wifi name
const char password[] = "57575757";//wifi password

// The IP address of a computer you are trying to reach

IPAddress destinationIP(255, 255, 255, 255);
int destinationPort = 12000;

long ms;
String loaded = "";
int volume = 15;
String addrPattern = "/Phonograph";
int playing = 0;

const int numReadings = 5;
float battArr[numReadings];
int readIndex = 0;
float total = 0;

float batteryLevel;
int lowestInput = 370;
int highestInput = 520;
//.618 == 4.2v  == 632/1023 - actually ~520
//.462 == 3.14v == 473/1023 - actually ~ 370

//593 = 5v
//300 = 2.9v = dead
//512 = 4v

const int tagLen = 16;
const int idLen = 13;
char newTag[idLen];

void setup() {
  Serial.begin (9600);
  mp3.begin (9600);
  rfid.begin(9600);
  if (!myDFPlayer.begin(mp3)) {  //Use softwareSerial to communicate with mp3.
    Serial.println(F("Unable to begin:"));
    Serial.println(F("1.Please recheck the connection"));
    Serial.println(F("2.Please insert the SD card"));
    Serial.println(F("3.Restart the device"));
    while (true)yield();
  }
  delay(1);  //wait 1ms for mp3 module to set volume
  myDFPlayer.volume(volume);

  WiFi.begin(ssid, password);
  // wait for wifi to connect
  Serial.print("Connecting to ");
  Serial.println(ssid);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  // startUDP
  wifiUDP.begin(listeningPort);
  oscUDPwifi.begin(wifiUDP);
  destination.set(destinationIP, destinationPort);

  pinMode(0, INPUT);

  for (int thisReading = 0; thisReading < numReadings; thisReading++) {
    battArr[thisReading] = 0;
  }
}

void loop() {
  // put your main code here, to run repeatedly:
  if (ms > 40000) {
    Serial.println(batteryLevel);
    sendOscStatus();
    ms = 0;
  }
  yield();
  oscUDPwifi.listen();
  ms++;
  if (ms % 5000 == 0) {
    total = total - battArr[readIndex];
    battArr[readIndex] = analogRead(A0) * (68 / 8.67) / 1000;
    //battArr[readIndex] = map(analogRead(A0), lowestInput, highestInput, 0, 100);
    total = total + battArr[readIndex];
    readIndex++;
    if (readIndex >= numReadings) {
      readIndex = 0;
    }
  }

  //////////////////////////////////RFID///////////////////////////////////

  if (rfid.available() == 16) {
    char tag[16];
    rfid.readBytes(tag,16); 
    OscMessage msg("/Phonograph");
    msg.add(tag);
    oscUDPwifi.send(msg, destination);
    Serial.print(tag);
    Serial.println(" - rfid message sent");
  }
  
}

void sendOscStatus() {
  batteryLevel = total / numReadings;
  playing = digitalRead(0);

  OscMessage msg("/Phonograph");
  msg.add(playing);
  msg.add(volume);
  msg.add(batteryLevel);
  msg.add(myDFPlayer.readCurrentFileNumber());

  //msg.add(loaded);

  oscUDPwifi.send(msg, destination);
  Serial.print("msg sent    ");
  Serial.println(playing);
}

void oscEvent(OscMessage & msg) {
  Serial.println("Recieved a message!");
  msg.plug("/Phonograph/play", startPlaying);
  msg.plug("/Phonograph/stop", stopPlaying);
  msg.plug("/Phonograph/volume", volumeControl);
}

void startPlaying(OscMessage & msg) {
  int file = msg.getInt(0);
  myDFPlayer.play(file);
  sendOscStatus();
}

void stopPlaying(OscMessage & msg) {
  myDFPlayer.stop();
  sendOscStatus();
}

void volumeControl(OscMessage & msg) {
  volume = msg.getInt(0);
  Serial.print("Volume set to: ");
  Serial.println(volume);
  myDFPlayer.volume(volume);
  sendOscStatus();
}

