function [fig] = plot(str, cfg, varargin)
% plot function for a McsCmosSpikeSorterUnit object
%
% function plot(str, cfg, varargin)
%
% Produces a time series plot for each identified unit in the object.
%
% Input:
%
%   str             -   A McsCmosSpikeSorterUnit object
%
%   cfg             -   Either empty (for default parameters) or a
%                       structure with (some of) the following fields:
%
% Usage:
%   plot(str, cfg);
%   plot(str, cfg, ...);
%   str.plot(cfg);
%   str.plot(cfg, ...);
%
% (c) 2018 by Multi Channel Systems MCS GmbH

    fig = gcf;
    clf
    set(fig,'NumberTitle', 'off','Name',sprintf('Spike Sorter Unit %d',str.Info.UnitID),'Tag','SpikeSorterUnitPlot');
    
%% CHECK AND SET PROPER CONFIGURATION VALUES

% end section "CHECK AND SET PROPER CONFIGURATION VALUES"
%% SET UP FIGURE LAYOUT
%axes outer_position in normalized units
spacing = 0.01;
AX1_outerPosition   = [ spacing                   (2*spacing+0.382)                                   (0.191-1.5*spacing) (0.618-1.5*spacing) ];
AX2_outerPosition   = [ (2*spacing +0.191)        (2*spacing+0.382)                                   (0.4045-spacing)    (0.618-1.5*spacing) ];
AX3_outerPosition   = [ (3*spacing +0.191+0.4045) (2*spacing+0.382)                                   (0.4045-spacing)    (0.618-1.5*spacing) ];
AX6_outerPosition   = [ spacing                   spacing                                             (1-2*spacing)       (0.382*0.618^2-1.5*spacing) ];
AX5_outerPosition   = [ spacing                   spacing+AX6_outerPosition(4)                        (1-2*spacing)       (0.382^2*0.618-1.5*spacing) ];
AX4_outerPosition   = [ spacing                   spacing+AX5_outerPosition(4)+AX6_outerPosition(4)   (1-2*spacing)       (0.382^2-1.5*spacing) ];
fontSizeInfobox     = AX1_outerPosition(4)/20;
fontSizeSignal      = fontSizeInfobox*1000; %result should be equal to fontSizeInfobox
fontSizeTicks       = 6;
fontSizeTitle       = 1/60;
fontSizeLabel       = 9;
%
%% VISUALIZE UNIT INFORMATION IN AXES 'AX1'
AX1 = axes('Position',AX1_outerPosition,'Visible','off');
basicsHeaders   = {'ID:';...
                    'Channel:';...
                    'Coordinate:'};
basicInfo       = {sprintf('%d',str.Info.UnitID);...
                    sprintf('unknown');...
                    sprintf('(%d,%d)',str.Info.Column,str.Info.Row)};
detailsHeaders  = {'IsoIBg:';...
                    'Separability:';...
                    'RSTD:';...
                    'SNR:';...
                    'IsoINN:';...
                    'Skewness:';...
                    'Kurtosis:'};
detailedInfo    = {sprintf('%1.3d',str.UnitInfo.IsoIBg);...
                    sprintf('%1.3d',str.UnitInfo.Separability);...
                    sprintf('%1.3d',str.UnitInfo.RSTD);...
                    sprintf('%1.3d',str.UnitInfo.SNR);...
                    sprintf('%1.3d',str.UnitInfo.IsoINN);...
                    sprintf('%1.3d',str.UnitInfo.Skewness);...
                    sprintf('%1.3d',str.UnitInfo.Kurtosis)};

axes(AX1)%sets current axes to AX1
text([0 0],[0.75 0.1],{basicsHeaders,detailsHeaders},'VerticalAlignment','bottom','HorizontalAlignment','left','FontUnits','normalized','FontSize', fontSizeInfobox);
text([0.618 0.618],[0.75 0.1],{basicInfo,detailedInfo},'VerticalAlignment','bottom','HorizontalAlignment','left','FontUnits','normalized','FontSize', fontSizeInfobox);

%visualize Image
AXImage_outerPosition = [ AX1_outerPosition(1) AX1_outerPosition(2)+AX1_outerPosition(4)/2-AX1_outerPosition(3)/4 AX1_outerPosition(3) AX1_outerPosition(3) ];
AX_image = axes('Position',AXImage_outerPosition);
box off;
axis off;

