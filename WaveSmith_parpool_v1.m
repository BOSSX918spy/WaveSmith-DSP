function liveFFTwithFiltersDSP()
    % liveFFTwithFiltersDSP - Real-time audio playback with live FFT display
    % and live power spectrogram. This version offloads both the FFT
    % computation and the spectrogram update to separate parallel tasks.
    
    %% File Selection and DSP Object Setup
    [file, path] = uigetfile('*.wav', 'Select an audio file');
    if isequal(file,0)
        disp('User canceled file selection.');
        return;
    end
    fullFileName = fullfile(path, file);
    
    % Create an audio file reader with a frame size of 2048 samples.
    frameSize = 8192;
    afr = dsp.AudioFileReader(fullFileName, 'SamplesPerFrame', frameSize);
    fs = afr.SampleRate;
    
    % Create an audio device writer for playback.
    ap = audioDeviceWriter('SampleRate', fs);
    
    %% Initialize Filter Variables and Spectrogram Buffer
    currentFilter = 'none';
    b = 1; a = 1;  % default (no filtering)
    filterState = [];  % preserve filter state across frames
    
    numFreqBins = frameSize/2 + 1;
    specNumCols = 100;  % number of time columns to display
    specMatrix = -100 * ones(numFreqBins, specNumCols);  % initialize spectrogram
    
    %% Create UI Figure and Controls
    hFig = figure('Name', 'Live FFT & Spectrogram with Filters v4', ...
        'NumberTitle', 'off', 'CloseRequestFcn', @closeFigure, ...
        'Position', [100 100 900 700]);
    
    % FFT axes
    hAxFFT = axes('Parent', hFig, 'Position', [0.08 0.55 0.55 0.4]);
    xlabel(hAxFFT, 'Frequency (Hz)');
    ylabel(hAxFFT, 'Magnitude (dB)');
    title(hAxFFT, 'Live FFT');
    xlim(hAxFFT, [0 fs/2]);
    ylim(hAxFFT, [-100 0]);
    fftLine = plot(hAxFFT, nan, nan);
    
    % Spectrogram axes
    hAxSpec = axes('Parent', hFig, 'Position', [0.08 0.1 0.55 0.35]);
    freqVec = linspace(0, fs/2, numFreqBins);
    timeVec = linspace(-specNumCols+1, 0, specNumCols); % relative frame indices
    hImg = imagesc(timeVec, freqVec, specMatrix, 'Parent', hAxSpec);
    axis(hAxSpec, 'xy');
    xlabel(hAxSpec, 'Frame Index');
    ylabel(hAxSpec, 'Frequency (Hz)');
    title(hAxSpec, 'Live Power Spectrogram (dB)');
    caxis(hAxSpec, [-100 0]);
    colorbar('peer', hAxSpec);
    
    % Play/Pause Buttons (top right)
    uicontrol('Parent', hFig, 'Style', 'pushbutton', 'String', 'Play', ...
        'Units', 'normalized', 'Position', [0.70 0.80 0.12 0.08], ...
        'FontSize', 12, 'Callback', @playCallback);
    uicontrol('Parent', hFig, 'Style', 'pushbutton', 'String', 'Pause', ...
        'Units', 'normalized', 'Position', [0.83 0.80 0.12 0.08], ...
        'FontSize', 12, 'Callback', @pauseCallback);
    
    % Filter Selection Group (left side of right column)
    filterGroup = uibuttongroup('Parent', hFig, 'Title', 'Filter Selection', ...
        'Units', 'normalized', 'Position', [0.70 0.45 0.12 0.25], ...
        'SelectionChangedFcn', @filterCallback);
    uicontrol(filterGroup, 'Style', 'radiobutton', 'String', 'None', ...
        'Units', 'normalized', 'Position', [0.1 0.75 0.8 0.2], 'FontSize', 11);
    uicontrol(filterGroup, 'Style', 'radiobutton', 'String', 'Low-pass', ...
        'Units', 'normalized', 'Position', [0.1 0.50 0.8 0.2], 'FontSize', 11);
    uicontrol(filterGroup, 'Style', 'radiobutton', 'String', 'Band-pass', ...
        'Units', 'normalized', 'Position', [0.1 0.25 0.8 0.2], 'FontSize', 11);
    uicontrol(filterGroup, 'Style', 'radiobutton', 'String', 'High-pass', ...
        'Units', 'normalized', 'Position', [0.1 0.0 0.8 0.2], 'FontSize', 11);
    
    % Custom Filter Panel (right of filter group)
    customPanel = uipanel('Parent', hFig, 'Title', 'CUSTOM FILTER', ...
        'Units', 'normalized', 'Position', [0.83 0.45 0.12 0.25]);
    uicontrol('Parent', customPanel, 'Style', 'text', 'String', 'Lower Frequency (Hz):', ...
        'Units', 'normalized', 'Position', [0.1 0.70 0.8 0.2], 'FontSize', 10);
    lowerEdit = uicontrol('Parent', customPanel, 'Style', 'edit', 'String', '500', ...
        'Units', 'normalized', 'Position', [0.1 0.55 0.8 0.15], 'FontSize', 10);
    uicontrol('Parent', customPanel, 'Style', 'text', 'String', 'Upper Frequency (Hz):', ...
        'Units', 'normalized', 'Position', [0.1 0.35 0.8 0.15], 'FontSize', 10);
    upperEdit = uicontrol('Parent', customPanel, 'Style', 'edit', 'String', '9000', ...
        'Units', 'normalized', 'Position', [0.1 0.20 0.8 0.15], 'FontSize', 10);
    uicontrol('Parent', customPanel, 'Style', 'pushbutton', 'String', 'Set Custom Filter', ...
        'Units', 'normalized', 'Position', [0.1 0.05 0.8 0.10], 'FontSize', 10, ...
        'Callback', @customFilterCallback);
    
    %% Global Flags and Parallel Task Futures
    isPlaying = false;
    keepRunning = true;
    fftFuture = [];
    specFuture = [];
    
    % Precompute the Hann window once.
    win = hann(frameSize);
    
    % Ensure a parallel pool is running.
    poolobj = gcp('nocreate');
    if isempty(poolobj)
        poolobj = parpool;
    end
    
    %% Main Processing Loop
    while keepRunning && ishandle(hFig)
        if isPlaying
            frame = step(afr);
            % Convert stereo to mono if needed.
            if size(frame,2) > 1
                frame = mean(frame,2);
            end
            % Apply filter if selected.
            if ~strcmp(currentFilter, 'none')
                if isempty(filterState)
                    filterState = zeros(max(length(b), length(a))-1, 1);
                end
                [frame, filterState] = filter(b, a, frame, filterState);
            end
            % Play the audio frame.
            ap(frame);
            
            % Offload FFT computation if no FFT task is pending.
            if isempty(fftFuture)
                fftFuture = parfeval(poolobj, @computeFFT, 1, frame, win, numFreqBins);
            end
            
            % Check if FFT result is ready.
            if ~isempty(fftFuture) && strcmp(fftFuture.State, 'finished')
                try
                    magdB = fetchOutputs(fftFuture);
                    % Update FFT plot on the main thread.
                    freqAxis = linspace(0, fs/2, numel(magdB));
                    set(fftLine, 'XData', freqAxis, 'YData', magdB);
                    fftFuture = [];
                    
                    % Offload spectrogram update using the new FFT column.
                    if isempty(specFuture)
                        specFuture = parfeval(poolobj, @updateSpec, 1, specMatrix, magdB);
                    end
                catch ME
                    disp(['Error in FFT computation: ' ME.message]);
                    fftFuture = [];
                end
            end
            
            % Check if spectrogram update is ready.
            if ~isempty(specFuture) && strcmp(specFuture.State, 'finished')
                try
                    specMatrix = fetchOutputs(specFuture);
                    set(hImg, 'CData', specMatrix);
                catch ME
                    disp(['Error in spectrogram update: ' ME.message]);
                end
                specFuture = [];
            end
            
            drawnow;
        else
            pause(0.05);
        end
        
        % Reset file and filter state when end-of-file is reached.
        if isDone(afr)
            reset(afr);
            filterState = [];
        end
    end
    
    %% Cleanup on Close
    release(ap);
    release(afr);
    if ishandle(hFig)
        close(hFig);
    end
    
    %% Callback Functions
    function playCallback(~, ~)
        isPlaying = true;
    end

    function pauseCallback(~, ~)
        isPlaying = false;
    end

    function filterCallback(~, event)
        selected = event.NewValue.String;
        currentFilter = lower(selected);
        switch currentFilter
            case 'none'
                b = 1; a = 1;
            case 'low-pass'
                cutoff = 200;  % cutoff frequency in Hz
                [b, a] = butter(4, cutoff/(fs/2), 'low');
            case 'band-pass'
                lowCut = 500; highCut = 9000;
                [b, a] = butter(4, [lowCut highCut]/(fs/2), 'bandpass');
            case 'high-pass'
                cutoff = 10000;
                [b, a] = butter(4, cutoff/(fs/2), 'high');
            otherwise
                b = 1; a = 1;
        end
        if ~strcmp(currentFilter, 'none')
            filterState = zeros(max(length(b), length(a))-1, 1);
        else
            filterState = [];
        end
        disp(['Filter set to: ' currentFilter]);
    end

    function customFilterCallback(~, ~)
        lowerFreq = str2double(get(lowerEdit, 'String'));
        upperFreq = str2double(get(upperEdit, 'String'));
        if isnan(lowerFreq) || isnan(upperFreq) || lowerFreq <= 0 || upperFreq <= lowerFreq || upperFreq >= fs/2
            disp('Invalid custom frequency range. Please enter valid values.');
            return;
        end
        [b, a] = butter(4, [lowerFreq upperFreq]/(fs/2), 'bandpass');
        currentFilter = 'custom';
        filterState = zeros(max(length(b), length(a))-1, 1);
        disp(['Custom band-pass filter set: ' num2str(lowerFreq) ' Hz to ' num2str(upperFreq) ' Hz']);
    end

    function closeFigure(~, ~)
        keepRunning = false;
        isPlaying = false;
        delete(hFig);
    end
end

%% Local Functions for Parallel Processing

% Compute FFT: window, FFT, and convert magnitude to dB.
function magdB = computeFFT(frame, win, numFreqBins)
    frameWindowed = frame .* win;
    fftData = fft(frameWindowed);
    mag = abs(fftData(1:numFreqBins));
    magdB = 20*log10(mag + eps);
end

% Update the spectrogram matrix by shifting and appending the new FFT column.
function newSpecMatrix = updateSpec(oldSpecMatrix, newColumn)
    newSpecMatrix = [oldSpecMatrix(:,2:end) newColumn];
end
