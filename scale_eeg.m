function [ scaled_eeg ] = scale_eeg( input_eeg, channel, rec, max_eeg )
%SCALE_EEG Scales Muse EEG data for display in a PTB window
%   Version 2.0
%   input_eeg: channels by samples eeg data
%   channel: which channel to max_eeg (e.g. 1)
%   rec:    the dimensions of the PTB window (e.g. [0 0 800 400])
%   max_eeg:    max absolute EEG value

% Time vector
num_samples = length(input_eeg);
times = (1:num_samples) ./ num_samples; % Scaled from 0 to 1

% EEG vector
input_eeg = input_eeg ./max_eeg; % max_eeg the rest of the EEG
input_eeg = input_eeg - nanmean(input_eeg) + 0.5; % Baseline correction so that waveforms are centered around 0.5
input_eeg(input_eeg > 1) = 1;
input_eeg(input_eeg < 0) = 0;

these_points = [times; input_eeg];

% max_eeg the points for display
scale_factor = repmat([rec(3); rec(4)/4],1,num_samples);
shift_factor = repmat([0; (channel - 1)*rec(4)/4],1,num_samples);
scaled_eeg = these_points .* scale_factor + shift_factor;
end