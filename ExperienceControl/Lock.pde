class Lock {
  private int lastCheckIn;
  private PImage lockedIm, unlockedIm;
  private int unlocked; //0=locked  1=unlocked
  private NetAddress address;
  private String addrPattern = "/lock";
  private int fillColor = 0;

  public Lock() {
    lastCheckIn = millis();
    unlocked = 0;
    lockedIm = loadImage("locked.png");
    unlockedIm = loadImage("unlocked.png");
  }

  public String getAddrPattern() {
    return addrPattern;
  }

  public int getLockedStatus() {
    return unlocked;
  }

  public int getLastCheckIn() {
    return lastCheckIn;
  }

  public NetAddress getAddress() {
    return address;
  }

  public void update(OscMessage incoming) {
    fillColor = 255;
    lastCheckIn = millis();
    if (address==null) {
      address = new NetAddress(incoming.address().substring(1), incoming.port());
    }
    unlocked = incoming.get(0).intValue();
  }

  public void lock() {
    if (address!=null) {
      OscMessage msg = new OscMessage(addrPattern);
      msg.add(0);
      oscNet.send(msg, address);
      println("lock");
    } else {
      throw new NullPointerException();
    }
  }

  public void unlock() {
    if (address!=null) {
      OscMessage msg = new OscMessage(addrPattern);
      msg.add(1);
      oscNet.send(msg, address);
      println("sent to: " +address);
    } else {
      throw new NullPointerException();
    }
  }

  public void draw(float x, float y) {
    noStroke();
    fill(fillColor);
    ellipse(width/2-20, height/2+20, 10, 10);
    if (fillColor>0)fillColor-=5;
    fill(255);
    text(toString(), x, y);
    if (address!=null && millis()-lastCheckIn>30000) 
      address = null;
  }

  public String toString() {
    String status = "unknown";
    if (unlocked == 0) {
      status = "locked";
    }
    if (unlocked == 1) {
      status = "unlocked";
    }
    if ((millis()-lastCheckIn)/1000>=5) return getClass().getSimpleName() + "\nLast check in:\n" + ((millis()-lastCheckIn)/1000) + " Seconds" + "\nAddress:\n" + address;
    return getClass().getSimpleName() + "\nAddress:\n" + address + "\nstatus: " + status;
  }
}