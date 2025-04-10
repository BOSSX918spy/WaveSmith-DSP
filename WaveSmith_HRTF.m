function combinedHRTF_and_LiveFFT_withBufferCleanup()
% combinedHRTF_and_LiveFFT_withBufferCleanup - Combined GUI for HRTF-based spatialization 
% with 3D source visualization, live FFT display, additional filter options, and buffer cleanup.
%
% Run with:
%   combinedHRTF_and_LiveFFT_withBufferCleanup

%%  Setup Figure and Panels
fig = figure('Name','Combined HRTF, Live FFT & Buffer Cleanups','NumberTitle','off',...
    'Position',[100 100 1280 800], 'CloseRequestFcn',@closeFigure);

% --- Left Panel: HRTF Controls & 3D Visualization ---
panelLeft = uipanel('Parent',fig, 'Title','HRTF Controls & 3D Visualization',...
    'Units','normalized','Position',[0.02 0.02 0.46 0.96]);

% Azimuth slider and label
azSlider = uicontrol(panelLeft,'Style','slider',...
    'Min',-180,'Max',180,'Value',0,...
    'Units','normalized','Position',[0.05 0.85 0.4 0.05],...
    'Callback',@updateHRTF);
uicontrol(panelLeft,'Style','text',...
    'Units','normalized','Position',[0.05 0.90 0.4 0.03],...
    'String','Azimuth (°): + = right, – = left');
azLabel = uicontrol(panelLeft,'Style','text',...
    'Units','normalized','Position',[0.47 0.85 0.1 0.05],...
    'String','Azimuth: 0°','FontSize',11);

% Elevation slider and label
elSlider = uicontrol(panelLeft,'Style','slider',...
    'Min',-90,'Max',90,'Value',0,...
    'Units','normalized','Position',[0.05 0.75 0.4 0.05],...
    'Callback',@updateHRTF);
uicontrol(panelLeft,'Style','text',...
    'Units','normalized','Position',[0.05 0.80 0.4 0.03],...
    'String','Elevation (°): + = up, – = down');
elLabel = uicontrol(panelLeft,'Style','text',...
    'Units','normalized','Position',[0.47 0.75 0.1 0.05],...
    'String','Elevation: 0°','FontSize',11);

% Swap L/R checkbox
swapChk = uicontrol(panelLeft,'Style','checkbox',...
    'String','Swap L/R',...
    'Units','normalized','Position',[0.05 0.68 0.3 0.05],...
    'Value',0,'Callback',@setSwap);

% Button to load audio
uicontrol(panelLeft,'Style','pushbutton',...
    'String','Select Audio File',...
    'Units','normalized','Position',[0.05 0.60 0.4 0.07],...
    'Callback',@selectAudio);

% 3D Visualization Axes (for HRTF source location)
ax3d = axes('Parent',panelLeft,...
    'Units','normalized','Position',[0.1 0.05 0.8 0.45]);
[sx,sy,sz] = sphere(30);
surf(ax3d, sx, sy, sz, 'FaceAlpha',0.1, 'EdgeColor','none');
hold(ax3d,'on');
hPoint = scatter3(ax3d, 1, 0, 0, 80, 'filled');
axis(ax3d,'equal');
xlabel(ax3d,'X'); ylabel(ax3d,'Y'); zlabel(ax3d,'Z');
title(ax3d,'Source Location');
view(ax3d, [45 20]);
hold(ax3d,'off');

%% --- Right Panel: Live FFT Display & Additional Filter Controls ---
panelRight = uipanel('Parent',fig, 'Title','Live FFT & Additional Filters',...
    'Units','normalized','Position',[0.5 0.02 0.48 0.96]);

% FFT Axes
hAxFFT = axes('Parent',panelRight, 'Units','normalized',...
    'Position',[0.1 0.45 0.8 0.45]);
xlabel(hAxFFT, 'Frequency (Hz)');
ylabel(hAxFFT, 'Magnitude (dB)');
title(hAxFFT, 'Live FFT');
% Preconfigure limits (will be updated later)
xlim(hAxFFT, [0 1]);
ylim(hAxFFT, [-100 0]);
fftLine = plot(hAxFFT, nan, nan);

% Play and Pause Buttons
uicontrol(panelRight,'Style','pushbutton','String','Play',...
    'Units','normalized','Position',[0.1 0.92 0.35 0.06],...
    'FontSize',12, 'Callback',@playCallback);
uicontrol(panelRight,'Style','pushbutton','String','Pause',...
    'Units','normalized','Position',[0.55 0.9 0.35 0.06],...
    'FontSize',12, 'Callback',@pauseCallback);

% --- Filter Selection Group (Radio buttons) moved lower ---
filterGroup = uibuttongroup('Parent',panelRight, 'Title', 'Filter Selection',...
    'Units','normalized','Position',[0.1 0.10 0.35 0.30],...
    'SelectionChangedFcn',@filterCallback);

% Create radio buttons for filter selection.
uicontrol(filterGroup, 'Style','radiobutton', 'String','None',...
    'Units','normalized','Position',[0.1 0.75 0.8 0.20], 'FontSize',11);
