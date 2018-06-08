class SampleBox {
    Sampler[] samplers;
    Line[] ampEnvs;
    int channelNum;

    SampleBox(String[] fileNames) {
        channelNum = fileNames.length;
        samplers = new Sampler[channelNum];
        ampEnvs = new Line[channelNum];

        for(int i=0;i<channelNum;i++) {
            samplers[i] = new Sampler(fileNames[i], 4, minim);
            ampEnvs[i] = new Line();
            ampEnvs[i].patch(samplers[i].amplitude);
            samplers[i].patch(out);
        }
        //ampEnv.patch(sampler.amplitude);
    }

    void createSound(PVector position, float duration) {
        int ptr = position2Ptr(position);
        ampEnvs[ptr].activate( duration, 1.5f, 0 );
        samplers[ptr].trigger();
    }

    void closeSound(PVector position) {
        samplers[position2Ptr(position)].stop();
    }

    int position2Ptr(PVector position) {
        float ptr =  (float)position.x/width*channelNum;
        return (int)ptr;
    }
}