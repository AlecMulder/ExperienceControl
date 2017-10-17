class Phonograph {
  private int lastCheckIn;
  private int playing = 0;
  private int volume = 15;
  private NetAddress address;
  private String addrPattern = "/Phonograph";
  private WaxCylinder loaded;
  private ArrayList<WaxCylinder> cylinders = new ArrayList<WaxCylinder>();
  //private String filename = "data/Cylinders.txt";
  private String filename = "data/cylinders.json";
  private JSONArray jsonData;
  private color fillColor = color(0, 0, 0), 
    red = color(255, 0, 0), 
    green = color(0, 255, 0);
  private float batteryVoltage;
  private int currentFileNumber;

  Phonograph() {
    lastCheckIn = millis();
  }

  public String getAddrPattern() {
    return addrPattern;
  }

  public NetAddress getAddress() {
    return address;
  }

  public int getLastCheckIn() {
    return lastCheckIn;
  }

  public int getPlaying() {
    return playing;
  }

  public WaxCylinder getLoaded() {
    return loaded;
  }

  public int getVolume() {
    return volume;
  }

  public float getBattery() {
    return batteryVoltage;
  }

  public int getCurrentFileNumber() {
    return currentFileNumber;
  }

  private color fadeColorOut(color c, int inc) {
    if (red(c)>0)c = color(red(c)-inc, green(c), blue(c));
    if (green(c)>0)c = color(red(c), green(c)-inc, blue(c));
    if (blue(c)>0)c = color(red(c), green(c), blue(c)-inc);
    return c;
  }

  private void drawButtons(float x, float y) {
    stroke(100);

    if (mouseX <x-50+15 && mouseX>x-50-15 && mouseY < y+75+10 && mouseY > y+75-10) {
      if (mousePressed) {
        fill(64);
        setVolume(getVolume()-1);
        noLoop();
      } else {
        fill(32);
      }
    } else {
      noFill();
    }
    rect(x-50, y+75, 30, 20);
    fill(255);
    text("-", x-50, y+73);

    if (mouseX <x+25 && mouseX>x-25 && mouseY < y+75+10 && mouseY > y+75-10) {
      if (mousePressed) {
        fill(64);
        if (getPlaying()==0) stopPlaying();
        else {
          // TODO: a way to select file to play using mouse/touchscreen
        }
        noLoop();
      } else {
        fill(32);
      }
    } else {
      noFill();
    }
    rect(x, y+75, 50, 20);
    fill(255);
    if (getPlaying()==1) {
      text("play", x, y+73);
    } else {
      text("stop", x, y+73);
    }
    if (mouseX <x+50+15 && mouseX>x+50-15 && mouseY < y+75+10 && mouseY > y+75-10) {
      if (mousePressed) {
        fill(64);
        setVolume(getVolume()+1);
        noLoop();
      } else {
        fill(32);
      }
    } else {
      noFill();
    }
    rect(x+50, y+75, 30, 20);
    fill(255);
    text("+", x+50, y+73);
  }

  public void setVolume(int v) {
    if (v<=30 && v>=0) {
      if (address!=null) {
        OscMessage msg = new OscMessage(addrPattern+"/volume");
        msg.add(v);
        oscNet.send(msg, address);
      }
    } else throw new IllegalArgumentException("Volume must be between 0-30");
  }
  /**
   @depreciated
   
   public void saveCylinders() {
   String list[] = new String[cylinders.size()];
   for (int i = 0; i<cylinders.size(); i++) {
   list[i] = cylinders.get(i).id + " " + cylinders.get(i).name + " " + cylinders.get(i).fileNumber;
   }
   saveStrings(filename, list);
   println(cylinders.size() + " cylinders saved");
   }
   */
  public void saveCylinders() {
    if (jsonData.size()>0) {
      saveJSONArray(jsonData, filename);
      println(jsonData.size() + " cylinders saved");
    } else
      throw new IllegalArgumentException("No data to save!");
  }
  /**
   @depreciated
   
   public void loadCylindersString() {
   String[] lines = loadStrings(filename);
   for (int i = 0; i < lines.length; i++) {
   String[] data = split(lines[i], ' ');
   cylinders.add(new WaxCylinder(data[0], data[0], Integer.parseInt(data[2])));
   println("loaded: " + data[0] + " " + data[1] + " " + data[2]);
   }
   println(cylinders.size() + " cylinders loaded");
   saveCylinders();
   }
   */
  public void loadCylinders() {
    jsonData = loadJSONArray(filename);
    for (int i = 0; i<jsonData.size(); i++) {
      JSONObject cyl = jsonData.getJSONObject(i);
      String id = cyl.getString("id");
      String filename = cyl.getString("name");
      int fileNumber = cyl.getInt("file");
      cylinders.add(new WaxCylinder(id, filename, fileNumber));
    }
    println(cylinders.size() + " cylinders loaded");
    saveCylinders();
  }

  public void addCylinder(String id, String name, int file) {
    JSONObject add = new JSONObject();
    add.setString("id", id);
    add.setString("name", name);
    add.setInt("file", file);
    jsonData.setJSONObject(jsonData.size(), add);

    cylinders.add(new WaxCylinder(id, name, file));
    saveCylinders();
  }

  public WaxCylinder findFile(int file) throws Exception {
    for (int i = 0; i<cylinders.size(); i++) {
      if (file == cylinders.get(i).fileNumber) {
        return cylinders.get(i);
      }
    }
    throw new FileNotFoundException("Cylinder does not exist");
  }

  public WaxCylinder findName(String name) throws Exception {
    for (int i = 0; i<cylinders.size(); i++) {
      if (name.equals(cylinders.get(i).name)) {
        return cylinders.get(i);
      }
    }
    throw new FileNotFoundException("Cylinder does not exist");
  }

  public WaxCylinder findID(String id) throws Exception {
    for (int i = 0; i<cylinders.size(); i++) {
      if (id.equals(cylinders.get(i).id)) {
        return cylinders.get(i);
      }
    }
    throw new FileNotFoundException("Cylinder does not exist");
  }

  public void startPlayingFile(int file) {
    try {
      WaxCylinder temp = findFile(file);
      OscMessage msg = new OscMessage(addrPattern+"/play");
      msg.add(temp.fileNumber);
      oscNet.send(msg, address);
    }
    catch(Exception e) {
      println(e);
    }
  }

  public void playFile(int file) {

    OscMessage msg = new OscMessage(addrPattern+"/play");
    msg.add(file);
    oscNet.send(msg, address);
  }

  public void stopPlaying() {
    OscMessage msg = new OscMessage(addrPattern+"/stop");
    oscNet.send(msg, address);
  }

  public void update(OscMessage incoming) {
    //println(incoming);
    lastCheckIn = millis();
    if (incoming.checkTypetag("iifi")) {
      playing = incoming.get(0).intValue();
      volume = incoming.get(1).intValue();
      batteryVoltage = incoming.get(2).floatValue();
      currentFileNumber = incoming.get(3).intValue();
      if (batteryVoltage>4.3) fillColor = color(0, 0, 255);
      else fillColor = lerpColor(red, green, map(batteryVoltage, 3, 4.2, 0, 1));
      /*try {
       loaded = findFile(incoming.get(2).intValue());
       }
       catch(Exception e) {
       println(e);
       }
       */
    } else if (incoming.checkTypetag("c")) {
      try {
        loaded = findID(incoming.get(0).stringValue());
      }
      catch (Exception e) {
        println(e);
      }
    } else {
      throw new NullPointerException("No method written to recive data type");
    }

    if (address==null) 
      address = new NetAddress(incoming.address().substring(1), incoming.port());
  }

  public void draw(float x, float y) {
    noStroke();
    fill(fillColor);
    ellipse(width/2+20, height/2+20, 10, 10);

    fillColor = fadeColorOut(fillColor, 5);

    if (fillColor>0)fillColor-=5;

    if (address != null)
      drawButtons(x, y);

    if (batteryVoltage<3.2&& address!=null)
      fill(255, 0, 0);
    else if (address==null)
      fill(150);
    else
      fill(255);

    text(toString(), x, y);

    if (address!=null && millis()-lastCheckIn>30000) 
      address = null;
  }

  public String toString() {
    String batteryStatus;
    if (batteryVoltage>4.3)
      batteryStatus = "Battery: Charging";
    else
      batteryStatus = "Voltage: " + String.format("%.1f", batteryVoltage);
    if ((millis()-lastCheckIn)/1000>=5 && address!=null) 
      return getClass().getSimpleName() + "\nLast check in:\n" + ((millis()-lastCheckIn)/1000) + " Seconds" + "\n" + address.address();
    else if (loaded!=null  && address!=null)
      return getClass().getSimpleName() + "\n" + address.address() + "\n"+ batteryStatus+ "\nLoaded: " + loaded.name + "\nPlaying: " + playing + "\nVolume: " + volume;
    else if (playing == 0  && address!=null)
      return getClass().getSimpleName() + "\n" + address.address() + "\n"+ batteryStatus+ "\nPlaying" + "\nVolume: " + volume;
    else if (address==null) 
      return getClass().getSimpleName()+"\nWaiting for\nConnection";
    else
      return getClass().getSimpleName() + "\n" + address.address() + "\n"+ batteryStatus+ "\nStandby" + "\nVolume: " + volume;
  }
}