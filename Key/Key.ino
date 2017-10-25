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

const int keyPin = 14;//4
int keyState = 0;


const char ssid[] = "Cottage";//wifi name
const char password[] = "57575757";//wifi password

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

//temporary string to look for
//will be changed as soon as the client connects
char* goalWord = "something";

static const struct {
  const char letter, *code;
} MorseMap[] =
{
  { 'A', ".-" },
  { 'B', "-..." },
  { 'C', "-.-." },
  { 'D', "-.." },
  { 'E', "." },
  { 'F', "..-." },
  { 'G', "--." },
  { 'H', "...." },
  { 'I', ".." },
  { 'J', ".---" },
  { 'K', ".-.-" },
  { 'L', ".-.." },
  { 'M', "--" },
  { 'N', "-." },
  { 'O', "---" },
  { 'P', ".--." },
  { 'Q', "--.-" },
  { 'R', ".-." },
  { 'S', "..." },
  { 'T', "-" },
  { 'U', "..-" },
  { 'V', "...-" },
  { 'W', ".--" },
  { 'X', "-..-" },
  { 'Y', "-.--" },
  { 'Z', "--.." },
  { ' ', "     " }, //Gap between word, seven units

  { '1', ".----" },
  { '2', "..---" },
  { '3', "...--" },
  { '4', "....-" },
  { '5', "....." },
  { '6', "-...." },
  { '7', "--..." },
  { '8', "---.." },
  { '9', "----." },
  { '0', "-----" },

  { '.', "·–·–·–" },
  { ',', "--..--" },
  { '?', "..--.." },
  { '!', "-.-.--" },
  { ':', "---..." },
  { ';', "-.-.-." },
  { '(', "-.--." },
  { ')', "-.--.-" },
  { '"', ".-..-." },
  { '@', ".--.-." },
  { '&', ".-..." },
};


void setup() {
  Serial.begin(9600);
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
  pinMode(keyPin, INPUT);
  pinMode(5, OUTPUT);
  for (int i = 0; i < 4; i++) {
    pinMode(bulbPins[i], OUTPUT);
  }

  for (int thisReading = 0; thisReading < numReadings; thisReading++) {
    battArr[thisReading] = 0;
  }
}

void loop() {
  KeyDetect();
  if (ms > 40000) {
    Serial.println(analogRead(A0));
    Serial.println(batteryLevel);
    sendOscStatus();
    ms = 0;
  }
  yield();
  oscUDPwifi.listen();
  ms++;
  if (ms % 5000 == 0) {
    total = total - battArr[readIndex];
    battArr[readIndex] = analogRead(A0) * (68 / 8.2) / 1000;
    //battArr[readIndex] = map(analogRead(A0), lowestInput, highestInput, 0, 100);
    total = total + battArr[readIndex];
    readIndex++;
    if (readIndex >= numReadings) {
      readIndex = 0;
    }
  }
  for (int i = 0; i < 4; i++) {
    digitalWrite(bulbPins[i], bulbs[i]);
  }
}

void oscEvent(OscMessage & msg) {
  msg.plug("/sounder/updateWord", updateWord);
  msg.plug("/key/bulbs", updateBulbs);
  msg.plug("/key/incorrect", incorrect);
}

//blinks the specified bulb three times
void incorrect(OscMessage & msg) {
  int bulb = msg.getInt(0);

digitalWrite(bulbPins[bulb], HIGH); //turn the bulb on
delay(500);
digitalWrite(bulbPins[bulb], LOW);  //turn the bulb off
delay(250);
digitalWrite(bulbPins[bulb], HIGH); //turn the bulb on
delay(500);
digitalWrite(bulbPins[bulb], LOW);  //turn the bulb off
delay(250);
digitalWrite(bulbPins[bulb], HIGH); //turn the bulb on
delay(500);
digitalWrite(bulbPins[bulb], LOW);  //turn the bulb off
}

void updateWord(OscMessage & msg) {
  // set the word to incoming string
  msg.getString(0, goalWord, msg.getDataLength(0));
}

void updateBulbs(OscMessage & msg) {
  for (int i = 0; i < 4; i++) {
    bulbs[i] = msg.getInt(i);
  }
}

void sendOscStatus() {
  batteryLevel = total / numReadings;
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
          rawInput += ".";
        }
      } else {
        Serial.println("DASH");
        OscMessage msg("/key");
        msg.add("-");
        oscUDPwifi.send(msg, destination);
        rawInput += "-";
      }
      digitalWrite(5, LOW);
      buttonWasPressed = false;
      lastTimestamp = currentTimestamp;
    }
    if (duration > letterGap && duration < wordGap) {
      rawInput += " ";
      wordInput = Decode(rawInput);
      rawInput = "";
    } else if (duration > wordGap && !wordInput.equals("null")) {
      wordFinished = true;
      OscMessage msg("/key");
      msg.add(wordInput);
      oscUDPwifi.send(msg, destination);
      //wordInput="";
    }
  }
}

//converts morse code into letters
String Decode(String morse)
{
  String msg = "";

  int lastPos = 0;
  int pos = morse.indexOf(' ');
  while ( lastPos <= morse.lastIndexOf(' ') )
  {
    for ( int i = 0; i < sizeof MorseMap / sizeof * MorseMap; ++i )
    {
      if ( morse.substring(lastPos, pos) == MorseMap[i].code )
      {
        msg += MorseMap[i].letter;
      }
    }

    lastPos = pos + 1;
    pos = morse.indexOf(' ', lastPos);

    while ( morse[lastPos] == ' ' && morse[pos + 1] == ' ' )
    {
      pos ++;
    }
  }
  //Serial.println(msg);
  return msg;
}
