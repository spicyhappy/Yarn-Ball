import ddf.minim.*;

Minim minim;
AudioPlayer backgroundMusic;
AudioPlayer soundEffect;

void setup()
{
size(100, 100);


// Audio files setup
minim = new Minim(this);
backgroundMusic = minim.loadFile("backgroundMusic.wav");
backgroundMusic.play();
backgroundMusic.loop();
soundEffect = minim.loadFile("effect.wav");

}

void draw()
{
background(0);
}

void keyPressed()
{
  if ( key == 'p' )
  {
    soundEffect.rewind();
    soundEffect.play();
  }
}

void stop()
{
backgroundMusic.close();
soundEffect.close();
minim.stop();
super.stop();
}
