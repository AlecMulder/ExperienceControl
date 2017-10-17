class Lock {
  private int lastCheckIn;
  private PImage lockedIm, unlockedIm;
  private int unlocked; //0=locked  1=unlocked
  private NetAddress address;
  private String addrPattern = "/lock";
  private color fillColor = color(0, 0, 0), 
    red = color(255, 0, 0), 
    green = color(0, 255, 0);
  private float batteryVoltage;

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

  public float getBattery() {
    return batteryVoltage;
  }

  private color fadeColorOut(color c, int inc) {
    if (red(c)>0)c = color(red(c)-inc, green(c), blue(c));
    if (green(c)>0)c = color(red(c), green(c)-inc, blue(c));
    if (blue(c)>0)c = color(red(c), green(c), blue(c)-inc);
    return c;
  }

  private void drawButtons(float x, float y) {
    stroke(100);
    if (mouseX <x+35 && mouseX>x-35 && mouseY < y+75+10 && mouseY > y+75-10) {
      if (mousePressed) {
        fill(64);
        if (getLockedStatus()==0)
          unlock();
        else
          lock();
        noLoop();
      } else {
        fill(32);
      }
    } else {
      noFill();
    }
    rect(x, y+75, 70, 20);
    fill(255);
    if (getLockedStatus()==0)
      text("unlock", x, y+73);
    else
      text("lock", x, y+73);
  }

  public void update(OscMessage incoming) {

    lastCheckIn = millis();
    if (address==null) {
      address = new NetAddress(incoming.address().substring(1), incoming.port());
    }
    unlocked = incoming.get(0).intValue();
    batteryVoltage = incoming.get(1).floatValue();
    if (batteryVoltage>4.3) fillColor = color(0, 0, 255);
    else fillColor = lerpColor(red, green, map(batteryVoltage, 3, 4.2, 0, 1));
  }

  public void lock() {
    if (address!=null) {
      OscMessage msg = new OscMessage(addrPattern);
      msg.add(0);
      oscNet.send(msg, address);
      //println("lock");
    } else {
      throw new NullPointerException();
    }
  }

  public void unlock() {
    if (address!=null) {
      OscMessage msg = new OscMessage(addrPattern);
      msg.add(1);
      oscNet.send(msg, address);
      //println("sent to: " +address);
    } else {
      throw new NullPointerException();
    }
  }

  public void draw(float x, float y) {
    noStroke();
    fill(fillColor);
    ellipse(width/2-20, height/2+20, 10, 10);

    fillColor = fadeColorOut(fillColor, 5);

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

    String status = "unknown";
    if (unlocked == 0) {
      status = "locked";
    }
    if (unlocked == 1) {
      status = "unlocked";
    }
    if ((millis()-lastCheckIn)/1000>=5 && address!=null) 
      return getClass().getSimpleName() + "\nLast check in:\n" + ((millis()-lastCheckIn)/1000) + " Seconds" + "\n" + address.address();
    else if (address==null) 
      return getClass().getSimpleName()+"\nWaiting for\nConnection";
    else
      return getClass().getSimpleName() + "\n" + address.address() + "\n" + batteryStatus + "\nstatus: " + status;
  }
}