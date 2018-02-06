% Keyboard Hero
% C. Hassall
% December, 2017

%% Standard Krigolson Lab pre-script code
close all; clear variables; clc; % Clear everything
rng('shuffle'); % Shuffle the random number generator

%% Run flags
justTesting = 0; % Testing
usingMuse = 1;

%% OSC/Muse Variables
% u = udp('localhost',5555); % specify the UDP address that markers will be sent to
% fopen(u); % open the UDP connection
% oscsend(u,'/muse/elements/marker','i',0); % Send dummy marker
sample_rate = 500;                  % Muse sample rate, in Hz
length_of_baseline = 1;           % length of the ERP baseline to be recorded, in seconds
length_of_erp = 1;                % length of the ERP window to be recorded, in seconds
osc_wait_factor = 1.5;              % This factor determines how long we'll wait for data, e.g. if we're trying to get 1000 ms of data then we are willing to wait up to 1500 ms
osc_timeout = 0.1;                  % Timeout for receiving OSC messages
num_pre_samples = length_of_baseline * sample_rate; % Number of samples for baseline given the sampling rate and desired length of baseline
num_post_samples = length_of_erp * sample_rate; % Number of samples given the sampling rate and the length of erp we wish to record

% OPEN THE CONNECTION
if usingMuse
    osc_stream = osc_new_server(5555); % creates a new OSC server on Port 5555
end

%% Define control keys
KbName('UnifyKeyNames'); % Ensure that key names are mostly cross-platform
ExitKey = KbName('ESCAPE'); % Exit program

% Response keys
keys(1) = KbName('q');
keys(2) = KbName('w');
keys(3) = KbName('e');
keys(4) = KbName('r');
keys(5) = KbName('u');
keys(6) = KbName('i');
keys(7) = KbName('o');
keys(8) = KbName('p');


% Cam's office (iMac)
viewingDistance = 700; % mm, approximately MARGE
screenWidth = 570; % mm MARGE
screenHeight = 330; % mm MARGE
horizontalResolution = 2560; % Pixels MARGE
verticalResolution = 1440; % Pixels MARGE

% % Cam's laptop (Macbook Air)
% viewingDistance = 560; % mm, approximately BOB
% screenWidth = (800/1440)*286; % mm BOB
% screenHeight = (600/980)*179; % mm BOB
% horizontalResolution = 1440; % Pixels BOB
% verticalResolution = 980; % Pixels BOB

horizontalPixelsPerMM = horizontalResolution/screenWidth;
verticalPixelsPerMM = verticalResolution/screenHeight;

%% Participant info and data1852
p_data = [];
if justTesting
    p_number = '99';
    rundate = datestr(now, 'yyyymmdd-HHMMSS');
    filename = strcat('kbh_', rundate, '_', p_number, '.mat');
    sex = 'M';
    age = '21';
    handedness = 'R';
else
    while 1
        clc;
        p_number = input('Enter the participant number:\n','s');  % get the subject name/number
        rundate = datestr(now, 'yyyymmdd-HHMMSS');
        filename = strcat('kbh_', rundate, '_', p_number, '.mat');
        checker1 = ~exist(filename,'file');
        checker2 = isnumeric(str2double(p_number)) && ~isnan(str2double(p_number));
        if checker1 && checker2
            break;
        else
            disp('Invalid number, or filename already exists.');
            WaitSecs(1);
        end
    end
    sex = input('Sex (M/F): ','s');
    age = input('Age: ');
    handedness = input('Handedness (L/R): ','s');
end

