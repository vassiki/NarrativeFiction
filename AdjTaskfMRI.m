function AdjTaskfMRI(Subject,Run,DEBUG)
% AdjTaskfMRI(SubNum,RunNum,DEBUG)
ViewDist = 30;

if DEBUG
    listenScan = 0;
    listenInput = 0;
else
    listenScan = 1;
    listenInput = 1;
end

outdir = pwd;
subdir = fullfile(outdir,['Sub' num2str(Subject)]);

if ~exist(subdir,'dir')
    mkdir(subdir);
end

addpath(fullfile(outdir,'ExpUtils'));

PsychDefaultSetup(2);
% XXX: REMOVE ME XXXX
Screen('Preference', 'SkipSyncTests', 1);
% XXXXXXX
screens = Screen('Screens');
screenNumber = max(screens);
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);

% opening a PTB window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
HideCursor;
ifi = Screen('GetFlipInterval', window);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
[xCenter, yCenter] = RectCenter(windowRect);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[mmx, ~] = Screen('DisplaySize', screenNumber);
cmx = mmx/10;
CmToPix = (screenXpixels/cmx);
D2P = ceil(tan(2*pi/360)*(ViewDist*CmToPix));

%correctButtons = [1 2 3 4];

% timing

instrSecs = 4;
fixSecs = 16;
if DEBUG
    nameSecs = 4;
    wordsSecs = 4;
else
    nameSecs = 4;
    wordsSecs = 4;
end
respSecs = 2;

instrFrames = round(instrSecs / ifi);
fixFrames = round(fixSecs / ifi);
nameFrames = round(nameSecs / ifi);
wordsFrames = round(wordsSecs / ifi);
respFrames = round(respSecs / ifi);

waitFrames = 1;

% stimuli

file = fullfile(subdir,['Run' num2str(Run) '.csv']);
stimFile = fopen(file,'r');
stim = textscan(stimFile, '%s%s%s%s%s', 'delimiter', ',');
fclose(stimFile);

for i = 1:length(stim)
    for j=1:length(stim{1,1})
        words{j,i} = stim{1,i}{j,1};
    end
end

for i = 1:length(words)
    jitter{i} = str2num(words{i,5});
    jittFrame{i,1} = round(jitter{i} / ifi);
    lORr{i,1} = str2num(words{i,4});
end


% fixation
fixCrossDimPix = 30;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

lineWidthPix = 4;

VisAn = 3;
leftBound = xCenter-(VisAn*D2P); rightBound = xCenter+(VisAn*D2P);
topBound = yCenter-(VisAn*D2P); bottomBound = yCenter+(VisAn*D2P);

% waiting for scanner trigger
if listenScan
    hLum = lumOpen();
end

vbl = Screen('Flip',window);
% instruction screen
for frame=1:instrFrames
    blocktext='Please indicate with left or \n right arrow which adjective applies \n more to each character. \n';
    Screen(window,'TextSize', 30);
    DrawFormattedText(window, blocktext, 'center', 'center', white);
    vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
end

TrialInfo = struct('onset',[],'dur',[],'char',[],'top',[],...
    'bottom',[],'nameorth',[],'toporth',[],'botorth',[],'wordsw',[],...
    'RT',[],'pressedButtons',[],'leftorth',[],'rightorth',[],'ISI',[]);

% muting for debugging
waitT = 0;
if 0%listenScan
    %waitT = waitForTrigger(hLum);
    while waitT == 0
        DisplayText = 'Waiting for trigger...';
        Screen(window,'TextSize', 50);
        DrawFormattedText(window,DisplayText,'center','center', white);
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
        waitT = waitForTrigger(hLum);
    end
else
    WaitSecs(1);
    vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
end

