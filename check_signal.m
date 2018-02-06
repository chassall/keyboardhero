function [ output_args ] = check_signal( win, osc_stream )
%CHECK_SIGNAL Displays raw EEG, colour-coded for variance
%   Version 2.0
%   Displays Muse EEG in a given PTB window win.
%   EEG is colour-coded for variance (green = low, yellow = mid, red =
%   high).
%   Actual variances are also displayed.
%   C. Hassall
%   March, 2016

% Get the window dimensions
rec = Screen('Rect',win);

% EEG parameters
max_var = 200; % This value determines the EEG colour (max_var and above will be red)
max_eeg = 500; % Defines the max_eeg for the displayed data (the scale)
num_samples = 5000; % Defines the number of samples to display
base_var_on = 500; % Number of samples on which to base the variance computation
sample_rate = 500;
num_channels = 4;

% Define control keys
ExitKey = KbName('a');
UpKey =  KbName('UpArrow');
DownKey =  KbName('DownArrow');

instructions = '(up) increase scale\n(down) decrease scale\n(a) accept\n';

% Define our own colour map (green to yellow to red)
this_map = [0    1.0000         0;
    0.0645    1.0000         0;
    0.1290    1.0000         0;
    0.1935    1.0000         0;
    0.2581    1.0000         0;
    0.3226    1.0000         0;
    0.3871    1.0000         0;
    0.4516    1.0000         0;
    0.5161    1.0000         0;
    0.5806    1.0000         0;
    0.6452    1.0000         0;
    0.7097    1.0000         0;
    0.7742    1.0000         0;
    0.8387    1.0000         0;
    0.9032    1.0000         0;
    0.9677    1.0000         0;
    0.9698    1.0000         0;
    0.9718    1.0000         0;
    0.9738    1.0000         0;
    0.9758    1.0000         0;
    0.9778    1.0000         0;
    0.9798    1.0000         0;
    0.9819    1.0000         0;
    0.9839    1.0000         0;
    0.9859    1.0000         0;
    0.9879    1.0000         0;
    0.9899    1.0000         0;
    0.9919    1.0000         0;
    0.9940    1.0000         0;
    0.9960    1.0000         0;
    0.9980    1.0000         0;
    1.0000    1.0000         0;
    1.0000    0.9980    0.0002;
    1.0000    0.9961    0.0004;
    1.0000    0.9941    0.0005;
    1.0000    0.9922    0.0007;
    1.0000    0.9902    0.0009;
    1.0000    0.9883    0.0011;
    1.0000    0.9863    0.0013;
    1.0000    0.9844    0.0015;
    1.0000    0.9824    0.0016;
    1.0000    0.9805    0.0018;
    1.0000    0.9785    0.0020;
    1.0000    0.9766    0.0022;
    1.0000    0.9746    0.0024;
    1.0000    0.9727    0.0026;
    1.0000    0.9707    0.0027;
    1.0000    0.9688    0.0029;
    1.0000    0.9082    0.0086;
    1.0000    0.8477    0.0143;
    1.0000    0.7871    0.0200;
    1.0000    0.7266    0.0256;
    1.0000    0.6660    0.0313;
    1.0000    0.6055    0.0370;
    1.0000    0.5449    0.0427;
    1.0000    0.4844    0.0483;
    1.0000    0.4238    0.0540;
    1.0000    0.3633    0.0597;
    1.0000    0.3027    0.0654;
    1.0000    0.2422    0.0710;
    1.0000    0.1816    0.0767;
    1.0000    0.1211    0.0824;
    1.0000    0.0605    0.0881;
    1.0000         0    0.0938];

% Convert to PTB RGB values (range from 1 - 255)
this_map = round(255.*this_map);

Screen(win,'TextColor',[255 255 255]);
Screen(win,'TextFont','Arial');
Screen(win,'TextSize',20);
DrawFormattedText(win, 'Press any key to check signal','center', 'center', [],[],[],[],2);
Screen('Flip',win);
KbWait([],2);

% Grab samples
temp_eeg = nan(num_channels,num_samples);
while 1
    muse_data = osc_recv(osc_stream,0.1);
    if ~isempty(muse_data)
        for p = 1:length(muse_data)
            this_path = muse_data{p}.path;
            if strcmp(this_path,'/muse/eeg')
                temp_eeg(:,1:end-1) = temp_eeg(:,2:end);
                temp_eeg(:,end) = double(cell2mat(muse_data{p}.data))';
            end
        end
        
        % If we've not yet defined the EEG max_eeg, do so now
        if isnan(max_eeg)
            max_eeg = max(max(temp_eeg - repmat(min(temp_eeg,[],2),1,num_samples)));
        end
        
        % Compute variance
        if base_var_on <= num_samples
            this_var = nanvar(temp_eeg(:,end-base_var_on+1:end),[],2);
        else
            this_var = nanvar(temp_eeg,[],2);
        end
        
        % Determine the colours for each channel
        colour_i = round((this_var ./ max_var) .* 64);
        colour_i(colour_i > 64) = 64; % Don't go above 64 (we only have 64 colours)
        colour_i(colour_i == 0) = 1; % Don't go below 1
        
        % Text properties for the displayed variance
        Screen('TextFont',win, 'Courier New');
        Screen('TextSize',win, 24);
        % Screen('TextStyle', win, 1);
        DrawFormattedText(win,[instructions '\n\n\nTP9  ' num2str(round(this_var(1))) '\nFp1  ' num2str(round(this_var(2))) '\nFp2  ' num2str(round(this_var(3))) '\nTP10 ' num2str(round(this_var(4)))],'center','center',[255 255 255]);
        
        for i = 1:4
            Screen('DrawLines',win,scale_eeg(temp_eeg(i,:),i,rec,max_eeg),[],this_map(colour_i(i),:));
        end
        Screen('Flip',win);
    else
        Screen(win,'TextFont','Arial');
        Screen(win,'TextSize',20);
        DrawFormattedText(win,'Muse data missing\nPress any key to exit','center','center',[255 255 255]);
        Screen('Flip',win);
        KbWait();
        ME = MException('check_signal:noMuseData', ...
            'No Muse data (the device is not connected and/or the battery is dead)');
        throw(ME);
    end
    
    % Check for keyboard input
    [~, ~, keyCode, ~] = KbCheck();
    if keyCode(ExitKey)
        break;
    elseif keyCode(UpKey)
        max_eeg = max_eeg + 5;
        if max_eeg > 2000
            max_eeg = 2000;
        end
    elseif keyCode(DownKey)
        max_eeg = max_eeg - 5;
        if max_eeg < 5
            max_eeg = 5;
        end
    end
end