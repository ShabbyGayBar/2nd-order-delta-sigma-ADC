clear;clc;
%% Simulation setup

Adc_list = [logspace(1,5,20) 1e2]; % List of DC gain of opamp to sweep
Ain=0.5; % Signal amplitude
Ts=1/1.024e7; % Sampling interval (s)
N=2^18; % Number of FFT points
Fin=61/N/Ts; % Signal frequency (Hz)
OSR=2^8; % Oversampling ratio

GBW=Inf; % Gain bandwidth product of opamp

%% Run simulation

metrics = table( ...
    [],[],[],[], ...
    'VariableNames', ...
    {'DC gain (dB)','SNR (dB)','THD (dB)','SINAD (dB)'});

for Adc = Adc_list
    [input,bitstream,output] = simDeltaSigmaAdc(Ts,Fin,Ain,N,OSR,Adc,GBW);
    
    % Normalize output amplitude to match with Input
    output.("Voltage (V)") = OSR^(-3)*double(output.("Voltage (V)"));

    % Save specific bitstream waveforms
    if (Adc == 1e2)
        bitstream_1e2 = bitstream;
    end
    if (Adc == 1e5)
        bitstream_1e5 = bitstream;
    end

    % Compute the fourier transform of the downsampled output waveform
    output_downsampled = downsample( ...
        output.("Voltage (V)")(end-N+1:end),OSR);

    % Save metrics to table
    row = { ...
        mag2db(Adc) ...
        snr(output_downsampled,1/OSR/Ts) ...
        thd(output_downsampled,1/OSR/Ts) ...
        sinad(output_downsampled,1/OSR/Ts)};
    metrics(end+1,:) = row;
end
%% Plot SINAD vs Opamp DC gain

fig = figure('Units','inches','Position',[0 0 5 3]);
fontname(fig,'TeXGyreTermes');
fontsize(fig,10,"points");

hold on;
scatter(metrics,"DC gain (dB)","SINAD (dB)");
plot([0,200],[104,104],"LineStyle","--");
line([20,100],[62,220],"LineStyle","--");
hold off;
xlim([20,100]);
ylim([60,120]);
grid on;

exportgraphics(fig,"figures/sinad_Adc.svg");

%% Plot overlaid bitstream spectrum of A=1e2 & 1e5

% Compute the single-sided fourier transform of the quantizer's bitstream
[~,fft_bitstream_1e2] = fft_1_sided(bitstream_1e2.("Voltage (V)"),N,1/Ts);
[f,fft_bitstream_1e5] = fft_1_sided(bitstream_1e5.("Voltage (V)"),N,1/Ts);

fig = figure('Units','inches','Position',[0 0 5 3]);
fontname(fig,'TeXGyreTermes');
fontsize(fig,10,"points");

hold on;
% Spectrum of bitstream
plot(f,mag2db(fft_bitstream_1e5));
plot(f,mag2db(fft_bitstream_1e2));
% Theoretical spectrum of quantization noise
plot(f, ...
    mag2db(sqrt(1/6/Ts)/N.*abs((1-exp(-1i*2*pi.*f*Ts)).^2)), ...
    "LineStyle","--");
hold off;
xscale('log');
xlabel("Frequency (Hz)");
ylabel("Normalized Magnitude (dB)");
ylim([-200,0]);
legend(["A=40dB","A=100dB","NTF"],"Location","southeast");
grid on;

exportgraphics(fig,"figures/fft_Adc.svg");