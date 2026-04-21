% Ammeter connection
available_ports = serialportlist("available");
COM_port = 'COM4';
ammeter = Ammeter('COM4');
%%

% Set amplitude and period
amplitede = 5;
period = 2;
ammeter.set_amp_and_period(amplitede,period);

% Set waveform signal
% 0 - up and down, 1 - up, 2 - down
ammeter.set_wave_form_gen(0);

% Get data

ammeter.start_measuring();
data_ch1 = [];
data_ch2 = [];
measuring_time = 4;
tic
while toc < measuring_time
    [ch1, ch2] = ammeter.read_data();
    data_ch1 = [data_ch1 ch1];
    data_ch2 = [data_ch2 ch2];
end
time = tic - toc;
plot(data_ch1)
%%
% Ammeter disconnection
ammeter.terminate
delete(ammeter)
disp('Ammeter termitane')