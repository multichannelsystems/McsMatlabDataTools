function sec = TimeStampToSec(ts)
% Converts time stamps in 100 ns to seconds
%
% function sec = TimeStampToSec(ts)
%
% Input:
%   ts     -   Time in units of 100 ns
%
% Output:
%   sec    -   100 ns converted to seonds.

    sec = double(ts) * 1e-7;
end