function img = loadStackFromImageSequence(imgFiles)

    info = imfinfo(imgFiles{1});
    num_images = length(imgFiles);
    A = zeros(info(1).Height, info(1).Width, num_images);
    
    for k = 1:num_images
        A(:,:,k) = imread(imgFiles{k});
    end

    img = dip_image(A);

end
