class KeyLight {
    AudioSample sample;
    Sampler sampler;
    Line ampEnv;
    float noteLength;
    PVector position;
    color noteColor;
    int id;
    float lightRadius;

    KeyLight(String fileName, PVector p, int id_) {
        // sample = minim.loadSample(fileName);
        sampler = new Sampler(fileName, 4, minim);
        ampEnv = new Line();
        ampEnv.patch(sampler.amplitude);
        sampler.patch(out);
        // noteLength = sample.length();
        position = p;
        id = id_;
        lightRadius = keyLightHandler.gridScale;
        setRandomColorById();
    }
    
    // AudioSample getSample() {
    //     return sample;
    // }

    void setLightRadius(float givenRadius) {
        lightRadius = givenRadius;
    }

    void createSound(float releaseTime) {
        ampEnv.activate( releaseTime, 1.5f, 0 );
        sampler.trigger();
        setActivateColor();
    }

    void closeSound() {
        sampler.stop();
        setDeactivateColor();
    }

    float getLength() {
        return noteLength;
    }

    void setLength(float len) {
        noteLength = len;
    }

    void show() {
        fill(noteColor);
        ellipse(position.x, position.y, lightRadius, lightRadius);
        fill(255);
        text(id, position.x, position.y);
    }
    void show(int order) {
        fill(noteColor);
        ellipse(position.x, position.y, lightRadius, lightRadius);
        fill(255);
        text(id, position.x, position.y);
        text(order, position.x, position.y+10);
    }

    void setRandomColorById() {
        randomSeed(id+(int)random(12345678));
        noteColor = color(random(0, 255), random(0, 255), random(0, 255), 128);
    }

    void setActivateColor() {
        noteColor = color(red(noteColor), green(noteColor), blue(noteColor), 255);        
    }

    void setDeactivateColor() {
        noteColor = color(red(noteColor), green(noteColor), blue(noteColor), 128);        
    }

    void showColor() {
        println(id, red(noteColor), green(noteColor), blue(noteColor), alpha(noteColor));
    }
}

class KeyLightInstrument implements Instrument{

    int notePointer;
    KeyLight thisNote;
    KeyLightInstrument() {
        notePointer = 0;
    }

    void noteOn(float duration) {
        if(keyLights.size() > 0) {
            thisNote = keyLights.get(notePointer);
            thisNote.createSound(0.8*duration);
            println("<<<<<<note on<<<<<");
        }
        //else
            // println("nothing in que..");
    }

    void noteOff() {
        if(keyLights.size() > 0){
            println(">>>>note off>>>>");
            if(thisNote != null)
                thisNote.closeSound();
            
            // Proceed to next note
            // println("notePointer: "+notePointer);            
            int nextNotePointer = (notePointer+1) % keyLights.size();
            // println("notePointer after: "+notePointer);            
            float msOfNextNote = keyLights.get(nextNotePointer).getLength();
            out.playNote( 0, milliSeconds2beats(msOfNextNote), this );
            notePointer = nextNotePointer;
            println("next's length: " + msOfNextNote);
        }
        else{//keep waiting for keylight
            out.playNote(0, 0.25f, this);
            // println("playing nothing...");
        }
    }

    float milliSeconds2beats(float second) {
        float bpm = out.getTempo();
        return second/1000 * bpm/60;
    }

    void deleteNote() {
        notePointer--;
        if(notePointer < 0)
            notePointer = 0;
    }
}