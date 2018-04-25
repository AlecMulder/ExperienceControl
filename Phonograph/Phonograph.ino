#include <OscUDPwifi.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <OSCMessage.h>
#include <OSCData.h>
#include <SoftwareSerial.h>
#include "DFRobotDFPlayerMini.h"

SoftwareSerial mySerial(13, 12); // TX, RX - on the mp3
DFRobotDFPlayerMini myDFPlayer;

WiFiUDP wifiUDP;
unsigned int listeningPort = 9999;

OscUDPwifi oscUDPwifi;
NetAddress destination;

const char ssid[] = "X-Files";//wifi name
const char password[] = "paradigm";//wifi password

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

float persistence = 0.9;
float previous_output = 0;
float output;
float input;

//.618 == 4.2v  == 632/1023 - actually ~520
//.462 == 3.14v == 473/1023 - actually ~ 370

//593 = 5v
//300 = 2.9v = dead
//512 = 4v

void setup() {
  Serial.begin (9600);
  mySerial.begin (9600);
  if (!myDFPlayer.begin(mySerial)) {  //Use softwareSerial to communicate with mp3.
    Serial.println(F("Unable to begin:"));
    Serial.println(F("1.Please recheck the connection"));
    Serial.println(F("2.Please insert the SD card"));
    Serial.println(F("3.Restart the device"));
    while (true)yield();
  }
  delay(1);  //wait 1ms for mp3 module to set volume
  myDFPlayer.volume(volume);
  WiFi.mode(WIFI_STA);
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

  sendOscStatus();
  yield();
  oscUDPwifi.listen();
  ms++;

  input = analogRead(A0) * (68 / 8.67) / 1000;
  output = input * (1 - persistence ) + previous_output * (persistence);
  previous_output = output;
}

void sendOscStatus() {
  batteryLevel = output;
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

