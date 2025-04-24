% Configure the carrier.
simParameters.Carrier = nrCarrierConfig;
simParameters.Carrier.NSizeGrid = 51;            % Bandwidth in number of resource blocks (51 RBs at 30 kHz SCS for 20 MHz BW)
simParameters.Carrier.SubcarrierSpacing = 30;    % 15, 30, 60, 120, 240 (kHz)
simParameters.Carrier.CyclicPrefix = 'Normal';   % 'Normal' or 'Extended' (Extended CP is relevant for 60 kHz SCS only)

% Configure the carrier frequency, transmitter (BS), receiver (UE), and
% distance between the BS and UE. Specify this distance as a vector for
% multiple SNR points.
simParameters.CarrierFrequency = 3.5e9;   % Carrier frequency (Hz)
simParameters.TxHeight = 25;              % Height of the BS antenna (m)
simParameters.TxPower = 40;               % Power delivered to all antennas of the BS on a fully allocated grid (dBm)
simParameters.RxHeight = 1.5;             % Height of UE antenna (m)
simParameters.RxNoiseFigure = 6;          % Noise figure of the UE (dB)
simParameters.RxAntTemperature = 290;     % Antenna temperature of the UE (K)
simParameters.TxRxDistance = [5e2 9e2];   % Distance between the BS and UE (m)
simParameters.PathLossModel = '5G-NR';        % '5G-NR' or 'fspl'

simParameters.PathLoss = nrPathLossConfig;
simParameters.PathLoss.Scenario = 'UMa';      % Urban macrocell
simParameters.PathLoss.EnvironmentHeight = 1; % Average height of the environment in UMa/UMi
simParameters.DelayProfile = 'TDL-A'; % A, B, and C profiles are NLOS channels. D and E profiles are LOS channels.

if contains(simParameters.DelayProfile,'CDL','IgnoreCase',true)
    channel = nrCDLChannel;
    channel.DelayProfile = simParameters.DelayProfile;
    chInfo = info(channel);
    kFactor = chInfo.KFactorFirstCluster; % dB
else % TDL
    channel = nrTDLChannel;
    channel.DelayProfile = simParameters.DelayProfile;
    chInfo = info(channel);
    kFactor = chInfo.KFactorFirstTap; % dB
end

% Determine LOS between Tx and Rx based on Rician factor K.
simParameters.LOS = kFactor>-Inf;

% Determine the sample rate and FFT size that are required for this carrier.
waveformInfo = nrOFDMInfo(simParameters.Carrier);

% Get the maximum delay of the fading channel.
chInfo = info(channel);
maxChDelay = chInfo.MaximumChannelDelay;
% Calculate the path loss.
if contains(simParameters.PathLossModel,'5G','IgnoreCase',true)
    txPosition = [0;0; simParameters.TxHeight];
    dtr = simParameters.TxRxDistance;
    rxPosition = [dtr; zeros(size(dtr)); simParameters.RxHeight*ones(size(dtr))];
    pathLoss = nrPathLoss(simParameters.PathLoss,simParameters.CarrierFrequency,simParameters.LOS,txPosition,rxPosition);
else % Free-space path loss
    lambda = physconst('LightSpeed')/simParameters.CarrierFrequency;
    pathLoss = fspl(simParameters.TxRxDistance,lambda);
end
kBoltz = physconst('Boltzmann');
NF = 10^(simParameters.RxNoiseFigure/10);
Teq = simParameters.RxAntTemperature + 290*(NF-1); % K
N0 = sqrt(kBoltz*waveformInfo.SampleRate*Teq/2.0);
fftOccupancy = 12*simParameters.Carrier.NSizeGrid/waveformInfo.Nfft;
simParameters.SNRIn = (simParameters.TxPower-30) - pathLoss - 10*log10(fftOccupancy) - 10*log10(2*N0^2);
disp(simParameters.SNRIn)

SNRInc = mat2cell(simParameters.SNRIn(:),length(pathLoss),1);
tSNRIn = table(simParameters.TxRxDistance(:),SNRInc{:},'VariableNames',{'Distance Tx-Rx (m)','SNR (dB)'});
disp(tSNRIn)
NFrames = 20;
NSlots = NFrames*simParameters.Carrier.SlotsPerFrame;
nSNRPoints = length(pathLoss);                          % Number of SNR points