uicontrol(filterGroup, 'Style','radiobutton', 'String','Low-pass',...
    'Units','normalized','Position',[0.1 0.50 0.8 0.20], 'FontSize',11);
uicontrol(filterGroup, 'Style','radiobutton', 'String','Band-pass',...
    'Units','normalized','Position',[0.1 0.25 0.8 0.20], 'FontSize',11);
uicontrol(filterGroup, 'Style','radiobutton', 'String','High-pass',...
    'Units','normalized','Position',[0.1 0.00 0.8 0.20], 'FontSize',11);

customPanel = uipanel('Parent',panelRight, 'Title','Custom Filter',...
    'Units','normalized','Position',[0.55 0.10 0.35 0.16]);

uicontrol('Parent',customPanel, 'Style','text', 'String','Lower Frequency (Hz):',...
    'Units','normalized','Position',[0.05 0.65 0.9 0.2], 'FontSize',10);

lowerEdit = uicontrol('Parent',customPanel, 'Style','edit', 'String','500',...
    'Units','normalized','Position',[0.05 0.50 0.9 0.15], 'FontSize',10);

uicontrol('Parent',customPanel, 'Style','text', 'String','Upper Frequency (Hz):',...
    'Units','normalized','Position',[0.05 0.30 0.9 0.2], 'FontSize',10);

upperEdit = uicontrol('Parent',customPanel, 'Style','edit', 'String','9000',...
    'Units','normalized','Position',[0.05 0.15 0.9 0.15], 'FontSize',10);

uicontrol('Parent',customPanel, 'Style','pushbutton', 'String','Set Custom Filter',...
    'Units','normalized','Position',[0.05 0.01 0.9 0.12], 'FontSize',10,...
    'Callback',@customFilterCallback);


%% DSP and State Setup

% Load the SOFA file for HRTF.
sofaPath = "P0086_Raw_96kHz.sofa";
hrtfData = sofaread(sofaPath);
fs = hrtfData.SamplingRate;
xlim(hAxFFT, [0 fs/2]);

