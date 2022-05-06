// import libraries
import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

/* SETTINGS BEGIN */

// Serial port to connect to
//String serialPortName = "/dev/tty.usbmodem1411";

/* SETTINGS END */

Serial serialPort; // Serial port object

// interface stuff
ControlP5 cp5;
PFont font;

// Settings for the plotter are saved in this file
JSONObject plotterConfigJSON;

Table table;
String filename;
String time;

// plots
Graph LineGraph1 = new Graph(100, 80, 250, 150, color (20, 20, 200));
Graph LineGraph2 = new Graph(520, 80, 250, 150, color (20, 20, 200));
Graph LineGraph3 = new Graph(940, 80, 250, 150, color (20, 20, 200));
Graph LineGraph4 = new Graph(100, 370, 250, 150, color (20, 20, 200));
Graph LineGraph5 = new Graph(520, 370, 250, 150, color (20, 20, 200));
Graph LineGraph6 = new Graph(940, 370, 250, 150, color (20, 20, 200));
Graph LineGraph7 = new Graph(100, 660, 250, 150, color (20, 20, 200));

float[][] lineGraphValues1 = new float[1][100];
float[][] lineGraphValues2 = new float[1][100];
float[][] lineGraphValues3 = new float[1][100];
float[][] lineGraphValues4 = new float[1][100];
float[][] lineGraphValues5 = new float[2][100];
float[][] lineGraphValues6 = new float[1][100];
float[][] lineGraphValues7 = new float[1][100];

float[] lineGraphSampleNumbers1 = new float[100];
float[] lineGraphSampleNumbers2 = new float[100];
float[] lineGraphSampleNumbers3 = new float[100];
float[] lineGraphSampleNumbers4 = new float[100];
float[] lineGraphSampleNumbers5 = new float[100];
float[] lineGraphSampleNumbers6 = new float[100];
float[] lineGraphSampleNumbers7 = new float[100];

color[] graphColors = new color[6];

// helper for saving the executing path
String topSketchPath = "";

String num1, num2, num3, num4, num5, num6, num7;
String numm1, numm2, numm3, numm4, numm5, numm6, numm7;
float nnum1 = 1;
float nnum2 = 1;
float nnum3 = 1;
float nnum4 = 1;
float nnum5 = 1;
float nnum6 = 1;
float nnum7 = 1;
float nuum1 = -1;
float nuum2 = -1;
float nuum3 = -1;
float nuum4 = 0;
float nuum5 = -1;
float nuum6 = -1;
float nuum7 = -1;
int mun, muun; 

String tempe,hum,pres;
int count2 = 0;
int count3 = 0;

int status1 = 0;  // 2,3,4,5 check; 1,6,7,8,9,10 launch
int timee, timme, tiime, mills;
int mil;
String miil;
int miii = 0;
String status2 = "0"; // working status
int stay;
String[] serialnum;

