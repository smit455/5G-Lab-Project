% Simulate transmitted and received bits
% Assume QPSK-like modulation for simplicity
transmittedBits = real(waveform(:, 1)) > 0; % Simplified transmitted bits
receivedBits = real(noisyWaveform(:, 1)) > 0; % Simplified received bits after noise

% Calculate Bit Errors
bitErrors = sum(transmittedBits ~= receivedBits); % Count mismatched bits

% Calculate Bit Error Rate (BER)
totalBits = length(transmittedBits);
ber = bitErrors / totalBits; % BER formula

% Display BER results
disp(['Total Transmitted Bits: ', num2str(totalBits)]);
disp(['Total Bit Errors: ', num2str(bitErrors)]);
disp(['Bit Error Rate (BER): ', num2str(ber)]);