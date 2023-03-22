/**
 * oscP5message by andreas schlegel
 * example shows how to create osc messages.
 * oscP5 website at http://www.sojamo.de/oscP5
 */
 
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

void setup() {
  size(400,400);
  frameRate(25);
    
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,12301);
  
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  myRemoteLocation = new NetAddress("127.0.0.1",12300);
  
  PrintMenu(1);
  int commandId = getInt("Enter command to be send by OSC");
  SendOSCMessage(commandId);
}


void draw() {
  background(0);  
}

//SENDER

void keyPressed() {

  if (key == ' ') {      
    int commandId = getInt("Enter command to be send by OSC");
    SendOSCMessage(commandId);
  }

}

void SendOSCMessage(int commandID) { 
  OscMessage myMessage = new OscMessage(""); 
  myMessage = GetV1Message(commandID);
  oscP5.send(myMessage, myRemoteLocation); 
}

OscMessage GetV1Message(int commandID) {  
  String brt_base ="/"; 
  String brt_source_base ="/source/";
   
   OscMessage myMessage = new OscMessage("");    
   if (commandID == 0) {   
     myMessage = new OscMessage(brt_base +"ECG");
     myMessage.add("hola dani");
     myMessage.add(12.12);
  }
  else if (commandID == 1) {      
    myMessage = new OscMessage(brt_base +"play");    
  } 
  else if (commandID == 2) {    
    myMessage = new OscMessage(brt_base +"pause");    
  }
  else if (commandID == 3) {    
    myMessage = new OscMessage(brt_base +"stop");    
  }
  else if (commandID == 4) {    
    myMessage = new OscMessage(brt_base +"loadHRTF");
    myMessage.add("HRTFNULL");
    myMessage.add("resources//8_UMA_NULL_S_HRIR_power_adjusted.sofa");    
  }  
  else if (commandID == 5) {    
    myMessage = new OscMessage(brt_base +"playAndRecord");
    //myMessage.add("G:\\Repos\\matfile");
    myMessage.add("record\\testmatfile.mat");
    myMessage.add("mat");
    myMessage.add(5);
  }
  
  else if (commandID == 10) {    
    myMessage = new OscMessage(brt_source_base +"loadSource");
    myMessage.add("soundSource_1");
    myMessage.add("resources//speech_male.wav");
  }
  else if (commandID == 11) {    
    myMessage = new OscMessage(brt_source_base +"removeSource");
    myMessage.add("soundSource_1");    
  }
  else if (commandID == 12) {      
    myMessage = new OscMessage(brt_source_base +"play");
    myMessage.add("soundSource_1");    
  }   
  else if (commandID == 13) {      
    myMessage = new OscMessage(brt_source_base +"pause");
    myMessage.add("soundSource_1");    
  }   
  else if (commandID == 14) {      
    myMessage = new OscMessage(brt_source_base +"stop");
    myMessage.add("soundSource_1");    
  } 
  else if (commandID == 15) {      
    myMessage = new OscMessage(brt_source_base +"mute");
    myMessage.add("soundSource_1");        
  } 
  else if (commandID == 16) {      
    myMessage = new OscMessage(brt_source_base +"unmute");
    myMessage.add("soundSource_1");        
  } 
  else if (commandID == 17) {      
    myMessage = new OscMessage(brt_source_base +"solo");
    myMessage.add("soundSource_1");
    //myMessage.add("DefaultSoundSource");
  } 
  else if (commandID == 18) {      
    myMessage = new OscMessage(brt_source_base +"unsolo");
    myMessage.add("soundSource_1");        
  }   
  else if (commandID == 19) {      
    myMessage = new OscMessage(brt_source_base +"loop");
    myMessage.add("soundSource_1");    
    myMessage.add(false);
  }
  else if (commandID == 20) {      
    myMessage = new OscMessage(brt_source_base +"loop");
    myMessage.add("soundSource_1");    
    myMessage.add(true);
  }     
  else if (commandID == 21) {      
    myMessage = new OscMessage(brt_source_base +"gain");
    myMessage.add("soundSource_1");    
    myMessage.add(-10);
  } 
  
  else if (commandID == 22) {      
    myMessage = new OscMessage(brt_source_base +"location");
    myMessage.add("DefaultSoundSource");    
    myMessage.add(0);
    myMessage.add(0.1);
    myMessage.add(0);
  } 
  else if (commandID == 23) {      
    myMessage = new OscMessage(brt_source_base +"location");
    myMessage.add("soundSource_1");    
    myMessage.add(4);
    myMessage.add(5);
    myMessage.add(6); 
  } 
  
  else if (commandID == 30) {      
    myMessage = new OscMessage(brt_base +"listener/location");
    myMessage.add("listener1");
    myMessage.add(0);
    myMessage.add(0);
    myMessage.add(0);
  } 
    
  else if (commandID == 31) {      
    myMessage = new OscMessage(brt_base +"listener/orientation");
    myMessage.add("listener1");
    myMessage.add(1.5707963267); // 1.5707963267
    myMessage.add(0.78539816);
    myMessage.add(1.5707963267);
  } 
  else if (commandID == 32) {      
    myMessage = new OscMessage(brt_base +"listener/setHRTF");
    myMessage.add("LISTENER1");
    myMessage.add("HRTFNULL");
  } 
    else if (commandID == 33) {      
    myMessage = new OscMessage(brt_base +"listener/enableSpatialization");
    myMessage.add("LISTENER1");    
    myMessage.add(true);    
  } 
  else if (commandID == 34) {      
    myMessage = new OscMessage(brt_base +"listener/enableInterpolation");
    myMessage.add("LISTENER1");    
    myMessage.add(true);    
  } 
  else if (commandID == 35) {      
    myMessage = new OscMessage(brt_base +"listener/enableNearFiedlEffect");
    myMessage.add("LISTENER1");    
    myMessage.add(true);    
  } 
   else if (commandID == 36) {      
    myMessage = new OscMessage(brt_base +"listener/enableNearFiedlEffect");
    myMessage.add("LISTENER1");    
    myMessage.add(true);    
  } 
  
    else if (commandID == 99) {      
    myMessage = new OscMessage(brt_base +"nofunciono");    
  } 
  println(myMessage); 
  
  return myMessage;
  
}



