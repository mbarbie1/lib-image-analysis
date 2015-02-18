function lab = segmentHeightMap2D( imgMIPZ, imgMIPZH, pixelSize, minRadius, neighbourhoodRadius, maxRangeZ, removeBorderObjectsInPlane, removeBorderObjectsInZ, borderZRemoveMethod, thresholdIntensity)

    % nnSize = 3
    % maxRangeZ = 3
    kernelSize = 2 * max( 1, round( neighbourhoodRadius / pixelSize(1) ) )  +  1;
    disp(kernelSize);
    maxRangeZPixels = max( 1 + 0.0001, maxRangeZ / pixelSize(3) );
    disp(maxRangeZPixels);

    minH = min(imgMIPZH);
    maxH = max(imgMIPZH);
    img_range = dip_image( rangefilt( dip_array(imgMIPZH), true(kernelSize) ) );
    imgt = fillholes(img_range < maxRangeZPixels );
    
    lab = label(  imgt, 1, round( pi*(minRadius/pixelSize(1))^2), 0  );

    %%% Threshold intensity
    if ( thresholdIntensity > 0 )
        msr = measure(lab, imgMIPZ, ({'mean'}));
        imgMean = msr2obj(lab,msr,'mean');
        imgt_intensity = threshold(imgMean, 'fixed', thresholdIntensity);
        imgt = imgt .* imgt_intensity;
    end

    %%% REMOVE EDGE OBJECTS in (x,y)-plane
    if ( removeBorderObjectsInPlane == true )
        tic 
        imgt = brmedgeobjs(imgt,1);
        lab = label(  imgt, 1, round( pi*(minRadius/pixelSize(1))^2), 0  );
        toc
    end

    %%% REMOVE EDGE OBJECTS along z
    if (removeBorderObjectsInZ == true)
        if strcmp(borderZRemoveMethod, 'meanBorder') 
            img_borderOfSpheroids = (imgt-berosion(imgt));
            msr = measure(img_borderOfSpheroids, imgMIPZH, {'mean'});
            imgZmean = msr2obj(lab,msr,'mean');
            lab(imgZmean >= max(imgZmean)-1) = 0;
            lab(imgZmean <= min(imgZmean)+1) = 0;
        else
            lab = removeBorderObjects(lab, imgMIPZH, minH+1, maxH-1);
        end
    end

end