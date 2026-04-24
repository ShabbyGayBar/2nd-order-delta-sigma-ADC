clear;clc;
%% Simulation setup

GBW_list = [logspace(3,8,20) 1e5]; % List of Gain Bandwidth product of opamp to sweep
Ain=0.5; % Signal amplitude
Ts=1/1.024e7; % Sampling interval (s)
N=2^18; % Number of FFT points
Fin=61/N/Ts; % Signal frequency (Hz)
OSR=2^8; % Oversampling ratio

Adc=Inf; % DC gain of opamp

%% Run simulation

metrics = table([],[],[],[],'VariableNames',{'GBW (Hz)','SNR (dB)','THD (dB)','SINAD (dB)'});

for GBW = GBW_list
    [input,bitstream,output] = simDeltaSigmaAdc(Ts,Fin,Ain,N,OSR,Adc,GBW);
    
    % Normalize output amplitude to match with Input
    output.("Voltage (V)") = OSR^(-3)*double(output.("Voltage (V)"));

    % Save specific bitstream waveforms
    if (GBW == 1e5)
        bitstream_1e5 = bitstream;
    end
    if (GBW == 1e8)
        bitstream_1e8 = bitstream;
    end

    % Compute the fourier transform of the downsampled output waveform
    output_downsampled = downsample(output.("Voltage (V)")(end-N+1:end),OSR);

    % Save metrics to table
    row = {GBW snr(output_downsampled,1/OSR/Ts) thd(output_downsampled,1/OSR/Ts) sinad(output_downsampled,1/OSR/Ts)};
    metrics(end+1,:) = row;
end
%% Plot SINAD vs Opamp GBW

fig = figure('Units','inches','Position',[0 0 5 3]);
fontname(fig,'TeXGyreTermes');
fontsize(fig,10,"points");

hold on;
scatter(metrics,"GBW (Hz)","SINAD (dB)");
plot([1e3,1e8],[104,104],"LineStyle","--");
hold off;
xscale('log');
grid on;

exportgraphics(fig,"figures/sinad_GBW.svg");

%% Plot overlaid bitstream spectrum of GBW=1e5 & 1e8

% Compute the single-sided fourier transform of the quantizer's bitstream
[~,fft_bitstream_1e5] = fft_1_sided(bitstream_1e5.("Voltage (V)"),N,1/Ts);
[f,fft_bitstream_1e8] = fft_1_sided(bitstream_1e8.("Voltage (V)"),N,1/Ts);

fig = figure('Units','inches','Position',[0 0 5 3]);
fontname(fig,'TeXGyreTermes');
fontsize(fig,10,"points");

hold on;
% Spectrum of bitstream
plot(f,mag2db(fft_bitstream_1e5));
plot(f,mag2db(fft_bitstream_1e8));
% Theoretical spectrum of quantization noise
plot(f,mag2db(sqrt(1/6/Ts)/N.*abs((1-exp(-1i*2*pi.*f*Ts)).^2)),"LineStyle","--");
hold off;
xscale('log');
xlabel("Frequency (Hz)");
ylabel("Normalized Magnitude (dB)");
ylim([-200,0]);
legend(["GBW=100KHz","GBW=100MHz","NTF"],"Location","southeast");
grid on;

exportgraphics(fig,"figures/fft_GBW.svg");