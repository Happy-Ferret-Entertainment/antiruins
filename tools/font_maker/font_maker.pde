///////////////////////
int FONT_SIZE = 14;
int CELLSIZE = 16;

PFont font;
String fontName = "VG5000.otf";
//String fontName = "Format_1452.otf";


////////////////////////

PGraphics img;


void setup() {
  size(256, 128);
  noLoop();
  //noSmooth();
  background(0);

  img = createGraphics(width, height);

  //String[] fontList = PFont.list();
  //printArray(fontList);

  fontName = "SpaceMono-Regular.ttf";
  font = createFont(fontName, FONT_SIZE);

  drawCharAtlas();
  image(img, 0, 0);
  img.save("spacemono.png");
}

void draw() {
}

void drawCharAtlas() {
  int line = 0;
  int col = 0;
  char c = '!' - 1;

  img.beginDraw();
  img.textFont(font);
  img.textAlign(LEFT, TOP);
  img.textSize(FONT_SIZE);
  
  for (int i = 0; i < 256; i++) {
    img.text(c, col * CELLSIZE, line * CELLSIZE - 4);
    
    c++;
    col++;
    
    if (col * CELLSIZE > width - CELLSIZE) {
      col = 0;
      line++;
    } else {
    }
  }
  img.endDraw();
}