void setup() {
  surface.setTitle("Ground Control");
  size(1800, 900);

  // set line graph colors
  graphColors[0] = color(131, 255, 20);
  graphColors[1] = color(232, 158, 12);
  graphColors[2] = color(255, 0, 0);
  graphColors[3] = color(62, 12, 232);
  graphColors[4] = color(13, 255, 243);
  graphColors[5] = color(200, 46, 232);

  // settings save file
  topSketchPath = sketchPath();
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  table = new Table();
  table.addColumn("Time");
  table.addColumn("MILLIS");
  table.addColumn("accelz");
  table.addColumn("pitch");
  table.addColumn("roll");
  table.addColumn("posX");
  table.addColumn("posY");
  table.addColumn("PIDX");
  table.addColumn("PIDY");
  table.addColumn("RT");

  // gui
  cp5 = new ControlP5(this);
  
  // init charts
  setChartSettings();

  // button
  font = createFont("arial", 25);

  cp5.addButton("LAUNCH")
    .setColorBackground(color(200,0,0))
    .setPosition(1320, 730)
    .setSize(350, 80)
    .setFont(font)
    ;
  cp5.addButton("Check")
    .setColorBackground(color(0,128,0))
    .setPosition(520, 730)
    .setSize(350, 80)
    .setFont(font)
    ;
  cp5.addButton("Calibrate")
    .setColorBackground(color(0,128,0))
    .setPosition(920, 730)
    .setSize(350, 80)
    .setFont(font)
    ;
  cp5.addButton("test")
    .setColorBackground(color(0,128,0))
    .setPosition(1350, 505)
    .setSize(350, 80)
    .setFont(font)
    ;

  //cp5.addTextfield("setposX").setPosition(1330, 500).setSize(180, 80).setText(getPlotterConfigString("setposX")).setFont(font).setAutoClear(false);
  //cp5.addTextfield("setposY").setPosition(1530, 500).setSize(180, 80).setText(getPlotterConfigString("setposY")).setFont(font).setAutoClear(false);
  // build x axis values for the line graph
  for (int i=0; i<lineGraphValues1.length; i++) {
    for (int k=0; k<lineGraphValues1[0].length; k++) {
      lineGraphValues1[i][k] = 0;
      if (i==0){
        lineGraphSampleNumbers1[k] = k;
      }
    }
  }

  for (int i=0; i<lineGraphValues2.length; i++) {
    for (int k=0; k<lineGraphValues2[0].length; k++) {
      lineGraphValues2[i][k] = 0;
      if (i==0){
        lineGraphSampleNumbers2[k] = k;
      }
    }
  }

  for (int i=0; i<lineGraphValues3.length; i++) {
    for (int k=0; k<lineGraphValues3[0].length; k++) {
      lineGraphValues3[i][k] = 0;
      if (i==0){
        lineGraphSampleNumbers3[k] = k;
      }
    }
  }

  for (int i=0; i<lineGraphValues4.length; i++) {
    for (int k=0; k<lineGraphValues4[0].length; k++) {
      lineGraphValues4[i][k] = 0;
      if (i==0){
        lineGraphSampleNumbers4[k] = k;
      }
    }
  }

  for (int i=0; i<lineGraphValues5.length; i++) {
    for (int k=0; k<lineGraphValues5[0].length; k++) {
      lineGraphValues5[i][k] = 0;
      if (i==0){
        lineGraphSampleNumbers5[k] = k;
      }
    }
  }

  for (int i=0; i<lineGraphValues6.length; i++) {
    for (int k=0; k<lineGraphValues6[0].length; k++) {
      lineGraphValues6[i][k] = 0;
      if (i==0){
        lineGraphSampleNumbers6[k] = k;
      }
    }
  }

  for (int i=0; i<lineGraphValues7.length; i++) {
    for (int k=0; k<lineGraphValues7[0].length; k++) {
      lineGraphValues7[i][k] = 0;
      if (i==0){
        lineGraphSampleNumbers7[k] = k;
      }
    }
  }
  
  // start serial communication
  String serialPortName = "COM7";
  serialPort = new Serial(this, serialPortName, 115200);

}

