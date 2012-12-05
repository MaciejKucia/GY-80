// Created 1.12.12
// by Maciej Kucia

import processing.serial.*;

Serial myPort;        // The serial port
int xPos = 1;         // horizontal position of the graph

color[] colors = {
  color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 255, 0), color(0, 255, 255), color(255, 0, 255), color(100, 100, 0), color(100, 0, 100), color(0, 100, 100), color(20, 50, 80), color(80, 50, 20), color(0, 0, 0)
}; 

// Timestep
float deltaT = (1/50);

// Note: Far from optimal implementation
//class FIRfilter
//{
//  float coeffs[];
//  float buffer[];
//  
//  FIRfilter(float[] coef)
//  {
//    coeffs = coef;
//    buffer = new float[coef.length];
//
//  }
//  
//  public float Process(float value)
//  {
//    float result=0.0;
//    
//    // put new
//    
//    for(int i=0;i<coeffs.length-1;++i)
//       buffer[i+1]=buffer[i];
//    
//    buffer[0] = value;
//      
//    for(int i=0;i<coeffs.length;++i)
//      result += coeffs[i] * buffer[i];
//
//    return result;
//  }
//  
//  
//}

//// lowpass for 0.5 nyquist
//FIRfilter lowpass = new FIRfilter(new float[] {0.00329661,  0.05897323,  0.24920989,  0.37704053,  0.24920989,
//        0.05897323,  0.00329661});
//
////hipass 0.5 nyquist
//FIRfilter highpass = new FIRfilter(new float[]{0.00521554, -0.00804016, -0.01335863,  0.10573869, -0.24054812,
//        0.30722052, -0.24054812,  0.10573869, -0.01335863, -0.00804016,
//        0.00521554});

class SensorsC
{
  public float gyroX=0;
  public float gyroY=0;
  public float gyroZ=0;

  public float accX=0;
  public float accY=0;
  public float accZ=0;

  public float gyroAngle=0;
  public float accAngle=0;

  public float Angle =0.0;

  public void UpdateMeasurements(float gX, float gY, float gZ, float aX, float aY, float aZ)
  {
    // 250 dps
    // 25Hz = 40ms
    gyroX=(0.04*gX)/250.0;
    gyroY=(0.04*gY)/250.0;
    gyroZ=(0.04*gZ)/250.0;

    // range +-4g - 11 bits = 10 bits + sign
    // (2^10)-1 = 4g -> 4g = 1023 -> 1g = 255 
    accX=aX/255.0;
    accY=aY/255.0;
    accZ=aZ/255.0;

    accAngle = (float)Math.toDegrees(Math.atan2(aZ, aX) + Math.PI*0.5 );

    // "fuse" two sensor data
    Angle =  (0.90)*(Angle+gyroY) + (0.10)*accAngle;
  }

  public void Draw()
  {
    //DrawAcc();
    //DrawGyroAngle();
    //DrawAccAngle();
    DrawComplAngle();
  }

  public void DrawAcc()
  {
    float hh = ((float)height/2.0);
    stroke(color(0, 255, 0, 100));

    //blue
    stroke(color(0, 0, 255, 100));
    line((float)xPos, hh, (float)xPos, (float) (hh-accX*90) );

    //green
    stroke(color(0, 255, 0, 100));
    line((float)xPos, hh, (float)xPos, (float) (hh-accY*90) );

    //red
    stroke(color(255, 0, 0, 100));
    line((float)xPos, hh, (float)xPos, (float) (hh-accZ*90) );
  }

  public void DrawGyro()
  {
    float hh = ((float)height/2.0);
    stroke(color(0, 255, 0, 100));

    //blue
    stroke(color(0, 0, 255, 100));
    line((float)xPos, hh, (float)xPos, (float) (hh-gyroX) );

    //green
    stroke(color(0, 255, 0, 100));
    line((float)xPos, hh, (float)xPos, (float) (hh-gyroY) );

    //red
    stroke(color(255, 0, 0, 100));
    line((float)xPos, hh, (float)xPos, (float) (hh-gyroZ) );
  }

  public void DrawGyroAngle()
  {
    float hh = ((float)height/2.0);
    stroke(color(0, 255, 0, 100));

    //blue
    stroke(color(0, 0, 255, 100));
    line((float)xPos, hh, (float)xPos, (float) (hh-gyroAngle) );
  }

  public void DrawAccAngle()
  {
    float hh = ((float)height/2.0);
    stroke(color(0, 255, 0, 100));

    //red
    stroke(color(255, 0, 0, 100));
    line((float)xPos, hh, (float)xPos, (float) (hh-accAngle) );
  }


  public void DrawComplAngle()
  {
    float hh = ((float)height/2.0);
    stroke(color(0, 255, 0, 100));

    //green
    stroke(color(0, 255, 0, 100));
    line((float)xPos, hh, (float)xPos, (float) (hh-Angle) );
  }
}

SensorsC sensors = new SensorsC();

void cleanup()
{
  float hh = ((float)height/2.0);
  background(255, 255, 255);
  stroke(0);
  line(0, hh, width, hh);
  stroke(100, 100, 100);
  line(0, hh-90, width, hh-90);
  line(0, hh+90, width, hh+90);

  xPos = 0;
}

void setup () 
{
  // set the window size:
  size(800, 400);        

  println(Serial.list());
  myPort = new Serial(this, Serial.list()[1], 115200);
  //                                      ^ UPDATE THIS MANUALLY!

  // don't generate a serialEvent() unless you get a newline character:
  myPort.bufferUntil('\n');

  myPort.clear();
  cleanup();
}

void keyPressed() 
{
  switch (key)
  {

  case 'c': 
    cleanup(); 
    break;

  default: 
    println("key not active");
  }
}

void serialEvent (Serial myPort) {

  String inString = myPort.readStringUntil('\n');

  if (inString == null) return;
  if (inString.charAt(0) != '~')
  {
    println("No data.");
    return;
  }

  String[] inStrings = trim(inString).split(",");

  sensors.UpdateMeasurements(
  float(inStrings[4]), float(inStrings[5]), float(inStrings[6]), 
  float(inStrings[1]), float(inStrings[2]), float(inStrings[3]));

  sensors.Draw();

  // at the edge of the screen, go back to the beginning:
  if (xPos++ >= width) 
    cleanup();
}


void draw () {
  // everything happens in the serialEvent()
}

