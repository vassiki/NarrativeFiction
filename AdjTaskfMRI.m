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
addpath(fullfile(outdir,'ExpUtils'));

PsychDefaultSetup(2);

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

correctButtons = [1 2 3 4];

% timing

instrSecs = 4;
fixSecs = 0.5;
if DEBUG
    nameSecs = 4;
    wordsSecs = 4;
else
    nameSecs = 4;
    wordsSecs = 4;
end
readySecs = 0.5;
respSecs = 2;

instrFrames = round(instrSecs / ifi);
fixFrames = round(fixSecs / ifi);
nameFrames = round(nameSecs / ifi);
wordsFrames = round(wordsSecs / ifi);
readyFrames = round(readySecs / ifi);
respFrames = round(respSecs / ifi);

waitFrames = 1;

% stimuli

%stimFile = fopen('Words.csv','r');
stimFile = fopen(['Run' num2str(Run) '.csv'],'r');
%stim = textscan(stimFile, '%s%s%s', 'delimiter', ',');
stim = textscan(stimFile, '%s%s%s%s', 'delimiter', ',');
fclose(stimFile);

for i = 1:length(stim)
    for j=2:length(stim{1,1})
        words{j-1,i} = stim{1,i}{j,1};
    end
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

TrialInfo = struct('char',[],'top',[],'bottom',[], ...
    'nameorth',[],'toporth',[],'botorth',[],'wordsw',[],...
    'RT',[],'pressedButtons',[],...
    'leftorth',[],'rightorth',[]);

waitT = 0;
if listenScan
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

tic
% presentation

for trial = 1:length(words)
    
    %vbl = Screen('Flip', window);
    
    character = words{trial,1};
    word_top = words{trial,2};
    word_bottom = words{trial,3};
    
    TrialInfo(trial).char = character;
    TrialInfo(trial).top = word_top;
    TrialInfo(trial).bottom = word_bottom;
    
    for frame = 1:fixFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    Screen('TextSize', window, 80);
    Screen('TextFont', window, 'Sans Serif');
    nameTextRect = Screen('TextBounds',window,character);
    for frame = 1:nameFrames
        DrawFormattedText(window, character, 'center', 'center', white);
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    TrialInfo(trial).nameorth = nameTextRect;
    
    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Sans Serif');
    topTextRect = Screen('TextBounds',window,word_top);
    top = topBound-topTextRect(4);
    botTextRect = Screen('TextBounds',window,word_bottom);
    bot = bottomBound;
    for frame = 1:wordsFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);      
        DrawFormattedText(window, word_top, 'center', top, white);        
        DrawFormattedText(window, word_bottom, 'center', bot, white);        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    TrialInfo(trial).toporth = topTextRect;
    TrialInfo(trial).botorth = botTextRect;
    
    for frame = 1:readyFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, [1 0 0], [xCenter yCenter], 2);
        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    % this information should come from an excel file so it is the same
    % across subjects
    
    %lORr = randi([1,2],1);
    lORr = words{trial,4};
    if lORr == 1
        TrialInfo(trial).wordsw = 'top2left';
    else
        TrialInfo(trial).wordsw = 'top2right';
    end
    
    numPresses = []; RT = 0; isCorrect = [];

    %while isempty(numPresses)
    %while sum(numPresses) == 0
    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Sans Serif');
    
    if lORr == 1
        leftTextRect = Screen('TextBounds',window,word_top);
        xaxis_left = leftBound-leftTextRect(3);
        rightTextRect = Screen('TextBounds',window,word_bottom);
        xaxis_right = rightBound;
    else
        leftTextRect = Screen('TextBounds',window,word_bottom);
        xaxis_left = leftBound-leftTextRect(3);
        rightTextRect = Screen('TextBounds',window,word_top);
        xaxis_right = rightBound;        
    end
    
    resp_start = GetSecs();
    for frame = 1:respFrames

        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
        if lORr == 1
            DrawFormattedText(window, word_top, xaxis_left, 'center', white);
            DrawFormattedText(window, word_bottom, xaxis_right, 'center', white);
            Screen('DrawingFinished', window);
            %Flip
            vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);         
            if listenScan && listenInput
                [isCorrect, numPresses, RT, ~] = getAnyButtonPress(hLum,correctButtons);
                if isCorrect
                    RT = RT-resp_start;
                end
            else
                [isCorrect, rt, keyCode] = KbCheck;
                if isCorrect
                    RT = rt-resp_start;
                    numPresses = KbName(find(keyCode));  
                end
                if keyCode(KbName('ESCAPE')) == 1
                    sca;
                    disp('*** Experiment terminated ***');
                    return
                end
            end            

        else
            DrawFormattedText(window, word_bottom, xaxis_left, 'center', white);
            DrawFormattedText(window, word_top, xaxis_right, 'center', white);
            Screen('DrawingFinished', window);
            %Flip
            vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
            if listenScan && listenInput
                [isCorrect, numPresses, RT, ~] = getAnyButtonPress(hLum,correctButtons);
                if isCorrect
                    RT = RT-resp_start;
                end
            else
                [isCorrect, rt, keyCode] = KbCheck;
                if isCorrect
                    RT = rt-resp_start;
                    numPresses = KbName(find(keyCode));
                end
                if keyCode(KbName('ESCAPE')) == 1
                    sca;
                    disp('*** Experiment terminated ***');
                    return
                end
            end            

        end
    end
    TrialInfo(trial).RT = RT;
    TrialInfo(trial).pressedButtons = numPresses;
    TrialInfo(trial).leftorth = leftTextRect;
    TrialInfo(trial).rightorth = rightTextRect;
        
end

if listenScan
    IOPort('Flush',hLum);
    IOPort('Close',hLum);
end


ShowCursor;
Screen('CloseAll');
sca
toc

out_file=['Sub' num2str(Subject) 'Run' num2str(Run) '_Adj.mat'];
save (fullfile(outdir,out_file), 'TrialInfo');
end




