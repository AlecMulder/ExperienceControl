class Key {
  private int lastCheckIn;
  private String attempt;
  private String answer = "1";
  private boolean complete;
  private NetAddress address;
  private String addrPattern = "/key";
  private int fillColor = 0;

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

  public void update(OscMessage incoming) {
    fillColor = 255;
    lastCheckIn = millis();
    if (incoming.checkTypetag("s")) {
      attempt = incoming.get(0).stringValue();
    } else if (incoming.checkTypetag("i")) {
      attempt = ""+incoming.get(0).intValue();
    }
    if (address!=incoming.netAddress()) {
      address = new NetAddress(incoming.address().substring(1), incoming.port());
    }
  }

  public void draw(float x, float y) {
    noStroke();
    fill(fillColor);
    ellipse(width/2-20, height/2-20, 10, 10);
    if (fillColor>0)fillColor-=5;
    fill(255);
    if (!attempt.equals("") && attempt.equals(answer)) 
      complete=true;

    text(toString(), x, y);

    if (address!=null && millis()-lastCheckIn>30000) 
      address = null;
  }

  public String toString() {
    if ((millis()-lastCheckIn)/1000>=5) return getClass().getSimpleName() + "\nLast Check in:\n" + ((millis()-lastCheckIn)/1000) + " Seconds" + "\nAddress:\n" + address;
    else if (!complete) return getClass().getSimpleName() + "\nAddress:\n" + address + "\nAnswer: " + answer + "\nAttempt: " + attempt;
    else return getClass().getSimpleName() + "\nAddress:\n" + address + "\nComplete";
  }
}