function ts = SecToTimeStamp(sec)
% Converts seconds to time in units of 100 ns.
%
% function ts = SecToTimeStamp(sec)
%
% Input:
%   sec     -   Time in seconds
%
% Output:
%   ts    -   seconds converted to time in 100 ns.

    ts = sec * 1e7;
end