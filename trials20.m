%% defaults
Subject = 101;
outdir = pwd;
close all;
sca;

PsychDefaultSetup(2);


screens = Screen('Screens');

screenNumber = max(screens);

black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
gray = white/2;

% opening a PTB window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

ifi = Screen('GetFlipInterval', window);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

[xCenter, yCenter] = RectCenter(windowRect);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

topPriorityLevel = MaxPriority(window);

spaceKey = KbName('space');
escapeKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
RestrictKeysForKbCheck([spaceKey escapeKey leftKey rightKey]);
HideCursor;

%% timing

fixSecs = 0.5;
nameSecs = 4;
%fix2Secs = 3;
wordsSecs = 4;
readySecs = 0.5;
responseSecs = 1;

fixFrames = round(fixSecs / ifi);
nameFrames = round(nameSecs / ifi);
%fix2Frames = round(fix2Secs / ifi);
wordsFrames = round(wordsSecs / ifi);
readyFrames = round(readySecs / ifi);
responseFrames = round(responseSecs / ifi);

waitFrames = 1;

%% stimuli

stimFile = fopen('Words.csv','r');
stim = textscan(stimFile, '%s%s%s', 'delimiter', ',');
fclose(stimFile);

for i = 1:length(stim)
    for j=2:length(stim{1,1})
        words{j-1,i} = stim{1,i}{j,1};
    end
end

%% fixation
fixCrossDimPix = 30;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

lineWidthPix = 4;

% Deg2Pix is approz 45 for viewing distance of 60 cm
D2P = 45; VisAn = 3;
leftBound = xCenter-(VisAn*D2P); rightBound = xCenter+(VisAn*D2P);
topBound = yCenter-(VisAn*D2P); bottomBound = yCenter+(VisAn*D2P);
%% presentation

for trial = 1:length(words)
    
    vbl = Screen('Flip', window);
    
    character = words{trial,1};
    word_top = words{trial,2};
    word_bottom = words{trial,3};
    
    TrialInfo(trial).char = character;
    TrialInfo(trial).left = word_top;
    TrialInfo(trial).right = word_bottom;
    
    for frame = 1:fixFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    for frame = 1:nameFrames
        Screen('TextSize', window, 80);
        Screen('TextFont', window, 'Courier');
        nameTextRect = Screen('TextBounds',window,character);
        DrawFormattedText(window, character, 'center', 'center', white);
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
%     for frame = 1:fix2Frames
%         Screen('DrawLines', window, allCoords,...
%             lineWidthPix, white, [xCenter yCenter], 2);
%         
%         vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
%     end
    
    for frame = 1:wordsFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
        
        Screen('TextSize', window, 50);
        Screen('TextFont', window, 'Courier');
        %DrawFormattedText(window, word_top, 'center', screenYpixels * 0.35, white);
        topTextRect = Screen('TextBounds',window,word_top);
        DrawFormattedText(window, word_top, 'center', topBound-topTextRect(4), white);
        
        botTextRect = Screen('TextBounds',window,word_bottom);
        DrawFormattedText(window, word_bottom, 'center', bottomBound, white);
        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    for frame = 1:readyFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, [0 1 0], [xCenter yCenter], 2);
        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    lORr = randi([1,2],1);
    if lORr == 1
        TrialInfo(trial).wordsw = 'top2left';
    else
        TrialInfo(trial).wordsw = 'top2right';
    end
    
    PromptStart = GetSecs();
    respMade = 0;
    frame = 1;
    while respMade == 0 && frame < wordsFrames
        %for frame = 1:responseFrames
        frame = frame + 1;
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
        
        if lORr == 1
            Screen('TextSize', window, 50);
            Screen('TextFont', window, 'Courier');
            %DrawFormattedText(window, word_top, screenXpixels * 0.30, 'center', white);
            leftTextRect = Screen('TextBounds',window,word_top);
            DrawFormattedText(window, word_top, leftBound-leftTextRect(3), 'center', white);
            %DrawFormattedText(window, word_bottom, screenXpixels * 0.60, 'center', white);
            rightTextRect = Screen('TextBounds',window,word_bottom);
            DrawFormattedText(window, word_bottom, rightBound, 'center', white);
            
            vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
            
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyCode(leftKey) == 1
                TrialInfo(trial).resp = 'left';
                TrialInfo(trial).rt = secs-PromptStart;
                respMade = 1;
            elseif keyCode(rightKey) == 1
                TrialInfo(trial).resp = 'right';
                TrialInfo(trial).rt = secs-PromptStart;
                respMade = 1;
            elseif keyCode(KbName('ESCAPE')) == 1
                sca;
                disp('*** Experiment terminated ***');
                return
            end
        else
            Screen('TextSize', window, 50);
            Screen('TextFont', window, 'Courier');
            %DrawFormattedText(window, word_bottom, screenXpixels * 0.20, 'center', white);
            leftTextRect = Screen('TextBounds',window,word_bottom);
            DrawFormattedText(window, word_bottom, leftBound-leftTextRect(3), 'center', white);
            %DrawFormattedText(window, word_top, screenXpixels * 0.70, 'center', white);
            rightTextRect = Screen('TextBounds',window,word_top);
            DrawFormattedText(window, word_top, rightBound, 'center', white);
            vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
            
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyCode(leftKey) == 1
                TrialInfo(trial).resp = 'left';
                TrialInfo(trial).rt = secs-PromptStart;
                respMade = 1;
            elseif keyCode(rightKey) == 1
                TrialInfo(trial).resp = 'right';
                TrialInfo(trial).rt = secs-PromptStart;
                respMade = 1;
            elseif keyCode(KbName('ESCAPE')) == 1
                sca;
                disp('*** Experiment terminated ***');
                return
            end
            
        end
    end
    
    
end

out_file=['Sub' num2str(Subject) '_Adj.mat'];
save (fullfile(outdir,out_file), 'TrialInfo');

%%
sca;




