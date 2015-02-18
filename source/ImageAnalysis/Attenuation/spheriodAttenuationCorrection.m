function [labSpheroid, imgCorrected] = spheriodAttenuationCorrection( img, lab, dx, dz, sigma, atBorder, decayFactorMethod, fixedDecay)
% spheriodAttenuationCorrection: Returns an image corrected for attenuation
%
%   INPUT:  
%       img               : the image
%       lab               : the mask of the image
%       dx                : Pixelsize x (y) direction
%       dz                : Pixelsize z direction
%       sigma             : The smooting in the x,y plane to get the border
%                             of the spheroid 
%       atborder          : equals to 1 if the spheroid is not included
%                              completely in the image


%% Case 1: object is in the middle
    if (atBorder == 0)
        [maskAttenuation, labSpheroid, imgCorrected] = spheroidNotAtBorder( img, lab, dx, dz, sigma, decayFactorMethod, fixedDecay);
%% Case 2: object is at border
    else
        [maskAttenuation, labSpheroid, imgCorrected] = spheroidNotAtBorder( img, lab, dx, dz, sigma, decayFactorMethod, fixedDecay);
    end
    
end

function [maskAttenuation, imgCorrected] = spheroidAtBorder( img, lab, dx, dz, sigma)
    sz = imsize(img);
    labSpheroid = newim(sz);
    maskAttenuation = newim(sz);
    
    % TODO
    imgCorrected = img;
end

function [maskAttenuation, labSpheroid, imgCorrected] = spheroidNotAtBorder( img, lab, dx, dz, sigma, decayFactorMethod, fixedDecay)
    sz = imsize(img);
    labSpheroid = newim(sz);
    maskAttenuation = newim(sz);
    plotExponentialFit = false;

    % We need a mask of the image that is not that sensitive to
    % attenuation. We can do it by (thresholding) segmenting plane by plane.
    % So, first we loop over the planes and check whether the plane n has some
    % spheroid, if so 'msrSet(n) = 1' and we threshold the plane (thereby we 
    % will be less dependent on the attenuation for deeper layers).
    % Afterwards we fill the holes in the labeled plane 'labplane'.
    % This gives us a newly labeled image 'labSperoid'.
    msrSet = zeros(1,sz(3));
    for j = 1:sz(3)
        plane = squeeze(img(:,:,j-1));
        labPlane = squeeze(lab(:,:,j-1));
        if (max(labPlane) > 0)
            temp = threshold( gaussf(plane,[sigma,sigma]), 'otsu');
            msrSet(j) = 1;
        else
            temp = labPlane;
            msrSet(j) = 0;
        end
        labPlane = bmajority( bclosing( bclosing( fillholes(temp) ) ) );
        labSpheroid(:,:,j-1) = labPlane;
    end

    % The attenuation of the image is larger with each layer the light has 
    % to pass through tissue (the spheroid). The border of the spheroid is 
    % given by 'labSperoid'. We let 'maskAttenuation' represent the
    % amount of layers the light has to pass to reach each pixel.
    for j = 1:sz(3)
        if (j > 1)
            maskAttenuation(:,:,j-1) = maskAttenuation(:,:,j-2) + labSpheroid(:,:,j-1);
        end
    end
    % % Plots for testing:
    % contourSpheroid = createContourLabOverlay( img(:,:,:), labSpheroid(:,:,:));
    % H = dipshow(contourSpheroid); dipmapping(H,'xy'); dipmapping(H,'global'); dipmapping(H,'lin'); diptruesize(H,100); dipstep(H,'on');
    % H = dipshow(maskAttenuation); dipmapping(H,'xy'); dipmapping(H,'global'); dipmapping(H,'lin'); diptruesize(H,100); dipstep(H,'on');

    
    % 'maskAttenuation' gives the amount of layers the light has to pass to
    % reach a pixel, for each layer the intensity diminishes by a small
    % factor: I --> I * (1 - d), which means the intensity will decay 
    % exponentially with the amount of layers:
    %
    %       I_att(:,:,n) = I_0(:,:,n) * exp[ - a * maskAttenuation(:,:,n) ]
    %
    % But we don't know the factor a, so we have to guess it.
    % 'decayFactorMethod' is the method used to find the decaying factor 'a'
    plotResults = plotExponentialFit;
    switch decayFactorMethod
        case 'fixed'
            % Fixed decaying factor 'a':
            a = fixedDecay;
        case 'exponentialFit'
            % We can guess decaying factor 'a' by assuming that the unattenuated intensity 
            % inside the spheroid should be everywhere the same on average. 
            % Therefore we could fit an exponential to the measured mean intensity
            % values of the different layers in the spheroid.
            a = estimateAttenuationDecayFromExponentialFit(img, labSpheroid, msrSet, plotResults);
        case 'exponentialMinMax'
            % Here again, we guess the decaying factor 'a' by assuming that the unattenuated intensity 
            % inside the spheroid should be everywhere the same on average. 
            % Therefore we could fit an exponential to the measured mean intensity
            % values of the different layers in the spheroid.
            % But we take only the layer with the highest intensity and the
            % last layer into account for the fit.
            a = estimateAttenuationDecayFromExponentialMinMax(img, labSpheroid, msrSet, plotResults);
        otherwise
            a = 0;
            warning('The decaying factor is not defined, assuming it is zero.');
    end
