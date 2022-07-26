#include <Wire.h>
#include "BlueDot_BME280.h"
#include "I2Cdev.h"
#include "MPU6050_6Axis_MotionApps20.h"
#include <PWMServo.h>
#include <SPI.h>
#include <RH_RF69.h>
#include <SD.h>
#include <buzzer.h>
//22 tvc down 23 tvc up
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
#include "Wire.h"
#endif

#define RFM69_HW
#define RFM69_RST     0
#define RFM69_CS      9
#define RFM69_INT     digitalPinToInterrupt(2)  // only pins 0, 1, 2 allowed
#define RF69_FREQ     433.0
RH_RF69 rf69(RFM69_CS,RFM69_INT);
BlueDot_BME280 bme280 = BlueDot_BME280();
MPU6050 mpu;
PWMServo myservo; // create servo object to control a servo
PWMServo myservo1;

#define INTERRUPT_PIN 2 // use pin 2 on Arduino Uno & most boards

// MPU control/status vars
bool dmpReady = false;  // set true if DMP init was successful
uint8_t mpuIntStatus;   // holds actual interrupt status byte from MPU
uint8_t devStatus;      // return status after each device operation (0 = success, !0 = error)
uint16_t packetSize;    // expected DMP packet size (default is 42 bytes)
uint16_t fifoCount;     // count of all bytes currently in FIFO
uint8_t fifoBuffer[64]; // FIFO storage buffer

Quaternion q;        // [w, x, y, z]         quaternion container
VectorFloat gravity; // [x, y, z]            gravity vector
float ypr[3];        // [yaw, pitch, roll]   yaw/pitch/roll container and gravity vector
int16_t ax, ay, az;
int16_t gx, gy, gz;

// sd card
const int chipSelect = 10;
const char filename[] = "datalog.txt";
File myFile;
//string to buffer output
String dataBuffer;

// servo
int posX = 0;
int posY = 0;
float servoalignmentX = 95;
float servoalignmentY = 0;
float servoflex = 25;

// LED light
int LED = 4;
int LED2 = 5;
int LED3 = 6;

// PID var
float PIDX, PIDY, error_X, error_Y;
float pidX_p, pidX_i, pidX_d, pidY_p, pidY_i, pidY_d, pidXP, pidYP;
float perror_X = 0; // p == previous
float perror_Y = 0;
float setangleX = 0;
float setangleY = 0;
float kp = 0.55;
float ki = 0.25;
float kd = 0.085;
float tau = 0.07; 
float maxAngle = 15;
float iLimitX = 0;
float iLimitY = 0;
uint32_t timer;   // count dt

// settings
int status2 = 0; // ground reciver send back message 0 = normal mode 2 = check mode 3 = calibrate mode 1 = launch mode 4 = landing mode 
int Status = 0; // 5 = finished 1 = land 2 = launch 6 = stable
int status1 = 0; // keep running launch until hit
int millis1;
int millis2;
int millis3;
int count1 = 0;
char * status5;


int times;


volatile bool mpuInterrupt = false; // indicates whether MPU interrupt pin has gone high

void dmpDataReady()
{
  mpuInterrupt = true;
}

void servoX(int posX)
{
  myservo.write(posX); // tell servo to go to position in variable 'posX'
}

void servoY(int posY)
{
  myservo1.write(posY); // tell servo to go to position in variable 'posY'
}

