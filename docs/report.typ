#import "@preview/charged-ieee:0.1.4": ieee
#import "@preview/unify:0.8.0": *

#show: ieee.with(
  title: [Behavioral Modeling of a 2nd-Order Delta-Sigma ADC],
  abstract: [
    This project develops a behavioral model of a 2nd-order delta-sigma ADC for an AD/DA course. The design target is a high-resolution converter with 104dB SNR and 20kHz signal bandwidth. The model is implemented in MATLAB and Simulink, then evaluated through FFT analysis together with THD, SNR, and SNDR measurements. Several non-idealities, including finite op-amp DC gain, finite gain-bandwidth product, and input amplitude stress, are also swept to study their impact on converter performance.
  ],
  authors: (
    (
      name: "Brian Li",
      organization: [University of Macau],
      location: [Macau, China],
      email: "brian.li@connect.um.edu.mo",
    ),
  ),
  index-terms: ("Delta-Sigma ADC", "Behavioral Modeling", "Simulink", "FFT", "SNDR"),
  bibliography: bibliography("refs.bib"),
  figure-supplement: [Fig.],
)

#set figure(placement: top)

#let ppi = $upright(pi)$
#let ee = $upright(e)$

= Introduction

Delta-sigma analog-to-digital converters are attractive when high resolution is required at moderate bandwidth because they trade sampling rate for noise shaping and digital decimation. In this project, we designed a delta-sigma ADC with a #qty(20,"kHz") signal band and an SNR goal of #qty(96,"dB"). The behavioral model is built in Simulink so that both ideal operation and non-ideal effects can be evaluated in a consistent simulation flow.

Rather than optimizing circuit-level transistor behavior, the model focuses on system-level metrics. This makes it possible to compare FFT spectra, dynamic range, and distortion behavior directly against the project specification while keeping the simulation lightweight enough for design sweeps.

= Behavioral Model Design

== Delta-Sigma Order

To begin with, we should determine the order of the modulator and the oversampling ratio (OSR) needed to meet the SNR target. The relationship between SNR, OSR, and modulator order can be expressed as@schreier_understanding_2005:
$
  "SNR"
  = (A_"sig"^2 (2L+1) ("OSR")^(2L+1)) / (ppi^(2L) e_"rms"^2)
$ <eqn:SNR>
where $A_"sig"$ is the signal amplitude, $L$ is the modulator order, and $e_"rms"$ is the quantization noise level. Assuming the quantization noise is uniformly distributed, we have $e_"rms"^2 = "LSB"^2 / 12$. 

Based on @eqn:SNR, with an insufficient noise shaping of #qty(20, "dB")/decade, 1st order modulators would not be able to reach #qty(96, "dB") without absurd OSR. 3rd and higher order modulators can provide steeper noise shaping, but they are more difficult to stabilize, and non-idealities often create confusing spurs which are harder to suppress. A 2nd-order modulator is a good compromise for this project.

== Quantizer and DAC

For the sake of simplicity, we choose a 1-bit quantizer and a single-bit DAC feedback, both with an LSB Of 2. This allows us to focus on the noise-shaping behavior without worrying about multi-bit linearity issues. 

== Oversampling Ratio

We chose $A_"sig"$ to be 0.5, which is half of the full-scale range. This ensures that the signal is strong enough to be above the quantization noise floor while still leaving some headroom for distortion. With $L=2, "LSB" = 2$, and the SNR target of #qty(96, "dB"), we can rearrange @eqn:SNR to solve for the required OSR:
$
"OSR"
  gt.eq (("SNR" * ppi^(2L) e_"rms"^2) / (A_"sig"^2 (2L+1)))^(1/(2L+1))
  approx 159.556
$ <eqn:OSR>

We round this up to an OSR of 256 to ensure that we meet the SNR target with some margin, while simplifying the FFT analysis. This sets the sampling frequency to #qty(10.24, "MHz").

== Decimation Filter

We use a typical $sinc^3$ decimation filter to suppress out-of-band quantization noise and downsample the output to the Nyquist rate of #qty(40, "kHz"). The filter is designed to have a cutoff frequency at the signal bandwidth of #qty(20, "kHz") to maximize in-band SNR.

== Simulink Implementation

#figure(
  box(
    image("../figures/block_diagram.pdf"),
    clip: true,
    inset: (x: -50pt, y: -100pt),
  ),
  caption: [Block diagram of the 2nd-order delta-sigma ADC.],
) <fig:block_diagram>

The Simulink model is built around a 2nd-order architecture with a 1-bit quantizer and a digital decimation filter as shown in @fig:block_diagram.

= Analysis and Simulation

The simulation flow is organized around the helper function #link("../functions/simDeltaSigmaAdc.m")[`simDeltaSigmaAdc.m`], which configures the Simulink testbench, runs the model, and returns the input, bitstream, and output waveforms as tables. The FFT helper #link("../functions/fft_1_sided.m")[`fft_1_sided.m`] computes the single-sided spectrum used throughout the analysis.

The FFT is conducted using coherent sampling. The number of points is set to $2^18$ so that the quantization-noise shaping can be observed clearly. The output waveform is downsampled after simulation to evaluate SNR, THD, and SNDR in the baseband.

