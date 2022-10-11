% Hi again..

% Updates on 10/10/2019:
% 1- Performed resizing based on the area ratios of the two regions under
% search, to correct for the image scaling.
%
% 2- the clustering strategy is changed by doing the clustering with half
% number of iterations (50 interations), but with repeated clustering for 3
% times, that nearly guarentees the same convergance for repeated runs but
% not absolutely. i.e. you still might end with different clustering
% sometimes
% 
% _________________________-
% 


% Here is the change log:
% 1- Separate processing for the gray scale and the color images, the gray
% scale passes through the older algorithm of the intensity gating where as
% the color images passes thtough the color clustering.
% 2- To accomplish this, the segmented images were firstly prepared then
% fed to the forgery algorithm, the earlier method segmenting the image to
% be tested, (color / intensity band) inside the forgery detection
% algorithm.


% 1- Color image processing, the algorithm now is almost valid for every
% type of image 2- The algorithm depend mainly on the dimensions of the
% image, the forgried cameraman image is a gray scale image with dimensions
% 256x256 it took (Elapsed time is 0.510566 seconds.) to complete. Where as
% for the forgery image of dimensions of (960x1280) color image it took
% (Elapsed time is 16.376981 seconds) 
% this image is roughly 18 times more than the  cameraman image and with
% colors that's why I THINK it took all this time
% 
% A note also about the computation time is that if you ran the function
% for the first time, or you ran right after Matlab starts in this cases it
% will consume more time because Matlab doesn't initiate everything unless
% it's needed, that's why if you just run it again you will notice much
% reduction
% 
% A final notice when I ran the function many times, once I got different
% results for the Forgery color image, this I think was because k-means
% ended up finding different optima, but this occured only once. Anyway,
% this could be processed either by increasing number of iterations or used
% repeated clustering (this is done automatically) but both of these
% operations are much time consuming that's why I decided not to perform
% any of them, and kept everything as it is.


% 
% The idea work as follows:: 1- I divided the image into fixed intensity
% values (Multiples of 16) (0    16    32    48    64    80    96   112 128
% 144   160   176   192   208   224   240   256)
%
% 2- Then I performed segmentation based on these intensities.. i.e each
% time I change the intensity range to have a different image, in other
% words it's like having intensity gates, each time we search forgery in
% one gate..
%
% 3- after doing the intensity gating, I do search on similar area objects,
% that mean, up to this stage, if a match found, then we have similar
% intensity and similar size objects.
%
% 4- On the matches only, we I did the Mellin Fourier transform, by putting
% the two similar objects with their original intensities in a template of
% zeros before feeding it to the Mellin Fourier, the zero template to let
% them have similar sizes before doing the transform..
%
% 5- Now, the SSIM output of the Mellin Fourier is compared with high
% threshold I picked 0.88 as similarity index.
%
% 6- If a match was found, this is considered as forgery; this time, and
% due to the change in the of the bounding box size, all the bounding box
% information is stored in a valid bounding boxes array.
%
% Finally, the representation by putting a red and a green bounding boxes
% on the match locations..
%
% % Pros and cons: 1- It works very good if the forgery was object.. 2- It
% may succeed or fail if the forgery was blending from background.. 3-
% Computation time is very fast compared to boxes searching, that's because
% we don't blindly search over the image..
%
% Future updates.. 1- if the intensity gate has detected big objects i.e,
% greater than area of 10 block sizes, i.e. if the block size is 16 then
% it's area is 256 (16*16), if at any intensity gate we found area larger
% than 2560 pixels we do block search, any way it may be faster, cause the
% search size will be limited to the detected area of that intensity level
% and we will do the block sorting and the search will be limited maximum
% to 3 boxes..
%
% 2- For now only, color images are turned into gray, but we can  do the
% intensity gating on the three channels, having working on a colored image
% directly, I'm even thinking of doing color clustering if it was necessary
% but unless we had bad results in all color images we wont do that. cause
% clustering itself is not a cheap operation..

close all; clear, clc

tic
%
%%
% I = imread('I2.jpg');
I = imresize(imread('New - image.png'), [512 512]);
% I = imread('Random - image.jpg');


color_image = I;
image_copy = color_image;
input_image = color_image;


[height, width, nColor_planes] = size(input_image);
test_image = zeros(height, width, 3);


block_size = 16;
Valid_Block = [];