STAimage = McsHDF5.McsCmosSpikeSorterUnit.createUnitSTAImage(str);
image           = STAimage.image;

map             = jet;                                      %set colormap to jet
map(1,:)        = get(gcf,'Color');                         %modify colormap - set color for lowest intensity to color current figure

%rescale image to make sure all non-zero values are larger than 1/64 so
%that they are not converted to gray
image           = image*(size(map,1)-1)/size(map,1);        %rescaling
image(image~=0) = image(image~=0) + 1 - max(max(image));    %shifting all non-zero values up so that max(max(image)) == 1 again
imshow(image,'Colormap',map,'Parent',AX_image);
%
%% VISUALIZE CUTOUTS
%fetch data
noisyCutouts    =   str.Peaks.Cutout(~logical(str.Peaks.IncludePeak),:);
relevantCutouts =   str.Peaks.Cutout(logical(str.Peaks.IncludePeak),:);
[M,I] = min(relevantCutouts(:));
[I_row, I_col]  = ind2sub(size(relevantCutouts),I);
timeWindow      =   ((1:1:size(str.Peaks.Cutout,2))-I_col)*1e-3*double(str.PeaksInfo.Tick);
%timeWindow      =   0:(double(str.PeaksInfo.Tick)*1e-3):size(str.Peaks.Cutout,2)*double(str.PeaksInfo.Tick)*1e-3;
%timeWindow      =   (timeWindow(1:end-1)-timeWindow(end-1)/2).';
%assemble axes
AX2 = axes('OuterPosition',AX2_outerPosition);
if noisyCutouts
    plot(AX2,timeWindow,noisyCutouts,'Color',[0.618 0.618 0.618]);
    hold on
end
if relevantCutouts
    plot(AX2,timeWindow,relevantCutouts,'Color','black');
    hold on
end
axis([min(timeWindow) ...
        max(timeWindow) ...
        min(min(str.Peaks.Cutout))-0.01*abs(min(min(str.Peaks.Cutout))-max(max(str.Peaks.Cutout))) ...
        max(max(str.Peaks.Cutout))+0.01*abs(min(min(str.Peaks.Cutout))-max(max(str.Peaks.Cutout)))]);
set(AX2,'YTick',[],...
        'YColor',get(gcf,'Color'),...
        'Box','off',...
        'color',get(gcf,'Color'),...
        'TickLength',[0.005 0.0125]);
xAX = get(AX2,'XAxis');
set(xAX,'FontSize', fontSizeTicks)
xlabel('Time [ms]','FontSize',fontSizeLabel);
%
%% VISUALIZE PEAK AMPLITUDE HISTOGRAMM
AX3 = axes('OuterPosition',AX3_outerPosition);
hist(AX3,str.Peaks.PeakAmplitude);
hold on;
l = line([str.PeaksInfo.AmplitudeThreshold, str.PeaksInfo.AmplitudeThreshold], ylim, 'LineWidth', 1, 'Color', 'blue','LineStyle','--');
yLimits = ylim;
text(str.PeaksInfo.AmplitudeThreshold,yLimits(2),'Cutoff Amlpitude ',...
        'Color','blue',...
        'HorizontalAlignment','right',...
        'VerticalAlignment','bottom',...
        'FontUnits','normalized',...
        'FontSize',1/30);
h = findobj(AX3,'Type','patch');
h.FaceColor = 'black';
h.EdgeColor = get(gcf,'Color');
set(AX3,'Box','off',...
        'color',get(gcf,'Color'),...
        'TickLength',[0.005 0.0125],...
        'YGrid','on');
xAX = get(AX3,'XAxis');
set(xAX,'FontSize', fontSizeTicks)
xlabel('Amplitude','FontSize',fontSizeLabel);
yAX = get(AX3,'YAxis');
set(yAX,'FontSize', fontSizeTicks)
ylabel('Count','FontSize',fontSizeLabel);
%
%% VISUALIZE SOURCE SIGNAL
%visualize signal
AX4 = axes('OuterPosition',AX4_outerPosition);
plot(AX4,str.Source,'Color','black');
set(AX4,'XTick',[],...
        'XColor',get(gcf,'Color'),...
        'Box','off',...
        'color',get(gcf,'Color'),...
        'TickLength',[0.005 0.0125],...
        'xlim',[0 length(str.Source)]);