% Create initial HRTF filters using first measurement.
leftFilt  = dsp.FIRFilter('Numerator', squeeze(hrtfData.Numerator(1,1,:))');
rightFilt = dsp.FIRFilter('Numerator', squeeze(hrtfData.Numerator(1,2,:))');

% Additional Filter defaults (none)
currentFilter = 'none';
b = 1; a = 1;
filterState = [];

% Playback State (audio file is loaded later in callback).
state.audioData  = [];
state.currentIdx = 1;
% Adjust chunk size if necessary (try larger sizes if you encounter discontinuities)
state.chunkSize  = 4098;
state.isPlaying  = false;
player = audioDeviceWriter('SampleRate',fs,...
    'ChannelMappingSource','Property',...
    'ChannelMapping',[1 2]);
state.player = player;

%% Pack UI and DSP handles into the figure UserData
fig.UserData = struct(...
    'hrtfData', hrtfData, ...
    'leftFilter', leftFilt, ...
    'rightFilter', rightFilt, ...
    'state', state, ...
    'azSlider', azSlider, ...
    'elSlider', elSlider, ...
    'azLabel', azLabel, ...
    'elLabel', elLabel, ...
    'swapChk', swapChk, ...
    'hPoint', hPoint, ...
    'hAxFFT', hAxFFT, ...
    'fftLine', fftLine, ...
    'currentFilter', currentFilter, ...
    'b', b, 'a', a, ...
    'filterState', filterState, ...
    'lowerEdit', lowerEdit, ...
    'upperEdit', upperEdit);

%% Main Processing Loop
while ishandle(fig)
    ud = fig.UserData;
    st = ud.state;
    if st.isPlaying && ~isempty(st.audioData)
        % Determine next chunk boundaries
        idxEnd = min(st.currentIdx + st.chunkSize - 1, numel(st.audioData));
        frame = st.audioData(st.currentIdx:idxEnd);
        
        % Additional Filter Stage: apply if set (and reset filter state if needed)
        if ~strcmp(ud.currentFilter, 'none')
            if isempty(ud.filterState)
                ud.filterState = zeros(max(length(ud.b), length(ud.a)) - 1, 1);
            end
            [frame, ud.filterState] = filter(ud.b, ud.a, frame, ud.filterState);
        end
        
        % HRTF Processing: pass through left/right filters.
        L = step(ud.leftFilter, frame);
        R = step(ud.rightFilter, frame);
        
        % Swap channels if specified.
        if get(ud.swapChk, 'Value')
            out = [R, L];
        else
            out = [L, R];
        end
        
        % Send processed output to audio device.
        step(st.player, out);
        
        % --- Buffer Cleanup ---
        % Update playback index and check for restart (looping file).
        st.currentIdx = idxEnd + 1;
        if st.currentIdx > numel(st.audioData)
            st.currentIdx = 1;
            ud.filterState = [];    % Clear additional filter buffer
            % Also reset HRTF filters to clear any internal buffering.
            reset(ud.leftFilter);
            reset(ud.rightFilter);
        end
        
        ud.state = st;
        fig.UserData = ud;
        
        % Live FFT Update: using a Hann window.
        win = hann(length(frame));
        fftData = fft(frame .* win);
        numFreqBins = floor(length(frame)/2) + 1;
        mag = abs(fftData(1:numFreqBins));
        magdB = 20*log10(mag + eps);
        freqAxis = linspace(0, fs/2, numel(magdB));
        set(ud.fftLine, 'XData', freqAxis, 'YData', magdB);
    end
    drawnow;
    pause(0.001);  % brief pause to ease processor load and improve audio timing
end

%% --- Nested Callback Functions ---

    function updateHRTF(~, ~)
        % Update HRTF filters based on azimuth and elevation slider values.
        ud = fig.UserData;
        az = round(get(ud.azSlider, 'Value'));
        el = round(get(ud.elSlider, 'Value'));
        set(ud.azLabel, 'String', sprintf('Azimuth: %+d°', az));
        set(ud.elLabel, 'String', sprintf('Elevation: %+d°', el));
        
        % Find nearest HRTF measurement (by Euclidean distance in [az el]).
        pos = ud.hrtfData.SourcePosition; % Format: [az el dist]
        d = hypot(pos(:,1) - az, pos(:,2) - el);
        [~, idx] = min(d);
        
        % Update filter coefficients.
        ud.leftFilter.Numerator  = squeeze(ud.hrtfData.Numerator(idx,1,:))';
        ud.rightFilter.Numerator = squeeze(ud.hrtfData.Numerator(idx,2,:))';
        fig.UserData = ud;
        
        % Update 3D source location on a unit sphere.
        r = 1;
        xC = r * cosd(el) * cosd(az);
        yC = r * cosd(el) * sind(az);
        zC = r * sind(el);
        set(ud.hPoint, 'XData', xC, 'YData', yC, 'ZData', zC);
        drawnow limitrate;
    end

    function selectAudio(~, ~)
        % Let user select an audio file.
        [f, p] = uigetfile({'*.wav;*.mp3','Audio Files (*.wav, *.mp3)'}, 'Select Audio File');
        if isequal(f, 0)
            return;
        end
        fp = fullfile(p, f);
        [y, yFs] = audioread(fp);
        if size(y, 2) == 2
            y = mean(y, 2); % Convert stereo to mono.
        end
        if yFs ~= fs
            y = resample(y, fs, yFs);
        end
        
        % Normalize the audio to avoid clipping.
        y = y / max(abs(y));
        
        ud = fig.UserData;
        ud.state.audioData  = y;
        ud.state.currentIdx = 1;
        ud.state.isPlaying  = true;
        % Reset filter and HRTF buffers when loading a new file.
        ud.filterState = [];
        reset(ud.leftFilter);
        reset(ud.rightFilter);
        fig.UserData = ud;
    end

    function playCallback(~, ~)
        % Resume playback.
        ud = fig.UserData;
        ud.state.isPlaying = true;
        fig.UserData = ud;
    end

    function pauseCallback(~, ~)
        % Pause playback.
        ud = fig.UserData;
        ud.state.isPlaying = false;
        fig.UserData = ud;
    end

    function filterCallback(~, event)
        % Set additional filter coefficients based on radio button selection.
        ud = fig.UserData;
        selected = lower(event.NewValue.String);
        ud.currentFilter = selected;
        switch selected
            case 'none'
                ud.b = 1; ud.a = 1;
            case 'low-pass'
                [ud.b, ud.a] = butter(4, 200/(fs/2), 'low');
            case 'band-pass'
                [ud.b, ud.a] = butter(4, [500 9000]/(fs/2), 'bandpass');
            case 'high-pass'
                [ud.b, ud.a] = butter(4, 200/(fs/2), 'high');
            otherwise
                ud.b = 1; ud.a = 1;
        end
        ud.filterState = []; % Clear additional filter buffer on filter change.
        fig.UserData = ud;
    end

    function customFilterCallback(~, ~)
        % Set custom filter parameters from the UI.
        ud = fig.UserData;
        lf = str2double(get(ud.lowerEdit, 'String'));
        uf = str2double(get(ud.upperEdit, 'String'));
        if isnan(lf) || isnan(uf) || lf <= 0 || uf <= lf || uf >= fs/2
            disp('Invalid frequency range for custom filter.');
            return;
        end
        [ud.b, ud.a] = butter(4, [lf uf]/(fs/2), 'bandpass');
        ud.currentFilter = 'custom';
        ud.filterState = zeros(max(length(ud.b), length(ud.a))-1, 1);
        fig.UserData = ud;
    end

    function setSwap(~, ~)
        % No extra processing needed; the checkbox state is read during playback.
        drawnow;
    end

    function closeFigure(~, ~)
        % Clean up buffers and DSP objects upon GUI closure.
        ud = fig.UserData;
        % Stop audio playback.
        ud.state.isPlaying = false;
        % Release the audio device.
        release(ud.state.player);
        % Reset DSP filter objects to clear internal states.
        reset(ud.leftFilter);
        reset(ud.rightFilter);
        fig.UserData = ud;
        delete(fig);
    end

end
