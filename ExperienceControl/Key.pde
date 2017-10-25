class Key {
  private int lastCheckIn;
  private String attempt;
  private String answer = "1";
  private boolean complete;
  private NetAddress address;
  private String addrPattern = "/key";
  private color fillColor = color(0, 0, 0), 
    red = color(255, 0, 0), 
    green = color(0, 255, 0);
  private float batteryVoltage;
  private int[] bulbs = {0, 0, 0, 0};

  public Key(String _answer) {
    attempt = "";
    lastCheckIn = millis();
    answer = _answer;
    complete = false;
  }

  public Key(String _answer, NetAddress _address) {
    attempt = "";
    lastCheckIn = millis();
    answer = _answer;
    address = _address;
    complete = false;
  }

  public void letterCorrect() {
    int currentBulb = 0;
    for (int i = 0; i<bulbs.length; i++) {
      if (bulbs[i] == 1)
        currentBulb=i+1;
    }
    if (currentBulb > 3) {
      complete = true;
    } else {
      bulbs[currentBulb] = 1;
    }
    updateBulbs();
  }

  public void letterIncorrect() {
    int currentBulb = 0;
    for (int i = 0; i<bulbs.length; i++) {
      if (bulbs[i] == 1)
        currentBulb=i+1;
    }
    if (address!=null) {
      OscMessage msg = new OscMessage(addrPattern + "/incorrect");
        msg.add(currentBulb+1);
      oscNet.send(msg, address);
    } else {
      throw new NullPointerException();
    }
  }

  public void updateBulbs() {
    if (address!=null) {
      OscMessage msg = new OscMessage(addrPattern);
      for (int i = 0; i<bulbs.length; i++)
        msg.add(bulbs[i]);
      oscNet.send(msg, address);
    } else {
      throw new NullPointerException();
    }
  }

  public String getAddrPattern() {
    return addrPattern;
  }

  public boolean complete() {
    return complete;
  }

  public int getLastCheckIn() {
    return lastCheckIn;
  }

  public String getAttempt() {
    return attempt;
  }

  public String getAnswer() {
    return answer;
  }

  public NetAddress getAddress() {
    return address;
  }

  public float getBattery() {
    return batteryVoltage;
  }

  public void setAnswer(String a) {
    answer = a;
  }
  /**
   fades a color to black
   @param c the color to fade
   @param inc the amount to fade by
   @return the darker color
   */
  private color fadeColorOut(color c, int inc) {
    if (red(c)>0)c = color(red(c)-inc, green(c), blue(c));
    if (green(c)>0)c = color(red(c), green(c)-inc, blue(c));
    if (blue(c)>0)c = color(red(c), green(c), blue(c)-inc);
    return c;
  }
  /**
   draws the onscreen control buttons
   @param x the x position
   @param y the y position
   @throws IllegalArgumentException if no input was given to update the answer
   */
  private void drawButtons(float x, float y) {
    stroke(100);
    if (mouseX <x-50+10 && mouseX>x-50-10 && mouseY < y+75+10 && mouseY > y+75-10) {
      if (mousePressed) {
        fill(64);
        attempt+="-";
        noLoop();
      } else {
        fill(32);
      }
    } else {
      noFill();
    }
    rect(x-50, y+75, 20, 20);
    fill(255);
    text("-", x-50, y+73);

    if (mouseX <x+30 && mouseX>x-30 && mouseY < y+75+10 && mouseY > y+75-10) {
      if (mousePressed) {
        fill(64);
        String newInput = "";
        newInput = JOptionPane.showInputDialog("Please input a new answer");
        println("*"+newInput+"*");
        if (newInput.equals("")) {
          throw new IllegalArgumentException("No Input!");
        } else {
          setAnswer(newInput);
        }
        noLoop();
      } else {
        fill(32);
      }
    } else {
      noFill();
    }
    rect(x, y+75, 60, 20);
    fill(255);
    text("update", x, y+73);

    if (mouseX <x+50+10 && mouseX>x+50-10 && mouseY < y+75+10 && mouseY > y+75-10) {
      if (mousePressed) {
        fill(64);
        attempt+=".";
        noLoop();
      } else {
        fill(32);
      }
    } else {
      noFill();
    }
    rect(x+50, y+75, 20, 20);
    fill(255);
    text(".", x+50, y+73);
  }
  /**
   updates variables based on incoming message
   @param incoming the plugged message
   */
  public void update(OscMessage incoming) {
    lastCheckIn = millis();
    if (incoming.checkTypetag("s")) {
      attempt = incoming.get(0).stringValue();
      String check = answer.substring(0, 1);
      if (attempt.equals(check)) {
        answer= answer.substring(1);
        letterCorrect();
      } else {
        letterIncorrect();
      }
      //batteryLevel = incoming.get(1).intValue();
    } else if (incoming.checkTypetag("f")) {
      batteryVoltage = incoming.get(0).floatValue();
      //println(batteryVoltage);
      if (batteryVoltage>4.3) fillColor = color(0, 0, 255);
      else fillColor = lerpColor(red, green, map(batteryVoltage, 3, 4.2, 0, 1));
    }
    if (address!=incoming.netAddress()) {
      address = new NetAddress(incoming.address().substring(1), incoming.port());
    }
  }
  public void draw(float x, float y) {
    noStroke();
    fill(fillColor);
    ellipse(width/2-20, height/2-20, 10, 10);
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

    if (!attempt.equals("") && attempt.equals(answer)) 
      complete=true;
    if (attempt.length()>10)
      attempt = attempt.substring(attempt.length()-10);
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
      return getClass().getSimpleName() + "\nLast Check in:\n" + ((millis()-lastCheckIn)/1000) + " Seconds" + "\n" + address.address();
    else if (!complete  && address!=null)
      return getClass().getSimpleName() + "\n" + address.address() + "\n" + batteryStatus + "\nAnswer: " + answer + "\nAttempt: " + attempt;
    else if (address==null) 
      return getClass().getSimpleName()+"\nWaiting for\nConnection";
    else 
    return getClass().getSimpleName() + "\n" + address.address() + "\n" + batteryStatus + "\nComplete";
  }
}