# 2nd-Order Delta-Sigma ADC

Behavioral modeling project for an AD/DA course. The goal is to design and evaluate a high-resolution delta-sigma ADC with at least second-order noise shaping, a target SNR of 96 dB, and a signal bandwidth of 20 kHz. The repository focuses on MATLAB and Simulink-based simulation, FFT analysis, and measurement of key dynamic metrics such as THD and SNDR.

## Project Goals

This project studies how a 2nd-order delta-sigma ADC behaves under ideal and non-ideal conditions. The main tasks are:

- Build a behavioral ADC model in Simulink.
- Verify the FFT spectrum of the modulator bitstream and decimated output.
- Evaluate SNR, THD, and SNDR.
- Explore non-idealities such as finite op-amp DC gain and gain-bandwidth product.
- Compare performance across different simulation settings and quantify the impact on the final ADC metrics.

## Repository Layout

- [functions/](functions/) - MATLAB helper functions used by the simulations.
	- [simDeltaSigmaAdc.m](functions/simDeltaSigmaAdc.m) runs the Simulink model and returns the input, bitstream, and output waveforms.
	- [fft_1_sided.m](functions/fft_1_sided.m) computes the single-sided FFT spectrum.
- [scripts/](scripts/) - Example MATLAB scripts for running simulations and generating plots.
	- [example_ideal.m](scripts/example_ideal.m) simulates the ideal ADC case.
	- [example_opamp_gain.m](scripts/example_opamp_gain.m) sweeps op-amp DC gain.
	- [example_opamp_GBW.m](scripts/example_opamp_GBW.m) sweeps op-amp GBW.
	- [example_loop_saturation.m](scripts/example_loop_saturation.m) explores amplitude-driven loop saturation behavior.
- [simulink/](simulink/) - Simulink models for the comparator, modulator, and testbench.
- [figures/](figures/) - Exported plots from the MATLAB scripts.
- [docs/](docs/) - Project report source.

## Requirements

- MATLAB with the Signal Processing Toolbox for `snr`, `thd`, and `sinad`.
- Simulink.
- A Simulink-compatible MATLAB release that supports `arguments` blocks and `Simulink.SimulationInput`.

## How To Run

1. Open the repository in MATLAB.
2. Make sure the `functions/` folder is on the MATLAB path.
3. Run one of the example scripts in `scripts/`.

For example, to run the ideal case:

```matlab
run("scripts/example_ideal.m")
```

The script will:

- set the simulation parameters such as input amplitude, sampling interval, OSR, op-amp gain, and GBW,
- call [simDeltaSigmaAdc.m](functions/simDeltaSigmaAdc.m),
- plot the input/output waveforms,
- generate the modulator bitstream FFT,
- compute SNR, THD, and SNDR on the decimated output,
- export the resulting figures into [figures/](figures/).

### Core Parameters

The example scripts use a common simulation setup:

- Sampling interval: `Ts = 1 / 1.024e7`
- FFT length: `N = 2^18`
- Input tone: `Fin = 61 / N / Ts`
- Oversampling ratio: `OSR = 2^8`
- Input amplitude: `Ain = 0.5`

Non-ideal behavior is introduced by sweeping parameters such as:

- `Adc` for op-amp DC gain,
- `GBW` for op-amp gain-bandwidth product.

### Measurement Flow

The workflow is:

1. Simulate the testbench in Simulink.
2. Capture the input, bitstream, and decimator output.
3. Normalize the decimated output to match the input amplitude.
4. Compute a single-sided FFT of the bitstream.
5. Downsample the output and evaluate `snr`, `thd`, and `sinad`.
6. Compare the ideal result against non-ideal sweeps.

### Expected Outputs

The scripts generate figures such as:

- input vs. output waveform comparisons,
- quantizer bitstream waveforms,
- bitstream FFT spectra with the theoretical noise transfer function overlay,
- SNR/THD/SNDR plots,
- performance sweeps across op-amp gain or GBW.

### Notes

- The Simulink testbench is named `testbench.slx`.
- The helper function [simDeltaSigmaAdc.m](functions/simDeltaSigmaAdc.m) expects the Simulink model to expose `input`, `bitstream`, and `output` signals through `ScopeData`.
- If you change the sample rate, OSR, or FFT length, update the derived tone frequency accordingly so the input remains coherent with the FFT window.

## License

See [LICENSE](LICENSE) for license information.
