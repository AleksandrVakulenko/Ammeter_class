%FIXME: add case to use non-numeric options
%NOTE: maybe new function with iteration parsing
%TODO: add choice of DWM or Single

function loop_opts = loop_options(varargin)
% options:
%   gain | amplifier gain
%   period | measuring period (for each part in case of DWM)
%   post | post period with zero voltage (after main wave gen)
%   amp |output amplitude
%   divider | voltage divider coefficient
%   delay | after measuring part in DWM
%   refnum | number of ref passes
%   init_pulse | 1 - on, 0 - off
%   voltage_ch | 1 - external, 0 - internal

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
    loop_opts.gain = 1; %[1]
    warning('default gain is set to 1')
end

ind = find(pred == 'divider');
if ~isempty(ind)
    loop_opts.divider = value(ind);
else
    loop_opts.divider = 1; %[1]
    warning('default divider is set to 1')
end

ind = find(pred == 'period');
if ~isempty(ind)
    loop_opts.period = value(ind);
else
    loop_opts.period = 1; %s
    warning('default period is set to 1 s')
end

ind = find(pred == 'post');
if ~isempty(ind)
    loop_opts.post_period = value(ind);
else
    loop_opts.post_period = 0; %s
    warning('default post period is set to 0 s')
end

ind = find(pred == 'amp');
if ~isempty(ind)
    loop_opts.amp = value(ind);
else
    loop_opts.amp = 1; %V
    warning('default amp is set to 1 V')
end

ind = find(pred == 'delay');
if ~isempty(ind)
    loop_opts.delay = value(ind);
else
    loop_opts.delay = 0.5; %s
    warning('default delay is set to 0.5 s')
end

ind = find(pred == 'refnum');
if ~isempty(ind)
    loop_opts.refnum = value(ind);
else
    loop_opts.refnum = 1;
    warning('default refnum is set to 1')
end

ind = find(pred == 'init_pulse');
if ~isempty(ind)
    loop_opts.init_pulse = value(ind);
else
    loop_opts.init_pulse = 1; % 1/0
    warning('init_pulse turned on')
end

ind = find(pred == 'voltage_ch');
if ~isempty(ind)
    loop_opts.voltage_ch = value(ind);
else
    loop_opts.voltage_ch = 0; % 1/0
    warning('voltage ch connected internaly')
end

loop_opts.name = 'feloop_opts';
end

