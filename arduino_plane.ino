#include <Servo.h> 
Servo servo;


int readIntFromSerial()
{
  union u_tag
  {
    char bytes[2];
    int val;
  } u;

  u.bytes[0] = Serial.read();
  u.bytes[1] = Serial.read();	
  return u.val;
}


byte switch_stat;
int trim;

byte input_values[2];
byte values[5];
int num_vals;

// Here we get bytes
int getBytes(byte byteArray[], int len)
{
  int checksum = 0;
  int checksum_in_data = 0;
  int return_val = -1;
  int timeout = 0;
  
  //Serial.println(Serial.available());
  while (Serial.available() < len + 3)
  {
    //wait, consider adding a break out trigger here
    //Serial.println("Waiting for required length of buffer...");
    timeout++;
    if (timeout == 100) return return_val;
  }
  timeout = 0;
  //Serial.println(Serial.available());
  while ((byte)Serial.read() != 0xff)
  {
    // chew through the bytes that arent the sync
    //Serial.println("Chewing for sync byte");
    timeout++;
    if (timeout == 100) return return_val;
  }
  //Serial.println("got sync byte..");
  
 // here we got a sync, so read the rest
       for (int i = 0; i < len; i++)
       {
         int val = Serial.read();
         //Serial.print("READ: ");
         //Serial.println(val);
         byteArray[i] = (byte)val;
         checksum+=val;
       }
       
       checksum_in_data = readIntFromSerial();
       
       if (checksum_in_data == checksum)
       {
         return_val = 0;
         //Serial.println("CHECKSUM OK");
       }
     

   return return_val; 
} 
// end ////////

// Here we send the byteArray over Serial.
void sendArray(byte byteArray[], int len)
{
  Serial.write(0xff); // Sync byte
  int checksum = 0;
  for (int i = 0; i < len; i++)
  {
    Serial.write(byteArray[i]);
    checksum += byteArray[i];
  }
  Serial.write((checksum >> 8));
  Serial.write(checksum);
}
// end ////////

// Here we set thePpin to HIGH if some value we read gets to toggleValue else LOW
void togglePinIfValue(int thePin, byte value, byte toggleValue)
{
  if (value == toggleValue)
  {
    digitalWrite(thePin,HIGH);
  }
  else
  {
    digitalWrite(thePin,LOW);
  }
}
// end ////////

// Here we set the byte at pByte to HIGH if thePin is HIGH and LOW if LOW
void toggleByteIfValueHIGH(byte* pByte, int thePin)
{
   if(digitalRead(thePin) == HIGH)
   {
     *pByte = HIGH;
   }
   else
   {
     *pByte = LOW;
   }
}
// end ////////

// PIN DEFINES
#define OUT_STALL       2
#define OUT_NOSE_GEAR   4
#define OUT_LEFT_GEAR   5
#define OUT_RIGHT_GEAR  6
#define OUT_FLAP_POS    7
#define IN_SWITCH       12
#define IN_TRIM         0
// END PIN DEFINES

void setup() 
{
	Serial.begin(9600);	// opens serial port, sets data rate to 9600 bps
        
        pinMode(OUT_STALL,OUTPUT); //stall
        pinMode(OUT_NOSE_GEAR, OUTPUT); //gear
        pinMode(OUT_LEFT_GEAR,OUTPUT); //left
        pinMode(OUT_RIGHT_GEAR,OUTPUT); //right gear  
        servo.attach(OUT_FLAP_POS);  //flap pos  
        pinMode(IN_SWITCH,INPUT); //switch
        pinMode(13,OUTPUT);
        
}

void loop()
{


                getBytes(values,5);


                servo.write(map(values[0], 127, 255, 0, 180));
                
                togglePinIfValue(OUT_RIGHT_GEAR, values[2], 255);
                togglePinIfValue(OUT_NOSE_GEAR, values[1], 255);
                togglePinIfValue(OUT_LEFT_GEAR, values[3], 255);
                
                togglePinIfValue(OUT_STALL, values[4], 255);
                toggleByteIfValueHIGH(&switch_stat, IN_SWITCH);
                
              
                
                
                input_values[0] = switch_stat;
                trim = analogRead(IN_TRIM);
                trim = map(trim, 0, 800, 0, 255);
                input_values[1] = trim; 
                
                sendArray(input_values,2);            
}

