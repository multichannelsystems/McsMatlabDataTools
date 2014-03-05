%% The McsHDF5 Matlab tools
% This document gives a short explanation of the usage of the McsHDF5
% Matlab tools.

%% Importing the package
% First, add the base path of the +McsHDF5 folder to your matlab path
%
%   addpath Path/To/+McsHDF5
%%
% Then import the package
%
%   import McsHDF5.*

%% Loading data
% As an example, lets load a data set with 2 analog streams, 1 event stream
% and 1 segment stream:
%
%   data = McsHDF5.McsData('DataSpikeAnalyzer.h5');

%%
% Up to this point, only the metadata has been read from the file. The
% actual data within the stream will be loaded as soon as you try to access
% the stream, for example in a plot function. The recorded data is
% organized as follows within the data structure:
%
% 
% * Top-level: General information and a cell array of McsRecording
% objects:
%
%   data

%%
% * Each recording is stored in its individual cell:
%
%   data.Recording{1}

%%
% * Each recording cell contains cell arrays of zero or more analog-,
% frame-, segment- and event-streams. The only exception is the frame
% stream which has additional sub-structures, the FrameDataEntities. If we
% access one of these streams (or a FrameDataEntity for FrameStreams), its
% data is loaded from the file:
%
%   data.Recording{1}.AnalogStream{1}

%% Units
% For each stream, the associated data is stored in the field ChannelData
% (AnalogStream), SegmentData (SegmentStream) or FrameData
% (FrameDataEntities of FrameStreams). These values have already been
% converted during loading from ADC units to more useful units such as
% Volts. The actual unit it is represented in can be found for each stream
% in the fields Unit and Exponent (values 'V' and -9, respectively, mean
% that the data is stored in $$ 10^{-9} $$ V) of its Info structure:
%
%   data.Recording{1}.AnalogStream{1}.Info.Unit{1}
%   data.Recording{1}.AnalogStream{1}.Info.Exponent(1)

%%
% The time stamp associated with each sample is stored in the field
% {Channel,Frame,Segment}DataTimeStamps in microseconds. Similarly, the
% time stamps of events in the EventStream are stored in microseconds as
% well.

%% Plotting the data
% Each stream has simple plot functions to allow a quick check whether the
% data is all right:
%
%   plot(data.Recording{1}.AnalogStream{1},[])
%   plot(data.Recording{1}.EventStream{1},[])
%   plot(data.Recording{1}.SegmentStream{1},[])

%%
% If for example the event stream and the segment streams have not been
% accessed before, their data is loaded during the execution of the
% respective plot function.
%
% Plot functions can also be executed at the recording or top level in
% order to get an overview over all streams in the recording, or even all
% streams in the data:
%
%   plot(data.Recording{1},[]);
%   plot(data,[]);

%%
% If the second parameter of the plot function is empty, the default
% parameters are used for plotting. Otherwise, one can specify
% configuration structures for more fine-grained plotting. For example, the
% following commands will plot channels 1 and 2 of the second analog
% stream:
%
%   cfg = [];
%   cfg.channels = [1 2];
%   plot(data.Recording{1}.AnalogStream{2},cfg);

%%
% Each plot function has its own set of options, so you need to check the
% individual help functions for the specifics:
%
%   help McsHDF5.McsEventStream.plot

%%
% You can specify these configuration options also in higher level plot
% functions to achieve the same thing:
%
%   cfg = [];
%   cfg.analog{2}.channels = [1 2];
%   plot(data.Recording{1},cfg);
%
%   cfg = [];
%   cfg.conf.analog{2}.channels = [1 2];
%   plot(data,cfg);

%%
% You can also specify additional options in the plot function. These are
% forwarded to the underlying MATLAB plotting functions. The following
% command produces a time series plot of the first analog stream with thick
% dashed red lines:
%
%   plot(data.Recording{1}.AnalogStream{1},cfg,'--r','LineWidth',5);

%% Frame streams
% Frame streams have to be treated in more detail, because they can lead to
% potentially very large data sets. They comprise samples from a 2D array
% of recording channels for a total of possibly several thousand channels.
% Because of this, it can be problematic to store the full data cube (time
% $$ \times $$ channels_y $$ \times $$ channels_x) in memory.
% If you know which parts of the data you are interested in, you can also
% load just a small 'cuboid' (a 'hyperslab' in HDF5 terminology) to memory:
%
% First, load just the metadata:
%
%   frameData = McsHDF5.McsData('2014.02.28-13.20.20-Rec.h5');

%%
% If we would execute one of the following commands, the whole frame would
% be loaded, which we want to avoid to save memory.
%
%   frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1}
%   size(frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1}.FrameData)
%   plot(frameData.Recording{1}.FrameStream{1}.FrameDataEntity{1},[])
%   plot(frameData,[]) 

%%
% To avoid memory problems, you can load a region of interest as follows:
%
%   cfg = [];
%   cfg.time = [0 0.5]; % 0 to 0.5 s
%   cfg.channel_x = [10 30]; % channel "rows" 10 to 30
%   cfg.channel_y = []; % all channel "columns"
%   partialData = frameData.Recording{1}.FrameStream{1}.FrameDataEntities{1}.readPartialFrame(cfg);

%%
% where 'time', 'channel_x' and 'channel_y' are 2x1 vectors of [start end]
% indices. For 'time', these are given in seconds, for the channels these
% are channel indices. If any of these is an empty array, the whole
% dimension is used. partialFrame contains only the specified subregion of
% the frame.

%% Plotting frame data
% Due to the high dimensionality, finding useful plotting functions for
% frame data with several thousand channels can be tricky. Three options
% are provided here:

%%
% 3D-plot of a single slice through the frame, i.e. the amplitudes of all
% channels for a single time point:
%
%   cfg = [];
%   cfg.window = 0.1; % 100 ms
%   plot(partialData,cfg);

%%
% A 2D-array of line plots, each depicting the signal at each channel in a
% specified time range:
%
%   cfg = [];
%   cfg.window = [0.1 0.2]; % 100 ms to 200 ms
%   plot(partialData,cfg);

%%
% A "movie" of the 3D-plots (*EXPERIMENTAL*):
%
%   clf
%   cfg = [];
%   cfg.start = 0.1;
%   cfg.end = 0.2;
%   frameMovie(partialData,cfg);

%%
% Estimates firing rates for overlapping time segments for each channel and
% plots their evolution over time (*EXPERIMENTAL*, only useful for spike
% data. Uses a very simple, threshold based spike detector):
%
%   scatterSpikeRate(partialData,[]);

%% Cautionary note on matrix dimensions
% General note of caution for all users of the McsPyDataTools or people
% directly accessing HDF5 files: MATLAB changes the dimensions of the
% stored matrices, because it uses C-style ordering of dimensions in
% contrast to the FORTRAN-style ordering used in HDF5. For example, while
% the dimensions of FrameData are given in the HDF5 file as (channels_x $$
% \times $$ channels_y $$ \times $$ time), reading this file into MATLAB
% will yield a FrameData matrix with dimensions (time $$ \times $$
% channels_y $$ \times $$ channels_x). 2D matrices will be transposed as
% well, so please be careful about transferring any functions from the
% McsPyDataTools to Matlab!