byte[] inBuffer = new byte[500]; // holds serial message
int i = 0; // loop variable
void draw() {
  /* Read serial and update values */
  String myString = "";
  serialPort.readBytesUntil('\n', inBuffer);
  myString = new String(inBuffer);

  println(myString);

  // split the string at delimiter
  String[] nums = split(myString, ":");
  
  // csvv file
  try {
    TableRow newRow = table.addRow();
    int year1 = year();
    int month1 = month();
    int day1 = day();
    int hour1 = hour();
    int min1 = minute();
    int sec1 = second();
    int mill1 = millis();
    time = hour1 + ":" + min1 + ":" + sec1;
    newRow.setString("Time", time);
    newRow.setInt("MILLIS", mill1);
    newRow.setString("accelz", nums[0]);
    newRow.setString("pitch", nums[1]);
    newRow.setString("roll", nums[2]);
    newRow.setString("posX", nums[4]);
    newRow.setString("posY", nums[5]);
    newRow.setString("PIDX", nums[9]);
    newRow.setString("PIDY", nums[10]);
    newRow.setString("RT", nums[12]);

    filename = year1 + "/" + month1 + "/" + day1 + " Data.csv";
    saveTable(table, filename);
  }
  catch (Exception e){
  }
    
  // update line graph
  try {
    if (i<lineGraphValues1.length) {
      for (int k=0; k<lineGraphValues1[0].length-1; k++) {
        lineGraphValues1[0][k] = lineGraphValues1[0][k+1];
      }
      lineGraphValues1[0][lineGraphValues1[0].length-1] = float(nums[0]);
    }
  }
  catch (Exception e) {
  }

  try {
    if (i<lineGraphValues2.length) {
      for (int k=0; k<lineGraphValues2[0].length-1; k++) {
        lineGraphValues2[0][k] = lineGraphValues2[0][k+1];
      }
      lineGraphValues2[0][lineGraphValues2[0].length-1] = float(nums[1]);
    }
  }
  catch (Exception e) {
  }

  try {
    if (i<lineGraphValues3.length) {
      for (int k=0; k<lineGraphValues3[0].length-1; k++) {
        lineGraphValues3[0][k] = lineGraphValues3[0][k+1];
      }
      lineGraphValues3[0][lineGraphValues3[0].length-1] = float(nums[2]);
    }
  }
  catch (Exception e) {
  }

  try {
    if (i<lineGraphValues4.length) {
      for (int k=0; k<lineGraphValues4[0].length-1; k++) {
        lineGraphValues4[0][k] = lineGraphValues4[0][k+1];
      }
      lineGraphValues4[0][lineGraphValues4[0].length-1] = float(nums[3]);
    }
  }
  catch (Exception e) {
  }
  int iC = 0;
  for (int g=4; g<6; g++){ 
    try {
      if (iC<lineGraphValues5.length) {
        for (int k=0; k<lineGraphValues5[iC].length-1; k++) {
          lineGraphValues5[iC][k] = lineGraphValues5[iC][k+1];
        }
        lineGraphValues5[iC][lineGraphValues5[iC].length-1] = float(nums[g]);
      }
    }
    catch (Exception e) {
    }
    iC+=1;
  }
  try {
    if (i<lineGraphValues6.length) {
      for (int k=0; k<lineGraphValues6[0].length-1; k++) {
        lineGraphValues6[0][k] = lineGraphValues6[0][k+1];
      }
      lineGraphValues6[0][lineGraphValues6[0].length-1] = float(nums[9]);
    }
  }
  catch (Exception e) {
  }
  try {
    if (i<lineGraphValues7.length) {
      for (int k=0; k<lineGraphValues7[0].length-1; k++) {
        lineGraphValues7[0][k] = lineGraphValues7[0][k+1];
      }
      lineGraphValues7[0][lineGraphValues7[0].length-1] = float(nums[10]);
    }
  }
  catch (Exception e) {
  }

  try{
    
    nnum1 = max(lineGraphValues1[0]);
    nnum2 = max(lineGraphValues2[0]);
    nnum3 = max(lineGraphValues3[0]);
    nnum4 = max(lineGraphValues4[0]);
    
    nnum6 = max(lineGraphValues6[0]);
    nnum7 = max(lineGraphValues7[0]);

    num1 = String.valueOf(nnum1+1);
    num2 = String.valueOf(nnum2+1);
    num3 = String.valueOf(nnum3+1);
    num4 = String.valueOf(nnum4+100);
    num5 = String.valueOf(nnum5+1);
    num6 = String.valueOf(nnum6+5);
    num7 = String.valueOf(nnum7+5);

    nuum1 = min(lineGraphValues1[0]);
    nuum2 = min(lineGraphValues2[0]);
    nuum3 = min(lineGraphValues3[0]);
    //nuum4 = min(lineGraphValues4[0]);
    
    nuum6 = min(lineGraphValues6[0]);
    nuum7 = min(lineGraphValues7[0]);

    numm1 = String.valueOf(nuum1-1);
    numm2 = String.valueOf(nuum2-1);
    numm3 = String.valueOf(nuum3-1);
    numm4 = String.valueOf(0);
    numm5 = String.valueOf(nuum5-1);
    numm6 = String.valueOf(nuum6-5);
    numm7 = String.valueOf(nuum7-5);
    


    // lalala
    plotterConfigJSON.setString("lgMaxY1", num1);
    plotterConfigJSON.setString("lgMinY1", numm1); 
    plotterConfigJSON.setString("lgMaxY2", num2);
    plotterConfigJSON.setString("lgMinY2", numm2); 
    plotterConfigJSON.setString("lgMaxY3", num3);
    plotterConfigJSON.setString("lgMinY3", numm3); 
    plotterConfigJSON.setString("lgMaxY4", num4);
    plotterConfigJSON.setString("lgMinY4", numm4); 
    //plotterConfigJSON.setString("lgMaxY5", num5);
    //plotterConfigJSON.setString("lgMinY5", numm5); 
    plotterConfigJSON.setString("lgMaxY6", num6);
    plotterConfigJSON.setString("lgMinY6", numm6); 
    plotterConfigJSON.setString("lgMaxY7", num7);
    plotterConfigJSON.setString("lgMinY7", numm7); 

    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
    setChartSettings();

  }
  catch (Exception e) {
  }


  // draw the bar chart
  background(0); 
  // draw the line graphs
  LineGraph1.DrawAxis();
  for (int i=0;i<lineGraphValues1.length; i++) {
    LineGraph1.GraphColor = graphColors[i];
    LineGraph1.LineGraph(lineGraphSampleNumbers1, lineGraphValues1[i]);
  }

  LineGraph2.DrawAxis();
  for (int i=0;i<lineGraphValues2.length; i++) {
    LineGraph2.GraphColor = graphColors[i];
    LineGraph2.LineGraph(lineGraphSampleNumbers2, lineGraphValues2[i]);
  }

  LineGraph3.DrawAxis();
  for (int i=0;i<lineGraphValues3.length; i++) {
    LineGraph3.GraphColor = graphColors[i];
    LineGraph3.LineGraph(lineGraphSampleNumbers3, lineGraphValues3[i]);
  }

  LineGraph4.DrawAxis();
  for (int i=0;i<lineGraphValues4.length; i++) {
    LineGraph4.GraphColor = graphColors[i];
    LineGraph4.LineGraph(lineGraphSampleNumbers4, lineGraphValues4[i]);
  }

  LineGraph5.DrawAxis();
  for (int i=0;i<lineGraphValues5.length; i++) {
    LineGraph5.GraphColor = graphColors[i];
    LineGraph5.LineGraph(lineGraphSampleNumbers5, lineGraphValues5[i]);
  }

  LineGraph6.DrawAxis();
  for (int i=0;i<lineGraphValues6.length; i++) {
    LineGraph6.GraphColor = graphColors[i];
    LineGraph6.LineGraph(lineGraphSampleNumbers6, lineGraphValues6[i]);
  }

  LineGraph7.DrawAxis();
  for (int i=0;i<lineGraphValues7.length; i++) {
    LineGraph7.GraphColor = graphColors[i];
    LineGraph7.LineGraph(lineGraphSampleNumbers7, lineGraphValues7[i]);
  }

  try {
    hum = nums[6];
    pres = nums[7];
    tempe = nums[8];
    status2 = nums[11];

    // connect failed
    if (int(nums[12]) == miii){
      count3 += 1;
    }else{
      count3 = 0;
      if (status1 <= 0){
        status1 = 0;
      }else{
        if (stay == 1){
          status1 = stay;
        }
      }
    }
    if (count3 >= 50){
      status1 = -1;
      if (status1 == 1){
        status1 = stay;
      }
    }
    
    miii = int(nums[12]);
    
  }
  catch (Exception e) {
  }

  groundControl(hum, pres, tempe);
  controlPanel();

  // failed
  if (status1 == -1){
    status_1();
  }

  // sleep
  if (status1 == 0){
    statusbox();
  }
  
  //check
  if (status1 == 2){
    statusbox1();
  }

  //checkcalibrate
  if (status1 == 3){
    statusbox2();
  }
 
  //launch millis() > mil + 2000 &&   status1 == 1 || 
  if (status1 == 1 || status2.equals("2") && status1 != -1){
    statusbox8();
    if (status2.equals("1")){
      status1 = 10;
      stay = 0;
    }
  }

  // finished
  if (status2.equals("5")){
    statusbox3();
  }

  // stable
  if (status2.equals("6")){
    statusbox4();
  }

  //land
  if (status1 == 10 || status2.equals("1")){
    statusbox9();
    if (count2 == 0){
      mil = millis();
      count2 = 1;
    }
    if (millis() > mil + 2000){
      status1 = 0;
      count2 = 0;
    }
  }
}

