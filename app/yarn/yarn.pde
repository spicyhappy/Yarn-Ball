//                      
//     ______       o
//   / 0      \_/     o
//   \ _______/ \  o  

import java.util.*;
import org.json.*;
import ddf.minim.*;

// Audio variables
Minim minim;
AudioPlayer backgroundMusic;
AudioPlayer menuEffect;

// Level variables
PImage startScreen;
PImage creditScreen;
PImage winScreen;
PImage darkMask;
int gameLevel = 0;
boolean lightingEffectsOn = true;

// Set screen width and height
int screenWidth = 240;
int screenHeight = 160;

// Screen dimensions for testing (will always be 15x10 once real levels are in)
int sWidth = 3;
int sHeight = 3;


Boolean _keysLocked = false;


class Coordinate {
  int x = 0;
  int y = 0;
 
  public Coordinate(int x, int y) {
    this.x = x;
    this.y = y;
  }
  
  public int get_tile_x() { return x; }
  public int get_tile_y() { return y; }
  
  public int get_global_x() { return get_tile_x() * TILE_WIDTH; }
  public int get_global_y() { return get_tile_y() * TILE_HEIGHT; }
  
  public boolean equals(Object obj) {
    if (obj == null) return false;
    if (obj == this) return true;
    if (obj.getClass() != getClass()) return false;
    
    Coordinate other = (Coordinate) obj;
    return this.get_tile_x() == other.get_tile_x() &&
           this.get_tile_y() == other.get_tile_y();
  }
}

class Tile {
  int tile_set_row;
  int tile_set_column;
  boolean is_occupiable;
  boolean is_safe_spot;
  boolean is_exit;
  boolean north_passage;
  boolean east_passage;
  boolean south_passage;
  boolean west_passage;
  
  public Tile(int tile_set_column, int tile_set_row, boolean[] options) {
    if (options.length != 7)
      throw new IllegalArgumentException("Tile must have 7 bools!");
    
    this.tile_set_row = tile_set_row;
    this.tile_set_column = tile_set_column;
    
    is_occupiable = options[0];
    is_safe_spot = options[1];
    is_exit = options[2];
    north_passage = options[3];
    east_passage = options[4];
    south_passage = options[5];
    west_passage = options[6];
  }
}

class Grid<T extends Tile> {
  ArrayList<ArrayList<T>> data;
  
  public Grid(ArrayList<ArrayList<T>> data) {
    this.data = data;
  }
}

// TODO: pre-load PImages into an array; return
//       references to them as needed.
class TileSet {
  PImage tile_sheet = null;
  PImage tiles[] = null;  // assumes sprite sheet has only one row of tiles; may need to fix later!
  int tile_width = 0;
  int tile_height = 0;
  
  public TileSet(String filename, int tile_width, int tile_height) {
    println("Sheet file: " + filename);
    this.tile_sheet = loadImage(filename);
    println("Sheet width: " + tile_sheet.width + "px");
    int sprite_count = (int) (tile_sheet.width / tile_width);
    println("Initializing sprites array to length: " + sprite_count);
    this.tiles = new PImage[sprite_count];
    println("Sheet dimensions: " + tile_sheet.width + "x" + tile_sheet.height);
    this.tile_width = tile_width;
    this.tile_height = tile_height;
  }
  
  public PImage get_tile(int tile_row, int tile_column) {
    int tile_index = tile_column;
    if (tiles[tile_index] == null) {
      PImage img = createImage(tile_width, tile_height, RGB);
      for (int h = 0; h < tile_height; h++) {
        color[] row_data = pixel_row(tile_column, h);
        for (int w = 0; w < tile_width; w++) {
          img.pixels[h * tile_width + w] = row_data[w]; 
        }
      }
      tiles[tile_index] = img;
    }
    return tiles[tile_index];
  }
  
