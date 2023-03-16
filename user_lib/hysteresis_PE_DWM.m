%FIXME: ADD SAMPLE STRUCT

function feloop = hysteresis_PE_DWM(ammeter_obj, Loop_opts, fig)
amp = Loop_opts.amp;
period = Loop_opts.period;
gain = Loop_opts.gain;
divider = Loop_opts.divider;
delay = Loop_opts.delay; %s
init_pulse = Loop_opts.init_pulse;
voltage_ch = Loop_opts.voltage_ch;

obj = ammeter_obj;
Flags = obj.show_flags;
if ~Flags.connected
    disconnect = true;
    obj.connect();
else
    disconnect = false;
end

obj.set_gain(gain, divider);
obj.set_amp_and_period(amp, period);

switch voltage_ch
    case 1
        relay_chV(obj, true);
    case 0
        relay_chV(obj, false);
    otherwise
        obj.disconnect();
        error('Wrong "voltage_ch" value in Loop_options')
end


if fig == 0 
    draw_cmd = true;
    figure
else
    draw_cmd = false;
end

if class(fig) == "matlab.ui.Figure"
    figure(fig)
    draw_cmd = true;
end

switch init_pulse
    case 1
        obj.set_wave_form_gen(2);
        measure_part(obj, draw_cmd, amp);
        pause(delay)
    case 0
        % nothing to do here
    otherwise
        obj.disconnect();
        error('Wrong "init_pulse" value in Loop_options')
end

obj.set_wave_form_gen(1);
[E_part, P_part] = measure_part(obj, draw_cmd, amp);
feloop.init.E.p = E_part;
feloop.init.P.p = P_part;
pause(delay)

obj.set_wave_form_gen(1);
[E_part, P_part] = measure_part(obj, draw_cmd, amp);
feloop.ref.E.p = E_part;
feloop.ref.P.p = P_part;
pause(delay)

obj.set_wave_form_gen(2);
[E_part, P_part] = measure_part(obj, draw_cmd, amp);
feloop.init.E.n = E_part;
feloop.init.P.n = P_part;
pause(delay)

obj.set_wave_form_gen(2);
[E_part, P_part] = measure_part(obj, draw_cmd, amp);
feloop.ref.E.n = E_part;
feloop.ref.P.n = P_part;

if disconnect
    obj.disconnect();
end




end



function [E_part, P_part] = measure_part(obj, draw_cmd, amp)

obj.start_measuring();

stream_ch1 = [];
stream_ch2 = [];

Flags = obj.show_flags;
% timer = tic;
while Flags.sending
%     toc(timer)

    [part_ch_1, part_ch_2, mode, res_cap, isOk] = obj.read_data_units();
    %FIXME check mode
    if isOk == 0
        stream_ch1 = [stream_ch1 part_ch_1];
        stream_ch2 = [stream_ch2 part_ch_2];
    end
    
    % y-units
    switch mode
        case "res"
            y_unit = "I, A";
        case "cap"
            y_unit = "q, C";
        case "mix"
            y_unit = "volts, V";
        case "off"
            y_unit = "volts, V";
    end

    if draw_cmd
        cla
        plot(stream_ch1, stream_ch2, '-b', 'linewidth', 0.8);
        xlim([-amp*1.1 amp*1.1]);
        xlabel('voltage, V');
        ylabel(y_unit);
        drawnow
    end
    
    Flags = obj.show_flags;
end

E_part = stream_ch1;
P_part = stream_ch2;

% afterdelay = 1000; %ms
% obj.sending(true);
% [out_ch1, out_ch2] = Ammeter_get_data_frame_units(obj, afterdelay);
% E_part = [E_part out_ch1];
% P_part = [P_part out_ch2];
% obj.sending(false);
% 
% if draw_cmd
%     cla
%     plot(E_part, P_part, '-b', 'linewidth', 0.8);
%     xlim([-amp*1.1 amp*1.1])
%     drawnow
%     pause(0.2)
% end

end









