class BlobHandler {
    int blobCounter = 0;
    final static int maxBlobNum = 20;    

    void checkTrackedBlobs(ArrayList<Blob> trackedBlobs,ArrayList<Blob> currentBlobs) {
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

    void addToCompartBlob(ArrayList<Blob> blobs, float x, float y) {
        boolean found = false;
        float minD = 10000000;
        Blob candidate = null;
            for(Blob b : blobs){
                // if(b.isNear(x,y)){
                //     b.add(x,y);
                //     found = true;
                //     break;
                // }
                if(b.distance2Point(x, y) < minD){
                    candidate = b;
                    minD = b.distance2Point(x, y);
                }
            }
            if(candidate != null)
                if(candidate.isNear(x, y)){
                    candidate.add(x, y);
                    found = true;
                }
            if(!found){
                Blob b = new Blob(x, y);
                blobs.add(b);
            }
    }

    void deleteNotQualifiedBlobs(ArrayList<Blob> blobsDetected) {
        for(int i=0; i<blobsDetected.size(); i++) {
            Blob thisBlob = blobsDetected.get(i);
            // if(!thisBlob.isBigEnough() || thisBlob.isTooThin())
            if(!thisBlob.isBigEnough() || thisBlob.isTooThin() || thisBlob.isTooSparse())
                blobsDetected.remove(i--);
        }
    }

    void checkOverlappedBlobs(ArrayList<Blob> blobs) {
        Blob blobA = null, blobB = null;
        for(int i=0; i<blobs.size(); i++) {
            for(int j=0; j<i; j++) {
                blobA = blobs.get(i);
                blobB = blobs.get(j);
                if(blobA.isOverlappedWith(blobB)){
                    //println("found overlap");
                    blobA.combine(blobB);
                    blobs.remove(j);
                    i--;
                    j--;
                }
            }
        }
    }
}