void setup()
{
  #if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
    Wire.begin();
  #elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
    Fastwire::setup(400, true);
  #endif
  Serial.begin(115200);
  //catkeymusic();

  // LED light
  pinMode(LED, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);

  // SERVO
  myservo.attach(22);
  myservo1.attach(23);

  myservo1.write(servoalignmentY);
  delay(15);
  myservo.write(servoalignmentX);
  delay(15);

  //  MPU 6050--------------------------------------------------
  // initialize device
  Serial.println("Initializing I2C devices...");
  mpu.initialize();
  pinMode(INTERRUPT_PIN, INPUT);

  // verify connection
  Serial.println("Testing device connections...");
  Serial.println(mpu.testConnection() ? "MPU6050 connection successful" : "MPU6050 connection failed");

  // BME280

  bme280.parameter.communication = 0;          // Choose communication protocol
  bme280.parameter.I2CAddress = 0x76;          // Choose I2C Address
  bme280.parameter.sensorMode = 0b11;          // Choose sensor mode
  bme280.parameter.IIRfilter = 0b100;          // Setup for IIR Filter
  bme280.parameter.humidOversampling = 0b101;  // Setup Humidity Oversampling
  bme280.parameter.tempOversampling = 0b101;   // Setup Temperature Ovesampling
  bme280.parameter.pressOversampling = 0b101;  // Setup Pressure Oversampling
  bme280.parameter.pressureSeaLevel = 1013.25; // default value of 1013.25 hPa
  bme280.parameter.tempOutsideCelsius = 15;    // default value of 15°C

  if (bme280.init() != 0x60)
  {
    Serial.println(F("Ops! BME280 could not be found!"));
    Serial.println(F("Please check your connections."));
    Serial.println();
    musicdied();
    while (1)
      ;
  }

  else
  {
    Serial.println(F("BME280 detected!"));
  }

  // load and configure the DMP
  Serial.println(F("Initializing DMP..."));
  devStatus = mpu.dmpInitialize();

  // supply your own gyro offsets here, scaled for min sensitivity
  mpu.setXGyroOffset(220);
  mpu.setYGyroOffset(76);
  mpu.setZGyroOffset(-85);
  mpu.setZAccelOffset(1788);

  // make sure it worked (returns 0 if so)
  if (devStatus == 0)
  {
    // Calibration Time: generate offsets and calibrate our MPU6050
    mpu.CalibrateAccel(6);
    mpu.CalibrateGyro(6);
    mpu.PrintActiveOffsets();
    // turn on the DMP, now that it's ready
    Serial.println(F("Enabling DMP..."));
    mpu.setDMPEnabled(true);

    // enable Arduino interrupt detection
    Serial.print(F("Enabling interrupt detection (Arduino external interrupt "));
    Serial.print(digitalPinToInterrupt(INTERRUPT_PIN));
    Serial.println(F(")..."));
    attachInterrupt(digitalPinToInterrupt(INTERRUPT_PIN), dmpDataReady, RISING);
    mpuIntStatus = mpu.getIntStatus();

    // set our DMP Ready flag so the main loop() function knows it's okay to use it
    Serial.println(F("DMP ready! Waiting for first interrupt..."));
    dmpReady = true;

    // get expected DMP packet size for later comparison
    packetSize = mpu.dmpGetFIFOPacketSize();
  }
  else
  {
    // ERROR!
    // 1 = initial memory load failed
    // 2 = DMP configuration updates failed
    // (if it's going to break, usually the code will be 1)
    Serial.print(F("DMP Initialization failed (code "));
    Serial.print(devStatus);
    Serial.println(F(")"));
    musicdied();
  }

  //pinMode(10, OUTPUT);
 // pinMode(9, OUTPUT);
  //digitalWrite(10, LOW);

  //digitalWrite(9, HIGH);

  
  //sd card
  /*
  dataBuffer.reserve(2048);
  if (!SD.begin(chipSelect)) {
    Serial.println("initialization failed. Things to check:");
    Serial.println("1. is a card inserted?");
    Serial.println("2. is your wiring correct?");
    Serial.println("3. did you change the chipSelect pin to match your shield or module?");
    Serial.println("Note: press reset or reopen this Serial Monitor after fixing your issue!");
    while (true);
  }
*/
  digitalWrite(10, HIGH);
  

  //For Teensy 3.x and T4.x the following format is required to operate correctly
  pinMode(RFM69_RST, OUTPUT);
  digitalWrite(RFM69_RST, LOW);
  // manual reset
  digitalWrite(RFM69_RST, HIGH);
  delay(100);
  digitalWrite(RFM69_RST, LOW);
  delay(100);
  
  if (!rf69.init()){
    Serial.println("init failed");
    musicdied();
  }
  // Defaults after init are 434.0MHz, modulation GFSK_Rb250Fd250, +13dbM
  // No encryption
  if (!rf69.setFrequency(433.0)){
    Serial.println("setFrequency failed");
    musicdied();
  }
  // If you are using a high power RF69, you *must* set a Tx power in the
  // range 14 to 20 like this:
  rf69.setTxPower(16, true);

  // The encryption key has to be the same as the one in the server
  uint8_t key[] = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
                    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
  rf69.setEncryptionKey(key);

  // LED light turn RED
  digitalWrite(LED, LOW);
  digitalWrite(LED2, LOW);
  digitalWrite(LED3, HIGH);
  delay(1000);                
  digitalWrite(LED, LOW);
  digitalWrite(LED2, LOW);
  digitalWrite(LED3, LOW);
  //musicdied();
  //musicpirates();
  //starwarsmusic();
  //rickrollmusic();
  //supermario();
  //pinkmusic();
}

