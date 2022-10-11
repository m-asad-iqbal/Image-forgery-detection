function [segmented_bw, segmented_images] = img_k_means_fcn(I, nColors)


% This is based on Matlab Example 
% Color-Based Segmentation Using K-Means Clustering This example shows how
% to segment colors in an automated fashion using the L*a*b* color space
% and K-means clustering. This example requires Statistics and Machine
% Learning Toolbox™. Step 
% 1: Read Image
% I = imread('Forgery_copied.png');
% imshow(I), title('Origianl');
% This step was in the original m-file now it's fed to the function as
% input


% Step 2: Convert Image from RGB Color Space to L*a*b* Color Space. The
% L*a*b* color space (also known as CIELAB or CIE L*a*b*) enables you to
% quantify visual color differences. The L*a*b* color space is derived from
% the CIE XYZ tristimulus values. The L*a*b* space consists of a luminosity
% layer 'L*', chromaticity-layer 'a*' indicating where color falls along
% the red-green axis, and chromaticity-layer 'b*' indicating where the
% color falls along the blue-yellow axis. All of the color information is
% in the 'a*' and 'b*' layers. You can measure the difference between two
% colors using the Euclidean distance metric. Convert the image to L*a*b*
% color space using rgb2lab.
lab_I = rgb2lab(I);

% Step 3: Classify the Colors in 'a*b*' Space Using K-Means Clustering
% Clustering is a way to separate groups of objects. K-means clustering
% treats each object as having a location in space. It finds partitions
% such that objects within each cluster are as close to each other as
% possible, and as far from objects in other clusters as possible. K-means
% clustering requires that you specify the number of clusters to be
% partitioned and a distance metric to quantify how close two objects are
% to each other. Since the color information exists in the 'a*b*' space,
% your objects are pixels with 'a*' and 'b*' values. Use kmeans to cluster
% the objects into three clusters using the Euclidean distance metric.
ab = lab_I(:,:,2:3);
nrows = size(ab,1);
ncols = size(ab,2);
ab = reshape(ab,nrows*ncols,2);

% nColors = 4;

[cluster_idx, ~] = kmeans(ab,nColors,'distance','sqEuclidean');

% Step 4: Label Every Pixel in the Image Using the Results from KMEANS For
% every object in your input, kmeans returns an index corresponding to a
% cluster. The cluster_center output from kmeans will be used later in the
% example. Label every pixel in the image with its cluster_idx.
pixel_labels = reshape(cluster_idx,nrows,ncols);

% Step 5: Create Images that Segment the H&E Image by Color. Using
% pixel_labels, you can separate objects in hestain.png by color, which
% will result in three images.
segmented_images = cell(1,nColors);
segmented_bw = cell(1,nColors);
rgb_label = repmat(pixel_labels,[1 1 3]);

for k = 1:nColors
    color = I;
    color(rgb_label ~= k) = 0;
    segmented_images{k} = color;
    segmented_bw{k} = rgb2gray(color) > 0.02;
end
% toc
%%
% 
% for i = 1:nColors
% figure(1), imshow(segmented_images{i}), title(i)
% pause(1)
% end
