function print(s)
% Helper function to print strings on the Matlab command line. Respects the
% McsHDF5.verbosity setting.
%
% function print(s)
%
% Input:
%   s       -   (string) string to print
%
% (c) 2019 by Multi Channel Systems MCS GmbH
    global McsHDF5_verbosity
    
    if isempty(McsHDF5_verbosity)
        McsHDF5.verbosity('quiet')
    end
    
    if ~strcmp(McsHDF5_verbosity, 'quiet')
        fprintf(s)
    end