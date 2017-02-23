function CharTask(Subject,Character)

ViewDist = 60;

outdir = pwd;
close all;

PsychDefaultSetup(2);

screens = Screen('Screens');

screenNumber = max(screens);

black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
gray = white/2;

% opening a PTB window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
HideCursor
ifi = Screen('GetFlipInterval', window);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

[xCenter, yCenter] = RectCenter(windowRect);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[mmx, mmy] = Screen('DisplaySize', screenNumber);
cmx = mmx/10;

CmToPix = (screenXpixels/cmx);
D2P = ceil(tan(2*pi/360)*(ViewDist*CmToPix));

topPriorityLevel = MaxPriority(window);

spaceKey = KbName('space');
escapeKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
RestrictKeysForKbCheck([spaceKey escapeKey leftKey rightKey]);

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
topBound = yCenter-(VisAn*D2P); bottomBound = yCenter+(VisAn*D2P);

%% presentation
vbl = Screen('Flip',window);
for frame=1:instrFrames
    blocktext=['Please indicate with left or \n right arrow which character is closer to \n', Character];
    Screen(window,'TextSize', 30);
    DrawFormattedText(window, blocktext, 'center', 'center', white);
    vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
end
%%
for trial = 1:length(words)
    
    character = Character;
    word_left = words{trial,1};
    word_right = words{trial,2};
    
    TrialInfo(trial).char_prompt = character;
    TrialInfo(trial).char_left = word_left;
    TrialInfo(trial).char_right = word_right;
    
    Priority(topPriorityLevel);
    for frame = 1:fixFrames
        Screen('DrawLines', window, allCoords,...
            lineWidthPix, white, [xCenter yCenter], 2);
        Screen('DrawingFinished', window);
        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    Priority(0);
    
    
    nameText = [character,'?'];
    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Courier');
    Priority(topPriorityLevel);
    for frame = 1:nameFrames
        DrawFormattedText(window, nameText, 'center', 'center', white);
        Screen('DrawingFinished', window);
        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    end
    Priority(0);
    
    Screen('TextSize', window, 50);
    Screen('TextFont', window, 'Courier');
    leftTextRect = Screen('TextBounds',window,word_left);
    xaxis_left = leftBound-leftTextRect(3);
    PromptStart = GetSecs();
    respMade = 0;
    Priority(topPriorityLevel);
    while respMade == 0
        DrawFormattedText(window, word_left, xaxis_left, 'center', white);
        DrawFormattedText(window, word_right, rightBound, 'center', white);
        Screen('DrawingFinished', window);
        
        vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
        
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyCode(leftKey) == 1
            TrialInfo(trial).resp = word_left;
            TrialInfo(trial).rt = secs-PromptStart;
            respMade = 1;
        elseif keyCode(rightKey) == 1
            TrialInfo(trial).resp = word_right;
            TrialInfo(trial).rt = secs-PromptStart;
            respMade = 1;
        elseif keyCode(KbName('ESCAPE')) == 1
            sca;
            disp('*** Experiment terminated ***');
            return
        end
    end
    Priority(0);
    
    
    
end
CharFile=regexprep(Character,'[^\w'']','');
out_file=[Subject '_' CharFile(1:5) '.mat'];
save (fullfile(outdir,out_file), 'TrialInfo');

%%
sca;




