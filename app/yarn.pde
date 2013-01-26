import java.util.*;

class Coordinate {
  int x = 0;
  int y = 0;
 
  public Coordinate(int x, int y) {
    this.x = x;
    this.y = y;
  }
  
  // tile
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
    // TODO: check tile openings in `from` and `to`
    
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

void setup() {
  size(240, 160);
  yarn = new Yarn(new Coordinate(5,5));
}

void draw() {
  background(0);
  
  yarn.draw();
}

void keyPressed() {
  yarn.tryMove(keyCode); 
}
