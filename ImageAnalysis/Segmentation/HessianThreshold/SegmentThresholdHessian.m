function lab = SegmentThresholdHessian(img, minRUnit, maxRUnit, minSizeUnit, maxSizeUnit, nScale, pixelSize, noiseThresh)

    scaleOverRadiusRatio = 1/2;
    minScale = minRUnit * scaleOverRadiusRatio;
    maxScale = maxRUnit * scaleOverRadiusRatio;
    [s, ss1, ss2, ss3] = getScaleSpace(nScale,minScale,maxScale, pixelSize);
    [~,t] = threshold(img, 'otsu');
    imgt = threshold(bilateralf(img), 'fixed',0.1*t);
    imgt = bmajority(imgt);
    
    bimgall = newim(size(img));
    for k = 1:nScale
        L = hessianNormalized3D( img, ss1(k), ss2(k), ss3(k) );
        bLxx = L{1,1} < -noiseThresh;
        bLyy = L{2,2} < -noiseThresh;
        bLzz = L{3,3} < -noiseThresh;
        b = bLxx .* bLyy .* bLzz .* imgt;
        bimgall = bimgall + b;
    end

    bimgb = bimgall > 0;
    dV = prod(pixelSize);
    minSize = round(minSizeUnit/dV);
    maxSize = round(maxSizeUnit/dV);
    lab = label(bimgb,1, minSize, maxSize );

end
