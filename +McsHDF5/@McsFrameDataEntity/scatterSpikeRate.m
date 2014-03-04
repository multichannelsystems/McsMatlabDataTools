function scatterSpikeRate(fde,cfg,varargin)

    defaultRateWindow = 0.05;
    defaultRateStep = 0.01;

    if isempty(cfg)
        cfg.window = [];
        cfg.channelMatrix = [];
        cfg.spikeSD = 5;
        cfg.spikeBaselineSegment = [0 0.1];
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
    [XX,YY] = meshgrid(1:sz(2),1:sz(3));
    s = squeeze(sum(ratemat,3));
    s(s == 0) = NaN;
    contourf(XX,YY,s)
    hold off
    axis([0 sz(2) 0 sz(3) 0 cfg.window(2)])
    xlabel('y channels')
    ylabel('x channels')
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

    Fs = 1 / double(fde.InfoStruct.Tick) * 1e6;
    
    winlen = cfg.rateWindow * Fs;
    step = cfg.rateStep * Fs;
    
    rates = zeros(floor((size(spikes,1)-winlen) / step),size(spikes,2));
    count = 0;
    for i = 1:step:size(spikes,1)-winlen
        count = count + 1;
        rates(count,:) = sum(spikes(i:i+winlen,:));
    end
end

