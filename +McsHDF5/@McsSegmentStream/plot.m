function plot(segStream,cfg,varargin)
% Plot the contents of a McsSegmentStream object.
%
% function plot(segStream,cfg,varargin)
%
% Produces for each segment a 3D plot of trials x samples and a time series
% plot which overlays all trials.
%
% Input:
%
%   segStream     -   A McsSegmentStream object
%
%   cfg           -   Either empty (for default parameters) or a
%                     structure with (some of) the following fields:
%                     'segments': empty for all segments, otherwise a
%                       vector of segment indices (default: all)
%                     If fields are missing, their default values are used.
%
%   Optional inputs in varargin are passed to the plot function.

    clf
    
    if isempty(cfg) || ~isfield(cfg,'segments')
        cfg.segments = [];
    end
    
    if isempty(cfg.segments)
        cfg.segments = 1:length(segStream.SegmentData);
    end
    
    if any(cfg.segments < 1 | cfg.segments > length(segStream.SegmentData))
        warning(['Using only segment indices between 1 and ' num2str(length(segStream.SegmentData)) '!'])
        cfg.segments = cfg.segments(cfg.segments >= 1 & cfg.segments <= length(segStream.SegmentData));
    end
    
    for segi = 1:length(cfg.segments)
        id = cfg.segments(segi);
        subplot(2,length(cfg.segments),segi);
        
        if strcmp(segStream.DataType,'double')
            data_to_plot = segStream.SegmentData{id};
        else
            conv_cfg = [];
            conv_cfg.dataType = 'double';
            data_to_plot = segStream.getConvertedData(id,conv_cfg);
        end
        
        orig_exp = log10(max(abs(data_to_plot(:))));
        sourceChan = str2double(segStream.Info.SourceChannelIDs{segi});
        if length(sourceChan) > 1
            warning('Plots of multisegments are not yet supported!');
            return;
        end
        channel_idx = find(segStream.SourceInfoChannel.ChannelID == sourceChan);
        unit_exp = double(segStream.SourceInfoChannel.Exponent(channel_idx));

        [fact,unit_string] = McsHDF5.ExponentToUnit(orig_exp+unit_exp,orig_exp);

        data_to_plot = data_to_plot * fact;
        
        [X,Y] = meshgrid(1:size(data_to_plot,2),1:size(data_to_plot,1));
        if isempty([varargin{:}])
            surfl(X,Y,data_to_plot);
        else
            surfl(X,Y,data_to_plot,varargin{:});
        end
        shading interp
        xlabel('samples')
        ylabel('events')
        unit = segStream.SourceInfoChannel.Unit{channel_idx};
        zlabel([unit_string unit],'Interpreter','tex')
        title(['Segment label ' segStream.Info.Label{id}])
        
        
        subplot(2,length(cfg.segments),segi+length(cfg.segments));
        
        pre = double(segStream.Info.PreInterval(id));
        post = double(segStream.Info.PostInterval(id));
        ts = -pre:double(segStream.SourceInfoChannel.Tick(channel_idx)):post;
        if length(ts) ~= size(data_to_plot,1)
            warning('Pre- and post-interval does not match the number of samples!')
            ts = (1:size(data_to_plot,2)).*double(segStream.SourceInfoChannel.Tick(channel_idx));
        end
        
        ts = McsHDF5.TickToSec(ts);
        plot(ts,data_to_plot');
        
        hold on
        plot(ts,mean(data_to_plot),'-k','LineWidth',2);
        hold off
        
        axis tight
        xlabel('Time [s]');
        ylabel([unit_string unit],'Interpreter','tex')
        
    end
end
        