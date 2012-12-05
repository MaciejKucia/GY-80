// Created 4.11.12
// by Maciej Kucia

import processing.serial.*;

Serial myPort;        // The serial port
int xPos = 1;         // horizontal position of the graph

// 0 - old 1-new 2-max
float [][] values = new float[11][3];

int samples = 0;
float samplesPerS=0;

color[] colors = {color(255,0,0),color(0,255,0),color(0,0,255),color(255,255,0),color(0,255,255),color(255,0,255),color(100,100,0),color(100,0,100),color(0,100,100),color(20,50,80),color(80,50,20)}; 
boolean[] offChannel = {true,true,true,false,false,false,false,false,false,false,false};

void cleanup()
{
  background(255,255,255);
  stroke(0);
  line(0, height/2 , width, height/2);
  xPos = 0;
}

void setup () 
{
  // set the window size:
  size(800, 600);        

  println(Serial.list());
  myPort = new Serial(this, Serial.list()[1], 115200);
  //                                      ^ UPDATE THIS MANUALLY!
  // don't generate a serialEvent() unless you get a newline character:
  myPort.bufferUntil('\n');
  cleanup();
}

void timer_code()
{
  samplesPerS = samples;
  samples = 0;
}

void keyPressed() 
{
  switch (key)
  {
    case '1': offChannel[0] = !offChannel[0]; break;
    case '2': offChannel[1] = !offChannel[1]; break;
    case '3': offChannel[2] = !offChannel[2]; break;
    case '4': offChannel[3] = !offChannel[3]; break;
    case '5': offChannel[4] = !offChannel[4]; break;
    case '6': offChannel[5] = !offChannel[5]; break;
    case '7': offChannel[6] = !offChannel[6]; break;
    case '8': offChannel[7] = !offChannel[7]; break;
    case '9': offChannel[8] = !offChannel[8]; break;
    case '0': offChannel[9] = !offChannel[9]; break;
    case '-': offChannel[10] = !offChannel[10]; break;
    case 'c': cleanup(); break;
    default: println("key not active");
  }
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
    
    for(int i=0;i<=10;++i)
    {
      values[i][0] = values[i][1];
      values[i][1] = float(inStrings[i+1]);
      
      //store max
      if (values[i][1] > values[i][2])
        values[i][2] = values[i][1];
      
      values[i][1] = map(values[i][1], -values[i][2], values[i][2], 0, height);
    }

    // draw the line:
    for(int i=0;i<=10;++i)
    {
     if (!offChannel[i]) continue;
     stroke(colors[i]);
     line(xPos, values[i][0], xPos+1, values[i][1]);
    }
    
    // at the edge of the screen, go back to the beginning:
    if (xPos++ >= width) 
    {
      cleanup();
    } 
    
//    else {
//      // increment the horizontal position:
//      xPos++;
//    }
  
}


void draw () {
  // everything happens in the serialEvent()
}

