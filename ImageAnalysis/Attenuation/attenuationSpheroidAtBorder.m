function [maskAttenuation, imgCorrected] = attenuationSpheroidAtBorder( img, lab, dx, dz, sigma)

    sz = imsize(img);
    labSpheroid = newim(sz);
    maskAttenuation = newim(sz);
    
    % Mean intensity inside spheroid compared to 'first layer'
    Iavg = lab
    imgCorrected = ( max(maskAttenuation) * max(Iavg) - min() * Iavg() * maskAttenuation) .* img;


end

