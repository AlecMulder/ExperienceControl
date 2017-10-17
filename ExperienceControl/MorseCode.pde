public static class MorseCode {
  public static char character[] = new char[48];
  public static String code[] = new String[48];
  private int i = 0;

  MorseCode() {
    character[i] = 'A';
    i++;
    character[i] = 'B';
    i++;
    character[i] = 'C';
    i++;
    character[i] = 'D';
    i++;
    character[i] = 'E';
    i++;
    character[i] = 'F';
    i++;
    character[i] = 'G';
    i++;
    character[i] = 'H';
    i++;
    character[i] = 'I';
    i++;
    character[i] = 'J';
    i++;
    character[i] = 'K';
    i++;
    character[i] = 'L';
    i++;
    character[i] = 'M';
    i++;
    character[i] = 'N';
    i++;
    character[i] = 'O';
    i++;
    character[i] = 'P';
    i++;
    character[i] = 'Q';
    i++;
    character[i] = 'R';
    i++;
    character[i] = 'S';
    i++;
    character[i] = 'T';
    i++;
    character[i] = 'U';
    i++;
    character[i] = 'V';
    i++;
    character[i] = 'W';
    i++;
    character[i] = 'X';
    i++;
    character[i] = 'Y';
    i++;
    character[i] = 'Z';
    i++;
    character[i] = ' ';
    i++;
    character[i] = '1';
    i++;
    character[i] = '2';
    i++;
    character[i] = '3';
    i++;
    character[i] = '4';
    i++;
    character[i] = '5';
    i++;
    character[i] = '6';
    i++;
    character[i] = '7';
    i++;
    character[i] = '8';
    i++;
    character[i] = '9';
    i++;
    character[i] = '0';
    i++;
    character[i] = '.';
    i++;
    character[i] = ',';
    i++;
    character[i] = '?';
    i++;
    character[i] = '!';
    i++;
    character[i] = ':';
    i++;
    character[i] = ';';
    i++;
    character[i] = '(';
    i++;
    character[i] = ')';
    i++;
    character[i] = '"';
    i++;
    character[i] = '@';
    i++;
    character[i] = '&';
    i++;

    i = 0;
    code[i] = ".-";
    i++;
    code[i] = "-...";
    i++;
    code[i] = "-.-.";
    i++;
    code[i] = "-..";
    i++;
    code[i] = ".";
    i++;
    code[i] = "..-.";
    i++;
    code[i] = "--.";
    i++;
    code[i] = "....";
    i++;
    code[i] = "..";
    i++;
    code[i] = ".---";
    i++;
    code[i] = ".-.-";
    i++;
    code[i] = ".-..";
    i++;
    code[i] = "--";
    i++;
    code[i] = "-.";
    i++;
    code[i] = "---";
    i++;
    code[i] = ".--.";
    i++;
    code[i] = "--.-";
    i++;
    code[i] = ".-.";
    i++;
    code[i] = "...";
    i++;
    code[i] = "-";
    i++;
    code[i] = "..-";
    i++;
    code[i] = "...-";
    i++;
    code[i] = ".--";
    i++;
    code[i] = "-..-";
    i++;
    code[i] = "-.--";
    i++;
    code[i] = "--..";
    i++;
    code[i] = "     "; //Gap between word, seven units
    i++;
    code[i] = ".----";
    i++;
    code[i] = "..---";
    i++;
    code[i] = "...--";
    i++;
    code[i] = "....-";
    i++;
    code[i] = ".....";
    i++;
    code[i] = "-....";
    i++;
    code[i] = "--...";
    i++;
    code[i] = "---..";
    i++;
    code[i] = "----.";
    i++;
    code[i] = "-----";
    i++;
    code[i] = "·–·–·–";
    i++;
    code[i] = "--..--";
    i++;
    code[i] = "..--..";
    i++;
    code[i] = "-.-.--";
    i++;
    code[i] = "---...";
    i++;
    code[i] = "-.-.-.";
    i++;
    code[i] = "-.--.";
    i++;
    code[i] = "-.--.-";
    i++;
    code[i] = ".-..-.";
    i++;
    code[i] = ".--.-.";
    i++;
    code[i] = ".-...";
  }

  public char decode(String c)/*throws Exception*/ {
    boolean found = false;

    for (int pos = 0; pos<code.length; pos++) {
      if (c.equals(code[pos])) {
        found=true;
        return character[pos];
      }
    }
    if (!found) {
      throw new NoSuchElementException();
    }
    return 'n';
  }

  public String encode(char c) {
    boolean found = false;
    for (int pos = 0; pos<code.length; pos++) {
      if (Character.toUpperCase(c)==character[pos]) {
        found=true;
        return code[pos];
      }
    }
    if (!found) {
      throw new NoSuchElementException();
    }
    return "null";
  }
  public String encode(String c) {
    boolean found = false;
    String out = "";
    for (int i = 0; i<c.length(); i++) {
      for (int pos = 0; pos<code.length; pos++) {
        if (Character.toUpperCase(c.charAt(i))==character[pos]) {
          found=true;
          out += code[pos] + " ";
        }
      }
      if (!found) {
        throw new NoSuchElementException();
      }else{
        found = false;
      }
    }
    return out;
  }
}