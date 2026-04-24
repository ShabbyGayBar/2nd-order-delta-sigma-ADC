function [f,Y] = fft_1_sided(X,N,Fs)
%fft_1_sided Compute the N point single-sided spectrum of X
%   
arguments (Input)
    X % Input array for FFT
    N (1,1) % number of FFT points
    Fs (1,1) % Sampling frequency
end

arguments (Output)
    f
    Y
end
%% Compute the fourier transform of X
Y = double(fft(X(end-N+1:end)));
%% Convert it to single-sided spectrum
Y = abs(Y/N);
Y = Y(1:N/2+1);
Y(2:end-1) = 2*Y(2:end-1);
%% Define the frequency domain f for the single-sided spectrum
f = Fs/N*(0:(N/2));
end