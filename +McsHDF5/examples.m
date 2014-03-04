% Example script for the McsHDF5 tools:

% First, add the base path of the +McsHDF5 folder to your matlab path
% addpath YOURPATH

% import the package
import McsHDF5.*

% load a data set with 2 analog streams, 1 event stream and 1 segment
% stream:

data = McsHDF5.McsData('DataSpikeAnalyzer.h5');

% Up to this point, only the metadata has been read from the file
% the actual data within the stream will be loaded as soon as you try to
% access the stream, for example in a plot function.

% The recorded data is organized as follows within the data structure:

% top-level: general information and a cell array of McsRecording objects
disp(data)

% each recording is stored in its individual cell. 
disp(data.Recording{1})

% Each recording cell contains cell arrays of zero or more analog-, frame-,
% segment- and event-streams. If we access one of these streams, its data
% is loaded from the file:
disp(data.Recording{1}.AnalogStream{1})
% The only exception is the frame stream which has additional
% sub-structures, the FrameDataEntities. Access of those will load the data
% as well. 

% Each stream has simple plot functions to allow a quick check whether the
% data is all right:
plot(data.Recording{1}.AnalogStream{1},[])
plot(data.Recording{1}.EventStream{1},[])
plot(data.Recording{1}.SegmentStream{1},[])
% because the event stream and the segment streams have not been accessed
% before, its data is loaded during the execution of the plot function.

% plot functions can also be executed at the recording or top level in
% order to get an overview over all streams in the recording, or even all
% streams in the data:
plot(data.Recording{1},[]);
plot(data,[]);

% If the second parameter of the plot functions is empty, the default
% parameters are used for plotting. Otherwise, one can specify
% configuration structures for more fine-grained plotting. For example, the
% following commands will plot channels 2, 4 and 6 of the first analog
% stream:
cfg = [];
cfg.channels = [2 4 6];
plot(data.Recording{1}.AnalogStream{1},cfg);
% Each plot function has its own set of options, so you need to check the
% individual help functions (e.g. help McsHDF5.McsEventStream.plot) for the
% specifics. You can specify these options also in higher level plot
% functions to achieve the same thing:
cfg = [];
cfg.analog.channels = [2 4 6];
plot(data.Recording{1},cfg);
cfg = [];
cfg.conf.analog.channels = [2 4 6];
plot(data,cfg);

% You can also specify options for the underlying MATLAB plotting
% functions:
plot(data.Recording{1}.AnalogStream{1},cfg,'--r','LineWidth',5);

% For each stream, the associated data is stored in the field ChannelData
% (AnalogStream), SegmentData (SegmentStream) or FrameData
% (FrameDataEntities of FrameStreams). This has already been converted from
% ADC units to more useful units such as Volts. The actual unit it
% represented in can be found for each Stream in the the Info structure in
% its fields Unit and Exponent (values 'V' and -9, respectively, mean that
% the data is stored in 10^-9 V). The time stamp associated with each
% sample is stored in {Channel,Frame,Segment}DataTimeStamps in microseconds

% Frame streams have to be treated in more detail, because they can lead to
% potentially very large data sets. They comprise samples from a 2D array
% of recording channels for a total of possibly several thousand channels.
% Because of this, it can be problematic to store the full data cube (time
% x channels_x x channels_y) in memory.
% If you know, which parts of the data you are interested in, you can also
% load just a small 'cuboid' (a 'hyperslab' in HDF5 terminology) to memory:
frameData = McsHDF5.McsData('2014.02.28-13.20.20-Rec.h5');
% Again, this loads only the metadata. If we would execute one of the
% following commands, the whole frame would be loaded:
% frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1}
% size(frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1}.FrameData)
% plot(frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1},[])
% plot(frameData,[]) 

% To avoid memory problems, you can load a region of interest as follows:
partialData = frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1}.readPartialFrame(time,channel_x,channel_y);
% where 'time', 'channel_x' and 'channel_y' are 2x1 vectors of [start end]
% indices. For 'time', these are given in seconds, for the channels these
% are channel indices. If any of these is an empty array, the whole
% dimension is used. partialFrame contains only the specified subregion.
% Plot functions still work on partial frames.

% Due to the high dimensionality, finding useful plotting functions for
% frame data with several thousand channels can be tricky. Three options
% are provided here:

% 3D-plot of a single slice through the frame, i.e. the amplitudes of all
% channels for a single time point
cfg = [];
cfg.window = 0.1; % 100 ms
plot(frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1},cfg);

% A 2D-array of line plots, each depicting the signal at each channel in a
% specified time range:
cfg = [];
cfg.window = [0.1 0.2]; % 100 ms to 200 ms
plot(frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1},cfg);

% EXPERIMENTAL
% A 'movie' of the 3D-plots 
cfg = [];
cfg.start = 0.1;
cfg.end = 0.2;
frameMovie(frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1},cfg);

% EXPERIMENTAL, ONLY USEFUL FOR SPIKE DATA, USES VERY SIMPLE SPIKE DETECTOR
% (THRESHOLD-BASED)
% Estimates firing rates for overlapping time segments for each channel and
% plots thier evolution over time.
scatterSpikeRates(frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1},[]);

% General note of caution for all users of the McsPyDataTools or people
% directly accessing HDF5 files: MATLAB changes the dimensions of the
% stored matrices, because it uses C-style ordering of dimensions in
% contrast to the FORTRAN-style ordering used in HDF5. For example, while
% the dimensions of FrameData are given in the HDF5 file as
% (channels_x,channels_y,time), reading this file into MATLAB will yield a
% FrameData matrix with dimensions (time,channels_y,channels_x). Please be
% careful about this!