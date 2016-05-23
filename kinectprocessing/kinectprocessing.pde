//----------------------------------start processing code------------------------------------ 
import SimpleOpenNI.*;
SimpleOpenNI          context;

import processing.serial.*;    //  Load serial library
Serial arduinoPort;        //  Set arduinoPort as serial connection

int val1 = 0;                        //  servo 1 value
int val2 = 0;                        //  servo 2 value

// NITE
XnVSessionManager     sessionManager;
XnVSelectableSlider2D trackPad;

const int gridX = 3; 
const int gridY = 3;

Trackpad   trackPadViz;

//--- Function:
void setup()
{
  
  context = new SimpleOpenNI(this, SimpleOpenNI.RUN_MODE_MULTI_THREADED);
  context.setMirror(true);   // mirror is by default enabled
  context.enableDepth();    // enable depthMap generation 
  context.enableGesture();   // enable the hands + gesture
  context.enableHands();

  // setup NITE 
  sessionManager = context.createSessionManager("Click,Wave", "RaiseHand");

  trackPad = new XnVSelectableSlider2D(gridX, gridY);
  sessionManager.AddListener(trackPad);

  trackPad.RegisterItemHover(this);
  trackPad.RegisterValueChange(this);
  trackPad.RegisterItemSelect(this);

  trackPad.RegisterPrimaryPointCreate(this);
  trackPad.RegisterPrimaryPointDestroy(this);

  // create gui viz
  trackPadViz = new Trackpad(new PVector(context.depthWidth()/2, context.depthHeight()/2, 0), 
  gridX, gridY, 100, 100, 15);  

  size(context.depthWidth(), context.depthHeight()); 
  smooth();
  
  // info text
  println("-------------------------------");  
  println("1. Wave till the tiles get green");  
  println("2. The relative hand movement will select the tiles");  
  println("-------------------------------");   

  println("-------------------------------");
 // println(Serial.list());
  arduinoPort = new Serial(this, Serial.list()[0], 9600);    // Set arduino to 9600 baud
  println("-------------------------------");
  //set values to neutral for now
  val1 = (int) ( 127.0/2);  // left servo
  val2 = (int) ( 128 + 127.0/2);  //   RIGHT servi
}
//--- Function:
void draw()
{

  context.update(); // update the cam
  context.update(sessionManager);   // update nite

  image(context.depthImage(), 0, 0);  // draw depthImageMap
  trackPadViz.draw();

   arduinoPort.write(val1);     // Sends val1 to Arduino, left servo
   arduinoPort.write(val2);     // Sends val2 to Arduino, right servo
 //  println("Left servo value: " + val1 + " Right servo value: " + val2);
}
//--- Function:
void keyPressed()
{
  switch(key)
  {
  case 'e':
    // end sessions
    sessionManager.EndSession();
    println("end session");
    break;
  }
}

///--- session callbacks ----///
void onStartSession(PVector pos)
{
  println("onStartSession: " + pos);
}
//--- Function:
void onEndSession()
{
  println("onEndSession: ");
}
//--- Function:
void onFocusSession(String strFocus, PVector pos, float progress)
{
  println("onFocusSession: focus=" + strFocus + ",pos=" + pos + ",progress=" + progress);
}

