%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title:-->        Vortex Compensation                                 
%                                                                                                               
%                                                                                  
% Description:-->  This algorithm allows to find the frequencies for the tilt
%                  compensation using the Hilbert-2D transform and residual 
%                  theorem using vortex interpolation.              
%                                                                                  
% Authors:-->      Rene Restrepo(2), Karina Ortega-Sánchez(1,2), 
%                  Carlos Trujillo(2), Ana Doblas(2) and Alfonso Padilla (1)
%                  (1) Universidad Politecnica de Tulancingo
%                  (2) EAFIT Univeristy SOPHIA Research Group (Applied Optics) 
% References:-->   K. G. Larkin, D. J. Bone, and M. A. Oldfield, 
%                   Journal of the Optical Society of America A 18, 1862 (2001).
%                  W. Wang, T. Yokozeki, R. Ishijima, A. Wada, 
%                   Y. Miyamoto, M. Takeda, and S. G. Hanson, Opt Express 14, 120 (2006).
%                  D. C. Ghiglia and L. A. Romero, 
%                   Journal of the Optical Society of America A 11, 107 (1994).
%
% Inputs:-->       (1) Recorded hologram
%                  (2) Mask of +1 DO
%                  (3) Position of maximum value of frecuencies of +1 DO 
% Outputs:-->      (1) Position of the frequencies in a high-resolution
%                      sampling regime
%
% Email:-->        rrestre6@eafit.edu.co                                         
% Date:-->         12/17/2024                                                      
% version 1.0 (2024)                                                               
% Notes-->       

function [positions] = vortexCompensation ...
    (hologram, cir_mask, fxOverMax, fyOverMax)

ft_holo = log(abs(fftshift(fft2(fftshift(hologram)))).^2);
field = medfilt2(ft_holo, [1, 1], 'symmetric');

sd = hilbertTransform2D(field,1).*cir_mask;

cropVortex = 5;
factorOverInterpolation = 55;
sd_crop = sd(fyOverMax-cropVortex:fyOverMax+cropVortex-1,...
    fxOverMax-cropVortex:fxOverMax+cropVortex-1);

[n1,m1]=size(abs(sd_crop));
[xMat, yMat] = meshgrid(linspace(-1, 1, n1), linspace(-1, 1, m1));
[~, rMat] = cart2pol(xMat, yMat);
defocusPhaseMag = 0;
pupilPhase = exp(1i * 2 * pi * defocusPhaseMag * rMat .^ 2);
sd_crop = (sd_crop.*pupilPhase);


sz = size(abs(sd_crop));
xg = 1:sz(1);
yg = 1:sz(2);
F = griddedInterpolant({xg,yg}, ...
    real(sd_crop));
xq = (0:1/factorOverInterpolation:(sz(1)-1/(factorOverInterpolation)))';
yq = (0:1/factorOverInterpolation:(sz(2)-1/(factorOverInterpolation)))';
vq = double(F({xq,yq}));
c=contourc(vq, [0,0]);
c(:,~c(1,:)) = NaN;


F2 = griddedInterpolant({xg,yg}, ...
    imag(sd_crop));
vq2 = double(F2({xq,yq}));
c2=contourc(vq2, [0,0]);
c2(:,~c2(1,:)) = NaN;

psi = angle(vq+(1i.*vq2));
[n1,m1]=size(psi);
Ml=zeros(n1,m1);

M1=Ml; M2=Ml; M3=Ml; M4=Ml; M5=Ml; M6=Ml; M7=Ml; M8=Ml;

Y1=1:n1-2; Y2=2:n1-1; Y3=3:n1;
X1=1:m1-2; X2=2:m1-1; X3=3:m1;

M1(Y2,X2)=psi(Y1,X1); M2(Y2,X2)=psi(Y1,X2);
M3(Y2,X2)=psi(Y1,X3); M4(Y2,X2)=psi(Y2,X3);
M5(Y2,X2)=psi(Y3,X3); M6(Y2,X2)=psi(Y3,X2);
M7(Y2,X2)=psi(Y3,X1); M8(Y2,X2)=psi(Y2,X1);

D1=wrapToPi(M2-M1); D2=wrapToPi(M3-M2);
D3=wrapToPi(M4-M3); D4=wrapToPi(M5-M4);
D5=wrapToPi(M6-M5); D6=wrapToPi(M7-M6);
D7=wrapToPi(M8-M7); D8=wrapToPi(M1-M8);

Ml=D1+D2+D3+D4+D5+D6+D7+D8;
Ml=fftshift(Ml/(2*pi));
Ml(70:end, 70:end) = 0;
Ml= ifftshift(Ml);

[maxValue, linearIndex] = min(Ml, [], 'all', 'linear');
[yOverInterpolVortex, xOverInterpolVortex] = ind2sub(size(Ml), linearIndex);

positions = [];
positions=[positions; (xOverInterpolVortex/factorOverInterpolation)+((fxOverMax)-cropVortex-2),...
    (yOverInterpolVortex/factorOverInterpolation)+((fyOverMax)-cropVortex-2)];

end

