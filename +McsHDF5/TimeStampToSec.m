function factor = TimeStampToSec(ts)
    % Converts time stamps in 100 ns to seconds
    factor = double(ts) * 1e-7;
end