  protected color[] pixel_row(int tile_column, int row) {    
    color[] row_pixels = new color[tile_width];
    int tile_offset = tile_column * tile_width;
    
    for (int i = 0; i < row_pixels.length; i++) {
      int sheet_x = i + tile_offset;
      row_pixels[i] = tile_sheet.pixels[tile_sheet.width * row + sheet_x];
    }
    
    return row_pixels;
  }
}

class TileMap {
  TileSet tiles = null;
  Grid<Tile> grid = null;
  
  public TileMap(TileSet tiles, Grid<Tile> grid) {
    this.tiles = tiles;
    this.grid = grid; 
  }
  
  public void draw() {
     for (int row = 0; row < grid.data.size(); row++) {
       for (int column = 0; column < grid.data.get(row).size(); column++) {
         Tile tile = grid.data.get(row).get(column);
         PImage img = tiles.get_tile(tile.tile_set_row, tile.tile_set_column);
         image(img, row * TILE_HEIGHT, column * TILE_WIDTH);
       }
     }
  }
}

class MapDecoder {
  JSONObject json_obj = null;
  
  public TileMap read(String source) {
    try {
      json_obj = new JSONObject(source);
    } catch (Exception e) {
      e.printStackTrace();
    }
    return new TileMap(get_tile_set(), get_grid());
  }
  
  protected TileSet get_tile_set() {
    try {
      String filename = (String) json_obj.get("tileset_file");
      return new TileSet(filename, 16, 16);
    } catch (Exception e) {
      e.printStackTrace(); 
    }
    
    return null;
  }
  