%% Parameters
bgColour = [0 0 0];
occludeColour = [0 0 0];
textColour = [255 255 255];
lineColour = [255 255 255];
lineWidth = 3; % Pixels
lineSpacingDeg = 2;
lineSpacingMM = 2 * viewingDistance *tand(lineSpacingDeg/2);
lineSpaceingPx = lineSpacingMM * horizontalPixelsPerMM;
dotSizeDeg = 1;
dotSizeMM =  2 * viewingDistance *tand(dotSizeDeg/2);
dotSizePx = round(dotSizeMM*horizontalPixelsPerMM);
dotColour = [0 0 255];
winColour = [0 255 255];
loseColour = [255 0 0];
seqSpacingDeg = 5;
seqSpacingMM = 2 * viewingDistance *tand(seqSpacingDeg/2);
seqSpacingPx = round(seqSpacingMM*verticalPixelsPerMM);
speedDeg = 0.2; % Degrees per refresh (16 ms); 0.15
speedMM = 2*viewingDistance*tand(speedDeg/2);
speedPx = round(speedMM*verticalPixelsPerMM);

% Trial numbers - note that each trial takes around 3.6 seconds
trialsPerBin = 15; % Or, 50 to be able to look at interactions
nTrials = trialsPerBin*32;
trialTypes = repmat(1:32,1,trialsPerBin);
trialTypes = Shuffle(trialTypes);
showFeedback = 0;

% Set hand colour cue based on participant number
if mod(str2num(p_number),2)
    leftHandColour = [0 255 0]; % Green
    rightHandColour = [0 0 255]; % Blue
    colours = {'GREEN', 'BLUE'};
else
    leftHandColour = [0 0 255]; % Blue
    rightHandColour = [0 255 0]; % Green
    colours = {'BLUE', 'GREEN'};
end

%% ERP Variables
preResponse = nan(4,num_pre_samples);
postResponse = nan(4,num_post_samples);
eeg  = [];

%% Experiment
tic;
try
    ListenChar(0);
    if justTesting
        [win, rec] = Screen('OpenWindow', 0, bgColour,[0 0 800 600], 32, 2);
    else
        Screen('Preference', 'SkipSyncTests', 1);
        [win, rec] = Screen('OpenWindow', 0, bgColour);
    end
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    horRes = rec(3);
    verRes = rec(4);
    xmid = round(rec(3)/2);
    ymid = round(rec(4)/2);
    
    
    % Set variables that depend on xmid, ymid
    gameHeight = ymid*1.5;
    occludeHeight = ymid*0.8;
    fixationHeight = ymid*1.2;
    
    % lineLocs = [xmid-1.5*lineSpaceingPx xmid-.5*lineSpaceingPx xmid+.5*lineSpaceingPx xmid+1.5*lineSpaceingPx];
    numLines = 4;
