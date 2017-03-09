function [startTime] = PlayChapterfMRI(Sub,ChapNum, DEBUG)
% PlayChapterfMRI(Subject,Chapter,DEBUG)
AssertOpenGL;

if DEBUG
    listenScan = 0;
else
    listenScan = 1;
end
repetitions = 1;

outdir = pwd;
subdir = fullfile(outdir,['Sub' num2str(Sub)]);

if ~exist(subdir,'dir')
    mkdir(subdir);
end

UtilDir = fullfile(outdir,'ExpUtils');
ChapDir = fullfile(outdir,'Chapters');

addpath(UtilDir);
addpath(ChapDir);
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

% USE audiodevinfo IF RUNNING INTO TROUBLE WITH PLAYING AUDIO
instrSecs = 2;
instrFrames = round(instrSecs / ifi);
waitFrames = 1;

vbl = Screen('Flip',window);
% instruction screen
for frame=1:instrFrames
    blocktext='Please maintain fixation and \n listen to the following chapter from \n Pride and Prejudice. Enjoy! \n';
    Screen(window,'TextSize', 30);
    DrawFormattedText(window, blocktext, 'center', 'center', white);
    vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
end
fixCrossDimPix = 30;

% Fixation
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

lineWidthPix = 4;

% waiting for scanner trigger
if listenScan
    hLum = lumOpen();
end


% get chapter
%wavfilename = ['prideandprejudice_' num2str(ChapNum) '_austen_64kb.mp3'];
wavfilename = ['Chapter' num2str(ChapNum),'.m4a'];
[y, freq] = audioread(wavfilename);
ChapLength = size(y,1)/freq;
wavedata = y';
nrchannels = size(wavedata,1);

if nrchannels < 2
    wavedata = [wavedata ; wavedata];
    nrchannels = 2;
end

InitializePsychSound;

try
    % Try with the 'freq'uency we wanted:
    pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
catch
    % Failed. Retry with default frequency as suggested by device:
    fprintf('\nCould not open device at wanted playback frequency of %i Hz. Will retry with device default frequency.\n', freq);
    fprintf('Sound may sound a bit out of tune, ...\n\n');
    
    psychlasterror('reset');
    pahandle = PsychPortAudio('Open', [], [], 0, [], nrchannels);
end

PsychPortAudio('FillBuffer', pahandle, wavedata);

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

padding = 18; % for HRF to subside
TotalLength = GetSecs() + ChapLength + padding;
startTime = PsychPortAudio('Start', pahandle, repetitions, 0, 1);
ChapInfo.onset = GetSecs();
%t = datetime(now);
while GetSecs < TotalLength
    Screen('DrawLines', window, allCoords,...
        lineWidthPix, white, [xCenter yCenter], 2);
    vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
    [~, ~, keyCode] = KbCheck;
    
    if keyCode(KbName('ESCAPE')) == 1
        sca;
        disp('*** Experiment terminated ***');
        PsychPortAudio('Stop', pahandle);
        PsychPortAudio('Close', pahandle);
        return
    end
    PsychPortAudio('GetStatus', pahandle);
    
    
end
%
PsychPortAudio('Stop', pahandle);

% Close the audio device:
PsychPortAudio('Close', pahandle);

if listenScan
    IOPort('Flush',hLum);
    IOPort('Close',hLum);
end

ChapInfo.dur = GetSecs()-ChapInfo.onset;
ShowCursor;
Screen('Close All');
sca

save (fullfile(subdir,['Sub' num2str(Sub) 'Chp' num2str(ChapNum) '.mat']),'ChapInfo');
end%function
