%FIXME: add after delay
%FIXME: create sample struct
%FIXME: add chv relay option
%FIXME: add waveform option
%FIXME: figure hold on in DWM

clc

Loop_opts = loop_options('amp', 2600, 'period', 20, 'gain', 1000);

ammeter_obj = Ammeter('COM3');


ammeter_obj.connect();
ammeter_obj.relay_chV(true);

fig = figure;
[x, y] = hysteresis_PE_single(ammeter_obj, Loop_opts, fig);

ammeter_obj.disconnect()



%%



clc

Loop_opts = loop_options('amp', 3000, 'period', 15, 'gain', 1000);

ammeter_obj = Ammeter('COM3');


ammeter_obj.connect();
ammeter_obj.relay_chV(true);

fig = figure;
feloop = hysteresis_PE_DWM(ammeter_obj, Loop_opts, fig);

ammeter_obj.disconnect();


































