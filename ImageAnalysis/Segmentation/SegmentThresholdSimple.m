% -----------------------------------------------------------------------
% 
% FUNCTION: segmentThresholdSimple
% 
% DESCRIPTION: Segmentation of objects in a grey-valued 3D-image stacks by
%                   a simple threshold method.
% 
% INPUT: 
%           img                     : 2D/3D image (DIPimage image)
%           minSizeUnit             : minimal size of the objects (scalar)
%           maxSizeUnit             : maximal size of the objects (scalar)
%           pixelSize               : pixel size (x,y,(z)) (vector)
%
% OUTPUT:
%           lab                     : labeled image of the segmentation 
%                                       (DIPimage image)
%
% AUTHOR: 
% 
% 	Micha�l Barbier
%   mbarbie1@its.jnj.com
% 
% ----------------------------------------------------------------------- 
%
function lab = segmentThresholdSimple(img, minSizeUnit, maxSizeUnit, pixelSize)

    [~,t] = threshold(img, 'otsu');
    imgt = threshold(bilateralf(img), 'fixed',1*t);
    imgt = bmajority(imgt);
    
    dV = prod(pixelSize);
    minSize = round(minSizeUnit/dV);
    maxSize = round(maxSizeUnit/dV);
    lab = label(imgt, 1, minSize, maxSize );

end
