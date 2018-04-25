/*
   Morse Code Sounder
   connects to Morse Code Key
   modified to use osc messages march 2017

   Alec Mulder, 2017
*/

#include <OscUDPwifi.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <OSCMessage.h>
#include <OSCData.h>

WiFiUDP wifiUDP;
unsigned int listeningPort = 9999; // listen at port 9999

OscUDPwifi oscUDPwifi;
NetAddress destination;

const char ssid[] = "X-Files";//wifi name
const char password[] = "paradigm";//wifi password

IPAddress destinationIP(255, 255, 255, 255);
int destinationPort = 12000;//

const int numReadings = 5;
float battArr[numReadings];
int readIndex = 0;
float total = 0;

float batteryLevel;
int lowestInput = 300;
int highestInput = 502;
//.618 == 4.2v  == 632/1023 - fully charged 4.13 -
//.462 == 3.14v == 473/1023  --- went as low as 291 - not linear

float persistence = 0.9;
float previous_output = 0;
float output;
float input;


//Define the sounder Pin
#define PIN_OUT        5
//Define unit length in ms
#define UNIT_LENGTH    250

unsigned long timer;
int ledState = LOW;
int letterIndex = 0;
long ms = 0;
String morseCode = "";

char* morseRecieved = "";
boolean timerOn = false;

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

  pinMode(PIN_OUT, OUTPUT);
  digitalWrite( PIN_OUT, LOW );
  Serial.begin(9600);

  Serial.println();
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

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

  //3.962v

  // if (millis() % 1000 == 0 && ms > 5) {
  sendOscStatus();
  // ms = 0;

  //}

  if (!morseCode.equals("")) {
    //morseCode.trim();
    char morseArray[morseCode.length()];
    morseCode.toCharArray(morseArray, morseCode.length());
    printMorse(morseArray);
    //Serial.println("Playing");
  }
  digitalWrite(PIN_OUT, ledState);
  yield();
  ms++;
  oscUDPwifi.listen();
  
  input = analogRead(A0) * (68 / 7.929) / 1000;
  output = input * (1 - persistence ) + previous_output * (persistence);
  previous_output = output;
}

///////////////////////OSC/////////////////////////////

// listen for All OSC messages here
void oscEvent(OscMessage & msg) {
  msg.plug("/sounder/updateWord", updateWord);
}

void updateWord(OscMessage & msg) {
  // set the word to incoming string
  msg.getString(0, morseRecieved, msg.getDataLength(0));
  letterIndex = 0;
  Serial.print("Recieved: ");
  Serial.println(morseRecieved);
  morseCode = encode(morseRecieved);
  Serial.println(morseCode);
  morseCode = cleanMorseCode(morseCode);
  Serial.println(morseCode);
  Serial.print("play: ");
  Serial.println(morseCode);
}

// send OSC Internet messages
void sendOscStatus() {
  batteryLevel = output;
  OscMessage msg("/sounder"); // this could be any pattern
  if (morseRecieved == "") {
    msg.add(false);
  } else {
    msg.add(true);
  }
  msg.add(batteryLevel);
  oscUDPwifi.send(msg, destination);
  Serial.println("Message Sent");
}

//////////////////////MORSE CODE//////////////////////

//tap or show the question to the user
void printMorse(const char* string) {
  Serial.print("morseCode: ");
  Serial.println(morseCode);
  Serial.print("Print: ");
  Serial.println(string[letterIndex]);
  if (letterIndex > morseCode.length()) {
    Serial.println("Reset");
    morseCode = "";
  }
  switch ( string[letterIndex] )
  {
    case '.': //dot
      Serial.println("DOT");

      if (!timerOn && millis() - timer >= UNIT_LENGTH) {
        timer = millis();
        ledState = HIGH;
        timerOn = true;
      }

      if (millis() - timer >= UNIT_LENGTH && timerOn) {
        ledState = LOW;
        timer = millis();
        timerOn = false;
        letterIndex++;
      }

      break;

    case '-': //dash
      Serial.println("DASH");

      if (!timerOn && millis() - timer >= UNIT_LENGTH) {
        timer = millis();
        ledState = HIGH;
        timerOn = true;
      }
      if (millis() - timer >= UNIT_LENGTH * 3 && timerOn) {
        ledState = LOW;
        timer = millis();
        letterIndex++;
        timerOn = false;
      }

      break;

    case ' ': //gap
      Serial.println("SPACE");
      ledState = LOW;
      if (!timerOn && millis() - timer >= UNIT_LENGTH) {
        timer = millis();
        timerOn = true;
      }
      if (millis() - timer >= UNIT_LENGTH && timerOn) {
        ledState = LOW;
        timer = millis();
        letterIndex++;
        timerOn = false;
      } else {
        ledState = LOW;
      }
      break;

    default:
      letterIndex++;
      break;
  }
}

//converts a char array to morse code
String encode(const char *string)
{
  Serial.print("Start encoding: ");
  Serial.println(string);
  size_t i, j;
  String morseWord = "";

  for ( i = 0; string[i]; ++i )
  {
    for ( j = 0; j < sizeof MorseMap / sizeof * MorseMap; ++j )
    {
      if ( toupper(string[i]) == MorseMap[j].letter )
      {
        morseWord += MorseMap[j].code;
        Serial.println(morseWord);
        break;
      }
    }
    morseWord += " "; //Add tailing space to seperate the chars
  }
  Serial.print("Done encoding: ");
  //Serial.println(morseWord.substring(sizeof string));
  Serial.println(morseWord);

  return morseWord;
}

String cleanMorseCode(String in) {
  String out;
  for (int i = 0; i < in.length(); i++) {
    if (in.charAt(i) == '.' || in.charAt(i) == '-' || in.charAt(i) == ' ') {
      out += in.charAt(i);
    }
  }
  return out;
}


