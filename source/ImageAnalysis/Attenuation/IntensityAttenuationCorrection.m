function imgCorrected = IntensityAttenuationCorrection( img, derx, derz, sigma, firstSlice, decayFactor)
% IntensityAttenuationCorrection: Returns an image corrected for
% attenuation by using the intensity of the image as absorbing quantity 
% (the chorofores absorb also), the exponential decay is given by a
% decaying factor
%
%   INPUT:  
%       img               : the image
%       dx                : Pixelsize x (y) direction
%       dz                : Pixelsize z direction
%       sigma             : The smoothing


    sz = imsize(img);
    imgG = gaussf(img, sigma);

    % The attenuation of the image is larger with each layer the light has 
    % to pass through tissue (the spheroid). The border of the spheroid is 
    % given by 'labSperoid'. We let 'maskAttenuation' represent the
    % amount of layers the light has to pass to reach each pixel.
    maskAttenuation = 0 * img;
    for j = 1:sz(3)
        if (j > 1)
            maskAttenuation(:,:,j-1) = maskAttenuation(:,:,j-2) + 1; %imgG(:,:,j-1);
        end
    end
    maskAttenuation = maskAttenuation/max(maskAttenuation);
    % % Plots for testing:
    %H = dipshow(maskAttenuation); dipmapping(H,'xy'); dipmapping(H,'global'); dipmapping(H,'lin'); diptruesize(H,100); dipstep(H,'on');

    % 'maskAttenuation' gives the amount of layers the light has to pass to
    % reach a pixel, for each layer the intensity diminishes by a small
    % factor: I --> I * (1 - d), which means the intensity will decay 
    % exponentially with the amount of layers:
    %
    %       I_att(:,:,n) = I_0(:,:,n) * exp[ - decayFactor * maskAttenuation(:,:,n) ]
    %
    imgCorrected = imgG;
    imgCorrected(:,:,firstSlice:end) = exp(decayFactor * maskAttenuation(:,:,firstSlice:end)) .* imgG(:,:,firstSlice:end);
end
