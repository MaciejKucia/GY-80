// Created 4.11.12
// by Maciej Kucia

import processing.serial.*;

Serial myPort;        // The serial port
int xPos = 1;         // horizontal position of the graph

// 0 - old
// 1 - new 
// 2 - scale
float [][] values = new float[11][3];
float kalman_old = 0;

int kalman_sensor = 5;

color[] colors = {
  color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 255, 0), color(0, 255, 255), color(255, 0, 255), color(100, 100, 0), color(100, 0, 100), color(0, 100, 100), color(20, 50, 80), color(80, 50, 20),color(0,0,0)}; 

boolean[] offChannel = {
  false, true, false, false, false, false, false, false, false, false, false};

boolean enableKalman = true;
boolean enableMeasurement = true;

class KalmanFilterC
{
  // kalman variables
  public double q; // process noise
  public double r; // measurement noise
  public double x; // value
  public double p; // estimation error covariance
  public double k; // kalman gain
  
  public double scale;

  public KalmanFilterC()
  {
    x = 0;
    q = 100;
    r = 10000;
    p = 10000;
    k = 0;
    
    //for plotting
    scale = 0.01;
  }

  void Update(double x_m)
  {
    p = p + q; // we have more noise
    
    k = p / (p+r);
    
    // update by error* kalman gain
    x = x + k * (x_m - x);
    p = (1-k)*(1-k)* p + r*k*k;
  }
  
  void Print()
  {
    println(" q r p k x[" + q +":"+ r +":"+ p +":"+ k +":"+ x + "]");
  }
  
}

KalmanFilterC kalman;

// code

void cleanup()
{
  background(255, 255, 255);
  stroke(0);
  line(0, height/2, width, height/2);
  xPos = 0;
}

void setup () 
{
  // set the window size:
  size(800, 600);        

  kalman = new KalmanFilterC();

  //for(int i=0;i<values[0].length;++i)
  values[kalman_sensor][2] = (float)kalman.scale;

  println(Serial.list());
  myPort = new Serial(this, Serial.list()[1], 115200);
  //                                      ^ UPDATE THIS MANUALLY!
  
  // don't generate a serialEvent() unless you get a newline character:
  myPort.bufferUntil('\n');
  cleanup();
}

void keyPressed() 
{
  switch (key)
  {
  case 'm':
    enableMeasurement = !enableMeasurement;
    break;
    
  case 'c': 
    cleanup(); 
    break;
    
  case 'k': 
    enableKalman = !enableKalman;
    break;
    
  default: 
    println("key not active");
  }
}

void Process()
{
  if (enableKalman)
    kalman.Update(values[kalman_sensor][1]);
}

void Plot()
{
   if (enableMeasurement)
   {
    stroke(colors[colors.length-1]);
    line(xPos, values[kalman_sensor][0]*values[kalman_sensor][2]+(height/2), xPos+1, values[kalman_sensor][1]*values[kalman_sensor][2]+(height/2));
   }
  
  if(enableKalman)
  {
   float new_kalman = (float)kalman.x; 
   
   stroke(color(255, 0, 0,200));
   line(xPos, (float)(kalman_old * kalman.scale)+(height/2), xPos+1,(float)(new_kalman * kalman.scale)+(height/2));
   kalman_old = new_kalman;
   //kalman.Print();
  }

  // at the edge of the screen, go back to the beginning:
  if (xPos++ >= width) 
    cleanup();
 
}

void serialEvent (Serial myPort) {
  // get the ASCII string:
  String inString = myPort.readStringUntil('\n');

  if (inString == null) return;

  //println(inString);
  if (inString.charAt(0) != '~')
  {
    println("No data.");
    return;
  }

  // trim off any whitespace:
  inString = trim(inString);

  String[] inStrings = inString.split(",");

  for (int i=0;i<=10;++i)
  {
    values[i][0] = values[i][1];
    values[i][1] = float(inStrings[i+1]);
  }
  
  Process();
  Plot();

}


void draw () {
  // everything happens in the serialEvent()
}