%     lineLocs = [];
%     for l = 1:numLines/2
%         lineLocs = [lineLocs xmid-l*lineSpaceingPx];
%     end
%     for l = 1:numLines/2
%         lineLocs = [lineLocs xmid+l*lineSpaceingPx];
%     end
    lineLocs = [xmid-1.5*lineSpaceingPx xmid-0.5*lineSpaceingPx xmid+0.5*lineSpaceingPx xmid+1.5*lineSpaceingPx];
    % KbPressWait();
    
    % Instructions
    instructions{1} = ['KEYBOARD HERO\nHit the corresponding keys on the keyboard when the coloured dot is crossing the horizontal line\n' colours{1} ' = left hand, ' colours{2} ' = right hand\nLeft hand keys: q,w,e,r\nRight hand keys: u,i,o,p\n(position your hands now and press any key to begin)'];

    for t = 1:length(trialTypes)
        
        % Rest break?
        if (t == 1 || mod(t,120) == 0) && t ~= length(trialTypes)
            if usingMuse
                check_signal(win,osc_stream);
            end
            Screen(win,'TextFont','Arial');
            Screen(win,'TextSize',24);
            DrawFormattedText(win,instructions{1},'center','center',textColour);
            Screen('Flip',win);
            KbReleaseWait();
            KbPressWait();
        end
        
        % Trial variables
        thisTrialAccuracy = 0; % 1 = hit, 0 = no response, -1 = miss
        
        switch trialTypes(t)
            case 1
                side = 1;
                height = 1;
                distribution = 1;
                prepTime = 1;
            case 2
                side = 1;
                height = 1;
                distribution = 2;
                prepTime = 1;
            case 3
                side = 1;
                height = 1;
                distribution = 3;
                prepTime = 1;
            case 4
                side = 1;
                height = 1;
                distribution = 4;
                prepTime = 1;
            case 5
                side = 1;
                height = 2;
                distribution = 1;
                prepTime = 1;
            case 6
                side = 1;
                height = 2;
                distribution = 2;
                prepTime = 1;
            case 7
                side = 1;
                height = 2;
                distribution = 3;
                prepTime = 1;
           case 8
                side = 1;
                height = 2;
                distribution = 4;
                prepTime = 1;
            case 9
                side = 2;
                height = 1;
                distribution = 1;
                prepTime = 1;
            case 10
                side = 2;
                height = 1;
                distribution = 2;
                prepTime = 1;
            case 11
                side = 2;
                height = 1;
                distribution = 3;
                prepTime = 1;
            case 12
                side = 2;
                height = 1;
                distribution = 4;
                prepTime = 1;
            case 13
                side = 2;
                height = 2;
                distribution = 1;
                prepTime = 1;
            case 14
                side = 2;
                height = 2;
                distribution = 2;
                prepTime = 1;
            case 15
                side = 2;
                height = 2;
                distribution = 3;
                prepTime = 1;
            case 16
                side = 2;
                height = 2;
                distribution = 4;
                prepTime = 1;
            case 17
                side = 1;
                height = 1;
                distribution = 1;
                prepTime = 2;
            case 18
                side = 1;
                height = 1;
                distribution = 2;
                prepTime = 2;
            case 19
                side = 1;
                height = 1;
                distribution = 3;
                prepTime = 2;
            case 20
                side = 1;
                height = 1;
                distribution = 4;
                prepTime = 2;
            case 21
                side = 1;
                height = 2;
                distribution = 1;
                prepTime = 2;
            case 22
                side = 1;
                height = 2;
                distribution = 2;
                prepTime = 2;
            case 23
                side = 1;
                height = 2;
                distribution = 3;
                prepTime = 2;
           case 24
                side = 1;
                height = 2;
                distribution = 4;
                prepTime = 2;
            case 25
                side = 2;
                height = 1;
                distribution = 1;
                prepTime = 2;
            case 26
                side = 2;
                height = 1;
                distribution = 2;
                prepTime = 2;
            case 27
                side = 2;
                height = 1;
                distribution = 3;
                prepTime = 2;
            case 28
                side = 2;
                height = 1;
                distribution = 4;
                prepTime = 2;
            case 29
                side = 2;
                height = 2;
                distribution = 1;
                prepTime = 2;
            case 30
                side = 2;
                height = 2;
                distribution = 2;
                prepTime = 2;
            case 31
                side = 2;
                height = 2;
                distribution = 3;
                prepTime = 2;
            case 32
                side = 2;
                height = 2;
                distribution = 4;
                prepTime = 2;
        end
        
        % Set up dot parameters
        if side == 1
            %xs = lineLocs(1:numLines/2);
            dotColour = [0 0 255];
            xs = lineLocs;
            keysToCheck = keys(1:4);
        else
            %xs = lineLocs(numLines/2+1:end);
            dotColour = [0 255 0];
            xs = lineLocs;
            keysToCheck = keys(5:8);
        end
        
        if height == 1
            thisDotHeight = dotSizePx/2;
        else
            thisDotHeight = 10*dotSizePx/2;
        end
        
        % 1 = single (left side of display)
        % 2 = single (right side of display)
        % 3 = multiple same time
        % 4 = multiple different times
        thisLine = [];
        offsets = zeros(1,length(xs));
        switch distribution
            case 1
                thisLine = randi(length(xs)/2);
                thisOrder = [];
            case 2
                thisLine = length(xs)/2 + randi(length(xs)/2);
                thisOrder = [];
            case 4
                thisOrder = randperm(4);
                thisOrder = thisOrder-1;
                offsets = seqSpacingPx*thisOrder ;
        end
        
        markerSent = 0; % Flag to check if marker has been sent for this trial
        drawReward = zeros(1,length(xs));
        drawPunishment = zeros(1,length(xs));
        
        % Clear the MUSE OSC buffer by calling osc_recv
        if usingMuse
            osc_recv(osc_stream,osc_timeout);
        end
        preResponseI = 1;
        postResponseI = 1;
        responseMade = 0;
        
        % Random ITI
        wTime = 0.4 + 0.2*rand;
        wStart = GetSecs();
        wEnd = GetSecs();
        while wEnd - wStart < wTime
            
            if usingMuse
                muse_data = osc_recv(osc_stream,0.1);
                temp_samples = nan(4,1);
                if ~isempty(muse_data)
                    for d = 1:length(muse_data)
                        this_path = muse_data{d}.path; % find the bit we want
                        if strcmp(this_path,'/muse/eeg') % specifically find the eeg data
                            preResponse(:,preResponseI) = double(cell2mat(muse_data{d}.data))';
                            preResponseI = preResponseI + 1;
                            if preResponseI == num_pre_samples
                                preResponseI = 1;
                            end
                        end
                    end
                end
            end
            wEnd = GetSecs();
            
        end
        
        for p = 1:speedPx:verRes+max(offsets)
            
            xy = [lineLocs(1); p];
            xyRect = [];
            
            correctResponse = 1;
            % Single point, on either the left or right side of display
            if distribution == 1 || distribution == 2
                xyRect = [xs(thisLine)-dotSizePx/2; p-thisDotHeight; xs(thisLine)+dotSizePx/2;  p+thisDotHeight];
                % Determine correct response
                if xyRect(4) < gameHeight
                    correctResponse = 1;
                else
                    correctResponse = keysToCheck(thisLine);
                end
                %xyRect(2,:) < gameHeight & xyRect(4,:) > gameHeight
            else % Non-discrete (distribution == 3 or 4)
                
                if distribution == 3 % Multiple same time
                    for r = 1:length(xs)
                        xyRect = [xyRect  [xs(r)-dotSizePx/2; p-thisDotHeight; xs(r)+dotSizePx/2;  p+thisDotHeight]];
                    end
                    
                    % Determine correct response
                    if xyRect(4,1) < gameHeight
                        correctResponse = 1;
                    else
                        correctResponse = keysToCheck(1:4);
                    end
                    
                else % Distribution == 4 - multiple targets, different times
                    for r = 1:length(xs)
                        xyRect = [xyRect  [xs(r)-dotSizePx/2; p-offsets(r)-thisDotHeight; xs(r)+dotSizePx/2;  p-offsets(r)+thisDotHeight]];
                    end
                    
                    % Determine correct response
                    inTheZone = xyRect(2,:) < gameHeight & xyRect(4,:) > gameHeight;
                    thisTarget = find(inTheZone);
                    if any(inTheZone)
                        correctResponse = keysToCheck(thisTarget);
                    end
                    
                end
            end
            
            % Game lines
            Screen('DrawLine', win, lineColour, 0, gameHeight, horRes, gameHeight,lineWidth);
            for l = 1:length(lineLocs)
                Screen('DrawLine', win, lineColour, lineLocs(l), 0, lineLocs(l), verRes,lineWidth);
            end
            
            % Draw dots
            Screen('FillOval', win,dotColour, xyRect);
            
            [keyIsDown, ~, keyCode] = KbCheck();
            
            % Send response marker
            isCorrect = 0;
            thisTrialDistance = NaN;
            if keyIsDown
                % KbName(keyCode)
                
                % For marking EEG (not used)
