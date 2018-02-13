classdef McsVideo < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties %(Access = private)
        playing = 0;
        environment     = [];
        imageCube       = [];
        framerate       = [];
        curFrame        = 1;
        CoordinateOI    = [];
        signalUOI        = [];
    end
    
    methods 
        function vid = McsVideo(fig, images, CoordinateOI, varargin)
            % Construct an instance of class McsVideo
            vid.environment     = fig;
            vid.imageCube       = images;
            vid.framerate       = 25;
            vid.CoordinateOI    = CoordinateOI;
            vid.signalUOI       = reshape(images(CoordinateOI(2),CoordinateOI(1),:),[1,size(images,3)]);
            %scale Images
            maxValue         	= max(max(max(abs(images))));
            images              = images/maxValue;
            minValue          	= min(min(min(images)));
            images              = images-minValue;
            maxValue         	= max(max(max(abs(images))));
            images              = images/maxValue;
            vid.imageCube       = images;
        end
        
        function playVideo( vid )
            %fetch data
            data                        = guidata(vid.environment);
            vid                         = data.video;
            
            AX_Video                    = findobj(get(vid.environment,'Children'),'Tag','video');
            AX_SingleUnitPlot           = findobj(get(vid.environment,'Children'),'Tag','singleUnitPlot');
            
            %prepare data
            imageStack                  = vid.imageCube;
            UnitOIData                  = vid.signalUOI;
            imageStack  = num2cell(imageStack,[1 2]);
            %Prepare figure
            figure(vid.environment);
            
            %play video
            vid.playing = 1;
            
            %save state playing
            data.video  = vid;
            guidata(vid.environment,data)
            %
            while(vid.playing && gcf == vid.environment)
                for frame=vid.curFrame:size(imageStack,3)
                    if gcf ~= vid.environment %&& gca~=AX_Video
                        break
                    end
                    
                    %show Video
                    set(0,'CurrentFigure',vid.environment) %not the optimal solution: multithreading would be better
                 	if exist('imshow')
                        h = imshow(imageStack{frame},'Parent',AX_Video);
                    else
                        h = imagesc(imageStack{frame},[0 1]);
                        set(h,'Parent',AX_Video);
                    end
                    set(h,'Interruptible','off');
                    set(AX_Video,'Tag','video','Interruptible','off');
                    
                    %plot Data and Video progress
                    set(0,'CurrentFigure',vid.environment)
                    axes(AX_SingleUnitPlot);
                    plot(UnitOIData)
                    hold on
                    plot([frame-1 frame-1],ylim,'--','LineWidth',1,'Color',[0.3333 0.4196 0.1843])
                    hold off
                    xlabel('Time [s]');
                    ylabel('Voltage [V]');
                    title(sprintf('Sensor Signal (%d,%d)',vid.CoordinateOI(1),vid.CoordinateOI(2)));
                    set(AX_SingleUnitPlot,'Tag','singleUnitPlot',...
                                            'Box','off',...
                                            'color',get(gcf,'Color'));
                    pause(1/vid.framerate);
                    
                    %handle interruption
                    if isgraphics(vid.environment,'figure')
                        data = guidata(vid.environment);
                    else
                        break
                    end
                    if data.video.playing == 0
                        data.video.curFrame = frame;
                        guidata(data.video.environment,data);
                        break
                    end
                    guidata(data.video.environment,data);
                end
                %handle interruption
                if isgraphics(vid.environment,'figure')
                    data = guidata(vid.environment);
                else
                    break
                end
                if data.video.playing == 0
                    break
                end
                
                vid.curFrame = 1;
            end
        end
        
        function pauseVideo( vid )
            data = guidata(vid.environment);
            data.video.playing = 0;
            guidata(vid.environment,data);
        end
        
        function [ vid , success ] = loadVideo( vid , AX )
            success        	= 0;
            colormap(AX,gray);
            if exist('imshow')
                h = imshow(vid.imageCube(:,:,1),'Parent',AX);
            else
                h = imagesc(vid.imageCube(:,:,1),[0 1]);
                set(h,'Parent',AX);
            end
            vid.curFrame    = 2;
            if isgraphics(h)
                success         = 1;
            end
        end
    end
    
    methods (Access = private)
    end
end