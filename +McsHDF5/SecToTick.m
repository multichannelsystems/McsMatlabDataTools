function tick = SecToTick(sec)
% Converts seconds to tick in microseconds
%
% function tick = SecToTick(sec)
%
% Input:
%   sec     -   Time in seconds
%
% Output:
%   tick    -   seconds converted to microseconds.

    tick = sec * 1e6;
end