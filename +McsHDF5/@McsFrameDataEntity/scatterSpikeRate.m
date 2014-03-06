function scatterSpikeRate(fde,cfg,varargin)
% Very experimental function to visualize spike rates
%
% function scatterSpikeRate(fde,cfg,varargin)
%
% This function provides a possibility to visualize spike rates in data
% recorded in a 2D electrode array, i.e. a frame stream. It performs a
% simple, threshold based spike detection on the raw data. This detection
% is done channel-wise to save memory. The result is transformed to
% channel-wise spike rates which are shown in a 3D plot. In this plot,
% rates > 0 are plotted as open circles with a radius proportional to the
% rate. A contour function color-codes the the total spike rate per
% channel.
%
% Input:
%
%   fde         -   A McsFrameDataEntity object.
%
%   cfg         -   Either empty (for default parameters) or a
%                   structure with (some of) the following fields:
%                   'channelMatrix': empty for all channels, otherwise a
%                       matrix of bools with size channels_x x channels_y.
%                       All channels with 'true' entries in this matrix are
%                       used in the plots. (default: all channels)
%                   'window': empty for the whole time range, otherwise
%                       a vector with two entries: [start end] of the time
%                       range, both in seconds.
%                   'spikeBaselineSegment': [start end] in seconds of the
%                       time range used to get a baseline estimation of the
%                       noise standard deviation. If empty, the first 100
%                       ms are used.
%                   'spikeSD': threshold for spike detection in standard
%                       deviations. If a data point exceeds
%                       cfg.spikeSD*std(signal in cfg.spikeBaselineSegment)
%                       after subtraction of the mean, it is counted as a
%                       spike.
%                   'rateWindow': Length in seconds of the window for spike
%                       rate computation.
%                   'rateStep': Step size in seconds for moving the rate
%                       computation window over the data.
    defaultRateWindow = 0.05;
    defaultRateStep = 0.01;

    if isempty(cfg)
        cfg.window = [];
        cfg.channelMatrix = [];
        cfg.spikeSD = 5;
        cfg.spikeBaselineSegment = [McsHDF5.TickToSec(fde.FrameDataTimeStamps(1)) McsHDF5.TickToSec(fde.FrameDataTimeStamps(1))+0.1];
        cfg.rateWindow = defaultRateWindow;
        cfg.rateStep = defaultRateStep;    
    end
    
    if ~isfield(cfg,'window')
        cfg.window = [];
    end
    
    if ~isfield(cfg,'channelMatrix')
        cfg.channelMatrix = [];
    end
    
    if isempty(cfg.window)
        cfg.window = McsHDF5.TickToSec([fde.FrameDataTimeStamps(1) fde.FrameDataTimeStamps(end)]);
    end
    if isempty(cfg.channelMatrix)
        cfg.channelMatrix = true(size(fde.FrameData,2),size(fde.FrameData,3));
    end
    
    if ~isfield(cfg,'spikeSD')
        cfg.spikeSD = 5;
    end
    
    if ~isfield(cfg,'spikeBaselineSegment')
        cfg.spikeBaselineSegment = [0 0.1];
    end
    
    if ~isfield(cfg,'rateWindow')
        cfg.rateWindow = defaultRateWindow;
    end
    
    if ~isfield(cfg,'rateStep')
        cfg.rateStep = defaultRateStep;
    end
    
    % detect spikes
    spikes = detectSpikes(fde,cfg);
    
    % compute rate
    rates = computeRates(fde,spikes,cfg);
    
    % plot
    sz = size(fde.FrameData);
    
    ratemat = zeros(size(rates,1),sz(2),sz(3));
    ratemat(:,cfg.channelMatrix) = rates;
    
    [X,Y,Z] = meshgrid(1:sz(2),1:sz(3),cfg.window(1)+cfg.rateWindow:cfg.rateStep:cfg.window(2));
    
    ratemat = shiftdim(ratemat,1);
    
    xx = X(ratemat > 0);
    yy = Y(ratemat > 0);
    zz = Z(ratemat > 0);
    
    if isempty(varargin)
        scatter3(xx,yy,zz,ratemat(ratemat > 0));
    else
        scatter3(xx,yy,zz,ratemat(ratemat > 0),varargin{:})
    end
    hold on
    [XX,YY] = meshgrid(1:sz(3),1:sz(2));
    s = squeeze(sum(ratemat,3));
    s(s == 0) = NaN;
    contourf(XX,YY,s)
    hold off
    axis([0 sz(2) 0 sz(3) 0 cfg.window(2)])
    xlabel('x channels')
    ylabel('y channels')
    zlabel('Time [s]')
end

function spikes = detectSpikes(fde,cfg)

    base_idx = fde.FrameDataTimeStamps >= McsHDF5.SecToTick(cfg.spikeBaselineSegment(1)) & ...
        fde.FrameDataTimeStamps <= McsHDF5.SecToTick(cfg.spikeBaselineSegment(2));
    
    [~,tstart] = min(abs(fde.FrameDataTimeStamps - McsHDF5.SecToTick(cfg.window(1))));
    [~,tend] = min(abs(fde.FrameDataTimeStamps - McsHDF5.SecToTick(cfg.window(2))));
    
    c = find(cfg.channelMatrix);
    
    mn = squeeze(mean(fde.FrameData(tstart:tend,c)));
    
    base_sd = squeeze(sqrt(var(fde.FrameData(base_idx,c))));
    
    spikes = sparse(length(tstart:tend),numel(c));
    
    for ci = 1:size(c)
        chan = c(ci);
        spikes(abs(fde.FrameData(tstart:tend,chan)-mn(ci)) > cfg.spikeSD*base_sd(ci),ci) = true;
    end

end

function rates = computeRates(fde,spikes,cfg)

    Fs = 1 / double(fde.Info.Tick) * 1e6;
    
    winlen = cfg.rateWindow * Fs;
    step = cfg.rateStep * Fs;
    
    rates = zeros(floor((size(spikes,1)-winlen) / step),size(spikes,2));
    count = 0;
    for i = 1:step:size(spikes,1)-winlen
        count = count + 1;
        rates(count,:) = sum(spikes(i:i+winlen,:));
    end
end

