function imgCorrected = IntensityAttenuationCorrectionSimpleFlat( img, firstSlice, decayFactorMethod, fixedDecay)
% IntensityAttenuationCorrectionFlat: Returns an image corrected for
% attenuation by supposing an exponential decay only dependent on the 
% amount of layers. The decaying factor is calculated by 
%
%   INPUT:  
%       img               : the image
%       dx                : Pixelsize x (y) direction
%       dz                : Pixelsize z direction
%       sigma             : The smoothing


    sz = imsize(img);

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
    % But we don't know the factor decayFactor, so we have to guess it.
    % 'decayFactorMethod' is the method used to find the 'decayFactor'
    switch decayFactorMethod
        case 'fixed'
            % Fixed decaying factor 'decayFactor':
            decayFactor = fixedDecay;
        case 'exponentialFit'
            % We can guess 'decayFactor' by assuming that the unattenuated intensity 
            % inside the spheroid should be everywhere the same on average. 
            % Therefore we could fit an exponential to the measured mean intensity
            % values of the different layers in the spheroid.
            msrSet = ones(1,sz(3));
            decayFactor = estimateAttenuationDecayFromExponentialFit(img, img > 0, msrSet);
        case 'exponentialMinMax'
            % Here again, we guess the decaying factor 'a' by assuming that the unattenuated intensity 
            % inside the spheroid should be everywhere the same on average. 
            % Therefore we could fit an exponential to the measured mean intensity
            % values of the different layers in the spheroid.
            % But we take only the layer with the highest intensity and the
            % last layer into account for the fit.
            msrSet = ones(1,sz(3));
            decayFactor = estimateAttenuationDecayFromExponentialMinMax(img, img > 0, msrSet);
        otherwise
            decayFactor = 0;
            warning('The decaying factor is not defined, assuming it is zero.');
    end
    imgCorrected = imgG;
    imgCorrected(:,:,firstSlice:end) = exp(decayFactor * maskAttenuation(:,:,firstSlice:end)) .* imgG(:,:,firstSlice:end);
end

function a = estimateAttenuationDecayFromExponentialFit(img, mask, msrSet)

    % We can guess decaying factor 'a' by assuming that the unattenuated intensity 
    % inside the spheroid should be everywhere the same on average. 
    % Therefore we could fit an exponential to the measured mean intensity
    % values of the different layers in the spheroid.
    msrList = {'Size','Mean'};
    sz = imsize(img);
    for j = 1:sz(3)
        msrR{j} = measure(mask(:,:,j-1)~=0, img(:,:,j-1), msrList, [], inf, 0, 0);
    end
    % Mean intenstity of each spheroid z-slice
    Iavg = zeros(size(msrSet));
    Iavg(logical(msrSet)) = msrFeatureToArray( msrR(logical(msrSet)), 'Mean');
    %
    % Fit an exponential decaying function through the mean intenstity of each spheroid
    % z-slice:  Iavg(n) = Iavg(0)*exp(-a*n)
    %
    xdata = 1:sum(msrSet);
    ydata = Iavg(logical(msrSet));
    [estimates, model] = exponential_fit(xdata,ydata);
    %
    plot(xdata, ydata, '*')
    hold on
    [~, FittedCurve] = model(estimates);
    plot(xdata, FittedCurve, 'r');
    %
    xlabel('xdata');
    ylabel('f(estimates,xdata)');
    title(['Fitting to function ', func2str(model)]);
    legend('data', ['fit using ', func2str(model)]);
    hold off
    %
    a = - estimates(2);
end

function a = estimateAttenuationDecayFromExponentialMinMax(img, labSpheroid, msrSet)

    % We can guess decaying factor a by assuming that the unattenuated intensity 
    % inside the spheroid should be everywhere the same on average. 
    % Therefore we could fit an exponential to the measured mean intensity
    % values of the different layers in the spheroid. Here we guess the
    % exponential decay by only taking two points for the fitting:
    % the highest intensity plane and the last plane
    msrList = {'Size','Mean'};
    sz = imsize(img);
    for j = 1:sz(3)
        msrR{j} = measure(labSpheroid(:,:,j-1)~=0, img(:,:,j-1), msrList, [], inf, 0, 0);
    end
    % Mean intenstity of each spheroid z-slice
    Iavg = zeros(size(msrSet));
    Iavg(logical(msrSet)) = msrFeatureToArray( msrR(logical(msrSet)), 'Mean');
    %
    % Fit an exponential decaying function through the mean intenstity of 2 spheroid
    % z-slices:  Iavg(n) = Iavg(0)*exp(-a*n)
    [IavgMax, indMax] = max(Iavg);
    Dindex = length(Iavg) - indMax;
    DI = IavgMax - Iavg(find(msrSet,1,'last'));
    I0 = IavgMax;
    %
    % exp(a * Dindex) = (I0 - DI) / I0
    % ==> a = log(1-DI/I0) / Dindex
    a = - log(1-DI/I0) / Dindex;
    figure(); plot(Iavg);
    hold on; plot(I0 * exp(a));

end
