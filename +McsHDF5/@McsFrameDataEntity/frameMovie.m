function frameMovie(fde,cfg,varargin)

    if isempty(cfg);
        cfg.start = McsHDF5.TickToSec(fde.FrameDataTimeStamps(1));
        cfg.end = McsHDF5.TickToSec(fde.FrameDataTimeStamps(end));
        cfg.step = McsHDF5.TickToSec(fde.InfoStruct.Tick);
    end
    
    if ~isfield(cfg,'start')
        cfg.start = McsHDF5.TickToSec(fde.FrameDataTimeStamps(1));
    end
        
    if ~isfield(cfg,'end')
        cfg.end = McsHDF5.TickToSec(fde.FrameDataTimeStamps(end));
    end
    
    if ~isfield(cfg,'step')
        cfg.step = McsHDF5.TickToSec(fde.InfoStruct.Tick);
    end
    
    cfg.window = cfg.start;
   
    initial = true;
    
    while cfg.window < cfg.end - cfg.step
        cfg.window = cfg.window + cfg.step;
        tmp = get(gca);
        plot(fde,cfg)
        fn = fieldnames(tmp);
        for fi = 1:length(fn)
            try
                set(gca,fn{fi},tmp.(fn{fi}));
            catch
                continue
            end
        end
        if ~isempty(varargin)
            set(gca,varargin{:});
        end
        if initial
            input('Set initial position');
            initial = false;
        end
        pause(0.1);
    end
end