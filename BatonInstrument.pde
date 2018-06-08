class BatonInstrument implements Instrument{
    void noteOn(float duration) {
        checkBlobTouchingState(duration);
        //if is amid certain
            //do createSound
        //else 
            //do not make sound
    }

    void noteOff() {
        // keep the instrument repeating
        out.playNote(0, 0.25f, this);
    }

    void checkBlobTouchingState(float duration) {
        for(int i=0;i<trackedBlobs.size();i++) {
            Blob b = trackedBlobs.get(i);
            if(b.touchingState == true) {
                //get the position and make sound by that
                sampleBox.createSound(b.getCenter(), duration);
            }
        }
    }
}