// it just a test will be deleted soon
void test(){
  serialPort.write('4');
}

void LAUNCH(){
  //serialnum[0] = '1';
  serialPort.write('1');
  status1 = 1;
}

void Check(){
  //serialnum[0] = '2';
  serialPort.write('2');
  status1 = 2;
}
void Calibrate(){
  //serialnum[0] = '3';
  serialPort.write('3');
  status1 = 3;
}

void groundControl(String hum, String pres, String tempe){
  textSize(50);
  fill(255);
  text("Ground Control", 1680, 80);
  text("System", 1600, 130);
  int day = day();    // Values from 1 - 31
  int month = month();  // Values from 1 - 12
  int year = year();   // 2003, 2004, 2005, 
  int second = second();  // Values from 0 - 59
  int minute = minute();  // Values from 0 - 59
  int hour = hour();  // Values from 0 - 23
  textSize(30);
  text("CST: "+year+"/"+month+"/"+day+" "+hour+":"+minute+":"+second, 1670, 190);
  text("Humidity: "+hum+"%", 1670, 230);
  text("Pressure: "+pres+"Pa", 1670, 270);
  text("Temperature: "+tempe+"°C", 1670, 310);
}

void controlPanel(){
  stroke(255, 255, 255);
  fill(36,36,36);
  rect(430, 610, 1340, 250, 20);
  noStroke();
  textSize(50);
  fill(255);
  text("Control Panel", 1250, 680);
}

