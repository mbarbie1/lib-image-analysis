function atBorder = isAtBorder2D( origin, range, sz )
% FUNCTION:     isAtBorder2D
% DESCRIPTION:  calculates whether an array of 3D bounding boxes are at the
%               border of a 3D image with size 'sz'. The bounding boxes are
%               described by the indices of the origin (upper left pixel)
%               and the range
%
% INPUT:
%        origin         : The upper left index of the bounding box, for
%                           m dimensions and n bounding boxes it is an (m x
%                           n) array.
%        range          : The interval range [lower_right_index - upper_left_index]
%                           of the bounding box. It is an (m x n) array.
%        sz             : The size of the image
%

    nBoundingBoxes = size(origin,2);
    ulBorder = min(origin);
    lrBorder = min( repmat(sz(1:2)' - [1;1], 1, nBoundingBoxes) - (origin(1:2,:) + range(1:2,:)) );
    atBorder = (lrBorder .* ulBorder) == 0;


end

