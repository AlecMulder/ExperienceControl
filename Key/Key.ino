/*
   Morse Code Key
   WiFi AP for Morse Code Sounder to connect to

   Alec Mulder, 2017
*/

#include <OscUDPwifi.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <OSCMessage.h>
#include <OSCData.h>

WiFiUDP wifiUDP;
unsigned int listeningPort = 9999;

OscUDPwifi oscUDPwifi;
NetAddress destination;

const int keyPin = 4;//4
int keyState = 0;


const char ssid[] = "X-Files";//wifi name
const char password[] = "paradigm";//wifi password

IPAddress destinationIP(255, 255, 255, 255);
int destinationPort = 12000;

//standard morse code timings
int dotDuration = 250;
int dashDuration = dotDuration * 3;
int signalGap = dotDuration;
int letterGap = dotDuration * 3;
int wordGap = dotDuration * 7;

long currentTimestamp;
long lastTimestamp = 0;
boolean buttonWasPressed = false;

//four LED/bulbs
int bulbPins[] = {0, 4, 13, 12};
int bulbs[] = {0, 0, 0, 0};

boolean sent = false;

String rawInput = "";
String wordInput = "null";
boolean wordFinished = false;
long ms = 0;

const int numReadings = 5;
float battArr[numReadings];
int readIndex = 0;
float total = 0;

float batteryLevel;
int lowestInput = 290;
int highestInput = 502;
//.618 == 4.2v  == 632/1023
//.462 == 3.14v == 473/1023

float persistence = 0.9;
float previous_output = 0;
float output;
float input;

void setup() {
  pinMode(keyPin, INPUT);
  pinMode(5, OUTPUT);
  for (int i = 0; i < 4; i++) {
    pinMode(bulbPins[i], OUTPUT);
  }

  Serial.begin(9600);
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


  for (int thisReading = 0; thisReading < numReadings; thisReading++) {
    battArr[thisReading] = 0;
  }
}

void loop() {
  KeyDetect();

  sendOscStatus();
  yield();
  oscUDPwifi.listen();

  input = analogRead(A0) * (68 / 8.2) / 1000;
  output = input * (1 - persistence ) + previous_output * (persistence);
  previous_output = output;

  for (int i = 0; i < 4; i++) {
    digitalWrite(bulbPins[i], bulbs[i]);
  }
}

void oscEvent(OscMessage & msg) {
  msg.plug("/key/bulbs", updateBulbs);
  msg.plug("/key/incorrect", incorrect);
}

//blinks the specified bulb three times
void incorrect(OscMessage & msg) {
  int bulb = msg.getInt(0);

  digitalWrite(bulbPins[bulb], HIGH); //turn the bulb on
  delay(500);
  digitalWrite(bulbPins[bulb], LOW);  //turn the bulb off
}


void updateBulbs(OscMessage & msg) {
  for (int i = 0; i < 4; i++) {
    bulbs[i] = msg.getInt(i);
  }
}

void sendOscStatus() {
  batteryLevel = output;
  char ca[wordInput.length()];
  wordInput.toCharArray(ca, wordInput.length() + 1);
  OscMessage msg("/key");
  msg.add(batteryLevel);
  oscUDPwifi.send(msg, destination);
}

//convert button presses into morse code
void KeyDetect() {

  currentTimestamp = millis();
  long duration = currentTimestamp - lastTimestamp;
  String msg = "";

  if (digitalRead(keyPin) == HIGH) {
    if (!buttonWasPressed) {
      //Serial.println("Pressed");
      buttonWasPressed = true;
      digitalWrite(5, HIGH);
      lastTimestamp = currentTimestamp;
      if (duration > wordGap) {
        rawInput = "";
      }
    }
  } else {
    if (buttonWasPressed) {
      if (duration < dotDuration) {
        if (duration > 20) {
          Serial.println("DOT");
          OscMessage msg("/key");
          msg.add(".");
          oscUDPwifi.send(msg, destination);
        }
      } else {
        Serial.println("DASH");
        OscMessage msg("/key");
        msg.add("-");
        oscUDPwifi.send(msg, destination);
      }
      digitalWrite(5, LOW);
      buttonWasPressed = false;
      lastTimestamp = currentTimestamp;
    }
  }
}

