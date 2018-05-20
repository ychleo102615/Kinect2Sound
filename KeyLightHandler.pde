class KeyLightHandler {
    File[] files;
    String[] fileNames;
    AudioSample[] samples;
    Sampler[] samplers;
    int gridScale = 100;

    KeyLightHandler(){}

    KeyLightHandler(String[] fileNames_) {
        fileNames = fileNames_;
    }

    void readSamples() {
        samples = new AudioSample[fileNames.length];
        samplers = new Sampler[fileNames.length];
        for(int i=0; i<fileNames.length; i++) {
            println("fileName: "+fileNames[i]);
            samples[i] = minim.loadSample(fileNames[i]);
            samplers[i] = new Sampler(fileNames[i], 4, minim);
            samplers[i].patch(out);
        }
    }

    void addOrDeleteKeyLight(ArrayList<KeyLight> keyLights, int idNote, PVector position) {
        position = mouse2Grid(position);
        boolean deleteFlag = false;

        for(KeyLight k : keyLights) {
            if(PVector.dist(k.position, position) == 0){
                deleteFlag = true;
                keyLights.remove(k);
                instrument.deleteNote();
                break;
            }
        }
        if(deleteFlag == false){
            KeyLight newLight = new KeyLight(getSampleNameByPosition(position), 
                                            position, idNote);
            keyLights.add(newLight);
        }
        caculateDistancesOfKeyLights(keyLights);
    }

    PVector mouse2Grid(PVector mousePosition) {
        mousePosition.x += -mousePosition.x % gridScale + gridScale/2;
        mousePosition.y += -mousePosition.y % gridScale + gridScale/2;
        return mousePosition;
    }

    String getSampleNameByPosition(PVector position) {
        int gridNum = fileNames.length;
        float gridLength = width/gridNum;

        // This seems to be an ugly code
        for(int i=0;i<fileNames.length; i++) {
            if(position.x < gridLength*(i+1)){
                return fileNames[i];
            }
        }
        return "";
    }

    void caculateDistancesOfKeyLights(ArrayList<KeyLight> keyLights) {
        int size = keyLights.size();
        float distance;
        float dis2timeFactor = 5;
        KeyLight thisOne;// = keyLights.get(0);
        KeyLight nextOne;

        if(size == 0)
            return;
        thisOne = keyLights.get(0);
        if(size > 1) {
            for(int i=0; i<size-1; i++) {
                nextOne = keyLights.get(i+1);
                distance = PVector.dist(thisOne.position, 
                                        nextOne.position);
                thisOne.setLength(distance*dis2timeFactor);
                thisOne = nextOne;
            }
            nextOne = keyLights.get(0);
            distance = PVector.dist(thisOne.position, nextOne.position);
            thisOne.setLength(distance*dis2timeFactor);
        }
        else if (size == 1)
            thisOne.setLength(1500.0);
    }
}