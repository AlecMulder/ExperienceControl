class Phonograph {
  private int lastCheckIn;
  private int playing = 0;
  private int volume = 15;
  private NetAddress address;
  private String addrPattern = "/Phonograph";
  private WaxCylinder loaded;
  private ArrayList<WaxCylinder> cylinders = new ArrayList<WaxCylinder>();
  private String filename = "Cylinders.txt";
  private int status;
  private int fillColor = 0;

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

  public void setvolume(int v) {
    if (v<=30 && v>=0) {
      if (address!=null) {
        OscMessage msg = new OscMessage(addrPattern+"/volume");
        msg.add(v);
        oscNet.send(msg, address);
        //println(v+" sent");
      }
    } else throw new IllegalArgumentException("index out of bounds");
  }

  public void saveCylinders() {
    String list[] = new String[cylinders.size()];
    for (int i = 0; i<cylinders.size(); i++) {
      list[i] = cylinders.get(i).id + " " + cylinders.get(i).fileNumber;
    }
    saveStrings(filename, list);
    println(cylinders.size() + " cylinders saved");
  }

  public void loadCylinders() {
    String[] lines = loadStrings(filename);
    for (int i = 0; i < lines.length; i++) {
      String[] data = split(lines[i], ' ');
      cylinders.add(new WaxCylinder(data[0], Integer.parseInt(data[1])));
      println("Added: " + data[0] + " " + data[1]);
    }
    println(cylinders.size() + " cylinders loaded");
    saveCylinders();
  }

  public void addCylinder(String id, int file) {
    cylinders.add(new WaxCylinder(id, file));
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
    fillColor = 255;
    lastCheckIn = millis();
    if (incoming.checkTypetag("ii")) {
      playing = incoming.get(0).intValue();
      volume = incoming.get(1).intValue();
    }
    if (incoming.checkTypetag("iii")) {
      playing = incoming.get(0).intValue();
      volume = incoming.get(1).intValue();
      try {
        loaded = findFile(incoming.get(2).intValue());
      }
      catch(Exception e) {
        println(e);
      }
    }

    if (address==null) 
      address = new NetAddress(incoming.address().substring(1), incoming.port());
  }

  public void draw(float x, float y) {
    noStroke();
    fill(fillColor);
    ellipse(width/2+20, height/2+20, 10, 10);
    if (fillColor>0)fillColor-=5;
    fill(255);
    text(toString(), x, y);
    if (address!=null && millis()-lastCheckIn>30000) 
      address = null;
  }

  public String toString() {
    if ((millis()-lastCheckIn)/1000>=2) 
      return getClass().getSimpleName() + "\nLast check in:\n" + ((millis()-lastCheckIn)/1000) + " Seconds" + "\nAddress:\n" + address;
    else if (loaded!=null)
      return getClass().getSimpleName() + "\nAddress:\n" + address + "\nLoaded: " + loaded.id + "\nPlaying: " + playing + "\nVolume: " + volume;
    else if (playing == 0)
      return getClass().getSimpleName() + "\nAddress:\n" + address + "\nPlaying" + "\nVolume: " + volume;
    else
      return getClass().getSimpleName() + "\nAddress:\n" + address + "\nStandby" + "\nVolume: " + volume;
  }
}