function lab = SegmentThresholdSimple(img, minSizeUnit, maxSizeUnit, pixelSize)

    [~,t] = threshold(img, 'otsu');
    imgt = threshold(bilateralf(img), 'fixed',1*t);
    imgt = bmajority(imgt);
    
    dV = prod(pixelSize);
    minSize = round(minSizeUnit/dV);
    maxSize = round(maxSizeUnit/dV);
    lab = label(imgt, 1, minSize, maxSize );

end
