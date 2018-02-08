function mouseSingleSensor(src, evt)
% function mouseHandlerVideo(src, evt)
%
% Is triggered when the mouse is clicked in a Single Unit figure. Reads
% the subplot clicked. On clicking the video, it is played or paused. On
% clicking the Single unit plot, the current frame is moved to the clicked
% x-position

    if strcmp(get(src, 'SelectionType'), 'normal')
        subplts = get(src,'Children');
        if src.CurrentAxes == findobj(subplts,'Tag','neighborhood') %Neighborhood is clicked
        elseif src.CurrentAxes == findobj(subplts,'Tag','video') %Video is clicked
            data = guidata(src);
            if data.video.playing
                data.video.pauseVideo();
            else
                data.video.playVideo();
            end
        elseif src.CurrentAxes == findobj(subplts,'Tag','singleUnitPlot')
            pt = get(gca,'CurrentPoint');
            data = guidata(src);
            videoLength = size(data.video.imageCube,3);

            x = pt(1,1) - 0.5;
            x = min(x, videoLength);
            x = max(1,x);
            x = round(x);
            if data.video.playing
                data.video.pauseVideo();
            end
            data = guidata(src);
            data.video.curFrame = x;
            
            AX_Video            = findobj(get(data.video.environment,'Children'),'Tag','video');
            AX_SingleUnitPlot   = findobj(get(data.video.environment,'Children'),'Tag','singleUnitPlot');
            
            %prepare data
            imageStack  = data.video.imageCube;
            imageStack  = num2cell(imageStack,[1 2]);
            UnitOIData  = data.video.signalUOI;
            
            %show Video frame
            axes(AX_Video);
            h = imshow(imageStack{data.video.curFrame},'Parent',AX_Video);
            set(h,'Interruptible','off');
            set(AX_Video,'Tag','video','Interruptible','off');
            
            %plot Data and Video progress
            axes(AX_SingleUnitPlot);
            plot(UnitOIData)
            hold on
            plot([data.video.curFrame-1 data.video.curFrame-1],ylim,'--','LineWidth',1,'Color',[0.3333 0.4196 0.1843])
            hold off
            xlabel('Time [s]');
            ylabel('Voltage [V]');
            title(sprintf('Unit (%d,%d)',data.video.CoordinateOI(1),data.video.CoordinateOI(2)));
            set(AX_SingleUnitPlot,'Tag','singleUnitPlot');
            
            data.video.curFrame = data.video.curFrame + 1 ;
            
            guidata(src,data);
        end
    end
end

