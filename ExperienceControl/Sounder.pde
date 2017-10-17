class Sounder {
  private int lastCheckIn;
  private String question = "";
  private int playing = 0;
  private NetAddress address;
  private String addrPattern = "/sounder";
  private color fillColor;
  private float batteryVoltage;
  private color green = color(0, 255, 0), 
    red = color(255, 0, 0);

  Sounder(String _question) {
    lastCheckIn = millis();
    question = _question;
  }

  Sounder(String _question, NetAddress _address) {
    lastCheckIn = millis();
    question = _question;
    address = _address;
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

  public String getQuestion() {
    return question;
  }

  public void setQuestion(String q) {
    question =  q;
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

  private void drawButtons(float x, float y) throws Exception {
    stroke(100);

    //left button
    if (mouseX <x-40+25 && mouseX>x-40-25 && mouseY < y+75+10 && mouseY > y+75-10) {
      if (mousePressed) {
        fill(64);
        if (getPlaying()==1)
          stopPlaying();
        else 
        startPlaying();
        noLoop();
      } else {
        fill(32);
      }
    } else {
      noFill();
    }
    rect(x-40, y+75, 50, 20);
    fill(255);
    if (getPlaying()==1)
      text("pause", x-40, y+73);
    else
      text("play", x-40, y+73);

    //right button
    if (mouseX <x+40+25 && mouseX>x+40-25 && mouseY < y+75+10 && mouseY > y+75-10) {
      if (mousePressed) {
        fill(64);
        String newInput = "";
        newInput = JOptionPane.showInputDialog("Please input a new message");
        println("*"+newInput+"*");
        if (newInput.equals("")) {
          throw new IllegalArgumentException("No Input!");
        } else {
          setQuestion(newInput);
        }
        noLoop();
      } else {
        fill(32);
      }
    } else {
      noFill();
    }
    rect(x+40, y+75, 60, 20);
    fill(255);
    text("update", x+40, y+73);
  }

  public void startPlaying() {
    playing = 1;
    try {
      OscMessage msg = new OscMessage(addrPattern+"/updateWord");
      msg.add(question);
      oscNet.send(msg, address);
      println("Sent: " + question);
    }
    catch (Exception e) {
      println(e);
    }
  }

  public void stopPlaying() {
    playing = 0;
    try {
      OscMessage msg = new OscMessage(addrPattern+"/updateWord");
      msg.add("");
      oscNet.send(msg, address);
    }
    catch (Exception e) {
      println(e);
    }
  }

  public void update(OscMessage incoming) {
    lastCheckIn = millis();
    playing = incoming.get(0).intValue();
    batteryVoltage = incoming.get(1).floatValue();
    if (batteryVoltage>4.3) fillColor = color(0, 0, 255);
    else fillColor = lerpColor(red, green, map(batteryVoltage, 3, 4.2, 0, 1));

    if (address==null) address = new NetAddress(incoming.address().substring(1), incoming.port());
  }

  public void draw(float x, float y) {
    noStroke();
    fill(fillColor);
    ellipse(width/2+20, height/2-20, 10, 10);
    fillColor = fadeColorOut(fillColor, 5);

    if (address != null)
    try {
      drawButtons(x, y);
    }
    catch(Exception e) {
      println(e);
    }
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

    if ((millis()-lastCheckIn)/1000>=10 && address!=null) 
      return getClass().getSimpleName() + "\nLast check in:\n" + ((millis()-lastCheckIn)/1000) + " Seconds" + "\n" + address.address();
    else if (address==null) 
      return getClass().getSimpleName()+"\nWaiting for\nConnection";
    else if (playing==1)
      return getClass().getSimpleName() + "\n" + address.address() + "\n" + batteryStatus + "\nQuestion: " + question + "\nPlaying";
    else
      return getClass().getSimpleName() + "\n" + address.address() + "\n" + batteryStatus + "\nQuestion: " + question + "\nStandby";
  }
}