function [dsir lsir] = make_dSIR(im1,im2)
%[dsir lsir] = make_dSIR(im1,im2)
%
% Makes dSIR images from two IR images (or stack of images).
% Performs a primitive registration and thresholding.
%
% -im1 is the short TI image [nx ny nz]
% -im2 is the long TI image [nx ny nz]
%
% Returned image is scaled to integer for conversion to DICOM.

%% input validation
if ~isequal(size(im1),size(im2))
    error('size mismatch between im1 and im2');
end

if ~isfloat(im1) || ~isfloat(im2)
    im1 = single(im1);
    im2 = single(im2);
end

%% registration
im2 = rigid2(im1,im2);

%% create dsir
add = im1+im2;
sub = im1-im2;

dsir = sub./add;
lsir = atanh(dsir);

%% background removal (dodgy)

% image mask
thresh = 0.02*max(add(:));
%thresh = median(nonzeros(add));
%thresh = median(abs(sub(:)-median(sub(:))))^2;
mask = add > thresh;

% tidy up (bwmorph 'majority' filter)
for j = 1:100
    se = ones(13,13,'like',mask); 
    mask = convn(mask,se,'same') > nnz(se)/2;
end

% 1 pixel of dilation
[x y z] = meshgrid(-1:1);
se = (x.^2+y.^2+z.^2)<=1;
mask = convn(mask,se,'same');

% set background to lowest signal
dsir(~mask) = -1;
lsir(~mask) = -Inf;

%% convert to integer
dsir = int16(10000 * dsir);
lsir = int16(10000 * lsir);