void status_1(){
  fill(186,0,0);  
  rect(1330, 350, 380, 130, 20);
  textSize(50);
  fill(255);
  text("Failed", 1590, 430);
}

void statusbox(){
  fill(0,0,255);  
  rect(1330, 350, 380, 130, 20);
  textSize(50);
  fill(255);
  text("Status", 1590, 430);
}

void statusbox1(){
  fill(255,215,0);  
  rect(1330, 350, 380, 130, 20);
  textSize(50);
  fill(255);
  text("Checking", 1615, 430);
}

void statusbox2(){
  fill(255,215,0);  
  rect(1330, 350, 380, 130, 20);
  textSize(45);
  fill(255);
  text("Calibrate Gyro Accel", 1710, 430);
}

void statusbox3(){
  fill(76,187,23);  
  rect(1330, 350, 380, 130, 20);
  textSize(50);
  fill(255);
  text("Finished", 1610, 430);
}

void statusbox4(){
  fill(76,187,23);  
  rect(1330, 350, 380, 130, 20);
  textSize(50);
  fill(255);
  text("Stable", 1590, 430);
}


void statusbox8(){
  fill(57,255,20);  
  rect(1330, 350, 380, 130, 20);
  textSize(50);
  fill(255);
  text("Launch", 1600, 430);
}

