
function loop_opts = loop_options(varargin)
% options:
%   gain
%   period
%   amp
%

N = nargin;
if mod(N,2) ~= 0
    error('wrong number of arguments')
end

pred = string(varargin(1:2:end));
value_cell = varargin(2:2:end);

value = zeros(size(value_cell));
for i = 1:numel(value_cell)
    if ~isnumeric(value_cell{i})
       error(['non numeric value, in argument ' num2str(i*2)]);
    end
    value(i) = value_cell{i};
end


ind = find(pred == 'gain');
if ~isempty(ind)
    loop_opts.gain = value(ind);
else
    loop_opts.gain = 1;
    warning('default gain is set to 1')
end

ind = find(pred == 'divider');
if ~isempty(ind)
    loop_opts.divider = value(ind);
else
    loop_opts.divider = 1;
    warning('default divider is set to 1')
end

ind = find(pred == 'period');
if ~isempty(ind)
    loop_opts.period = value(ind);
else
    loop_opts.period = 1;
    warning('default period is set to 1 s')
end

ind = find(pred == 'amp');
if ~isempty(ind)
    loop_opts.amp = value(ind);
else
    loop_opts.amp = 1;
    warning('default amp is set to 1 V')
end

ind = find(pred == 'delay');
if ~isempty(ind)
    loop_opts.delay = value(ind);
else
    loop_opts.amp = 0.5; %s
    warning('default delay is set to 0.5 s')
end


end