yAX = get(AX4,'YAxis');
set(yAX,'FontSize', fontSizeTicks)
ylabel('Arbitrary Units','FontSize',fontSizeLabel);
%visualize spikes
AX5     = axes('OuterPosition',AX5_outerPosition);
peaks   = (double(str.Peaks.Timestamp(logical(str.Peaks.IncludePeak)))*double(str.PeaksInfo.Tick)*1e-6).';
y       = zeros(size(peaks));
axes(AX5)%sets current axes to AX5
text(peaks,y,'|','VerticalAlignment','middle','HorizontalAlignment','center','Color','black');
set(AX5,'Box','off',...
        'color',get(gcf,'Color'),...
        'XTick',[],...
        'XColor',get(gcf,'Color'),...
        'YTick',[],...
        'YColor',get(gcf,'Color'),...
        'TickLength',[0.005 0.0125]);
axis([0 double(str.Peaks.Timestamp(end))*double(str.PeaksInfo.Tick)*1e-6 -0.5 0.5]);
%visualize count
AX6             = axes('OuterPosition',AX6_outerPosition);
[count, edges]  = histcounts(peaks,100);
width           = edges(2)-edges(1);
index           = edges(1:end-1)+width/2;
bar(AX6,index,count,1,'FaceColor','black','EdgeColor',get(gcf,'Color'));
axis([edges(1) edges(end) 0 max(count)])
xTicks = edges(1):(edges(end)-edges(1))/10:edges(end);
set(AX6,'Box','off',...
        'color',get(gcf,'Color'),...
        'TickLength',[0.005 0.0125],...
        'YGrid','on')
xticks(xTicks);
xticklabels(arrayfun(@num2str,xTicks/double(str.PeaksInfo.Tick),'UniformOutput',false));
xAX = get(AX6,'XAxis');
set(xAX,'FontSize', fontSizeTicks)
xlabel('Time [s]','FontSize',fontSizeLabel);
yAX = get(AX6,'YAxis');
set(yAX,'FontSize', fontSizeTicks)
ylabel('Count','FontSize',fontSizeLabel);
%
%% WRITE BOX TITLES
%write Titles (into separate axes)
AX1_title = axes('Position',[0 0 1 1],'Visible','off'); %Unit Info Title
text(AX1_outerPosition(1)-0.5*spacing,0.99*(AX1_outerPosition(2)+AX1_outerPosition(4)),'Unit Information',...
        'VerticalAlignment','top',...
        'HorizontalAlignment','left',...
        'FontUnits','normalized',...
        'FontSize', fontSizeTitle,...
        'FontWeight','bold');
AX2_title = axes('Position',[0 0 1 1],'Visible','off'); %Cutout Title
text(AX2_outerPosition(1)-0.5*spacing,0.99*(AX2_outerPosition(2)+AX3_outerPosition(4)),'Cutouts',...
        'VerticalAlignment','top',...
        'HorizontalAlignment','left',...
        'FontUnits','normalized',...
        'FontSize', fontSizeTitle,...
        'FontWeight','bold');
AX3_title = axes('Position',[0 0 1 1],'Visible','off'); %Histogram Title
text(AX3_outerPosition(1)-0.5*spacing,0.99*(AX3_outerPosition(2)+AX3_outerPosition(4)),'Histogram',...
        'VerticalAlignment','top',...
        'HorizontalAlignment','left',...
        'FontUnits','normalized',...
        'FontSize', fontSizeTitle,...
        'FontWeight','bold');
AX4_title = axes('Position',[0 0 1 1],'Visible','off'); %Signal Title
text(AX4_outerPosition(1)-0.5*spacing,0.99*(AX4_outerPosition(2)+AX4_outerPosition(4)),'Source Signal',...
        'VerticalAlignment','top',...
        'HorizontalAlignment','left',...
        'FontUnits','normalized',...
        'FontSize', fontSizeTitle,...
        'FontWeight','bold');
%
end