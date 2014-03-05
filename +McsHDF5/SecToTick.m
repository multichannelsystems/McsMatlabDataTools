function tick = SecToTick(sec)
% Converts seconds to tick in µs
%
% function tick = SecToTick(sec)
%
% Input:
%   sec     -   Time in seconds
%
% Output:
%   tick    -   seconds converted to µs.

    tick = sec * 1e6;
end