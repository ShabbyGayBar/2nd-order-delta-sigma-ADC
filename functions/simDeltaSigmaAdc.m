function [input,bitstream,output] = simDeltaSigmaAdc(Ts,Fin,Ain,N,OSR,Adc,GBW)
%  simDeltaSigmaAdc Simulate the delta-sigma ADC
% 
% Run simulink simulation with the given input sine signal and sampling
% frequency, and record the input sine signal, quantizer bitstream, and CIC
% output waveform.
arguments (Input)
    Ts (1,1) % sample time
    Fin (1,1) % signal frequency
    Ain (1,1) % signal amplitude
    N (1,1) % FFT points
    OSR (1,1) % Oversampling ratio
    Adc (1,1)
    GBW (1,1)
end
arguments (Output)
    input
    bitstream
    output
end
%% Set Simulink conditions
simIn = Simulink.SimulationInput("testbench");
simIn = setVariable(simIn,'Ts',Ts);
simIn = setVariable(simIn,'Fin',Fin);
simIn = setVariable(simIn,'Ain',Ain);
simIn = setVariable(simIn,'N',N);
simIn = setVariable(simIn,'OSR',OSR);
simIn = setVariable(simIn,'Adc',Adc);
simIn = setVariable(simIn,'GBW',GBW);
%% Start Simulink
out=sim(simIn);
%% Extract data
% Input signal
input_data = out.ScopeData.get("input").Values.Data(:,1);
input_time = out.ScopeData.get("input").Values.Time;
% Quantizer bitstream
bitstream_data = out.ScopeData.get("bitstream").Values.Data(:,1);
bitstream_time = out.ScopeData.get("bitstream").Values.Time;
% CIC decimator output
output_data = out.ScopeData.get("output").Values.Data(:,1);
output_time = out.ScopeData.get("output").Values.Time;
%% Wrap up data in table form
input = table(input_time,input_data,'VariableNames',{'Time (sec)','Voltage (V)'});
bitstream = table(bitstream_time,bitstream_data,'VariableNames',{'Time (sec)','Voltage (V)'});
output = table(output_time,output_data,'VariableNames',{'Time (sec)','Voltage (V)'});
end