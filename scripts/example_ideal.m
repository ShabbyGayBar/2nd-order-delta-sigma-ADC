clear;clc;
%% Simulation setup

Ain=0.5; % Signal amplitude
Ts=1/1.024e7; % Sampling interval (s)
N=2^18; % Number of FFT points
Fin=61/N/Ts; % Signal frequency (Hz)
OSR=2^8; % Oversampling ratio

Adc=Inf; % DC gain of opamp
GBW=Inf; % Gain bandwidth product of opamp
%% Run simulation

[input,bitstream,output] = simDeltaSigmaAdc(Ts,Fin,Ain,N,OSR,Adc,GBW);

% Normalize output amplitude to match with Input
output.("Voltage (V)") = OSR^(-3)*double(output.("Voltage (V)"));

%% Plot waveforms

fig = figure('Units','inches','Position',[0 0 5 3]);
fontname(fig,'TeXGyreTermes');
fontsize(fig,10,"points");

% Input vs Output Signal
t_max = 4/Fin;
t_max_index = floor(t_max/Ts);

hold on;
plot(input(1:t_max_index,:),"Time (sec)","Voltage (V)");
plot(output(1:t_max_index,:),"Time (sec)","Voltage (V)");
hold off;
xlim([0,t_max]);
legend(["Input", "Output"],"Location","southeast");
grid on;

exportgraphics(fig,"figures/waveform_input_vs_output_ideal.svg");

% Bitstream signal
t_max = 1/Fin;
t_max_index = floor(t_max/Ts);

plot(bitstream(1:t_max_index,:),"Time (sec)","Voltage (V)");
xlim([0,t_max]);
legend off;
grid on;

exportgraphics(fig,"figures/waveform_bitstream_ideal.svg");

%% Compute FFT

% Compute the single-sided fourier transform of the quantizer's bitstream
[f,fft_bitstream] = fft_1_sided(bitstream.("Voltage (V)"),N,1/Ts);
%% Plot FFT

fig = figure('Units','inches','Position',[0 0 5 3]);
fontname(fig,'TeXGyreTermes');
fontsize(fig,10,"points");

hold on;
% Spectrum of bitstream
plot(f,mag2db(fft_bitstream));
% Theoretical spectrum of quantization noise
plot(f, ...
    mag2db(sqrt(1/6/Ts)/N.*abs((1-exp(-1i*2*pi.*f*Ts)).^2)), ...
    "LineStyle","--");
hold off;
xscale('log');
xlabel("Frequency (Hz)");
ylabel("Normalized Magnitude (dB)");
legend(["Bitstream", "NTF"],"Location","southeast");
grid on;

exportgraphics(fig,"figures/fft_ideal.svg");

%% Compute dynamic performance metrics

% Compute the fourier transform of the downsampled output waveform
output_downsampled = downsample(output.("Voltage (V)")(end-N+1:end),OSR);

fig = figure('Units','inches','Position',[0 0 5 3]);
fontname(fig,'TeXGyreTermes');
fontsize(fig,10,"points");

snr(output_downsampled,1/OSR/Ts);
exportgraphics(fig,"figures/snr_ideal.svg");

thd(output_downsampled,1/OSR/Ts);
exportgraphics(fig,"figures/thd_ideal.svg");

sinad(output_downsampled,1/OSR/Ts);
exportgraphics(fig,"figures/sinad_ideal.svg");