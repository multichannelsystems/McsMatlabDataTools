function verbosity(level)
% Set the verbosity level of print commands of the toolbox. 
%
% function verbosity(level)
%
% Input:
%   level       -   (string) The verbosity level, either 'verbose' or
%                   'quiet' (default).
%
% (c) 2019 by Multi Channel Systems MCS GmbH
    global McsHDF5_verbosity
    
    if ~strcmp(level, 'verbose') && ~strcmp(level, 'quiet')
        error('Only verbose and quiet are allowed as verbosity levels!')
    end
    
    McsHDF5_verbosity = level;
    