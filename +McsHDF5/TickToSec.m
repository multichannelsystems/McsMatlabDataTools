function sec = TickToSec(tick)
% Converts tick in microseconds to seconds
%
% function sec = TickToSec(tick)
%
% Input:
%   tick     -   Time in microseconds
%
% Output:
%   sec    -   microseconds converted to seonds.

    sec = double(tick) * 1e-6;
end