%%
% This section of the code checks whether the image is gray scale or
% colored, then, for the gray scale images it performs the earlier method
% of intensity division (Gating), for color images it performs color
% clustering with predefined number of color clusters as desired using the
% CIELAB transform and the K-means clustering algorithms. (please read the
% attached help in function)

if(nColor_planes == 1)
    intensities = 16 .* (0:16);
    nColors = length(intensities) - 1;
    segmented_images = cell(1, length(intensities));
    for i = 1:length(intensities) - 1
        segmented_images{i} = (I > intensities(i) & I < intensities(i+1));
    end
else
    nColors = 2; % Try 4 too
    segmented_images = img_k_means_fcn(I, nColors, 'Replicates', 3, 'maxiter', 50);
end

%%
for i = 1:nColors
%     pause
    SI = bwareafilt(medfilt2(segmented_images{i}, [5 5]), [30 inf]);
%     figure, imshowpair(SI, segmented_images{i}, 'montage'),% title(intensities(i))
    props = regionprops(SI);   
    Areas = [props.Area];
    bboxes = cat(1, props.BoundingBox);
    
    if(~isempty(bboxes))
        %  -       [bboxes_Areas, sort_indices] = sort(abs(bboxes(:, 4) -
        %         bboxes(:, 3)));
        [bboxes_Areas, sort_indices] = sort(Areas);
        bboxes_sorted = bboxes(sort_indices, :);
        
        Area_match_ind = 1:length(Areas) - 1;%find(diff(bboxes_Areas) < (10 * block_size));% /4;
        All_S = [];
        for j = 1:length(Area_match_ind)
            Four_box1 = bboxes_sorted(Area_match_ind(j), :);
            Four_box2 = bboxes_sorted(Area_match_ind(j) + 1, :);
            
            im1 = imcrop(I, Four_box1);
            im2 = imresize(imcrop(I, Four_box2), bboxes_Areas(j)/bboxes_Areas(j+1));
            
            
%             figure, imshowpair(im1, im2, 'montage')
            
            [im2_m, im2_n, ~] = size(im2);
            
            Four_box1(3:4) = Four_box1(3:4);
%             Four_box2(3:4) = ([im2_n, im2_m]) - 1;
            
            max_dim = max([round(Four_box1(3:4)), round(([im2_n, im2_m]) - 1)]);
            
            Four_img1 = zeros(max_dim+1, max_dim+1, nColor_planes, 'uint8');
            Four_img2 = zeros(max_dim+1, max_dim+1, nColor_planes, 'uint8');
            
            try 
                Four_img1(1:Four_box1(4)+1, 1:Four_box1(3)+1, :) = im1;
                Four_img2(1:im2_m, 1:im2_n, :) = im2;             
            
            catch nothing
                continue
            end
            % Updated code here too, to perform the Mellin Fourier for gray
            % images, or perform it for color by looping for each color
            % plane and perform the Mellin Fourier for each plane
            
            if (nColor_planes == 1)
                [S, T, Iout] = Mellin_Fourier_fcn(Four_img1, Four_img2);
                All_S = [All_S, max(S)];
            else
                S = 0;
                for nnn = 1:nColor_planes
                    [S11, T, Iout] = Mellin_Fourier_fcn(Four_img1(:, :, nnn), Four_img2(:, :, nnn));
                    S = S + S11;
                end
                S = S / 3;
                All_S = [All_S, max(S)];
            end
            
            if (max(S) > 0.58)% && min(T) > 5)
                Valid_Block = [Four_box1, Four_box2, S, T ;Valid_Block]; %#ok<*AGROW>
            end
        end
    end
end
%%
if(size(color_image, 3) == 1)
    image_copy = test_image;
    image_copy(:, :, 1) = color_image;
    image_copy(:, :, 2) = color_image;
    image_copy(:, :, 3) = color_image;
    image_copy = uint8(image_copy);
end
if(~exist('Valid_Block', 'var'))
    Valid_Block = zeros(1, 12);
end
for ind = 1:size(Valid_Block, 1) %for all the pairs that have that shift vector
    block_box1 = Valid_Block(ind, 1:4);
    block_box2 = Valid_Block(ind, 5:8);
    image_copy = insertShape(image_copy, 'Rectangle', block_box1, 'color', [255 0 0]);
    image_copy = insertShape(image_copy, 'Rectangle', block_box2, 'color', [0 255 0]);
end
toc
figure, imagesc(image_copy), impixelinfo