  protected Grid<Tile> get_grid() {
    ArrayList<ArrayList<Tile>> data = new ArrayList<ArrayList<Tile>>();
    
    Object obj;
    try {
      obj = json_obj.get("tile_data");
      if (obj.getClass() == JSONArray.class) {
        JSONArray rows = (JSONArray) obj;
        
        for (int r = 0; r < rows.length(); r++) {
          obj = rows.get(r);
          
          data.add(new ArrayList<Tile>());
          
          if (obj.getClass() == JSONArray.class) {
            JSONArray cells = (JSONArray) obj;
            for (int c = 0; c < cells.length(); c++) {
              obj = cells.get(c);
              if (obj.getClass() == JSONObject.class) {
                JSONObject cell = (JSONObject) obj;
                
                int x=0, y=0;
                boolean n=true, e=true, s=true, w=true,
                        occupiable=true, safe_spot=true, exit=true;

                obj = cell.get("tileset_coordinate");
                if (obj.getClass() == JSONArray.class) {
                  JSONArray coordinate = (JSONArray) obj;
                  
                  x = ((Number) coordinate.get(0)).intValue();
                  y = ((Number) coordinate.get(1)).intValue();
                } else {
                  println("Expected JSONArray for tileset_coordinate!"); 
                }
                
                obj = cell.get("entrances");
                if (obj.getClass() == JSONArray.class) {
                  JSONArray entrances = (JSONArray) obj;
                  
                  n = ((Boolean) entrances.get(0)).booleanValue();
                  e = ((Boolean) entrances.get(1)).booleanValue();
                  s = ((Boolean) entrances.get(2)).booleanValue();
                  w = ((Boolean) entrances.get(3)).booleanValue();
                } else {
                  println("Expected JSONArray for entrances!"); 
                }
                
                occupiable = ((Boolean) cell.get("is_occupiable")).booleanValue();
                safe_spot = ((Boolean) cell.get("is_safe_spot")).booleanValue();
                exit = ((Boolean) cell.get("is_exit")).booleanValue();
                
                boolean options[] = { occupiable, safe_spot, exit, n, e, s, w };
                data.get(data.size()-1).add(new Tile(x, y, options));
              } else {
                println("Expected JSONObject for cell data!");
              } 
            }
          } else {
            println("Expected JSONArray of cells in the row!"); 
          }
        }
      } else {
        println("Expected JSONArray of the rows!");
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
    
    return new Grid<Tile>(data);
  }
}

class Yarn {
  int remaining_length = 10;
  int max_length = 10;
  
  ArrayList<Coordinate> positions = new ArrayList<Coordinate>();
  
  public Yarn(Coordinate start_position) {
    positions.add(start_position);
  }
  
  public Coordinate get_position() {
    return positions.get(positions.size()-1); 
  }
  
  // TODO: Add light back later.
  public void draw() {
    drawPath();
    //drawLightMask();
    drawBall();
  }
  
  protected void drawBall() {
//    fill(255);
    int x = get_position().get_global_x() + TILE_WIDTH/2;
    int y = get_position().get_global_y() + TILE_HEIGHT/2;
//    ellipse(x, y, 10, 10);  
      
    PImage yarnBall;
    // Not animated yet - ball.png has animated sprites
    yarnBall = loadImage("ball_0000.png");
    image(yarnBall, x-TILE_WIDTH/2, y-TILE_HEIGHT/2);
  }
  
  protected void drawPath() {
    
    
    if (positions.size() <= 1) return;
    
    Coordinate prev = positions.get(0);
    for (int i = 1; i < positions.size(); i++) {
      Coordinate curr = positions.get(i);
      
      stroke(255,186,0);
      strokeWeight(2);
      line(prev.get_global_x() + TILE_WIDTH/2,
           prev.get_global_y() + TILE_HEIGHT/2,
           curr.get_global_x() + TILE_WIDTH/2,
           curr.get_global_y() + TILE_HEIGHT/2);
      
      prev = curr;
    }
  }
  
  protected void drawLightMask() {
    int x = get_position().get_global_x();
    int y = get_position().get_global_y();
    
    println("Screen dimensions: " + screenWidth + "x" + screenHeight);
    int brightness_ratio = remaining_length / max_length;
    /*
    int resizeWidth = screenWidth * brightness_ratio * 12;
    int resizeHeight = screenHeight * brightness_ratio * 12;
    */
    
    
    darkMask = loadImage("mask.png");
    if (darkMask == null) {
      println("Dark mask is null!"); 
    } else {
      println ("Mask width: " + darkMask.width); 
    }
    
    int resizeWidth = darkMask.width/2 * 10;
    int resizeHeight = darkMask.height/2 * 10;
    println ("Resizing to: " + resizeWidth + "x" + resizeHeight);
    
    darkMask.resize(resizeWidth,resizeHeight);
    println("placement: " + (x-resizeWidth/2) + ", " + (y-resizeHeight/2));
    image(darkMask, x-resizeWidth/2, y-resizeHeight/2);
  }
  
  public boolean valid_move(Coordinate from, Coordinate to)
  {
    Boolean rtn = false;
    
     // break if this would be out of bounds
    if (to.get_tile_x() < 0 ||
        to.get_tile_y() < 0 ||
        to.get_tile_x() > sWidth-1 ||
        to.get_tile_y() > sHeight-1) return false;
    
    // find direction
    int dir = getDirectionIndex(from, to);
    
    int tileX = to.get_tile_x();
    int tileY = to.get_tile_y();
    
    Tile toTile = map.grid.data.get(tileX).get(tileY);
    
    rtn = toTile.is_occupiable;
    
    return rtn;
  }
  
  // returns an index value that should map to the 'neighbors' array to determine compass direction
   // clockwise rotation...n,e,s,w
  public int getDirectionIndex(Coordinate from, Coordinate to)
  {
    int rtn = 0;
    
    if( from.get_tile_x() - to.get_tile_x() > 0 ) {
      rtn = 3; // west
    } else if( from.get_tile_x() - to.get_tile_x() < 0 ) {
      rtn = 1; // east
    } else if( from.get_tile_y() - to.get_tile_y() > 0 ) {
      rtn = 0; // north
    } else if( from.get_tile_y() - to.get_tile_y() < 0 ) {
      rtn = 2; // south
    }
    
    return rtn;
  }
  
  public void tryMove(int keyCode) {
    Coordinate next_position = neighbor_from_key(keyCode);
    if (valid_move(get_position(), next_position)) {
      // do move
      if (positions.size() >= 2 && next_position.equals(positions.get(positions.size() - 2))) {
        positions.remove(positions.size() - 1);
        remaining_length++; 
      } else if (remaining_length > 0) {
        positions.add(next_position);
        remaining_length--;
      }
      
      // check for safe/end spots
      checkForSpots();
    }
  }
  
  protected void checkForSpots()
  {
    Coordinate currentCord = get_position();
    // println("currentCord: "+currentCord);
    
    int tileX = currentCord.get_tile_x();
    int tileY = currentCord.get_tile_y();
    
    Tile currentTile = map.grid.data.get(tileX).get(tileY);
    
    if( currentTile.is_safe_spot ) {
      doSafeSpot();
    } else if( currentTile.is_exit ) {
      doEndLevel();
    }
  }
  
  protected void doSafeSpot()
  {
    println("IT'S SAFE");
    if( remaining_length == 0 ) {
      // only safe if it's the last move
      doSpagettiSuck();
    }
  }
  
  protected void doEndLevel()
  {
    println("IT'S THE END");
    // allow exit regardless of length
    doSpagettiSuck();
  }
  
  protected void doSpagettiSuck()
  {
    _keysLocked = true;
    // eat that yarn
    // loop on self until string is back to max
    _keysLocked = false;
  }
  
  protected Coordinate neighbor_from_key(int keyCode) {
    int next_x = get_position().get_tile_x();
    int next_y = get_position().get_tile_y();
    
    if (keyCode == UP) { next_y--; }
    if (keyCode == DOWN) { next_y++; }
    if (keyCode == LEFT) { next_x--; }
    if (keyCode == RIGHT) { next_x++; }
    
    return new Coordinate(next_x, next_y);
  }
}

int TILE_WIDTH = 16;
int TILE_HEIGHT = 16;
Yarn yarn = null;

MapDecoder decoder;
String json_map;
TileMap map;

String read_file(String filename) {
  String lines[] = loadStrings(filename);
  StringBuilder sb = new StringBuilder();
  for (int i = 0; i < lines.length; i++) {
    sb.append(lines[i]);
  }
  return sb.toString();
}

void setup() {
  size(240, 160);
  startScreen = loadImage("screen_start.png");
  winScreen = loadImage("screen_win.png");
  creditScreen = loadImage("screen_credits.png");

  
  // Audio files setup
  minim = new Minim(this);
  backgroundMusic = minim.loadFile("backgroundMusic.wav");
  backgroundMusic.play();
  backgroundMusic.loop();
  menuEffect = minim.loadFile("menu.wav");
  
  yarn = new Yarn(new Coordinate(0,0));
  
  decoder = new MapDecoder();
  json_map = read_file("maps/LevelA.json");
  map = decoder.read(json_map);

}

void draw() {
  background(0);
  
  if (gameLevel == 0) {
    image(startScreen, 0, 0);
  }
  
  if (gameLevel == 1) {
    map.draw();
    yarn.draw();
    
  }
  
  if (gameLevel == 2) {
    image(winScreen, 0, 0);
  }
  
  if (gameLevel == 3) {
    image(creditScreen, 0, 0);
  }
  
}

void keyPressed() {
  
  if(_keysLocked==false) {
    
    // Title screen
    if (gameLevel == 0) {
      gameLevel = 1;
    }
    
    else if (gameLevel == 1) {
      yarn.tryMove(keyCode);
      menuEffect.play();
      menuEffect.rewind();
    }
    
    // Win screen
    else if (gameLevel == 2) {
      gameLevel = 3;
    }
    
    // Credits screen
    else if (gameLevel == 3) {
      gameLevel = 0;
    }
    
  }
}

void stop()
{
  backgroundMusic.close();
  menuEffect.close();
  minim.stop();
  super.stop();
}
