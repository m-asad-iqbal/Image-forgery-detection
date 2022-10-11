function [SSIMS, THETAS, OutImages] = Mellin_Fourier_fcn(subImg1, subImg2)
%Function Mellin_Fourier_fcn computes the Mellin Fourier of subImg1 and
%subImg2
% 
% Syntax:
% [SSIMS, THETAS, OutImages] = Mellin_Fourier_fcn(subImg1, subImg2)
% 
% Inputs: subImg1 and subImg2 are input images to calculate the Fourier
% Mellin for.
% 
% Outputs:
% SSIMS are two SSIM values for rotation with -Theta and (-Theta + 180)
% respectively
% 
% THETAS are two values of the Theta, one is the natural Theta value, and
% the other is the quantized theta to one of these values [0 +90 +180 +270]
% 
% OutImages is a struct containing two fields im1 and im2 are the result of
% rotation of SubImg1 to -Theta and (-Theta + 180) respectively 
% 
% 
% Algorithm
% (1)   Read in I1 - the image to compare against
% (2)   Read in I2 - the image to compare
% (3)   Take the FFT of I1, shifting it to center on zero frequency
% (4)   Take the FFT of I2, shifting it to center on zero frequency
% (5)   Convolve the magnitude of (3) with a high pass filter
% (6)   Convolve the magnitude of (4) with a high pass filter
% (7)   Transform (5) into log polar space
% (8)   Transform (6) into log polar space
% (9)   Take the FFT of (7)
% (10)  Take the FFT of (8)
% (11)  Compute phase correlation of (9) and (10)
% (12)  Find the location (x,y) in (11) of the peak of the phase correlation
% (13)  Compute angle (360 / Image Y Size) * y from (12) then quantize it
%       to [0 +90 +180 +270]
% (14)  Rotate the image from (2) by - theta angle from (13)
% (15)  Rotate the image from (2) by - theta angle + 180 from (13)
% (16)  Compute the SSIM between the I1 and the rotated images from (15)
%       and (16) respectively.
% (17)  Output algorithm results (SSIMS, THETAS, OutImages)
% ---------------------------------------------------------------------

% I've been working with I1, and I2 while developing that's why I kept the
% varibles as they are cause they are used too much in the code as I1, I2

I1 = subImg1;
I2 = subImg2;

% ---------------------------------------------------------------------
% Convert both to FFT, centering on zero frequency component

SizeX = size(I1, 1);
SizeY = size(I1, 2);

FA = fftshift(fft2(I1));
FB = fftshift(fft2(I2));
% ---------------------------------------------------------------------
% Convolve the magnitude of the FFT with a high pass filter)

IA = hipass_filter(size(I1, 1),size(I1,2)) .* FA;
IB = hipass_filter(size(I2, 1),size(I2,2)) .* FB;
%%
% Transform the high passed FFT phase to Log Polar space
L1 = transformImage(IA, SizeX, SizeY, SizeX, SizeY, 'nearest', size(IA) / 2, 'valid');
L2 = transformImage(IB, SizeX, SizeY, SizeX, SizeY, 'nearest', size(IB) / 2, 'valid');


%%
% Convert log polar magnitude spectrum to FFT
THETA_F1 = fft2(L1);
THETA_F2 = fft2(L2);


% Compute cross power spectrum of F1 and F2
a1 = angle(THETA_F1);
a2 = angle(THETA_F2);

THETA_CROSS = exp(1i * (a1 - a2));
THETA_PHASE = real(ifft2(THETA_CROSS));
%%
% Find the peak of the phase correlation
[THETA_X, THETA_Y] = find(THETA_PHASE == max(THETA_PHASE(:))); %#ok<ASGLU>

%%
% Compute angle of rotation
DPP = 360 / size(THETA_PHASE, 2);
Theta = DPP * (THETA_Y - 1);

Theta_Rounded = round(Theta/90) * 90;
IR = imrotate(I2, -Theta_Rounded, 'crop');
IR2 = imrotate(I2,-(Theta_Rounded + 180), 'crop');

SSIMS = [ssim(IR, I1), ssim(IR2, I1)];


THETAS = [Theta_Rounded, Theta];

OutImages = struct;
OutImages.im1 = IR;
OutImages.im2 = IR2;

end