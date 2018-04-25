#include <OscUDPwifi.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <OSCMessage.h>
#include <OSCData.h>

WiFiUDP wifiUDP;
unsigned int listeningPort = 9999;

OscUDPwifi oscUDPwifi;
NetAddress destination;

const char ssid[] = "X-Files";//wifi name
const char password[] = "paradigm";//wifi password

// The IP address of a computer you are trying to reach

IPAddress destinationIP(255, 255, 255, 255);
int destinationPort = 12000;

//0-locked --- 1-unlocked
int unlocked = 0;

int lockPin = 5;
long ms = 0;

const int numReadings = 5;
float battArr[numReadings];
int readIndex = 0;
float total = 0;

float batteryLevel;
int lowestInput = 290;
int highestInput = 500;
//.618 == 4.2v  == 632/1023
//.462 == 3.14v == 473/1023

float persistence = 0.9;
float previous_output = 0;
float output;
float input;

void setup() {
  Serial.begin(9600);
  pinMode(lockPin, OUTPUT);
  digitalWrite(lockPin, unlocked);
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

void loop()
{
    sendOscStatus();
   
  input = analogRead(A0) * (68 / 8.25) / 1000;
  output = input * (1 - persistence ) + previous_output * (persistence);
  previous_output = output;
  
  yield();
  oscUDPwifi.listen();
  ms++;
}

void oscEvent(OscMessage & msg) {
  Serial.println("msg Recieved");
  msg.plug("/lock", lockPlug);
}

void lockPlug(OscMessage & msg) {
  int data = msg.getInt(0);
  if (data == 0) lock();
  else if (data == 1) unlock();
}

void sendOscStatus() {
  batteryLevel = output;
  OscMessage msg("/lock");
  msg.add(unlocked);
  msg.add(batteryLevel);
  oscUDPwifi.send(msg, destination);
  Serial.print("Msg Sent at ");
  Serial.println(millis());
}

void lock() {
  if (unlocked == 1) {
    unlocked = 0;
    Serial.println("Locked");
  } else if (unlocked == 0) {
    Serial.println("Already Locked");
  } else {
    Serial.print("unexpected value: ");
    Serial.print(unlocked);
    unlocked = 1;
    Serial.println("Unlocked");
  }
  digitalWrite(lockPin, unlocked);
  sendOscStatus();
}

void unlock() {
  if (unlocked == 0) {
    unlocked = 1;

    Serial.println("Unlocked");
  } else if (unlocked == 1) {
    Serial.println("Already unlocked");
  } else {
    Serial.print("unexpected value: ");
    Serial.print(unlocked);
    unlocked = 1;
    digitalWrite(lockPin, unlocked);
    Serial.println("Unlocked");
  }
  digitalWrite(lockPin, unlocked);
  sendOscStatus();
}





