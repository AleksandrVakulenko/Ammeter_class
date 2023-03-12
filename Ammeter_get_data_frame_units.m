function [out_ch1, out_ch2] = Ammeter_get_data_frame_units(ammeter_obj, time_ms)
out_ch1 = [];
out_ch2 = [];

if ~isvalid(ammeter_obj)
    error('invalid ammeter handle');
end

Flags = ammeter_obj.show_flags();

if ~Flags.connected
    warning([ammeter_obj.get_name() ' disconnected']);
elseif ~Flags.sending
    warning([ammeter_obj.get_name() ' is not sending anything']);
else
    isOk = 0;
    while (numel(out_ch1) < time_ms) && isOk == 0
        [part_ch_1, part_ch_2, mode, res_cap, isOk] = ammeter_obj.read_data_units();
        out_ch1 = [out_ch1 part_ch_1];
        out_ch2 = [out_ch2 part_ch_2];
    end
    
end

end