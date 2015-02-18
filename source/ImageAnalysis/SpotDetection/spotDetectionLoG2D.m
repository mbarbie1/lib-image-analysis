%%% Method 1: 2D LoG
function [outputMaxima, outputLab] = spotDetectionLoG2D(imgMIPZ, imgMIPZH, lab, pixelSizeR, avgSpotRadius, maxSpotRadius)

    radiusToGaussianScale = 1/2;
    scale = avgSpotRadius * radiusToGaussianScale / pixelSizeR;
    imgLoG = laplace(imgMIPZ, scale ) .* scale^2;

    imgt = threshold(-imgLoG,'otsu');

    max_depth = round( ( max(imgMIPZ) - min(imgMIPZ) ) * 0.5 );
    max_size = ceil( ( maxSpotRadius / pixelSizeR )^2 * pi );
    imgw = dip_localminima(imgLoG, imgt, 2, max_depth, max_size, 1);
    
    spotListXY = ind2sub(imgw,find(imgw));
    outputLab = imgw;
    for k = 1:length(spotListXY(:,1))
        outputMaxima(k).x = spotListXY(k,1);
        outputMaxima(k).y = spotListXY(k,2);
        outputMaxima(k).z = dip_array(imgMIPZH(spotListXY(k,1), spotListXY(k,2))) + 1;
        outputMaxima(k).intensity = dip_array( imgMIPZ(spotListXY(k,1), spotListXY(k,2)) );
        outputMaxima(k).inputLabIndex = dip_array( lab(spotListXY(k,1), spotListXY(k,2)) );
        outputLab(spotListXY(k,1), spotListXY(k,2)) = k;
    end

end
