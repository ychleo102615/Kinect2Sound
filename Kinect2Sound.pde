/*
    Kinect zone
*/
import org.openkinect.processing.*;
Kinect kinect;
float tiltAngle = .0;
/*
    Vision zone
*/
color trackColor;
PImage img;
PImage depth;
int rawDepthValue[];

BlobHandler blobHandler = new BlobHandler();
ArrayList<Blob> trackedBlobs = new ArrayList<Blob>();
float similarPixelThreshold = 2100;

Curtain curtain = new Curtain();
/*
    Minim Zone
*/
import ddf.minim.*;
import ddf.minim.ugens.*;

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

void setup() {
    size(640, 480);
    kinect = new Kinect(this);
    kinect.initVideo();
    kinect.initDepth();
    kinect.enableMirror(true);

    trackColor = color(190, 45, 45);

    minim = new Minim(this);
    out = minim.getLineOut();
    files = new File(sketchPath()+"/data").listFiles();
    // phonographs = new Phonograph[files.length];
    // for(int i=0; i<files.length; i++) {
    //     if(files[i].isFile()) {
    //         phonographs[i] = new Phonograph(files[i].getName());
    //         println(files[i].getName());
    //     }
    // }
}

void draw() {
    img = kinect.getVideoImage();
    kinect.setTilt(constrain(tiltAngle, .0, 30.0));
    depth = kinect.getDepthImage();
    image(img, 0, 0);
    rawDepthValue = kinect.getRawDepth();

    // pushMatrix();
    // scale(0.25);
    // image(depth, 0, 0);
    // popMatrix();

    ArrayList<Blob> blobs = new ArrayList<Blob>();
    img.loadPixels();
    for(int x = 0; x < img.width; x++){
        for(int y = 0; y < img.height; y++){
            int actualLoc = x + y*img.width;

            color currentColor = img.pixels[actualLoc];
            float r1 = red(currentColor);
            float g1 = green(currentColor);
            float b1 = blue(currentColor);

            float r2 = red(trackColor);
            float g2 = green(trackColor);
            float b2 = blue(trackColor);

            float d = distSq(r1, g1, b1, r2, g2, b2);
            if(d < similarPixelThreshold){
                blobHandler.addToCompartBlob(blobs, x, y);
            }

            // if(curtain.isAmidCurtain(rawDepthValue[actualLoc]))
            //     img.pixels[actualLoc] = color(255, 0, 0);
        }
    }
    img.updatePixels();
    //image(img, 0, 0);
    blobHandler.deleteNotQualifiedBlobs(blobs);
    blobHandler.checkOverlappedBlobs(blobs);
    blobHandler.checkTrackedBlobs(trackedBlobs, blobs);

    for(Blob b : trackedBlobs){
        b.show();
    }

    curtain.checkBlobTouchingState(trackedBlobs);

    fill(0, 255, 0);
    text(curtain.closeDistance, 0, 20);
    text(curtain.farDistance, 0, 40);

    // setPhonographs();

    // Show track color
    fill(trackColor);
    pushMatrix();
    translate(mouseX, mouseY);
    rectMode(CENTER);
    rect(0,0,15,15);
    popMatrix();
}

float distSq(float r1, float g1, float b1, float r2, float g2, float b2){
    return (r1-r2)*(r1-r2) + (g1-g2)*(g1-g2) + (b1-b2)*(b1-b2);
}
float distSq(float r1, float g1, float r2, float g2){
    return (r1-r2)*(r1-r2) + (g1-g2)*(g1-g2);
}

void mousePressed() {
    img.loadPixels();    
    // int loc = (width-1-mouseX) + mouseY*width;
    int loc = mouseX + mouseY*width;
    trackColor = img.pixels[loc];
}

void setPhonographs() {
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

void keyPressed() {
    float skip = 0.25;
    if(key == CODED) {
        if(keyCode == UP)
            tiltAngle += skip;
        if(keyCode == DOWN)
            tiltAngle -= skip;
    }
    else if (key == ' ')
        tiltAngle = 0;
    else {
        switch(key) {
            case 'q':
                curtain.addCloseDistance();
                break;
            case 'w':
                curtain.substractCloseDistance();
                break;
            case 'a':
                curtain.addFarDistance();
                break;
            case 's':
                curtain.substractFarDistance();
                break;
            default:
        }
    }
}

class Curtain {
    int closeDistance;
    int farDistance;
    int step = 20;

    Curtain() {
        closeDistance = 860;
        farDistance = 900;
    }

    void addCloseDistance() {
        closeDistance += step;
        if(isDistanceValid())
            closeDistance -= step;
    }

    void substractCloseDistance() {
        closeDistance -= step;
        if(isDistanceValid())
            closeDistance += step;
    }

    void addFarDistance() {
        farDistance += step;
        if(isDistanceValid())
            farDistance -= step;
    }

    void substractFarDistance() {
        farDistance -= step;
        if(isDistanceValid())
            farDistance += step;
    }

    boolean isDistanceValid() {
        if(closeDistance >= farDistance)
            return true;
        return false;
    }

    boolean isAmidCurtain(int depthValue) {
        if(depthValue > closeDistance && depthValue < farDistance) {
            return true;
        }
        else
            return false;
    }

    boolean isAmidCurtain(Blob b) {
        PVector position = b.getCenter();
        int depthValue = rawDepthValue[(int)position.x + (int)position.y*depth.width];

        if(depthValue > closeDistance && depthValue < farDistance) {
            return true;
        }
        else
            return false;
    }

    void checkBlobTouchingState(ArrayList<Blob> blobs) {
        for(Blob b : blobs){
            if(isAmidCurtain(b)){
                if(b.touchingState == false){
                    // blob touch the curtain
                    // do the trigger thing
                    b.flipTouchingState();
                }
                else {
                    // do not trigger
                }
            }
            else {
                // blob leave the curtain
                if(b.touchingState == true) {
                    b.flipTouchingState();
                }
            }
        }
    }
}