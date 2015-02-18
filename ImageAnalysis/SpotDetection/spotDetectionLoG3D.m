%%% Method 1: 2D LoG
function [outputMaxima, outputLab] = spotDetectionLoG3D(img, lab, pixelSize, avgSpotRadius, maxSpotRadius)

    radiusToGaussianScale = 1/2;
    s = avgSpotRadius * radiusToGaussianScale ./ pixelSize;
    imgLoG = laplacianNormalized3D(img, s(1), s(2), s(3));

    imgt = threshold(-imgLoG,'otsu');

    max_size = ceil( getVolumeSphere(maxSpotRadius) / prod(pixelSize) );
    max_depth = ceil( 0.5 * ( max(imgLoG) - min(imgLoG) ) );
    outputLab = dip_localminima(imgLoG, imgt, 2, max_depth, max_size, 1);

    spotList = ind2sub( outputLab, find(outputLab) );

    outputLab = newim(size(outputLab));
    for k = 1:length(spotList(:,1))
        outputMaxima(k).x = spotList(k,1);
        outputMaxima(k).y = spotList(k,2);
        outputMaxima(k).z = spotList(k,3);
        outputMaxima(k).intensity = double( img(spotList(k,1), spotList(k,2), spotList(k,3) ) );
        % Switch x, y for indexing? but we used ind2sub of dipimage?
        %   test: fprintf('value(%i,%i,%i) = %i\n', spotList(k,1), spotList(k,2), spotList(k,3), lab( spotList(k,2), spotList(k,1), spotList(k,3) ));
        outputMaxima(k).inputLabIndex = int32( lab( spotList(k,2), spotList(k,1), spotList(k,3) ) );
        outputLab(spotList(k,1), spotList(k,2), spotList(k,3)) = k;
    end

end
