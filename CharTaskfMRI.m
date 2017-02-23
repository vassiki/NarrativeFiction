function CharTaskfMRI(Subject,Character)

ViewDist = 30;

listenScan = 0;
listenInput = 0;

outdir = pwd;
addpath(fullfile(outdir,'ExpUtils'));


Screen('Preference', 'SkipSyncTests', 0);

PsychDefaultSetup(2);

screens = Screen('Screens');

screenNumber = max(screens);

black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);

% opening a PTB window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
HideCursor

ifi = Screen('GetFlipInterval', window);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

[xCenter, yCenter] = RectCenter(windowRect);
[screenXpixels, ~] = Screen('WindowSize', window);
[mmx, ~] = Screen('DisplaySize', screenNumber);
cmx = mmx/10;

CmToPix = (screenXpixels/cmx);
D2P = ceil(tan(2*pi/360)*(ViewDist*CmToPix));

%% correct buttons
%correctButtons = [1 2 3 4];
correctButtons = [1 2 3];
%% timing

fixSecs = 0.5;
nameSecs = 1;
instrSecs = 4;
fixFrames = round(fixSecs / ifi);
nameFrames = round(nameSecs / ifi);
instrFrames = round(instrSecs / ifi);
waitFrames = 1;

%% stimuli
chars = {'Mr Darcy','Lizzy Bennet','Lydia Bennet',...
    'Mrs Bennet','Mr Bennet','Jane Bennet','Mr Collins',...
    'Mr Wickham','Lady Catherine','Charlotte Lucas'};

runchars = chars(cellfun('isempty',strfind(chars,Character)));
runchars = Shuffle(runchars);
all_pairs = combnk(runchars,2);
words = Shuffle(all_pairs,2);

%% fixation
fixCrossDimPix = 30;

xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

lineWidthPix = 4;

%%
% Deg2Pix is approz 45 for viewing distance of 60 cm
VisAn = 3;
leftBound = xCenter-(VisAn*D2P); rightBound = xCenter+(VisAn*D2P);
%topBound = yCenter-(VisAn*D2P); bottomBound = yCenter+(VisAn*D2P);

%% Waiting for scanner trigger
if listenScan
    hLum = lumOpen();
end

% DisplayText = 'Waiting for trigger...';
% DrawFormattedText(window,DisplayText,'center','center');
% vbl = Screen('Flip',window);

if listenScan
    waitForTrigger(hLum);
    DisplayText = 'Waiting for trigger...';
    DrawFormattedText(window,DisplayText,'center','center');
    vbl = Screen('Flip',window);
else
    WaitSecs(1);
    vbl = Screen('Flip',window);
end


%% presentation
for frame=1:instrFrames
    blocktext=['Please indicate with left or \n right arrow which character is closer to \n', Character];
    Screen(window,'TextSize', 30);
    DrawFormattedText(window, blocktext, 'center', 'center', white);
    %[VBL, ~, FlipTime, Missed] = Screen('Flip',window,NextTime);
    vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    %NextTime = NextTime  + ExpStartTime;
end
%%
for trial = 1:length(words)
    
    character = Character;
    word_left = words{trial,1};
    word_right = words{trial,2};
    
    TrialInfo(trial).char_prompt = character;
    TrialInfo(trial).char_left = word_left;
    TrialInfo(trial).char_right = word_right;
    
    
    for frame = 1:fixFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
        Screen('DrawingFinished', window);
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    nameText = [character,'?'];
    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Courier');
    
    for frame = 1:nameFrames
        DrawFormattedText(window, nameText, 'center', 'center', white);
        Screen('DrawingFinished', window);
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Courier');
    leftTextRect = Screen('TextBounds',window,word_left);
    xaxis_left = leftBound-leftTextRect(3);
    
    numPresses = []; rt = 0; isCorrect = [];
    while isempty(numPresses)
        DrawFormattedText(window, word_left, xaxis_left, 'center', white);
        DrawFormattedText(window, word_right, rightBound, 'center', white);
        Screen('DrawingFinished', window);

        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
        
        if listenScan && listenInput
            [isCorrect, numPresses, rt, ~] = getAnyButtonPress(hLum,correctButtons);
            
        else
            [isCorrect, rt, keyCode] = KbCheck;
            numPresses = KbName(find(keyCode));
            if keyCode(KbName('ESCAPE')) == 1
                sca;
                disp('*** Experiment terminated ***');
                return
            end
        end
    end
    
    TrialInfo(trial).RT = rt;
    TrialInfo(trial).Correct = isCorrect;
    TrialInfo(trial).pressedButtons = numPresses;
    
end

CharFile=regexprep(Character,'[^\w'']','');
out_file=[Subject '_' CharFile(1:5) '.mat'];
save(fullfile(outdir,out_file), 'TrialInfo');

if listenScan
    IOPort('Flush',hLum);
    IOPort('Close',hLum);
end


ShowCursor;
Screen('Close All');


end
