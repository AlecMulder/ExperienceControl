class Sounder {
  private int lastCheckIn;
  private String question = "";
  private boolean playing = false;
  private NetAddress address;
  private String addrPattern = "/sounder";
  private int fillColor = 0;

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

  public boolean getPlaying() {
    return playing;
  }

  public String getQuestion() {
    return question;
  }

  public void setQuestion(String q) {
    question =  q;
  }

  public void startPlaying() {
    playing = true;
    OscMessage msg = new OscMessage(addrPattern+"/updateWord");
    msg.add(question);
    oscNet.send(msg, address);
  }

  public void stopPlaying() {
    playing = false;
    OscMessage msg = new OscMessage(addrPattern+"/updateWord");
    msg.add("");
    oscNet.send(msg, address);
  }

  public void update(OscMessage incoming) {
    fillColor = 255;
    lastCheckIn = millis();
    playing = incoming.get(0).booleanValue();
    if (address==null) address = new NetAddress(incoming.address().substring(1), incoming.port());
  }

  public void draw(float x, float y) {
    noStroke();
    fill(fillColor);
    ellipse(width/2+20, height/2-20, 10, 10);
    if (fillColor>0)fillColor-=5;
    fill(255);
    text(toString(), x, y);
    if (address!=null && millis()-lastCheckIn>30000) 
      address = null;
  }

  public String toString() {
    if ((millis()-lastCheckIn)/1000>=5) 
      return getClass().getSimpleName() + "\nLast check in:\n" + ((millis()-lastCheckIn)/1000) + " Seconds" + "\nAddress:\n" + address;
    else
      return getClass().getSimpleName() + "\nAddress:\n" + address + "\nQuestion: " + question + "\nPlaying: " + playing;
  }
}