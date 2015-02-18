% The metaInput argument is optional: if no metadata is given then the
% default metadata from "defaultMeta()" is used.
function [meta, omeMeta] = getOmeMeta(imgPath, metaInput)

    switch nargin
        case 2,
            meta = metaInput;
        otherwise,
            meta = defaultMeta();
    end

    disp(imgPath)
    reader = bfGetReader(imgPath);
    omeMeta = reader.getMetadataStore();
    

    try 
        meta.sizeX = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
    catch error
    end

    try
        meta.sizeY = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
    catch error
    end

    try
        meta.sizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % image depth, pixels
    catch error
    end

    try
        meta.sizeC = omeMeta.getPixelsSizeC(0).getValue(); % number of channels
    catch error
    end

    try
        meta.sizeT = omeMeta.getPixelsSizeT(0).getValue(); % number of timepoints
    catch error
    end

    try
        meta.pixelSizeX = omeMeta.getPixelsPhysicalSizeX(0).getValue(); % in µm
    catch error
    end

    try
        meta.pixelSizeY = omeMeta.getPixelsPhysicalSizeY(0).getValue(); % in µm
    catch error
    end

    try
        meta.pixelSizeZ = omeMeta.getPixelsPhysicalSizeZ(0).getValue(); % in µm
    catch error
    end

    try
        meta.pixelSizeT = omeMeta.getPixelsTimeIncrement(0).doubleValue(); % in µm
    catch error
    end

    try
        meta.bitDepth = char(omeMeta.getPixelsType(0).getValue());
    catch error
    end

    try
        % lowercase and 'xy' are removed.
        meta.dimsOrder = lower( char(omeMeta.getPixelsDimensionOrder(0).getValue()) );
        meta.dimsOrder = regexp(meta.dimsOrder,'[^xy]+','match','ignorecase');
        meta.dimsOrder = meta.dimsOrder{1};
    catch error
    end
    
end

