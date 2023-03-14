


warning on all
warning on backtrace
warning off verbose



%%

obj = Ammeter("COM3", [], 'bias');
% obj = Ammeter("COM3", []);
obj.set_gain(1, 1);


obj.connect();
relay_chV(obj, true);
pause(0.5)
relay_chV(obj, false);
%%

clc

obj = Ammeter("COM3", 'nyan');
obj.connect();

obj.voltage_set(1);

obj.sending(true);
pause(0.5);
% [ch_1, ch_2, isOk] = obj.read_data();
[ch1, ch2, mode, res_cap, isOk] = obj.read_data_units();
mean(ch1)
mean(ch2)
mode
res_cap
isOk
obj.sending(false);




obj.disconnect();





%% -10V testing
clc

obj = Ammeter("COM3", 'nyan');
obj.connect();

Volt_list = [-9.7:-0.1:-10 0];
Volt_out = zeros(size(Volt_list));

for i = 1:numel(Volt_list)
obj.voltage_set(Volt_list(i));

obj.sending(true);
pause(0.5);
[part_ch_1, part_ch_2, isOk] = obj.read_data();
obj.sending(false);
Volt_out(i) = mean(part_ch_1);

disp([num2str(Volt_list(i), '%+08.4f'), ' : ', num2str(Volt_out(i), '%+08.4f')]);
end

obj.disconnect();






%% Amp and Period test
clc

obj = Ammeter("COM3", 'nyan');
obj.connect();
relay_chV(obj, false);
obj.set_gain(20, 20);
obj.set_amp_and_period(50, 10);
obj.set_wave_form_gen(1);
obj.start_measuring();

obj.show_analog();

fig_main = figure;
hold on
    
stream_ch1 = [];
stream_ch2 = [];

Flags = obj.show_flags;

timer = tic;
pause(1)
while toc(timer) < 20 && Flags.sending

% [part_ch_1, part_ch_2, isOk] = obj.read_data();
[part_ch_1, part_ch_2, mode, res_cap, isOk] = obj.read_data_units();

stream_ch1 = [stream_ch1 part_ch_1];
stream_ch2 = [stream_ch2 part_ch_2];

cla
% plot(stream_ch1, '-r', 'linewidth', 0.8);
% plot(stream_ch2, '-b', 'linewidth', 0.8);
plot(stream_ch1, stream_ch2, '-b', 'linewidth', 0.8);
% ylim([-0.01 0.01])
drawnow

Flags = obj.show_flags;
end

obj.disconnect();


%% Get Frame with specific duration
clc

obj = Ammeter("COM3", 'nyan');

% obj.show_flags()

obj.connect();
relay_chV(obj, true);
obj.sending(1);
pause(0.1);
obj.relay_zerocap(true);
pause(0.6);
obj.relay_zerocap(false);

[ch_V, ch_I] =  Ammeter_get_data_frame(obj, 2000);

obj.sending(0);
obj.relay_zerocap(false);
relay_chV(obj, false);
obj.disconnect();

figure
hold on
plot(ch_V, '-r', 'linewidth', 0.8)
plot(ch_I, '-b', 'linewidth', 0.8)





%% get data in real-time

clc


obj = Ammeter("COM3", [], 'bias');
% obj = Ammeter("COM3", []);
obj.set_gain(1, 1);


obj.connect();
relay_chV(obj, false);
% obj.sending(1);
% obj.relay_zerocap(true);
obj.voltage_set(1);

obj.start_measuring();

fig_main = figure;
hold on
    
stream_ch1 = [];
stream_ch2 = [];

Flags = obj.show_flags;

timer = tic;
pause(1)
while toc(timer) < 5 && Flags.sending

[part_ch_1, part_ch_2, isOk] = obj.read_data();

stream_ch1 = [stream_ch1 part_ch_1];
stream_ch2 = [stream_ch2 part_ch_2];

cla
plot(stream_ch1, '-r', 'linewidth', 0.8);
plot(stream_ch2, '-b', 'linewidth', 0.8);
% ylim([-0.01 0.01])
drawnow

Flags = obj.show_flags;
end


% obj.relay_zerocap(false);
obj.sending(0);
relay_chV(obj, false);
obj.disconnect();


%% get data in real-time

clc


obj = Ammeter("COM3", [], 'bias');
% obj = Ammeter("COM3", []);
obj.set_gain(1, 1);


obj.connect();
relay_chV(obj, false);
obj.sending(1);
obj.relay_zerocap(true);
% obj.voltage_set(0);


fig_main = figure;
hold on
    
stream_ch1 = [];
stream_ch2 = [];

Flags = obj.show_flags;

timer = tic;
while toc(timer) < 2

[part_ch_1, part_ch_2, isOk] = obj.read_data();

stream_ch1 = [stream_ch1 part_ch_1];
stream_ch2 = [stream_ch2 part_ch_2];

cla
plot(stream_ch1, '-r', 'linewidth', 0.8);
plot(stream_ch2, '-b', 'linewidth', 0.8);
% ylim([-0.01 0.01])
ylim([-10 10])
drawnow

Flags = obj.show_flags;
end

obj.relay_zerocap(false);
obj.sending(0);
relay_chV(obj, false);
obj.disconnect();

%%



clc


obj = Ammeter("COM3", 'pig');

% obj.show_analog;


obj.connect();
obj.relay_chV(true);

% obj.voltage_set(-9);
% pause(3);

obj.sending(true);
[ch_V, ~] =  Ammeter_get_data_frame(obj, 100);
obj.sending(false);
Value = mean(ch_V);

disp(num2str(Value, '%+08.4f'))

% std(ch_V)

% obj.show_analog;

% obj.sending(true);
% pause(0.1);
% obj.sending(false);

% while 1
%     obj.get_handle_position();
%     pause(0.4)
% end

obj.disconnect();

%%


Vin = [8.915 7.923 6.934 5.944 3.961 -1.9845 -3.968];
Vout = [8.9293 7.9360 6.9449 5.9523 3.9657 -1.9872 -3.9734];

plot(Vin, Vout-Vin)

%%



clc
obj = Ammeter("COM3", 'nyan', 'bias');
obj.connect();

obj.relay_zerocap(false);
relay_chV(obj, false);

Volt_array = -10:0.25:10;
Volt_out = zeros(size(Volt_array));
for i = 1:numel(Volt_array)
disp([num2str(i) ' ' num2str(numel(Volt_array))])
obj.voltage_set(Volt_array(i));
pause(0.05)

obj.sending(true);
[ch_V, ~] =  Ammeter_get_data_frame(obj, 80);
obj.sending(false);
%[~, ~, ~] = obj.read_data();

Volt_out(i) = mean(ch_V);
end

obj.voltage_set(0);
relay_chV(obj, false);
obj.disconnect();




%%

Linear_data =  1.001*Volt_array - 0.000105;

% plot(Volt_array, Volt_out-Linear_data)
plot(Volt_array, Volt_out-Volt_array)

%%
hold on
plot(Volt_array,'-x')
plot(Volt_out,'-x')


%% warning test

clc

obj = Ammeter("COM3")

obj.bias_correction()

obj.disconnect()

obj.read_data()

obj.read_data_units()

obj.sending(false)

obj.relay_chV(false)

obj.relay_zerocap(false)

obj.voltage_set(2)

obj.start_measuring()

obj.set_amp_and_period(1,1)

obj.set_wave_form_gen(0)

obj.get_handle_position()

obj.show_flags()

obj.show_analog()

obj.set_gain(2, 2)

obj.get_name()