// RECEIVER

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  //print(" addrpattern: "+theOscMessage.addrPattern());
  //println(" typetag: "+theOscMessage.typetag());
  //print(theOscMessage.addrPattern());
  //theOscMessage.print();
  println(theOscMessage.toString());
  //println(theOscMessage.get(0).floatValue());
}

// Others
void PrintMenu(int commandVersion) { 
  if (commandVersion == 1){    
    //DEPRECATED:
    //println("0  /loadSource(v2)");
    //println("1  /play");
    //println("2  /pause");
    //println("3  /stop");  
    //println("4  /record");  
    //println("5  /loadSoundscape");
    //println("6  /source<X>  /play");  
    //println("7  /source<X>  /pause");
    //println("8  /source<X>  /stop");  
    //println("9  /source<X>  /mute");
    //println("10  /source<X>  /solo");
    //println("11  /source<X>  /loop");
    ////println("12  /source<X>  /seek  /seconds");
    ////println("13  /source<X>  /seek  /position");
    //// println("14  /source<X>  /gain");
    //// println("15  /source<X>  /location");
    //println("160  /source<X>  /anechoic  /enable OFF");
    //println("161  /source<X>  /anechoic  /enable ON");
    //println("170  /source<X>  /anechoic  /spatialisationMode 0");
    //println("171  /source<X>  /anechoic  /spatialisationMode 1");
    //println("172  /source<X>  /anechoic  /spatialisationMode 2");
    //println("180  /source<X>  /anechoic  /nearfield OFF");
    //println("181  /source<X>  /anechoic  /nearfield ON");
    //println("190  /source<X>  /anechoic  /farfield OFF");
    //println("191  /source<X>  /anechoic  /farfield ON");
    //println("200  /source<X>  /anechoic  /distance OFF");
    //println("201  /source<X>  /anechoic  /distance ON");
    //println("210  /source<X>  /environment  /enable OFF");
    //println("211  /source<X>  /environment  /enable ON");
    //println("220  /source<X>  /environment  /distance OFF");
    //println("221  /source<X>  /environment  /distance ON");
    //println("23  /anechoic  /attenuation");
    //println("24  /environment  /attenuation");
    //println("25  /environment  /loadBRIR");  
    //println("26  /environment  /order");  
    //println("27  /environment  /gain");  
    //println("28  /listener  /location");  
    //println("29  /listener  /orientation");  
    //println("30  /listener  /loadHRTF");
    //println("31  /HL  /left  /enable");
    //println("32  /HL  /right  /enable");
    //println("33  /HA  /left  /enable");
    //println("34  /HA  /right  /enable");
    //println("35  /environment /room");
    //println("36  /environment /ism  /order");
    //println("37  /environment /ism  /absorption");
    //println("38  /environment /sdn  /walltype");
    //println("39  /source<X>   /environment /type");
  }  
}
