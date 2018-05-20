class Blob {
    float upboundX, lowerboundX, upboundY, lowerboundY;
    int id;
    int maxLife = 5;
    int lifespan = maxLife;
    color blobColor = color(255, 200);
    boolean touchingState;
    ArrayList<PVector> points;
    int blobAddPointThreshold = 1500;
    float densityThreshold = 75;
    
    Blob(float x_, float y_){
        upboundX = x_;
        upboundY = y_;
        lowerboundX = x_;
        lowerboundY = y_;
        id = 0;
        points = new ArrayList<PVector>();
        // Add blue color to dot qualified
        stroke(0, 255, 0);        
        points.add(new PVector(x_, y_));

        touchingState = false;
    }

    boolean isDisappeared() {
        lifespan--;
        return lifespan < 0;
    }

    void lifespanReset() {
        lifespan = maxLife;
    }

    void setId(int givenId) {
        id = givenId;
        setRandomColorById();
    }

    void become(Blob otherBlob) {
        upboundX = otherBlob.upboundX;
        upboundY = otherBlob.upboundY;
        lowerboundX = otherBlob.lowerboundX;
        lowerboundY = otherBlob.lowerboundY;
    }

    void add(float x_, float y_ ) {
        upboundX = max(upboundX, x_);
        upboundY = max(upboundY, y_);
        lowerboundX = min(lowerboundX, x_);
        lowerboundY = min(lowerboundY, y_);
        points.add(new PVector(x_, y_));
        point(x_, y_);
    }

    boolean isNear(float x_, float y_){
        PVector corner = getClosestCorner(x_, y_);
        PVector center = getCenter();
        float d = distSq(corner.x, corner.y, x_, y_);
        d = min(d, distSq(center.x, center.y, x_, y_));

        /****
            Points version
            which cost too many cpu resource
        ****/
        // d = 10000000;
        // for (PVector v : points) {
        //     float tempD = distSq(x_, y_, v.x, v.y);
        //     if (tempD < d) {
        //         d = tempD;
        //     }
        // }
        if(d < blobAddPointThreshold){
            return true;
        }
        else{
            return false;
        }
    }

    PVector getClosestCorner(float x_, float y_) {
        PVector corner = new PVector(x_, y_);
        corner.x = max(min(corner.x, upboundX), lowerboundX);
        corner.y = max(min(corner.y, upboundY), lowerboundY);
        return corner;
    }

    float distance2Point(float x_, float y_) {
        PVector center = getCenter();
        return distSq(center.x, center.y, x_, y_);
    }

    PVector getCenter() {
        float centerX = (upboundX + lowerboundX)/2;
        float centerY = (upboundY + lowerboundY)/2;
        return new PVector(centerX, centerY);
    }

    void show() {
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
        text(blobArea(), center.x, center.y+30);
    }

    void setRandomColorById() {
        randomSeed(id+(int)random(12345678));
        blobColor = color(random(0, 255), random(0, 255), random(0, 255), 200);
    }

    float blobArea(){
        return (upboundX - lowerboundX) * (upboundY + lowerboundY);
    }

    boolean isBigEnough() {
        float areaThreshold = 8000;
        if(this.blobArea() > areaThreshold)
            return true;
        else
            return false;
    }

    
    boolean isOverlappedWith(Blob target) {
        if(
            (target.upboundX > lowerboundX && upboundX > target.lowerboundX)&&
            (target.upboundY > lowerboundY && upboundY > target.lowerboundY)
        )
            return true;
        else
            return false;
    }

    void combine(Blob target) {
        upboundX = max(upboundX, target.upboundX);
        lowerboundX = min(lowerboundX, target.lowerboundX);
        upboundY = max(upboundY, target.upboundY);
        lowerboundY = min(lowerboundY, target.lowerboundY);
        points.addAll(target.points);
    }

    boolean isTooThin() {
        float blobWidth  = upboundX - lowerboundX;
        float blobHeight = upboundY - lowerboundY;
        float ratioThreshold = 20.0;
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

    boolean isTooSparse() {
        int pointSum = points.size();
        float area = blobArea();
        // println("dots and area: "+ pointSum +" "+ area);
        // println("ratio: " + area/pointSum);
        if(area/pointSum > densityThreshold)
            return true;
        return false;
    }

    void flipTouchingState() {
        if(touchingState == true) {
            touchingState = false;
            setDeactivateColor();
        }
        else {
            touchingState = true;
            setActivateColor();
        }
    }

    void setActivateColor() {
        blobColor = color(red(blobColor), green(blobColor), blue(blobColor), 255);        
    }

    void setDeactivateColor() {
        blobColor = color(red(blobColor), green(blobColor), blue(blobColor), 200);        
    }
}