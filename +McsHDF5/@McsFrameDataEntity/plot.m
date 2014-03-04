function plot(frame,cfg,varargin)
% function plot(frame,cfg,varargin)
%
% Function to plot the contents of a McsFrameDataEntity object.
%
% Input:
%
%   frame       - A McsFrameDataEntity object.
%
%   cfg         -   Either empty (for default parameters) or a
%                   structure with (some of) the following fields:
%                   'channelMatrix': empty for all channels, otherwise a
%                       matrix of bools with size channels_x x channels_y.
%                       All channels with 'true' entries in this matrix are
%                       used in the plots. (default: all channels)
%                   'window': empty for the whole time range, otherwise
%                       either a vector with two entries: [start end] of
%                       the time range, both in seconds, or a scalar: a
%                       time point in seconds. If a range is given, the
%                       signal of each channel in this range is plotted
%                       individually. For a single time plot, a 2D/3D image
%                       over all channels is generated.
%               If fields are missing, their default values are used.
%
%   optional inputs in varargin are passed to the plot function.

    clf
    
    if isempty(cfg)
        cfg.window = [];
        cfg.channelMatrix = [];
    end
    
    if ~isfield(cfg,'window')
        cfg.window = [];
    end
    
    if ~isfield(cfg,'channelMatrix')
        cfg.channelMatrix = [];
    end
    
    if isempty(cfg.window)
        cfg.window = McsHDF5.TickToSec([frame.FrameDataTimeStamps(1) frame.FrameDataTimeStamps(end)]);
    end
    if isempty(cfg.channelMatrix)
        cfg.channelMatrix = true(size(frame.FrameData,2),size(frame.FrameData,3));
    end
    
    if size(cfg.channelMatrix,1) ~= size(frame.FrameData,2) || size(cfg.channelMatrix,2) ~= size(frame.FrameData,3)
        error('Size of cfg.channelMatrix does not match the number of channels in the file!');
    end
    
    if numel(cfg.window) == 1 || cfg.window(1) == cfg.window(2)
        % plot single time point as a 3D visualization
        
        idx = find(abs(frame.FrameDataTimeStamps - McsHDF5.SecToTick(cfg.window(1))) <= frame.InfoStruct.Tick);
        if isempty(idx)
            warning('No data point found!')
            return;
        elseif numel(idx) > 1
            [~,tmp] = min(abs(frame.FrameDataTimeStamps(idx) - McsHDF5.SecToTick(cfg.window(1))));
            idx = idx(tmp);
        end
        
        data_to_plot = frame.FrameData(idx,:,:);
        orig_exp = log10(max(abs(data_to_plot(:))));
        unit_exp = double(frame.InfoStruct.Exponent);

        [fact,unit_string] = McsHDF5.ExponentToUnit(orig_exp+unit_exp,orig_exp);

        data_to_plot = squeeze(data_to_plot * fact);
        data_to_plot(~cfg.channelMatrix) = NaN;

        [X,Y] = meshgrid(1:size(data_to_plot,2),1:size(data_to_plot,1));
        if isempty([varargin{:}])
            surf(X,Y,data_to_plot);
        else
            surf(X,Y,data_to_plot,varargin{:});
        end
        xlabel('y channels')
        ylabel('x channels')
        zlabel([unit_string frame.InfoStruct.Unit{1}],'Interpreter','tex')
        title(['Time: ' num2str(cfg.window(1)) ' [s]'])
    else
        
        start_index = find(frame.FrameDataTimeStamps >= McsHDF5.SecToTick(cfg.window(1)),1,'first');
        end_index = find(frame.FrameDataTimeStamps <= McsHDF5.SecToTick(cfg.window(2)),1,'last');

        if end_index < start_index
            warning('No time range found')
            return
        end

        data_to_plot = frame.FrameData(start_index:end_index,:,:);

        timestamps = McsHDF5.TickToSec(frame.FrameDataTimeStamps(start_index:end_index));
        
        orig_exp = log10(max(abs(data_to_plot(:))));
        unit_exp = double(frame.InfoStruct.Exponent);

        [fact,unit_string] = McsHDF5.ExponentToUnit(orig_exp+unit_exp,orig_exp);

        data_to_plot = data_to_plot * fact;
        
        num_x = size(data_to_plot,2);
        num_y = size(data_to_plot,3);

        left = 0.08;
        bottom = 0.08;

        width = (1-left)/(1.1*num_x+0.1);
        spacing_x = 0.1*width;
        height = (1-bottom)/(1.1*num_y+0.1);
        spacing_y = 0.1*height;
        
        range_y = [min(min(min(data_to_plot(:,cfg.channelMatrix)))) ...
            max(max(max(data_to_plot(:,cfg.channelMatrix))))];

        for xi = 1:num_x
            for yi = 1:num_y
                if cfg.channelMatrix(xi,yi)
                    axes('position',[left+xi*spacing_x+(xi-1)*width,...
                                    1-(yi*spacing_y+yi*height),...
                                    width,height]);
                    if isempty([varargin{:}])
                        plot(timestamps,data_to_plot(:,xi,yi));
                    else
                        plot(timestamps,data_to_plot(:,xi,yi),varargin{:});
                    end
                    axis([timestamps(1) timestamps(end) range_y(1) range_y(2)]);
                    if xi > 1 && yi < num_y
                        axis off
                    else
                        set(gca,'Box','off');
                        set(gca,'color',get(gcf,'Color'))
                    end
                    if yi == num_y
                        xlabel('Time [s]')
                        if xi ~= 1
                            set(gca,'YTick',[])
                            set(gca,'YColor',get(gcf,'Color'))
                        end
                    end
                    if xi == 1
                        ylabel([unit_string frame.InfoStruct.Unit{1}],'Interpreter','tex')
                        if yi ~= num_y
                            set(gca,'XTick',[])
                            set(gca,'XColor',get(gcf,'Color'))
                        end
                    end
                end
            end
        end
    end

end