void loop()
{

  if (status2 == 0 || status2 == 1 || status2 == 4){
    // mpu6050
    mpu.dmpGetCurrentFIFOPacket(fifoBuffer);
    // display Euler angles in degrees
    mpu.dmpGetQuaternion(&q, fifoBuffer);
    mpu.dmpGetGravity(&gravity, &q);
    mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);
    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

    // data
    float accelz = float((az * 0.061 / 1000) - 1);
    int roll = ypr[2] * 180 / M_PI;
    int pitch = ypr[1] * 180 / M_PI;
    int alttitude = bme280.readAltitudeMeter();
    int humidity = bme280.readHumidity();
    int pressure = bme280.readPressure();
    int temper = bme280.readTempC();
    if (status2 == 1){
      posX = posX - servoalignmentX;
      posY = posY - servoalignmentY;
    }

    millis2 = millis();
    // send data
    
    char buffer[50];
    int nouse = 8;
    sprintf(buffer, "%.1f:%d:%d:%d:%d:%d:%d:%d:%d:%.1f:%.1f:%d:%d:%d", accelz, pitch, roll, alttitude, posX, posY, humidity, pressure, temper, PIDX, PIDY, Status, millis2, nouse);  
    rf69.send((uint8_t *)buffer, sizeof(buffer));
    rf69.waitPacketSent();

    int millis5 = millis();
    if (millis5 > millis1+500 && status2 != 1){
      Status = 0;
    }

    uint8_t buf[RH_RF69_MAX_MESSAGE_LEN];
    uint8_t len = sizeof(buf);
    if (rf69.waitAvailableTimeout(10))
    { 
      // Should be a reply message for us now  
      if (status1 == 0){ 
        if (rf69.recv(buf, &len)){
          status2 = atoi((char *)buf);
        }
      }
    }
    // LED light turn GREEN
    digitalWrite(LED, LOW);
    digitalWrite(LED2, HIGH);
    digitalWrite(LED3, LOW);
  }

  //check mode
  if (status2 == 2){

    digitalWrite(LED, LOW);
    digitalWrite(LED2, HIGH);
    digitalWrite(LED3, HIGH);
    delay(1000);
    musicpirates();


    // X axis
    for (posX = servoalignmentX-servoflex; posX <= servoalignmentX+servoflex; posX += 1) { 
      // in steps of 1 degree
      myservo.write(servoalignmentX+servoflex);              
      delay(20);                      
    }
    myservo.write(servoalignmentX+servoflex);
    delay(1000);
    for (posX = servoalignmentX+servoflex; posX >= servoalignmentX-servoflex; posX -= 1) { 
      myservo.write(posX);   
      delay(20); 
    }
    myservo.write(servoalignmentX-servoflex);
    delay(1000);
    myservo.write(servoalignmentX); 
    delay(1000);

    // Y axis
    for (posY = servoalignmentY-servoflex; posY <= servoalignmentY+servoflex; posY += 1) { 
      // in steps of 1 degree
      myservo1.write(posY);            
      delay(20);                      
    }
    myservo1.write(servoalignmentY+servoflex);
    delay(1000);
    for (posY = servoalignmentY+servoflex; posY >= servoalignmentY-servoflex; posY -= 1) { 
      myservo1.write(posY);   
      delay(20);
    }
    myservo1.write(servoalignmentY-servoflex);
    delay(1000);

    // set back to center
    posX = servoalignmentX;
    posY = servoalignmentY;
    myservo.write(posX);
    myservo1.write(posY);

    posX = 0;
    posY = 0;
    delay(1000);
    status2 = 0;
    millis1 = millis();
    Status = 5;
  }

  if (status2 == 3){
    rickrollmusic();
    mpu.CalibrateAccel(6);
    mpu.CalibrateGyro(6);
    delay(5000);
    status2 = 0;
    millis1 = millis();
    Status = 5;
  }


  //test
  if (status2 == 4){
    mpu.dmpGetCurrentFIFOPacket(fifoBuffer);
    // display Euler angles in degrees
    mpu.dmpGetQuaternion(&q, fifoBuffer);
    mpu.dmpGetGravity(&gravity, &q);
    mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);
    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

    int roll = ypr[2] * 180 / M_PI;   //  define roll
    int pitch = ypr[1] * 180 / M_PI;  //  define pitch

    // PID controller------------------------------------------

    double dt = (double)(micros() - timer) / 1000000; // count time
    timer = micros();

    // set error
    error_X = pitch - setangleX; 
    error_Y = roll - setangleY;

    // define Proportional term
    pidX_p = kp * error_X;
    pidY_p = kp * error_Y;

    // define Derivative term
    pidX_d = (2 * kd * (error_X - perror_X) + (2 * tau - dt) * pidX_d) / (2 * tau + dt);
    pidY_d = (2 * kd * (error_Y - perror_Y) + (2 * tau - dt) * pidY_d) / (2 * tau + dt);

    // define Integal term
    pidX_i += ki * dt * error_X;
    pidY_i += ki * dt * error_Y;

    // limit
    pidXP = pidX_p;
    pidYP = pidY_p;

    if (pidXP > maxAngle) {
      pidXP = maxAngle;
    }
    if (pidXP < maxAngle * -1){
      pidXP = maxAngle * -1;
    }
    if (pidYP > maxAngle) {
      pidYP = maxAngle;
    }
    if (pidYP < maxAngle * -1){
      pidYP = maxAngle * -1;
    }
    
    if (pidX_p > 0){
      iLimitX = maxAngle - pidXP;
    }
    if (pidX_p < 0){
      iLimitX = maxAngle + pidXP;
    }
    if (pidY_p > 0){
      iLimitY = maxAngle - pidYP;
    }
    if (pidY_p < 0){
      iLimitY = maxAngle + pidYP;
    }

    if (pidX_i > iLimitX){
      pidX_i = iLimitX;
    }
    if (pidX_i < iLimitX * -1){
      pidX_i = iLimitX * -1;
    }
    if (pidY_i > iLimitY){
      pidY_i = iLimitY;
    }
    if (pidY_i < iLimitY * -1){
      pidY_i = iLimitY * -1;
    }

    perror_X = error_X; // define previous error X
    perror_Y = error_Y; // define previous error Y


    // sum 3 pid values
    PIDX = pidX_p + pidX_i + pidX_d; 
    PIDY = pidY_p + pidY_i + pidY_d;
    // turn pid value to servo value
    posX = PIDX * 2 + servoalignmentX;
    posY = PIDY * 2 + servoalignmentY;

    

    // set servo X maximum
    if (posX > servoalignmentX + servoflex)
    {
      posX = servoalignmentX + servoflex;
    }

    if (posX < servoalignmentX - servoflex)
    {
      posX = servoalignmentX - servoflex;
    }

    // set servo Y maximum
    if (posY > servoalignmentY + servoflex)
    {
      posY = servoalignmentY + servoflex;
    }

    if (posY < servoalignmentY - servoflex)
    {
      posY = servoalignmentY - servoflex;
    }

    servoX(posX);
    servoY(posY);

    if (times == 0){
      setangleY = 10;
    }

    if (roll == 10 && times == 0){
      times = 1;
      setangleY = -10;
    }

    if (roll == -10 && times == 1){
      times = 2;
      setangleY = 0;
      setangleX = 10;
    } 
    if (pitch == 10 && times == 2){
      times = 3;
      setangleX = -10;
    } 
    if (pitch == -10 && times == 3){
      setangleX = 0;
      times = 0;
      Status = 5;
      status2 = 0;
    } 
  }


  //launch mode
  if (status2 == 1){
    mpu.dmpGetCurrentFIFOPacket(fifoBuffer);
    // display Euler angles in degrees
    mpu.dmpGetQuaternion(&q, fifoBuffer);
    mpu.dmpGetGravity(&gravity, &q);
    mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);
    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

    int roll = ypr[2] * 180 / M_PI;   //  define roll
    int pitch = ypr[1] * 180 / M_PI;  //  define pitch

    // PID controller------------------------------------------

    double dt = (double)(micros() - timer) / 1000000; // count time
    timer = micros();

    // set error
    error_X = pitch - setangleX; 
    error_Y = roll - setangleY;

    // define Proportional term
    pidX_p = kp * error_X;
    pidY_p = kp * error_Y;

    // define Derivative term
    pidX_d = (2 * kd * (error_X - perror_X) + (2 * tau - dt) * pidX_d) / (2 * tau + dt);
    pidY_d = (2 * kd * (error_Y - perror_Y) + (2 * tau - dt) * pidY_d) / (2 * tau + dt);

    // define Integal term
    pidX_i += ki * dt * error_X;
    pidY_i += ki * dt * error_Y;

    // limit
    pidXP = pidX_p;
    pidYP = pidY_p;

    if (pidXP > maxAngle) {
      pidXP = maxAngle;
    }
    if (pidXP < maxAngle * -1){
      pidXP = maxAngle * -1;
    }
    if (pidYP > maxAngle) {
      pidYP = maxAngle;
    }
    if (pidYP < maxAngle * -1){
      pidYP = maxAngle * -1;
    }
    
    if (pidX_p > 0){
      iLimitX = maxAngle - pidXP;
    }
    if (pidX_p < 0){
      iLimitX = maxAngle + pidXP;
    }
    if (pidY_p > 0){
      iLimitY = maxAngle - pidYP;
    }
    if (pidY_p < 0){
      iLimitY = maxAngle + pidYP;
    }

    if (pidX_i > iLimitX){
      pidX_i = iLimitX;
    }
    if (pidX_i < iLimitX * -1){
      pidX_i = iLimitX * -1;
    }
    if (pidY_i > iLimitY){
      pidY_i = iLimitY;
    }
    if (pidY_i < iLimitY * -1){
      pidY_i = iLimitY * -1;
    }

    perror_X = error_X; // define previous error X
    perror_Y = error_Y; // define previous error Y


    // sum 3 pid values
    PIDX = pidX_p + pidX_i + pidX_d; 
    PIDY = pidY_p + pidY_i + pidY_d;
    // turn pid value to servo value
    posX = PIDX * 2 + servoalignmentX;
    posY = PIDY * 2 + servoalignmentY;

    

    // set servo X maximum
    if (posX > servoalignmentX + servoflex)
    {
      posX = servoalignmentX + servoflex;
    }

    if (posX < servoalignmentX - servoflex)
    {
      posX = servoalignmentX - servoflex;
    }

    // set servo Y maximum
    if (posY > servoalignmentY + servoflex)
    {
      posY = servoalignmentY + servoflex;
    }

    if (posY < servoalignmentY - servoflex)
    {
      posY = servoalignmentY - servoflex;
    }

    servoX(posX);
    servoY(posY);


    float accelz = float((az * 0.061 / 1000) - 1);
    status1 = 1;
    int millis4 = millis();
    if (pitch <= 1 && pitch >= -1 && roll <= 1 && roll >= -1 && millis4 >= millis3+5000){
      Status = 6;
    }else{
      Status = 2;
    }
    
    if (count1 == 0){
      millis3 = millis();
      count1 = 1;
    }

    
    // sd card
    dataBuffer += accelz;
    dataBuffer += ",";
    dataBuffer += millis2;
    dataBuffer += ",";
    dataBuffer += pitch;
    dataBuffer += ",";
    dataBuffer += roll;
    dataBuffer += ",";
    dataBuffer += posX;
    dataBuffer += ",";
    dataBuffer += posY;
    dataBuffer += ",";
    dataBuffer += PIDX;
    dataBuffer += ",";
    dataBuffer += PIDY;
    dataBuffer += "\r\n";
/*
    // check if the SD card is available to write data without blocking
    // and if the dataBuffered data is enough for the full chunk size
    unsigned int chunkSize = myFile.availableForWrite();
    if (chunkSize && dataBuffer.length() >= chunkSize) {
      myFile.write(dataBuffer.c_str(), chunkSize);
      // remove written data from dataBuffer
      dataBuffer.remove(0, chunkSize);
    }
    
*/
    if (accelz < -1.5){
      Status = 1;
      status2 = 0;
      status1 = 0;
      millis1 = millis();
      count1 = 0;
      posX = 0;
      posY = 0;
    }
  }
  delay(10);
  }