void statusbox9(){
  fill(186,0,0);  
  rect(1330, 350, 380, 130, 20);
  textSize(42);
  fill(255);
  text("Landing successfully", 1700, 430);
}

// called each time the chart settings are changed by the user 
void setChartSettings() {
  LineGraph1.xLabel=" Time(ms) ";
  LineGraph1.yLabel="g";
  LineGraph1.Title="Accel Z";  
  LineGraph1.xDiv=5;  
  LineGraph1.xMax=0; 
  LineGraph1.xMin=-2000;  
  LineGraph1.yMax=int(getPlotterConfigString("lgMaxY1")); 
  LineGraph1.yMin=int(getPlotterConfigString("lgMinY1"));

  LineGraph2.xLabel=" Time(ms) ";
  LineGraph2.yLabel="degrees";
  LineGraph2.Title="Pitch";  
  LineGraph2.xDiv=5;  
  LineGraph2.xMax=0; 
  LineGraph2.xMin=-2000;  
  LineGraph2.yMax=int(getPlotterConfigString("lgMaxY2")); 
  LineGraph2.yMin=int(getPlotterConfigString("lgMinY2"));

  LineGraph3.xLabel=" Time(ms) ";
  LineGraph3.yLabel="degrees";
  LineGraph3.Title="Roll";  
  LineGraph3.xDiv=5;  
  LineGraph3.xMax=0; 
  LineGraph3.xMin=-2000;  
  LineGraph3.yMax=int(getPlotterConfigString("lgMaxY3")); 
  LineGraph3.yMin=int(getPlotterConfigString("lgMinY3"));

  LineGraph4.xLabel=" Time(ms) ";
  LineGraph4.yLabel="meter";
  LineGraph4.Title="Alttitude";  
  LineGraph4.xDiv=5;  
  LineGraph4.xMax=0; 
  LineGraph4.xMin=-2000;  
  LineGraph4.yMax=int(getPlotterConfigString("lgMaxY4")); 
  LineGraph4.yMin=int(getPlotterConfigString("lgMinY4"));

  LineGraph5.xLabel=" Time(ms) ";
  LineGraph5.yLabel="degrees";
  LineGraph5.Title="ServoXY";  
  LineGraph5.xDiv=5;  
  LineGraph5.xMax=0; 
  LineGraph5.xMin=-2000;  
  LineGraph5.yMax=int(getPlotterConfigString("lgMaxY5")); 
  LineGraph5.yMin=int(getPlotterConfigString("lgMinY5"));

  LineGraph6.xLabel=" Time(ms) ";
  LineGraph6.yLabel="degrees";
  LineGraph6.Title="PID X";  
  LineGraph6.xDiv=5;  
  LineGraph6.xMax=0; 
  LineGraph6.xMin=-2000;  
  LineGraph6.yMax=int(getPlotterConfigString("lgMaxY6")); 
  LineGraph6.yMin=int(getPlotterConfigString("lgMinY6"));

  LineGraph7.xLabel=" Time(ms) ";
  LineGraph7.yLabel="degrees";
  LineGraph7.Title="PID Y";  
  LineGraph7.xDiv=5;  
  LineGraph7.xMax=0; 
  LineGraph7.xMin=-2000;  
  LineGraph7.yMax=int(getPlotterConfigString("lgMaxY7")); 
  LineGraph7.yMin=int(getPlotterConfigString("lgMinY7"));
}
/*
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class)){
    String parameter = theEvent.getName();
    String value = "";
    if (theEvent.isAssignableFrom(Textfield.class)){
      value = theEvent.getStringValue();
      //serialnum[1] = value; 
      if (parameter == "posX"){
        //serialPort.write(value+':');
      }
      if (parameter == "posY"){
        //serialPort.write(value+';');
      }
    }
    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
  }
  setChartSettings();
}
*/
// get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}
