clear;clc;
%% Simulation setup

% List of signal amplitude to sweep
Ain_list = [logspace(-2,-0.1,20) logspace(-0.08,0,5) 0.5 0.9];
Ts=1/1.024e7; % Sampling interval (s)
N=2^18; % Number of FFT points
Fin=61/N/Ts; % Signal frequency (Hz)
OSR=2^8; % Oversampling ratio

Adc=inf; % DC gain of opamp
GBW=inf; % Gain bandwidth product of opamp

%% Run simulation

metrics = table([],[],[],[], ...
    'VariableNames', ...
    {'Signal Amplitude (V)','SNR (dB)','THD (dB)','SINAD (dB)'});

for Ain = Ain_list
    [input,bitstream,output] = simDeltaSigmaAdc(Ts,Fin,Ain,N,OSR,Adc,GBW);
    
    % Normalize output amplitude to match with Input
    output.("Voltage (V)") = OSR^(-3)*double(output.("Voltage (V)"));

    % Save specific bitstream waveforms
    if (Ain == 0.5)
        bitstream_0p5 = bitstream;
    end
    if (Ain == 0.9)
        bitstream_0p9 = bitstream;
    end

    % Compute the fourier transform of the downsampled output waveform
    output_downsampled = downsample( ...
        output.("Voltage (V)")(end-N+1:end),OSR);

    % Save metrics to table
    row = {Ain ...
        snr(output_downsampled,1/OSR/Ts) ...
        thd(output_downsampled,1/OSR/Ts) ...
        sinad(output_downsampled,1/OSR/Ts)};
    metrics(end+1,:) = row;
end
%% Plot SINAD vs signal amplitude

Asig = logspace(-2,0,10);

fig = figure('Units','inches','Position',[0 0 5 3]);
fontname(fig,'TeXGyreTermes');
fontsize(fig,10,"points");

hold on;
scatter(metrics,"Signal Amplitude (V)","SINAD (dB)");
plot(Asig,mag2db(Asig/pi^2*sqrt(15*OSR^5)),"LineStyle","--")
hold off;
xscale('log');
grid on;

exportgraphics(fig,"figures/sinad_Ain.svg");

%% Plot overlaid bitstream spectrum of Ain=0.5 & 0.9

% Compute the single-sided fourier transform of the quantizer's bitstream
[~,fft_bitstream_0p5] = fft_1_sided(bitstream_0p5.("Voltage (V)"),N,1/Ts);
[f,fft_bitstream_0p9] = fft_1_sided(bitstream_0p9.("Voltage (V)"),N,1/Ts);

fig = figure('Units','inches','Position',[0 0 5 3]);
fontname(fig,'TeXGyreTermes');
fontsize(fig,10,"points");

hold on;
% Spectrum of bitstream
plot(f,mag2db(fft_bitstream_0p9));
plot(f,mag2db(fft_bitstream_0p5));
% Theoretical spectrum of quantization noise
plot(f, ...
    mag2db(sqrt(1/6/Ts)/N.*abs((1-exp(-1i*2*pi.*f*Ts)).^2)), ...
    "LineStyle","--");
hold off;
xscale('log');
xlabel("Frequency (Hz)");
ylabel("Normalized Magnitude (dB)");
ylim([-200,0]);
legend(["Ain=0.9","Ain=0.5","NTF"],"Location","southeast");
grid on;

exportgraphics(fig,"figures/fft_Ain.svg");