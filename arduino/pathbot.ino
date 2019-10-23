
#include <ESP8266WiFi.h>
#include<FirebaseArduino.h>
#include<math.h>
                          
#define FIREBASE_HOST "iotcar-88542.firebaseio.com"
//#define FIREBASE_AUTH "xxxxxxxxxx"

#define WIFI_SSID "Shail"                                           
#define WIFI_PASSWORD "KKISL8326"

float ROTATE_TIME = 5400;//Time taken by the bot to rotate the maxed allowed angle
float LINE_TIME = 10000; // Time taken by the bot the tavel the maxed allowed distance
float ROTATE_ANGLE = 6.28312; // The maxed allowed angle
float LINE_DISTANCE = 1; // The maxed allowed distance

// ============================  Pin diagram of NODEMCU ===========================
//static const int D0   = 16;
//static const int D1   = 5;
//static const int D2   = 4;
//static const int D3   = 0;
//static const int D4   = 2;
//static const int D5   = 14;
//static const int D6   = 12;
//static const int D7   = 13;
//static const int D8   = 15;
//static const int D9   = 3;
//static const int D10  = 1;

 int dataLength;

void setup() {
  pinMode(5,OUTPUT);//D1
  pinMode(4,OUTPUT);//D2
  pinMode(0,OUTPUT);//D3
  pinMode(2,OUTPUT);//D4
  
  Serial.begin(9600);
 
  getConnection();
  delay(1000);
}

void loop() {
  firebase();
  if(Firebase.getInt("/allow") == 1)getDate();
  Serial.println("One path traced..............");
  delay(5000);
}

void getDate()
{
  Serial.println("Starting the tracing a new path.....................");
  dataLength = Firebase.getInt("/length");
  double distances[dataLength];
  double angles[dataLength];
  for(int i = 0 ; i < dataLength ; i++)
  {
    distances[i] = Firebase.getFloat("/distances/" + String(i));
    angles[i] = Firebase.getFloat("/moveAngles/" + String(i));
  }
  for(int i = 0 ; i < dataLength ; i++)
  {
    moveLine(distances[i]);
    moveAngle(angles[i]);
  }
  Firebase.setInt("/allow", 0);
  moveStop();
 }

//======================================Custom methods=============================

void moveAngle(double angle){
  double moveTime = absolute((angle / ROTATE_ANGLE) * ROTATE_TIME); // This is the delay time in milliseconds
  angle < 0 ? moveRight() : moveLeft();
  Serial.println("Moving the angle of : " + String(angle));
  Serial.println("For a time of  : " + String(moveTime));
  delay(moveTime);
}

void moveLine(double distance){
  double moveTime = absolute((distance / LINE_DISTANCE) * LINE_TIME); // This is the delay time in milliseconds
  distance > 0 ? moveUp() : moveDown();
  Serial.println("Moving the distance of : " + String(distance));
  Serial.println("For a time of  : " + String(moveTime));
  delay(moveTime);
}


// ============================ Movement Methods Start ===============================
void moveStop(){
digitalWrite(5,LOW);
digitalWrite(4,LOW);
digitalWrite(0,LOW);
digitalWrite(2,LOW);
}

void moveUp(){
digitalWrite(5,LOW);
digitalWrite(4,HIGH);
digitalWrite(0,LOW);
digitalWrite(2,HIGH);
}

void moveRight(){
digitalWrite(5,LOW);
digitalWrite(4,HIGH);
digitalWrite(0,LOW);
digitalWrite(2,LOW);
}

void moveLeft(){
digitalWrite(5,LOW);
digitalWrite(4,LOW);
digitalWrite(0,LOW);
digitalWrite(2,HIGH);
}

void moveDown(){
digitalWrite(5,HIGH);
digitalWrite(4,LOW);
digitalWrite(0,HIGH);
digitalWrite(2,LOW);
}
// ========================== Movement Methods End ==================================

// ========================== Connection Methods Start ==============================

void firebase(){
  if (Firebase.failed()){ 
    delay(500);
    Firebase.begin(FIREBASE_HOST);
    Serial.println(Firebase.error());
    Serial.println("Connection to fiebase failed. Reconnecting...");
    delay(500);
  }
}

void getConnection(){
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Firebase.begin(FIREBASE_HOST);
}

// ========================== Connection Methods End ================================



void moveBot(){
  switch(Firebase.getInt("/option")){
      case 0 : moveStop();break;
      case 1 : moveUp();break;
      case 2 : moveLeft();break;
      case 3 : moveRight();break;
      case 4 : moveDown();break;
  }
}

// This is helper method to calculate the absolute value of the double number
double absolute(double input)
{
  return(input >= 0 ? input : -1 * input);
}