%
    % We can guess decaying factor a by assuming that the unattenuated intensity 
    % inside the spheroid should be everywhere the same on average. 
    % Therefore we could fit an exponential to the measured mean intensity
    % values of the different layers in the spheroid.
%%%%    a = estimateAttenuationDecayFromExponentialMinMax(img, labSpheroid, msrSet);
    imgCorrected = exp(a * maskAttenuation) .* img;
    % a = estimateAttenuationDecayFromExponentialFit(img, labSpheroid, msrSet)
    % imgCorrected = exp(a * maskAttenuation) .* img;
    % H = dipshow(imgCorrected); dipmapping(H,'xy'); dipmapping(H,'global'); dipmapping(H,'lin'); diptruesize(H,100); dipstep(H,'on');

    
    %%

end

function a = estimateAttenuationDecayFromExponentialMinMax(img, labSpheroid, msrSet, plotResults)

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

    if (plotResults) 
        figure(); plot(Iavg);
        hold on; plot(I0 * exp(a));
    end
    
end

function a = estimateAttenuationDecayFromExponentialFit(img, labSpheroid, msrSet, plotResults)

    % We can guess decaying factor a by assuming that the unattenuated intensity 
    % inside the spheroid should be everywhere the same on average. 
    % Therefore we could fit an exponential to the measured mean intensity
    % values of the different layers in the spheroid.
    msrList = {'Size','Mean'};
    sz = imsize(img);
    for j = 1:sz(3)
        msrR{j} = measure(labSpheroid(:,:,j-1)~=0, img(:,:,j-1), msrList, [], inf, 0, 0);
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
    if (plotResults) 
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
    end
    %
    a = - estimates(2);
end

function plotSpheriodFit(lab, msrSet, sz, dx, dz)
    msrList = {'Size','Center','Radius'};
    for j = 1:sz(3)
        labPlane = squeeze(lab(:,:,j-1));
        msr{j} = measure(labPlane~=0, [], msrList, [], inf, 0, 0);
    end
    
    msra = zeros(size(msrSet));
    % Indexing behaves weird so we perform a loop instead of doing
    % msra(find(msrSet))  =  msrRadiusToArray( msr(logical(msrSet)) );
    msraTemp = msrRadiusToArray( msr(logical(msrSet)) );
    nonZeroIndices = find(msrSet);
    for k = 1:length(nonZeroIndices)
        msra(nonZeroIndices(k)) = msraTemp(k);
    end
    
    figure();
    plot( (dz/dx)*(1:length(msra(:,2))), msra );
    [xc,yc,R,a] = circfit([(dz/dx)*(1:length(msra(:,2))), (dz/dx)*(1:length(msra(:,2))) ],[msra(:,2); -msra(:,2)]);
    t = linspace(0,2*pi,100);
    xx = (R-abs(yc)) * cos(t);
    yy = (R-abs(yc)) * sin(t);
    hold on; plot(xc,yc,'o');
    hold on; plot(xx+xc,yy,'-');

end
