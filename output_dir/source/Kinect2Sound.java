import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import org.openkinect.processing.*; 
import ddf.minim.*; 
import ddf.minim.ugens.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Kinect2Sound extends PApplet {

/*
    Kinect zone
*/

Kinect kinect;
float tiltAngle = .0f;
/*
    Vision zone
*/
int trackColor;
PImage img;

BlobHandler blobHandler = new BlobHandler();
ArrayList<Blob> trackedBlobs = new ArrayList<Blob>();
/*
    Minim Zone
*/



Minim       minim;
Summer[]    sum = new Summer[BlobHandler.maxBlobNum];
AudioOutput out;
String baseTone = "C3";
boolean hitFlag[] = new boolean[BlobHandler.maxBlobNum];
/*
    Phonograph
*/
File[] files;
Phonograph[] phonographs;
AudioSample[] soundEffects;

public void setup() {
    
    kinect = new Kinect(this);
    kinect.initVideo();
    kinect.initDepth();
    kinect.enableMirror(true);

    trackColor = color(190, 45, 45);

    minim = new Minim(this);
    out = minim.getLineOut();
    files = new File(sketchPath()+"/data").listFiles();
    phonographs = new Phonograph[files.length];
    for(int i=0; i<files.length; i++) {
        if(files[i].isFile()) {
            phonographs[i] = new Phonograph(files[i].getName());
            println(files[i].getName());
        }
    }
}

public void draw() {
    img = kinect.getVideoImage();
    kinect.setTilt(constrain(tiltAngle, .0f, 30.0f));
    // PImage depth = kinect.getDepthImage();
    image(img, 0, 0);
    /*pushMatrix();
    scale(0.25);
    image(depth, 0, 0);
    popMatrix();*/

    ArrayList<Blob> blobs = new ArrayList<Blob>();
    img.loadPixels();
    for(int x = 0; x < img.width; x++){
        for(int y = 0; y < img.height; y++){
            //int mirrorLoc = (img.width-x-1) + y*img.width;
            int actualLoc = x + y*img.width;

            //color currentColor = img.pixels[mirrorLoc];
            int currentColor = img.pixels[actualLoc];
            float r1 = red(currentColor);
            float g1 = green(currentColor);
            float b1 = blue(currentColor);

            float r2 = red(trackColor);
            float g2 = green(trackColor);
            float b2 = blue(trackColor);

            float d = distSq(r1, g1, b1, r2, g2, b2);
            float similarPixelThreshold = 600;
            if(d < similarPixelThreshold){
                blobHandler.addToCompartBlob(blobs, x, y);
            }
        }
    }
    blobHandler.deleteNotQualifiedBlobs(blobs);
    blobHandler.checkTrackedBlobs(trackedBlobs, blobs);

    for(Blob b : trackedBlobs){
        b.show();
    }

    setPhonographs();

    // Show track color
    fill(trackColor);
    pushMatrix();
    translate(mouseX, mouseY);
    rectMode(CENTER);
    rect(0,0,50,50);
    popMatrix();
}

public float distSq(float r1, float g1, float b1, float r2, float g2, float b2){
    return (r1-r2)*(r1-r2) + (g1-g2)*(g1-g2) + (b1-b2)*(b1-b2);
}
public float distSq(float r1, float g1, float r2, float g2){
    return (r1-r2)*(r1-r2) + (g1-g2)*(g1-g2);
}

public void mousePressed() {
    img.loadPixels();    
    // int loc = (width-1-mouseX) + mouseY*width;
    int loc = mouseX + mouseY*width;
    trackColor = img.pixels[loc];
}

public void setPhonographs() {
    int gridNum = phonographs.length;
    int gridLength = width/gridNum;
    int gridHeight = 30;

    int gridIndex = 0;
    rectMode(CORNERS);
    for(Phonograph p : phonographs){
        p.computePassedTime();
        int head = gridLength*gridIndex;
        if(p.isPlaying()) {
            for(Blob b : trackedBlobs){
                if(b.isNear(head+gridLength/2, height-gridHeight/2)) {
                    if(keyPressed == true){
                        p.turnOff();
                        p.noPlayingState = true;
                    }
                }
            }
            fill(100,0,0,200);
        }
        else {
            boolean nearFlag = false;
            for(Blob b : trackedBlobs){
                if(b.isNear(head+gridLength/2, height-gridHeight/2)){
                    if(p.noPlayingState == false)
                        p.turnOn();
                    nearFlag = true;
                }
            }
            if(nearFlag == false)// means all blobs are not nearby
                p.noPlayingState = false;
            fill(0,100,0,200);
        }
        rect(head, height-gridHeight, head+gridLength, height);
        gridIndex++;
    }
}

public void keyPressed() {
    float skip = 0.25f;
    if(key == CODED) {
        if(keyCode == UP)
            tiltAngle += skip;
        if(keyCode == DOWN)
            tiltAngle -= skip;
    }
    else if (key == ' ')
        tiltAngle = 0;
}
class Blob {
    float upboundX, lowerboundX, upboundY, lowerboundY;
    int id;
    int maxLife = 20;
    int lifespan = maxLife;
    int blobColor = color(255, 200);
    // ArrayList<PVector> points;
    
    Blob(float x_, float y_){
        upboundX = x_;
        upboundY = y_;
        lowerboundX = x_;
        lowerboundY = y_;
        id = 0;
        // points = new ArrayList<PVector>();
        // Add blue color to dot qualified
        stroke(0, 0, 255);        
        // points.add(new PVector(x_, y_));
    }

    public boolean isDisappeared() {
        lifespan--;
        return lifespan < 0;
    }

    public void lifespanReset() {
        lifespan = maxLife;
    }

    public void setId(int givenId) {
        id = givenId;
        setRandomColorById();
    }

    public void become(Blob otherBlob) {
        upboundX = otherBlob.upboundX;
        upboundY = otherBlob.upboundY;
        lowerboundX = otherBlob.lowerboundX;
        lowerboundY = otherBlob.lowerboundY;
    }

    public void add(float x_, float y_ ) {
        upboundX = max(upboundX, x_);
        upboundY = max(upboundY, y_);
        lowerboundX = min(lowerboundX, x_);
        lowerboundY = min(lowerboundY, y_);
        // points.add(new PVector(x_, y_));
        // point(x_, y_);
    }

    public boolean isNear(float x_, float y_){
        PVector corner = getClosestCorner(x_, y_);
        PVector center = getCenter();
        float d = distSq(corner.x, corner.y, x_, y_);
        d = min(d, distSq(center.x, center.y, x_, y_));

        /****
            Points version
            which cost too many cpu resource
        ****/
        // float d = 10000000;
        // for (PVector v : points) {
        //     float tempD = distSq(x_, y_, v.x, v.y);
        //     if (tempD < d) {
        //         d = tempD;
        //     }
        // }
        if(d < 2500){
            return true;
        }
        else{
            return false;
        }
    }

    public PVector getClosestCorner(float x_, float y_) {
        PVector corner = new PVector(x_, y_);
        corner.x = max(min(corner.x, upboundX), lowerboundX);
        corner.y = max(min(corner.y, upboundY), lowerboundY);
        return corner;
    }

    public PVector getCenter() {
        float centerX = (upboundX + lowerboundX)/2;
        float centerY = (upboundY + lowerboundY)/2;
        return new PVector(centerX, centerY);
    }

    public void show() {
        stroke(0);
        // fill(255, 200);
        fill(blobColor);
        strokeWeight(2);
        rectMode(CORNERS);
        rect(lowerboundX, lowerboundY, upboundX, upboundY);
        
        stroke(0);
        //text(blobArea(),lowerboundX, lowerboundY);
        fill(0);
        PVector center = getCenter();
        text(id, center.x, center.y);
        text(lifespan, center.x, center.y+15);
    }

    public void setRandomColorById() {
        randomSeed(id+(int)random(12345678));
        blobColor = color(random(0, 255), random(0, 255), random(0, 255), 200);
    }

    public float blobArea(){
        return (upboundX - lowerboundX) * (upboundY + lowerboundY);
    }

    public boolean isBigEnough() {
        float areaThreshold = 3000;
        if(this.blobArea() > areaThreshold)
            return true;
        else
            return false;
    }

    /*
    boolean isOverlapedWith(Blob target) {
        if(
            (target.upboundX > lowerboundX && upboundX > target.lowerboundX)&&
            (target.upboundY > lowerboundY && upboundY > target.lowerboundY)
        )
            return true;
        else
            return false;
    }*/

    public boolean isTooThin() {
        float blobWidth  = upboundX - lowerboundX;
        float blobHeight = upboundY - lowerboundY;
        float ratioThreshold = 20.0f;
        if(blobWidth != 0){
            float ratio = blobHeight/blobWidth;
            if(ratio > ratioThreshold || ratio < 1/ratioThreshold)
                return true;
            else
                return false;
        }
        else
            return false;//Maybe this should be written in exception
    }
}
class BlobHandler {
    int blobCounter = 0;
    final static int maxBlobNum = 20;    

    public void checkTrackedBlobs(ArrayList<Blob> trackedBlobs,ArrayList<Blob> currentBlobs) {
        boolean[] matchedTrackList   = new boolean[trackedBlobs.size()];
        boolean[] matchedCurrentList = new boolean[currentBlobs.size()];
        for(boolean flag : matchedTrackList)   flag = false;
        for(boolean flag : matchedCurrentList) flag = false;

        float distanceThreshold = 200;
        for(int i = 0; i < trackedBlobs.size(); i++) {
            if(matchedTrackList[i]) continue;
            float recordD = distanceThreshold;
            Blob matchedBlob = null;
            int matchIndex = -1;
            Blob tb = trackedBlobs.get(i);
            for(int j = 0; j < currentBlobs.size(); j++) {
                if(matchedCurrentList[j]) continue;
                Blob cb = currentBlobs.get(j);
                PVector centerTrack   = tb.getCenter();
                PVector centerCurrent = cb.getCenter();
                float d = PVector.dist(centerTrack, centerCurrent);
                if(d < recordD) {
                    recordD = d;
                    matchedBlob = cb;
                    matchIndex = j;
                }
            }

            if(matchIndex != -1) {
                matchedCurrentList[matchIndex] = true;
                matchedTrackList[i] = true;
                tb.become(matchedBlob);//keep id the same number, literally moving the blob
                tb.lifespanReset();
            }
        }

        // If two lists have flags which hadn't been "true", deal with them.
        for(int i = 0, offset = 0; i < trackedBlobs.size(); i++) {
            if(!matchedTrackList[i]) {
                Blob tb = trackedBlobs.get(i);
                if(tb.isDisappeared()){
                    trackedBlobs.remove(i-offset);
                    offset++;
                }
            }
        }
        for(int j = 0; j < currentBlobs.size(); j++) {
            if(!matchedCurrentList[j]) {
                Blob cb = currentBlobs.get(j);
                cb.setId(blobCounter);
                trackedBlobs.add(cb);
                blobCounter = (blobCounter+1) % maxBlobNum;
            }
        }
    }

    public void addToCompartBlob(ArrayList<Blob> blobs, float x, float y) {
        boolean found = false;
            for(Blob b : blobs){
                if(b.isNear(x,y)){
                    b.add(x,y);
                    found = true;
                    break;
                }
            }
            if(!found){
                Blob b = new Blob(x,y);
                blobs.add(b);
            }
    }

    public void deleteNotQualifiedBlobs(ArrayList<Blob> blobsDetected) {
        for(int i=0; i<blobsDetected.size(); i++) {
            if(!blobsDetected.get(i).isBigEnough() || blobsDetected.get(i).isTooThin())
                blobsDetected.remove(i--);
        }
    }

}
class Phonograph {
    AudioSample sample;
    int timeLength;
    int timeStamp;
    int passedTime;
    boolean noPlayingState;

    Phonograph(String sampleFileName) {
        sample = minim.loadSample(sampleFileName);
        timeLength = sample.length();
        timeStamp = -timeLength;
        noPlayingState = false;
    }

    public void computePassedTime() {
        passedTime = millis() - timeStamp;
    }

    public void turnOn() {
        sample.trigger();
        timeStamp = millis();
    }

    public void turnOff() {
        sample.stop();
        timeStamp = -timeLength;// initial situation
    }

    public boolean isPlaying() {
        return passedTime < timeLength;
    }
}
  public void settings() {  size(640, 480); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Kinect2Sound" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
