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

%% timing

fixSecs = 0.5;
nameSecs = 1;
blankSecs = 3;
wordsSecs = 4;
recallSecs = 3;
responseSecs = 1;

fixFrames = round(fixSecs / ifi);
nameFrames = round(nameSecs / ifi);
blankFrames = round(blankSecs / ifi);
wordsFrames = round(wordsSecs / ifi);
%recallFrames = round(recallSecs / ifi);
%responseFrames = round(responseSecs / ifi);

waitFrames = 1;

%% stimuli
chars = {'Mr Darcy','Lizzie Bennet','Jane Bennet','Lydia Bennet'...
    'Mr Wickham','Mr Collins','Lady Catherine','Charlotte Lucas'...
    'Mr Bennet','Mrs Bennet','Mr Bingley','Caroline Bingley'};

all_pairs = combnk(chars,3);
words = Shuffle(all_pairs,2);
clear all_pairs;

flag_idx = 1;
while ~isempty(flag_idx)
    for x=2:length(words)
        if strcmp(words{x,1},words{x-1,1})
            flag(x,1) = 1;
        else
            flag(x,1) = 0;
        end
    end
    flag_idx = find(flag==1);
    
    for idx = 1:length(flag_idx)
        if flag_idx(idx) ~= 220
            tmp = words(flag_idx(idx),:);
            words(flag_idx(idx),:) = words(flag_idx(idx)+1,:);
            words(flag_idx(idx)+1,:) = tmp;
        else
            idx_shift = randi([1,10],1);
            tmp = words(flag_idx(idx),:);
            words(flag_idx(idx),:) = words(flag_idx(idx_shift),:);
            words(flag_idx(idx_shift),:) = tmp;
        end
    end
end

%% fixation
fixCrossDimPix = 40;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

lineWidthPix = 4;


%% presentation

for trial = 1:10%length(words)
    
    vbl = Screen('Flip', window);
    
    character = words{trial,1};
    word_left = words{trial,2};
    word_right = words{trial,3};
    
    TrialInfo(trial).char_prompt = character;
    TrialInfo(trial).char_left = word_left;
    TrialInfo(trial).char_right = word_right;
    
    for frame = 1:fixFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    for frame = 1:nameFrames
        Screen('TextSize', window, 80);
        Screen('TextFont', window, 'Courier');
        DrawFormattedText(window, character, 'center', 'center', white);
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    for frame = 1:blankFrames
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    
    PromptStart = GetSecs();
    respMade = 0;
    frame = 1;
    while respMade == 0 && frame < wordsFrames
    %for frame = 1:wordsFrames
        frame = frame + 1;
        Screen('TextSize', window, 50);
        Screen('TextFont', window, 'Courier');
        DrawFormattedText(window, word_left, screenXpixels * 0.20, 'center', white);
        DrawFormattedText(window, word_right, screenXpixels * 0.70, 'center', white);
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
    
    %     for frame = 1:recallFrames
    %         vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    %     end
    %
% 
%     for frame = 1:responseFrames
%         Screen('TextSize', window, 80);
%         Screen('TextFont', window, 'Courier');
%         DrawFormattedText(window, '?', 'center', 'center', white);
%         vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);       
%     end
%     
    
end

out_file=['Sub' num2str(Subject) '_Adj.mat'];
save (fullfile(outdir,out_file), 'TrialInfo');

%%
sca;