% Initialize measurements and create auxiliary variables.
nTxAnt = chInfo.NumTransmitAntennas;
nRxAnt = chInfo.NumReceiveAntennas;
[powSignalRE,powSignal,powNoiseRE,powNoise] = deal(zeros(nSNRPoints,nRxAnt,NSlots));
pgains = zeros(length(chInfo.PathDelays),nTxAnt,nRxAnt,nSNRPoints,NSlots);
scs = simParameters.Carrier.SubcarrierSpacing;
nSizeGrid = simParameters.Carrier.NSizeGrid;
nfft = waveformInfo.Nfft;

% Reset the random generator for reproducibility.
rng('default');

% Transmit a CP-OFDM waveform through the channel and measure the SNR for
% each distance between Tx and Rx (path loss values).
for pl = 1:length(pathLoss)
    carrier = simParameters.Carrier;
    for slot = 0:NSlots-1
        slotIdx = slot+1;
        carrier.NSlot = slot;

        % Change random seed to generate an independent realization of the
        % channel in every time slot (block fading).
        release(channel);
        channel.Seed = slot; 
        
        % Create the OFDM resource grid and allocate random QPSK symbols.
        txgrid = nrResourceGrid(carrier,nTxAnt);
        txgrid(:) = nrSymbolModulate(randi([0 1],numel(txgrid)*2,1),'QPSK');
        
        % Perform CP-OFDM modulation.
        txWaveform = nrOFDMModulate(txgrid,scs,slot);

        % Calculate the amplitude of the transmitted signal. The FFT and
        % resource grid size scaling normalize the signal power. The
        % transmitter distributes the power across all antennas equally,
        % simulating the effect of unit norm beamformer.
        signalAmp = db2mag(simParameters.TxPower-30)*sqrt(nfft^2/(nSizeGrid*12*nTxAnt));
        txWaveform = signalAmp*txWaveform;
        
        % Pad the signal with zeros to ensure that a full slot is available
        % to the receiver after synchronization.
        txWaveform = [txWaveform; zeros(maxChDelay, size(txWaveform,2))]; %#ok<AGROW>
        
        % Pass the signal through fading channel.
        [rxWaveform,pathGains,sampleTimes] = channel(txWaveform);
        pgains(:,:,:,pl,slotIdx) = pathGains(1,:,:,:);

        % Apply path loss to the signal.
        rxWaveform = rxWaveform*db2mag(-pathLoss(pl));
        
        % Generate AWGN.
        noise = N0*complex(randn(size(rxWaveform)),randn(size(rxWaveform)));
        
        % Perform perfect synchronization.
        pathFilters = getPathFilters(channel); % Path filters for perfect timing estimation
        offset = nrPerfectTimingEstimate(pathGains,pathFilters);
        rxWaveform = rxWaveform(1+offset:end,:);
        noise = noise(1+offset:end,:);

        % Perform CP-OFDM demodulation of the received signal and noise.
        ngrid = nrOFDMDemodulate(carrier,noise);
        rxgrid = nrOFDMDemodulate(carrier,rxWaveform);

        % Measure the RE and overall power of the received signal and noise.
        powSignalRE(pl,:,slotIdx) = rms(rxgrid,[1 2]).^2/nfft^2;
        powSignal(pl,:,slotIdx) = powSignalRE(pl,:,slotIdx)*nSizeGrid*12;
        
        powNoiseRE(pl,:,slotIdx) = rms(ngrid,[1 2]).^2/nfft^2;
        powNoise(pl,:,slotIdx) = powNoiseRE(pl,:,slotIdx)*nfft;
    end
end
fprintf('The resource grid uses %.1f %% of the FFT size, introducing a %.1f dB SNR gain.\n', fftOccupancy*100, -10*log10(fftOccupancy))
% Correct CDL/TDL average gain.
Gf = permute(mean(sum(rms(pgains,5).^2,1),2),[4 3 1 2]); % Correction factor

% Calculate overall SNR and SNR per RE.
SNRo  = 10*log10(mean(powSignal,3)./mean(powNoise,3)) - 10*log10(Gf); 
SNRre = 10*log10(mean(powSignalRE,3)./mean(powNoiseRE,3)) - 10*log10(Gf);

% Create a table to display the results.
SNRrec = mat2cell(SNRre,nSNRPoints,ones(nRxAnt,1));
tSNRre = table(simParameters.TxRxDistance(:),SNRrec{:},'VariableNames',["Distance (m)", "SNR RxAnt"+(1:nRxAnt)]);
disp(tSNRre)