///--- XnVSelectableSlider2D callbacks ----///
//--- Function:
void onItemHover(int nXIndex, int nYIndex)
{
//  println("onItemHover: nXIndex=" + nXIndex +" nYIndex=" + nYIndex);
  // we can send values from 0 to 255 to the arduino  
  // left servo: 0-127, right servo 128-255.

  if ((nXIndex == 0) && (nYIndex == 0) ) // left back
  { 
    val1 = (int) ( 0);  // left servo
    val2 = (int) ( 192);  //   RIGHT servo
  }
  else if ((nXIndex == 1) && (nYIndex == 0)) // full back
  {
    val1 = (int) ( 0);  // left servo
    val2 = (int) (255);  //   RIGHT servo
  }
  else if ((nXIndex == 2) && (nYIndex == 0))   // right back
  {
    val1 = (int) ( 63);  // left servo
    val2 = (int) ( 255);  //   RIGHT servo
  }
  else if ((nXIndex == 0) && (nYIndex == 1) ) // left 
  {
    val1 = (int) ( 63);  // left servo
    val2 = (int) ( 129);  //   RIGHT servo
    
  }
  else if ((nXIndex == 1) && (nYIndex == 1))  // neutral
  {
    val1 = (int) ( 127.0/2);  // left servo
    val2 = (int) ( 128 + 127.0/2);  //   RIGHT servo
  }
  else if ((nXIndex == 2) && (nYIndex == 1))  // right 
  {
        val1 = (int) ( 127.0);  // left servo
    val2 = (int) ( 128 + 127.0/2);  //   RIGHT servo
  }
  else if ((nXIndex == 0) && (nYIndex == 2)) // left forward
  {
    val1 = (int) ( 63);  // left servo
    val2 = (int) ( 129);  //   RIGHT servo
  }
  else if ((nXIndex == 1) && (nYIndex == 2) ) // full forward
  {
    val1 = (int) (127);  // left servo
    val2 = (int) ( 129);  //   RIGHT servo
  }
  else if ((nXIndex == 2) && (nYIndex == 2))   // right forward
  {
    val1 = (int) ( 127.0);  // left servo
    val2 = (int) ( 192);  //   RIGHT servo
  }
  else
  {
    val1 = (int) ( 127.0/2);  // left servo
    val2 = (int) ( 128 + 127.0/2);  //   RIGHT servo 
  }

  trackPadViz.update(nXIndex, nYIndex);
}
//--- Function:
void onValueChange(float fXValue, float fYValue)
{
  // println("onValueChange: fXValue=" + fXValue +" fYValue=" + fYValue);
}
//--- Function:
void onItemSelect(int nXIndex, int nYIndex, int eDir)
{
  println("onItemSelect: nXIndex=" + nXIndex + " nYIndex=" + nYIndex + " eDir=" + eDir);
  trackPadViz.push(nXIndex, nYIndex, eDir);
}
//--- Function:
void onPrimaryPointCreate(XnVHandPointContext pContext, XnPoint3D ptFocus)
{
  println("onPrimaryPointCreate");
  trackPadViz.enable();
}
//--- Function:
void onPrimaryPointDestroy(int nID)
{
  println("onPrimaryPointDestroy");
  trackPadViz.disable();
}

///--- Trackpad class ----/// 
class Trackpad
{
  int     xRes;
  int     yRes;
  int     width;
  int     height;

  boolean active;
  PVector center;
  PVector offset;

  int      space;

  int      focusX;
  int      focusY;
  int      selX;
  int      selY;
  int      dir;


  Trackpad(PVector center, int xRes, int yRes, int width, int height, int space)
  {
    this.xRes     = xRes;
    this.yRes     = yRes;
    this.width    = width;
    this.height   = height;
    active        = false;

    this.center = center.get();
    offset = new PVector();
    offset.set(-(float)(xRes * width + (xRes -1) * space) * .5f, 
    -(float)(yRes * height + (yRes -1) * space) * .5f, 
    0.0f);
    offset.add(this.center);

    this.space = space;
  }
//--- Function:
  void enable()
  {
    active = true;

    focusX = -1;
    focusY = -1;
    selX = -1;
    selY = -1;
  }
//--- Function:
  void update(int indexX, int indexY)
  {
    focusX = indexX;
    focusY = (yRes-1) - indexY;
  }
//--- Function:
  void push(int indexX, int indexY, int dir)
  {
    selX = indexX;
    selY =  (yRes-1) - indexY;
    this.dir = dir;
  }

  void disable()
  {
    active = false;
  }
//--- Function:
  void draw()
  {    
    pushStyle();
    pushMatrix();

    translate(offset.x, offset.y);

    for (int y=0;y < yRes;y++)
    {
      for (int x=0;x < xRes;x++)
      {
        //          if(active && (selX == x) && (selY == y))
        //          { // selected object 
        //            fill(0,0,255,190);
        //            strokeWeight(3);
        //            stroke(100,200,100,220);
        //          }
        //          else 
        if (active && (focusX == x) && (focusY == y))
        { // focus object 
          fill(100, 255, 100, 220);
          strokeWeight(3);
          stroke(100, 200, 100, 220);
        }
        else if (active)
        {  // normal
          strokeWeight(3);
          stroke(100, 200, 100, 190);
          noFill();
        }
        else
        {
          strokeWeight(2);
          stroke(200, 100, 100, 60);
          noFill();
        }
        rect(x * (width + space), y * (width + space), width, height);
      }
    }
    popMatrix();
    popStyle();
  }
}
// end class trackpad