== Ideal Operation

#figure(
  image("../figures/fft_ideal.svg"),
  caption: [Ideal single-sided FFT of the bitstream, together with the theoretical noise-transfer trend.],
) <fig:fft_ideal>

@fig:fft_ideal shows the spectrum of the high frequency bitstream generated by the quantizer. The noise floor is shaped according to the expected trend for a 2nd-order modulator, with a steep roll-off of #qty(40, "dB")/decade.

At low frequencies, however, the noise floor deviates from the ideal trend. This is because the quantization noise is not perfectly white, and the finite FFT length causes some leakage.

#figure(
  image("../figures/waveform_input_vs_output_ideal.svg"),
  caption: [Ideal time-domain response showing the input signal and the decimated output waveform.],
) <fig:waveform_input_vs_output_ideal>

@fig:waveform_input_vs_output_ideal shows the time-domain response of the ideal case. The input is a coherent tone at #qty(2.363, "kHz"), and the output is a decimated waveform that closely follows the input, demonstrating the high-resolution conversion.

#figure(
  image("../figures/snr_ideal.svg"),
  caption: [Ideal SNR measurement for the decimated output.],
) <fig:snr_ideal>

#figure(
  image("../figures/thd_ideal.svg"),
  caption: [Ideal THD measurement for the decimated output.],
) <fig:thd_ideal>

@fig:snr_ideal and @fig:thd_ideal show the SNR and THD measurements for the ideal case using the MATLAB signal processing functions, respectively. The in-band SINAD, or Signal-to-Noise-and-Distortion Ratio, is measured to be around #qty(104.93, "dB"), which meets the design target.

== Loop Saturation

#figure(
  image("../figures/sinad_Ain.svg"),
  caption: [SNDR versus input amplitude.],
) <fig:sinad_Ain>

@fig:sinad_Ain shows the simulated SINAD versus input amplitude. At low input amplitudes, the SINAD is limited by the quantization noise floor, which follows @eqn:SNR. As the input amplitude increases above 0.5, however, the SINAD drops significantly due to distortion.

#figure(
  image("../figures/fft_Ain.svg"),
  caption: [FFT comparison when sweeping the input amplitude.],
) <fig:fft_Ain>

This is because when the input amplitude gets too large, the loop can saturate, which makes the quantization noise no longer uniformly distributed but tends to have more 1s when the input is closer to the positive full scale, and more 0s when the input is closer to the negative full scale. This reflects in the FFT spectrum as raised harmonics and a worse THD, as shown in @fig:fft_Ain.

== Opamp Non-Idealities

In reality, the integrators in the delta-sigma modulator are implemented using op-amps, which have finite DC gain and gain-bandwidth product (GBW). These non-idealities degrade the loop accuracy and can reduce the effectiveness of noise shaping.

=== Finite Op-Amp DC Gain

#figure(
  image("../figures/fft_Adc.svg"),
  caption: [FFT comparison when sweeping the op-amp DC gain.],
) <fig:fft_Adc>

An op-amp with finite DC gain has a non-ideal transfer function that can be approximated as:
$
H(z) = 1 / (1 - (1-1/A_0)z^(-1))
$
where $A_0$ is the DC gain. The finite gain reduces the loop gain at low frequencies, which degrades the noise-shaping behavior and increases the in-band noise floor, as shown in @fig:fft_Adc.

#figure(
  image("../figures/sinad_Adc.svg"),
  caption: [SNDR versus op-amp DC gain.],
) <fig:sinad_Adc>

@fig:sinad_Adc show the impact of finite op-amp DC gain on the noise-shaping behavior and the resulting SINAD. As the gain decreases, the loop accuracy degrades, which reduces the effectiveness of noise shaping and leads to a higher in-band noise floor.

=== Finite Op-Amp Gain-Bandwidth Product

An op-amp with finite GBW means the integrator has a gain loss due to not fully settling in a time interval of $T_s$, which can be modeled by:
$
H(z) = (1 - ee^(-2ppi dot "GBW" dot T_"s")) / (1 - z^(-1))
$

#figure(
  image("../figures/fft_GBW.svg"),
  caption: [FFT comparison when sweeping the op-amp gain-bandwidth product.],
) <fig:fft_GBW>

#figure(
  image("../figures/sinad_GBW.svg"),
  caption: [SNDR versus op-amp gain-bandwidth product.],
) <fig:sinad_GBW>

In a 2nd-order delta-sigma modulator, this effect is not as severe as the finite DC gain, but it still causes a reduction in loop gain at frequencies near the signal bandwidth. This can degrade noise shaping and increase in-band noise, as shown in @fig:fft_GBW and @fig:sinad_GBW.

= Conclusion

This project demonstrates a complete MATLAB/Simulink-based behavioral workflow for a 2nd-order delta-sigma ADC. The ideal case establishes the expected noise-shaping behavior, and the non-ideal sweeps show how implementation limits affect noise and distortion. Together, the figures provide a compact documentation trail for checking whether the design objective of high-resolution conversion is being met.
