// By: Rutger de Graaf
// 06-10-2018

#include "Keyboard.h"

// buttons[i][0] = minTrigger,
// buttons[i][1] = maxTrigger,
// buttons[i][2] = funcType(1=pinOut or 2=Usb),
// buttons[i][3] = funcValue(pinout or ascii),
const int buttons[][8] = {
  {290, 335, 2, 110}, //seek up - next - n 
  {225, 270, 2, 118}, //seek down - prev - v 
  {150, 195, 2, 49}, //scan up - scroll left - 1
  {60, 110, 2, 50}, //scan down - scroll right - 2 
  {530, 610, 2, 93},  //vol_u - vol up - ]  
  {475, 518, 2, 91},   //vol_d - vol down - [
  {422, 460, 2, 109},  //src - voice - m   
  {355, 412, 2, 98},   //mute - play/pause - b   
};
const int analogInPin = A5;  // Analog input pin that the stepped resistor circuit is attached to
const int referenceInPin = A4;  // Analog input pin that the stepped resistor circuit is attached to

// bootPi constants:
const int  buttonPin = A2;    // the pin that the pushbutton is attached to
const int switchPin = A3;

// bootPi variables:
int buttonState = 0;         // current state of the button
int lastButtonState = 0;     // previous state of the button

int x = 0;                //value read from the pot
int i;                    //button loop-counter
int c = 0;                //button streak-counter
boolean found = false;    //global counter-stop
int v = 5;                //verify necessary detection length in loops to press button
int vr = 5;               //verify necessary detection length in loops to release button
int d = 20;               //check-loop duration in ms

int d2 = 20;              //button-hold-loop duration in ms
int pressed = false;      //loop break condition for holding the button

void setup() {
  //initialize serial communications at 9600 bps
  Serial.begin(9600);
  //set pinout types
  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(switchPin, OUTPUT);
  int j;
  for(j = 0; j <= 7; j = j + 1) {
    //if button type is pinOut
    if(buttons[j][2] == 1) {
      //enable that pin as output
      pinMode(buttons[j][3], OUTPUT);
    }
  }
  Keyboard.begin();
}

void loop() {
  //read the analog in value and print to serial
  x = analogRead(referenceInPin)/analogRead(analogInPin);
  Serial.println(x);
  
  // BootPi - read the pushbutton input pin:
  buttonState = digitalRead(buttonPin);

  // BootPi - compare the buttonState to its previous state
  if (buttonState != lastButtonState){
    if (buttonState == LOW){
      digitalWrite(switchPin, HIGH);
      delay(2000);
      digitalWrite(switchPin, LOW);
    }
    
    delay(50);
  }

  // BootPi - save the current state as the last state, for next time through the loop
  lastButtonState = buttonState;
  
  //loop through all possible buttons
  for(i = 0; i <= 7; i = i + 1) {
    //if this button is not detected: skip to next iteration
    if(x <= buttons[i][0] || x >= buttons[i][1]) {
      continue;
    }
    //button is detected
    Serial.print("button detected for value ");
    Serial.print(x);
    c = c + 1;
    Serial.print(", c = ");
    Serial.println(c);
    //if button is not detected enough times: break
    if(c < v) {
      break;
    }
    //send button press event
    buttonPress(i);
    c = 0;
    break;
  }
  
  //delay next read
  delay(d);
}

void buttonPress(int i){
  Serial.print("going to send press for button int ");
  Serial.println(i);
  if(buttons[i][2] == 1) {
    Serial.println("sending gpio");
    //buttonGpio(i);
  }
  if(buttons[i][2] == 2) {
    Serial.println("sending usb");
    //buttonUsb(i);
  }
}

void buttonGpio(int i) {
  int pinOut = buttons[i][3];
  c = 0;
  Serial.print("pressed gpio button ");
  Serial.println(pinOut);
  digitalWrite(pinOut, HIGH);
  pressed = true;
  while(pressed) {
    x = analogRead(analogInPin);
    if(x <= buttons[i][0] || x >= buttons[i][1]) {
      Serial.print("Outvalue detected: ");
      Serial.println(x);
      c = c + 1;
    } else {
      c = 0;
    }
    if(c >= vr) {
      pressed = false;
    }
    delay(d2);
  }
  digitalWrite(pinOut, LOW);
  Serial.print("released gpio button ");
  Serial.println(pinOut);
}

void buttonUsb(int i) {
  Keyboard.begin();
  int ascii = buttons[i][3];
  c = 0;
  Serial.print("pressed usb button ");
  Serial.println(ascii);
  Keyboard.press(ascii);
  pressed = true;
  while(pressed) {
    x = analogRead(analogInPin);
    if(x <= buttons[i][0] || x >= buttons[i][1]) {
      Serial.print("Outvalue detected: ");
      Serial.println(x);
      c = c + 1;
    } else {
      c = 0;
    }
    if(c >= vr) {
      pressed = false;
    }
    delay(d2);
  }
  Keyboard.release(ascii);
  Serial.print("released usb button ");
  Serial.println(ascii);
}