% presentation
TrialLoopStart = GetSecs;
tic
for trial = 1:length(words)
    
    %vbl = Screen('Flip', window);
    TrialInfo(trial).onset = TrialLoopStart - GetSecs;
    
    character = words{trial,1};
    word_top = words{trial,2};
    word_bottom = words{trial,3};
    
    TrialInfo(trial).char = character;
    TrialInfo(trial).top = word_top;
    TrialInfo(trial).bottom = word_bottom;
    
    if trial == 1
        fixation_start = GetSecs;
        %for frame = 1:fixFrames
            Screen('DrawLines', window, allCoords,...
                lineWidthPix, white, [xCenter yCenter], 2);
        
            vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
            WaitSecs(fixSecs);
        %end
        fprintf('Initial fixation took %.2f s\n', GetSecs - fixation_start);
    end
    
    Screen('TextSize', window, 80);
    Screen('TextFont', window, 'Sans Serif');
    nameTextRect = Screen('TextBounds',window,character);
    name_presentation_start = GetSecs;
    %for frame = 1:nameFrames
        DrawFormattedText(window, character, 'center', 'center', white);
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
        WaitSecs(nameSecs);
    %end
    fprintf('Name presentation took %.2f s\n', GetSecs - name_presentation_start);
    TrialInfo(trial).nameorth = nameTextRect;
    
    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Sans Serif');
    topTextRect = Screen('TextBounds',window,word_top);
    top = topBound-topTextRect(4);
    botTextRect = Screen('TextBounds',window,word_bottom);
    bot = bottomBound;
    topdown_start = GetSecs;
    %for frame = 1:wordsFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);      
        DrawFormattedText(window, word_top, 'center', top, white);        
        DrawFormattedText(window, word_bottom, 'center', bot, white);        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
        WaitSecs(wordsSecs);
    %end
    fprintf('TopDown phase took %.2f s\n', GetSecs - topdown_start);
    
    TrialInfo(trial).toporth = topTextRect;
    TrialInfo(trial).botorth = botTextRect;
    
    
    numPresses = []; 
    RT = 0; 

    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Sans Serif');
    
    if lORr{trial} == 1
        TrialInfo(trial).wordsw = 'top2left';
        leftTextRect = Screen('TextBounds',window,word_top);
        xaxis_left = leftBound-leftTextRect(3);
        rightTextRect = Screen('TextBounds',window,word_bottom);
        xaxis_right = rightBound;
    else
        TrialInfo(trial).wordsw = 'top2right';
        leftTextRect = Screen('TextBounds',window,word_bottom);
        xaxis_left = leftBound-leftTextRect(3);
        rightTextRect = Screen('TextBounds',window,word_top);
        xaxis_right = rightBound;        
    end
    
    resp_start = GetSecs;
    responded = 0;
    AllowedResponse = 2;
    %for frame = 1:respFrames
    Screen('DrawLines', window, allCoords,...
        lineWidthPix, white, [xCenter yCenter], 2);
    if lORr{trial} == 1
        word_xaxis_left = word_top;
        word_xaxis_right = word_bottom;
    else
        word_xaxis_left = word_bottom;
        word_xaxis_right = word_top;
    end
    DrawFormattedText(window, word_xaxis_left, xaxis_left, 'center', white);
    DrawFormattedText(window, word_xaxis_right, xaxis_right, 'center', white);
    Screen('DrawingFinished', window);
    %Flip
    [vbl, stimOnset] = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    while GetSecs - stimOnset < AllowedResponse
        if listenScan && listenInput
            [portData, ~] = getAnyButtonPress_simple(hLum);
            if ~responded && ~isempty(portData)
                numPresses = portData;
                fprintf('Pressed button ASCII %s char %d\n', numPresses);
                RT = GetSecs - resp_start;
                responded = 1;
            end
        else
            [~, rt, keyCode] = KbCheck;
            if ~responded && any(keyCode)
                RT = rt-resp_start;
                numPresses = KbName(find(keyCode));
                responded = 1;
            end
            if keyCode(KbName('ESCAPE')) == 1
                sca;
                disp('*** Experiment terminated ***');
                return
            end
        end
    end  % for frames
    fprintf('Response period lasted %.2f\n', GetSecs - resp_start);
    TrialInfo(trial).dur = GetSecs - TrialInfo(trial).onset; 
    TrialInfo(trial).ISI = GetSecs; 
    jittFrames = jittFrame{trial};
    %jittFrames = nameFrames;
    
    jitter_start = GetSecs;
    %for frame = 1:jittFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
        WaitSecs(jitter{trial});
    %end
    fprintf('Jitter took %.2f s, supposed to be %.2f s\n', GetSecs - jitter_start, jitter{trial});
    
    TrialInfo(trial).RT = RT;
    TrialInfo(trial).pressedButtons = numPresses;
    TrialInfo(trial).leftorth = leftTextRect;
    TrialInfo(trial).rightorth = rightTextRect;
    
    
end

for frame = 1:fixFrames
    Screen('DrawLines', window, allCoords,...
        lineWidthPix, white, [xCenter yCenter], 2);
    
    vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
end
total_time = toc;
fprintf('*** TOTAL RUN TIME %.3f\n', total_time);

if listenScan
    IOPort('Flush',hLum);
    IOPort('Close',hLum);
end


ShowCursor;
Screen('CloseAll');
sca

out_file=['Sub' num2str(Subject) 'Run' num2str(Run) '_Adj.mat'];
save (fullfile(subdir,out_file), 'TrialInfo');
end




