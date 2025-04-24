% Create an SCS carrier configuration object with the default SCS of 15 kHz and 100 resource blocks.
carrier = nrSCSCarrierConfig('NSizeGrid',100);

% Create a customized BWP configuration object for the SCS carrier.
bwp = nrWavegenBWPConfig('NStartBWP',carrier.NStartGrid+10);

% Create an SS burst configuration object with block pattern Case A.
ssb = nrWavegenSSBurstConfig('BlockPattern','Case A');

% Create a PDCCH configuration object, specifying an aggregation of size two and the fourth candidate for the PDCCH instance
pdcch = nrWavegenPDCCHConfig('AggregationLevel',2,'AllocatedCandidate',4);

% Create a CORESET configuration object, specifying four frequency resources and a duration of three OFDM symbols.
coreset = nrCORESETConfig;
coreset.FrequencyResources = [1 1 1 1];
coreset.Duration = 3;

% Create a search space set configuration object, specifying two aggregation levels.
ss = nrSearchSpaceConfig;
ss.NumCandidates = [8 4 0 0 0];

% Create a PDSCH configuration object, specifying the modulation scheme and the target code rate. Enable the PDSCH PT-RS.
pdsch = nrWavegenPDSCHConfig( ...
    'Modulation','16QAM','TargetCodeRate',658/1024,'EnablePTRS',true);

% Create a PDSCH DM-RS and a PDSCH PT-RS configuration object with the specified property values.
dmrs = nrPDSCHDMRSConfig('DMRSTypeAPosition',3);
pdsch.DMRS = dmrs;
ptrs = nrPDSCHPTRSConfig('TimeDensity',2);
pdsch.PTRS = ptrs;

% Create a CSI-RS configuration object with the specified property values.
csirs = nrWavegenCSIRSConfig('RowNumber',4,'RBOffset',10,'NumRB',10,'SymbolLocations',5);

% Create a single-user 5G downlink waveform configuration object, specifying the previously defined configurations.
cfgDL = nrDLCarrierConfig( ...
    'FrequencyRange','FR1', ...
    'ChannelBandwidth',40, ...
    'NumSubframes',20, ...
    'SCSCarriers',{carrier}, ...
    'BandwidthParts',{bwp}, ...
    'SSBurst',ssb, ...
    'CORESET',{coreset}, ...
    'SearchSpaces',{ss}, ...
    'PDCCH',{pdcch}, ...
    'PDSCH',{pdsch}, ...
    'CSIRS',{csirs});

% Ensure PDSCH uses one layer (single transmit antenna)
pdsch.NumLayers = 1;

% Regenerate the waveform
waveform = nrWaveformGenerator(cfgDL);
disp("5G NR waveform generated");

% Plot the original waveform in time domain
figure;
subplot(3, 2, 1);
plot(real(waveform(:, 1)));
title('Original Waveform (Time Domain)');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

% Compute and plot the spectrum of the original waveform
freqAxis = linspace(-0.5, 0.5, length(waveform)) * cfgDL.ChannelBandwidth * 1e6;
spectrumOriginal = fftshift(abs(fft(waveform(:, 1))));
subplot(3, 2, 2);
plot(freqAxis / 1e6, 20*log10(spectrumOriginal / max(spectrumOriginal)));
title('Original Waveform Spectrum');
xlabel('Frequency (MHz)');
ylabel('Magnitude (dB)');
grid on;

% Configure the TDL channel
tdl = nrTDLChannel;
tdl.DelayProfile = 'TDL-C'; % Example delay profile
tdl.DelaySpread = 300e-9; % 300 ns
tdl.MaximumDopplerShift = 50; % 50 Hz Doppler
tdl.NumTransmitAntennas = size(waveform, 2); % Align transmit antennas

% Apply channel effects
[chanWaveform, pathGains] = tdl(waveform);
disp("Channel effects applied");

% Plot the channel-affected waveform in time domain
subplot(3, 2, 3);
plot(real(chanWaveform(:, 1)));
title('Waveform After Channel Effects (Time Domain)');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

% Compute and plot the spectrum of the channel-affected waveform
spectrumChan = fftshift(abs(fft(chanWaveform(:, 1))));
subplot(3, 2, 4);
plot(freqAxis / 1e6, 20*log10(spectrumChan / max(spectrumChan)));
title('Spectrum After Channel Effects');
xlabel('Frequency (MHz)');
ylabel('Magnitude (dB)');
grid on;

% Add AWGN to the channel-affected waveform
snrTarget = 20; % Desired SNR in dB
signalPower = mean(abs(chanWaveform).^2, 'all'); % Average signal power
noisePower = signalPower / (10^(snrTarget / 10)); % Noise power for desired SNR
noise = sqrt(noisePower / 2) * (randn(size(chanWaveform)) + 1i * randn(size(chanWaveform)));
noisyWaveform = chanWaveform + noise;

% Calculate the resulting SNR
measuredSNR = 10 * log10(mean(abs(chanWaveform).^2, 'all') / mean(abs(noise).^2, 'all'));

% Plot the noisy waveform in time domain
subplot(3, 2, 5);
plot(real(noisyWaveform(:, 1)));
title('Noisy Waveform (Time Domain)');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

% Compute and plot the spectrum of the noisy waveform
spectrumNoisy = fftshift(abs(fft(noisyWaveform(:, 1))));
subplot(3, 2, 6);
plot(freqAxis / 1e6, 20*log10(spectrumNoisy / max(spectrumNoisy)));
title('Spectrum After Adding Noise');
xlabel('Frequency (MHz)');
ylabel('Magnitude (dB)');
grid on;

% Display SNR analysis
figure;
bar([snrTarget, measuredSNR]);
set(gca, 'XTickLabel', {'Target SNR (dB)', 'Measured SNR (dB)'});
ylabel('SNR (dB)');
title('SNR Analysis');
grid on;

% Display results in the command window
disp(['Target SNR: ', num2str(snrTarget), ' dB']);
disp(['Measured SNR: ', num2str(measuredSNR), ' dB']);

