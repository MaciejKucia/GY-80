// Created 1.12.12
// by Maciej Kucia

import processing.serial.*;

Serial myPort;        // The serial port
int xPos = 1;         // horizontal position of the graph

color[] colors = {
  color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 255, 0), color(0, 255, 255), color(255, 0, 255), color(100, 100, 0), color(100, 0, 100), color(0, 100, 100), color(20, 50, 80), color(80, 50, 20), color(0, 0, 0)
}; 

// Timestep
float deltaT = (1./50.);

class KalmanC
{
    /* Kalman filter variables */
  float R_measure; // Measurement noise variance - this is actually the variance of the measurement noise

  float angle; // The angle calculated by the Kalman filter - part of the 2x1 state matrix
  float bias; // The gyro bias calculated by the Kalman filter - part of the 2x1 state matrix
  float rate; // Unbiased rate calculated from the rate and the calculated bias - you have to call Process to update the rate

  // 0 - Process noise variance for the accelerometer based angle
  // 1 - Process noise variance for the gyro bias
  float[] Q   = new float[2];     // Process noise covariance

  float[][] P = new float[2][2];   // Error covariance matrix - This is a 2x2 matrix
  float[] K = new float[2];        // Kalman gain - This is a 2x1 matrix
  float y;                         // Angle difference - 1x1 matrix
  float S;                         // Estimate error - 1x1 matrix
  
  KalmanC(float anglee)
  {
    K[0] = K [1] = 0;
    P[0][0] = P[0][1] = P[1][0] = P[1][1] = 0; 
    bias = 0;
    rate = 0;
    angle = anglee;
    
    Q[0] = 0.1;       //angle 
    Q[1] = 0.4;       //bias
    R_measure = 0.1;   //measurement noise 
  };
  
  // The angle should be in degrees and the rate should be in degrees per second and the delta time in seconds
  float Process(float newAngle, float newRate, float dt) 
  {
    // I - predict

    // Step 1 
    rate = newRate - bias;
    angle += dt * rate;

    // Update estimation error covariance - Project the error covariance ahead
    // Step 2 
    P[0][0] += dt * (dt*P[1][1] - P[0][1] - P[1][0] + Q[0]);
    P[0][1] -= dt * P[1][1];
    P[1][0] -= dt * P[1][1];
    P[1][1] += Q[1] * dt;
    
    // Discrete Kalman filter measurement update equations - Measurement Update ("Correct")
    // Calculate Kalman gain - Compute the Kalman gain
    // Step 4 
    S = P[0][0] + R_measure;
    // Step 5 
    K[0] = P[0][0] / S;
    K[1] = P[1][0] / S;

    // Calculate angle and bias - Update estimate with measurement zk (newAngle)
    /* Step 3 */
    y = newAngle - angle;
    /* Step 6 */
    angle += K[0] * y;
    bias += K[1] * y;

    // Calculate estimation error covariance - Update the error covariance
    /* Step 7 */
    P[0][0] -= K[0] * P[0][0];
    P[0][1] -= K[0] * P[0][1];
    P[1][0] -= K[1] * P[0][0];
    P[1][1] -= K[1] * P[0][1];

    return angle;
  };
  
}

class SensorsC
{
  public float gyroX=0;
  public float gyroY=0;
  public float gyroZ=0;

  public float accX=0;
  public float accY=0;
  public float accZ=0;

  KalmanC kalman = new KalmanC(90);

  public float gyroAngle=0;
  public float accAngle=0;

  public float Angle  =0.0;
  public float Angle2 =0.0;

  public void UpdateMeasurements(float gX, float gY, float gZ, float aX, float aY, float aZ)
  {
    // 250 dps
    // 25Hz = 40ms
    //gyroX=(gX)/250.0;
    gyroY=(gY)/250.0; //<<
    //gyroZ=(gZ)/250.0;

    // range +-4g - 11 bits = 10 bits + sign
    // (2^10)-1 = 4g -> 4g = 1023 -> 1g = 255 
    accX=aX/255.0;
    accY=aY/255.0;
    accZ=aZ/255.0;

    accAngle = (float)Math.toDegrees(Math.atan2(aZ, aX) + Math.PI*0.5 );

    // "fuse" two sensor data
    Angle =  kalman.Process(accAngle, gyroY, deltaT);
    
    
    float percent = 0.22;
    Angle2 =  (percent)*(Angle+gyroY) + (1-percent)*accAngle;
  }

  public void Draw()
  {
  float hh = ((float)height/2.0);
    stroke(color(0, 255, 0, 100));

    //green - kalman
    stroke(color(0, 255, 0, 100));
    line((float)xPos, hh, (float)xPos, (float) (hh-Angle) );
    
    //red - complementary
        stroke(color(255, 0, 0, 20));
    line((float)xPos, hh, (float)xPos, (float) (hh-Angle2) );
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

