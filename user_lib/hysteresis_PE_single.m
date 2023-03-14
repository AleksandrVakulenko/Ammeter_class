%FIXME: ADD SAMPLE STRUCT

function [E, P] = hysteresis_PE_single(ammeter_obj, Loop_opts, fig)
amp = Loop_opts.amp;
period = Loop_opts.period;
gain = Loop_opts.gain;
divider = Loop_opts.divider;

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
% relay_chV(obj, false); %undone
obj.set_wave_form_gen(0); %undone

obj.start_measuring();

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
    
    if draw_cmd
        cla
        plot(stream_ch1, stream_ch2, '-b', 'linewidth', 0.8);
        xlim([-amp*1.1 amp*1.1])
        drawnow
    end
    
    Flags = obj.show_flags;
end
if disconnect
    obj.disconnect();
end


E = stream_ch1;
P = stream_ch2;

end