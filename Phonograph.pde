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

    void computePassedTime() {
        passedTime = millis() - timeStamp;
    }

    void turnOn() {
        sample.trigger();
        timeStamp = millis();
    }

    void turnOff() {
        sample.stop();
        timeStamp = -timeLength;// initial situation
    }

    boolean isPlaying() {
        return passedTime < timeLength;
    }
}