% Basic 5G NR Downlink Waveform Simulation

% Define an SCS carrier with 100 resource blocks
carrier = nrSCSCarrierConfig('NSizeGrid', 100);

% Define PDSCH configuration with 16QAM modulation and PT-RS enabled
pdsch = nrWavegenPDSCHConfig('Modulation', '16QAM', 'TargetCodeRate', 658/1024, 'EnablePTRS', true);

% Configure downlink carrier with PDSCH
cfgDL = nrDLCarrierConfig('FrequencyRange', 'FR1', 'ChannelBandwidth', 40, ...
    'NumSubframes', 20, 'SCSCarriers', {carrier}, 'PDSCH', {pdsch});

% Generate the waveform
waveform = nrWaveformGenerator(cfgDL);
disp("5G NR waveform generated.");

% Apply TDL channel effects (multipath fading)
tdl = nrTDLChannel('DelayProfile', 'TDL-C', 'DelaySpread', 300e-9, 'MaximumDopplerShift', 50);
[chanWaveform, ~] = tdl(waveform);
disp("Channel effects applied.");

% Add AWGN noise at 20 dB SNR
snrTarget = 20;
signalPower = mean(abs(chanWaveform).^2, 'all');
noisePower = signalPower / (10^(snrTarget / 10));
noise = sqrt(noisePower / 2) * (randn(size(chanWaveform)) + 1i * randn(size(chanWaveform)));
noisyWaveform = chanWaveform + noise;

% Compute and display actual SNR
measuredSNR = 10 * log10(mean(abs(chanWaveform).^2, 'all') / mean(abs(noise).^2, 'all'));
disp(['Target SNR: ', num2str(snrTarget), ' dB']);
disp(['Measured SNR: ', num2str(measuredSNR), ' dB']);