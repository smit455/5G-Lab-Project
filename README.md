# 📡 5G Signal Propagation and Noise Simulation (MATLAB)

This repository simulates the behavior of 5G signals in the presence of multipath fading and noise using MATLAB's 5G Toolbox. The project provides a platform to evaluate how real-world channel impairments affect signal integrity, helping in better understanding and design of 5G communication systems.

---

## 🚀 Features

- 📶 **5G NR Waveform Generation** using 16-QAM and 15 kHz subcarrier spacing
- 🌆 **Channel Modeling** with TDL-C profile to emulate urban macro-cell environments
- 🌪️ **Noise Simulation** using Additive White Gaussian Noise (AWGN)
- 📊 **Performance Metrics**: Signal-to-Noise Ratio (SNR) and Bit Error Rate (BER)
- 📈 **Visualizations**: Time-domain and frequency-domain signal analysis

---

## 📁 Project Structure

- init.m: Main script to generate the 5G NR waveform, apply channel effects, and add noise.
- BER.m: Script to compute and display the Bit Error Rate (BER).
- Noise.m:Simulation uses 16-QAM modulated 5G NR waveform over TDL-C and CDL-C channels with 20 dB AWGN to compare frequency- and time-domain performance.
- frequency&time domain channel modeling.mlx:Simulation compares frequency- and time-domain modeling of 5G NR PDSCH over CDL channel based on EVM and execution time.
- Basic 5g Nr.m:Simulates a 5G NR downlink waveform with 16QAM, TDL-C fading, and AWGN at 20 dB SNR, then measures the resulting SNR.
- Visualizations: Plots showcasing signal behavior under different conditions.


---

## 🛠️ Methodologies

### 🔷 Waveform Generation
- Modulation: 16-QAM
- Subcarrier Spacing: 15 kHz
- Resource Blocks: 100

### 📡 Channel Configuration
- Channel Model: TDL-C,DCL-C
- Delay Spread: 300 ns
- Doppler Shift: 50 Hz

### 🌐 Noise Injection
- Target SNR: 20 dB
- Noise Type: AWGN

---


## 📊 Results Summary

### ⏱️ Time Domain
- **Original Signal**: Clean and undistorted
- **After Channel**: Delay and attenuation observed
- **After Noise**: Notable signal distortion

### 🔉 Frequency Domain
- **Original**: Spectrum intact
- **Channel**: Slight frequency spreading
- **Noise**: Noticeable spectrum corruption

### 📈 Metrics
- Measured SNR: `20.0041 dB`
- BER: `0.50325` (Uncoded)

---

## Demonstration
[Demonstration Video](https://drive.google.com/file/d/1RjNZSSpA9CF_9GutW7tKal4fv7QLgrMR/view?usp=sharing)

## 🧪 Usage Instructions

1. Clone this repository:
   ```bash
   git clone https://github.com/smit455/5G-Lab-Project.git
   cd 5G-Lab-Project

2. Open MATLAB and navigate to the project directory.


## Acknowledgment
- Special thanks to Dr. Bhupendra Kumar for his guidance and insights into 5G technology.