%                 if ~markerSent
%                     trialTypes(t)
%                     % oscsend(u,'/muse/elements/marker','i',trialTypes(t));
%                     markerSent = 1;
%                     if justTesting
%                         DrawFormattedText(win,num2str(trialTypes(t)),'center','center',textColour); % Display marker as it is sent
%                     end
%                     responseMade = 1;
%                 end
                
                % Check accuracy
                % Compare vertical location of dots, p, to vertical
                % location of line (gameHeight)
                % drawReward = xyRect(2,:) < gameHeight & xyRect(4,:) > gameHeight;
                if all(keyCode(correctResponse))
                    isCorrect = 1;
                else
                    isCorrect = -1;
                end
                
                if ~responseMade
                    thisTrialDistance = p - gameHeight;
                    thisTrialAccuracy = isCorrect;
                    responseMade = 1;
                end
                
            elseif correctResponse == 0
                isCorrect = 0;
            end
            
            if keyCode(ExitKey)
                ME = MException('kh:escapekeypressed','Exiting script');
                throw(ME);
            end
            
            % Draw win colour over top
            if showFeedback
                % winRect = xyRect(:,drawReward);
                % Screen('FillOval',win,winColour,winRect);
                if isCorrect == 1
                    Screen('DrawLine', win, winColour, 0, gameHeight, horRes, gameHeight,lineWidth);
                elseif isCorrect == -1
                    Screen('DrawLine', win, loseColour, 0, gameHeight, horRes, gameHeight,lineWidth);
                end
            end
            
            % If prep time is reduced, occlude top part
            if prepTime == 2
                Screen('FillRect',win,occludeColour,[0,0,horRes,occludeHeight]);
                for l = 1:length(lineLocs)
                    Screen('DrawLine', win, lineColour, lineLocs(l), 0, lineLocs(l), occludeHeight,lineWidth);
                end
            end
            
            % Blank out bottom of screen
            Screen('FillRect',win,bgColour,[0,gameHeight,horRes,verRes]);
            
            % Fixation cross
            Screen(win,'TextFont','Arial');
            Screen(win,'TextSize',64);
            DrawFormattedText(win,'+','center',fixationHeight,textColour);
            
            Screen('Flip',win);
            
            % Get EEG since last flip
            % Read in available MUSE data
            if usingMuse
                muse_data = osc_recv(osc_stream,0.1);
                temp_samples = nan(4,1);
                if ~isempty(muse_data)
                    for d = 1:length(muse_data)
                        this_path = muse_data{d}.path; % find the bit we want
                        if strcmp(this_path,'/muse/eeg') % specifically find the eeg data
                            
                            if ~responseMade
                                % Pre-response
                                preResponse(:,preResponseI) = double(cell2mat(muse_data{d}.data))';
                                preResponseI = preResponseI + 1;
                                if preResponseI > num_pre_samples
                                    preResponseI = 1;
                                end
                            elseif postResponseI <= num_post_samples
                                % Post-response
                                postResponse(:,postResponseI) = double(cell2mat(muse_data{d}.data))';
                                postResponseI = postResponseI + 1;
                            end
                            
                        end
                    end
                end
            end
            
        end
        
        eeg(:,:,t) = [preResponse(:,[preResponseI:end 1:preResponseI-1]) postResponse];
        p_data = [p_data; t trialTypes(t) side height distribution prepTime thisTrialDistance thisTrialDistance/verticalPixelsPerMM thisTrialAccuracy];
        save(filename,'eeg','p_data','sex','age','handedness');
        
        [keyIsDown, ~, keyCode] = KbCheck();
        if keyCode(ExitKey)
            ME = MException('kh:escapekeypressed','Exiting script');
            throw(ME);
        end
    end
    
    % End of Experiment
    Screen(win,'TextFont','Arial');
    Screen(win,'TextSize',24);
    DrawFormattedText(win,['end of experiment - thank you\nplease email ' filename ' to your lab instructor'],'center','center',textColour);
    Screen('Flip',win);
    WaitSecs(10);
    
    %%% CLOSE THE CONNECTION
    if usingMuse
        osc_free_server(osc_stream); % releases the connection with MUSE
    end    
    % Close the Psychtoolbox window and bring back the cursor and keyboard
    Screen('CloseAll');
    ListenChar(1);
catch e
    
    %%% CLOSE THE CONNECTION
    if usingMuse
        osc_free_server(osc_stream); % releases the connection with MUSE
    end
    
    Screen('CloseAll');
    ListenChar(1);
    rethrow(e);
end
toc
disp(['end of experiment - thank you... please email ' filename ' to your lab instructor']);