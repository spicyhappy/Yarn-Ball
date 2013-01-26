import java.util.*;
import org.json.*;

class Coordinate {
  int x = 0;
  int y = 0;
 
  public Coordinate(int x, int y) {
    this.x = x;
    this.y = y;
  }
  
  public int get_tile_x() { return x; }
  public int get_tile_y() { return y; }
  
  public int get_global_x() { return x * TILE_WIDTH; }
  public int get_global_y() { return y * TILE_HEIGHT; }
  
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
  
  public Tile(int tile_set_row, int tile_set_column, boolean[] options) {
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
  String tile_sheet_file = null;
  int tile_width = 0;
  int tile_height = 0;
  
  public TileSet(String filename, int tile_width, int tile_height) {
    this.tile_sheet_file = filename;
    this.tile_width = tile_width;
    this.tile_height = tile_height;
  }
  
  public PImage get_tile(int row, int column) {
    // TODO: Replace placeholder tile image.
    //
    //       Cut pixel data out of tile sheet file and
    //       use them to make the appropriate PImage.
    PImage img = createImage(tile_width, tile_height, RGB);
    img.loadPixels();
    for (int i = 10; i < img.pixels.length; i++) {
      img.pixels[i] = color(0, 90, 102);
    }
    img.updatePixels();
    return img;
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
         image(img, row * TILE_WIDTH, column * TILE_WIDTH);
       }
     }
  }
}

class MapDecoder {
  JSONObject json_obj = null;
  
  public TileMap read(String source) {
    //json_obj = new JSONObject(source);
    return new TileMap(get_tile_set(), get_grid());
  }
  
  protected TileSet get_tile_set() {
    // TODO: replace placeholder
    return new TileSet("", 16, 16);
  }
  
  protected Grid<Tile> get_grid() {
    // TODO: replace placeholder
    ArrayList<ArrayList<Tile>> data = new ArrayList<ArrayList<Tile>>();
    for (int row = 0; row < 10; row++) {
      data.add(new ArrayList<Tile>());
      for (int column = 0; column < ; column++) {
        boolean[] tile_data = { true, true, true, true, true, true, true };
        Tile tile = new Tile(0, 0, tile_data);
        data.get(row).add(tile);
      }
    }
    return new Grid<Tile>(data);
  }
}

class Yarn {
  int remaining_length = 10;
  ArrayList<Coordinate> positions = new ArrayList<Coordinate>();
  
  public Yarn(Coordinate start_position) {
    positions.add(start_position);
  }
  
  public Coordinate get_position() {
    return positions.get(positions.size()-1); 
  }
  
  public void draw() {
    drawBall();
    drawPath();
  }
  
  protected void drawBall() {
    fill(255);
    int x = get_position().get_global_x();
    int y = get_position().get_global_y();
    ellipse(x, y, 10, 10);  
  }
  
  protected void drawPath() {
    if (positions.size() <= 1) return;
    
    Coordinate prev = positions.get(0);
    for (int i = 1; i < positions.size(); i++) {
      Coordinate curr = positions.get(i);
      
      stroke(255);
      line(prev.get_global_x(),
           prev.get_global_y(),
           curr.get_global_x(),
           curr.get_global_y());
      
      prev = curr;
    }
  }
  
  public boolean valid_move(Coordinate from, Coordinate to) {
    if (to.get_global_x() < 0 ||
        to.get_global_y() < 0 ||
        to.get_global_x() > width ||
        to.get_global_y() > height) return false;
    if (!((Math.abs(from.get_tile_x() - to.get_tile_x()) == 1 &&
           Math.abs(from.get_tile_y() - to.get_tile_y()) == 0) ||
          (Math.abs(from.get_tile_x() - to.get_tile_x()) == 0 &&
           Math.abs(from.get_tile_y() - to.get_tile_y()) == 1))) return false;
    // TODO: check map's tile openings in `from` and `to`
    
    return true;
  }
  
  public void tryMove(int keyCode) {
    Coordinate next_position = neighbor_from_key(keyCode);
    if (valid_move(get_position(), next_position)) {
      if (positions.size() >= 2 && next_position.equals(positions.get(positions.size() - 2))) {
        positions.remove(positions.size() - 1); 
      } else {
        positions.add(next_position);
      }
    }
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

MapDecoder decoder = new MapDecoder();
TileMap map = decoder.read("");

void setup() {
  size(240, 160);
  yarn = new Yarn(new Coordinate(5,5));
}

void draw() {
  background(0);
  
  map.draw();
  yarn.draw();
}

void keyPressed() {
  yarn.tryMove(keyCode); 
}
