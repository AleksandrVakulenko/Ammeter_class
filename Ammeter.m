% (DONE)
% Update code in box CPU
% if (Analog_data_1 == 0x8000){
%   Analog_data_1 = 0x8001;
% }
% if (Analog_data_2 == 0x8000){
%   Analog_data_2 = 0x8001;
% }

% TODO:
%  1) create output voltage limits FUNCTION
%  2) add function send cmd: function(CMD_n, arg_high, arg_low) 
%  3) ADD double to binary converter (MAYBE NOT)
%  4) change isOk behavior to straight logic
%  5) 


% TODO user library:
%  1) Create library for user
%  2) Data2File export
%  3) Update README.md
%  4) Find real values of R&C
%  5) Create a new waveforms
%  6) 
%  7)

%CMD:
%  1) get handle pos      - DONE
%  2) ---(NOP)            - xxxx
%  3) set zero relay      - DONE
%  4) set sending flag    - DONE
%  5) Set amp and period  - DONE
%  6) Start measuring     - DONE
%  7) Set Output_flag     - xxxx output flag volatile behavior
%  8) Set DAC value       - DONE
%  9) RESET               - DONE
% 10) set V_ch relay      - DONE
% 11) set_wave_form_gen   - DONE

% To find all FIXME, TODO, NOTE use:
% dofixrpt('Ammeter.m','file') -> find notes in file
% dofixrpt(dir) -> find notes in all files in directory 'dir'

classdef Ammeter < handle
    %--------------------------------PUBLIC--------------------------------
    methods (Access = public)
        function obj = Ammeter(port_name, varargin)
            narginchk(1, 3);
            if nargin > 1 && ~isempty(varargin{1})
                name_in = varargin{1};
            else
                name_in = 'Yoyo';
            end
            close_all_ammeters();
            obj.name = char(name_in);
            obj.COM_port_str = char(port_name);
            port_name_check(obj.COM_port_str);
            disp(['"' obj.name '" Ammeter created at port: ' obj.COM_port_str]);
            if nargin > 2 && varargin{2} == "bias"
                disp(['Input bias correction in "' obj.name '"']);
                obj.bias_correction();
            end
        end
        
        function delete(obj)
            close(obj);
        end
        
        function connect(obj, varargin)
            narginchk(1, 2)
            if ~obj.Flags.connected
                obj.Serial_obj = serialport(obj.COM_port_str, 230400);
                obj.Flags.connected = true;
                if nargin == 2 && varargin{1} == "reset"
                    obj.RESET();
                elseif nargin == 2 && varargin{1} ~= "reset"
                    warning('wrong value of 2nd argument in connection()')
                end
                get_handle_position(obj);
                disp(['"' obj.name '" connected at port: ' obj.COM_port_str])
            else
                warning(['"' obj.name '" already connected at port: ' obj.COM_port_str]);
            end
        end
        
        function disconnect(obj)
            %FIXME: see flags ???
            if obj.Flags.connected
                obj.relay_zerocap(false);
                obj.voltage_set(0);
                obj.sending(false);
                obj.relay_chV(false)
                delete(obj.Serial_obj);
                obj.Flags.connected = false;
                disp(['Disconnecting "' obj.name '" at port: ' obj.COM_port_str])
            else
                warning(['Nothing to disconnect at ' obj.name]);
            end
        end
        
        function [V_ch1, V_ch2, isOk] = read_data(obj)
            V_ch1 = [];
            V_ch2 = [];
            isOk = 0;
            if ~obj.Flags.connected
                warning([obj.name ' disconnected'])
                isOk = -1;
            elseif ~obj.Flags.sending
                warning([obj.name ' is not sending anything'])
                isOk = -2;
            else
                [Temp_data, timeout_flag] = obj.get_bytes();
                if timeout_flag
                    warning('data recive timeout')
                    isOk = -3;
                end
                [V_ch1, V_ch2, CMD] = unpack_raw_bytes(Temp_data);
                V_ch1 = V_ch1 - obj.Analog.bias.ch1;
                V_ch2 = V_ch2 - obj.Analog.bias.ch2;
                if CMD.flag
                    if CMD.high == 2 && CMD.low == 0
                        % NOTE: message disabled
                        %disp('Measuring stopped')
                        obj.Flags.sending = false;
                    end
                end
            end
        end
        
        function [ch1, ch2, mode, res_cap, isOk] = read_data_units(obj)
            [V_ch1, V_ch2, isOk] = read_data(obj);
            res_cap = struct('res', obj.Analog.res, 'cap', obj.Analog.cap);
            gain_div = obj.Analog.gain_div;
            ch1 = V_ch1*gain_div;
            if obj.Analog.res == -1 && obj.Analog.cap == -1
                mode = "off";
                ch2 = V_ch2;
            end
            if obj.Analog.res ~= -1 && obj.Analog.cap ~= -1
                mode = "mix";
                ch2 = V_ch2;
            end
            if obj.Analog.res == -1 && obj.Analog.cap ~= -1
                mode = "cap";
                ch2 = V_ch2*obj.Analog.cap;
            end
            if obj.Analog.res ~= -1 && obj.Analog.cap == -1
                mode = "res";
                ch2 = V_ch2/obj.Analog.res;
            end
            
        end
        
        function bias_correction(obj)
            [ch1_mean, ch2_mean] = Ammeter_bias_measure(obj);
            obj.Analog.bias.ch1 = obj.Analog.bias.ch1 + ch1_mean;
            obj.Analog.bias.ch2 = obj.Analog.bias.ch2 + ch2_mean;
        end
        
        %-------------------------------CMD---------------------------------
        function sending(obj, flag)
            if obj.Flags.connected
                if ~obj.Flags.sending
                    get_handle_position(obj);
                end
                flag = logical(flag);
                obj.send_cmd(uint8([4 0 flag 0 0]));
                obj.Flags.sending = flag;
                if ~flag
                    serial_flush(obj.Serial_obj);
                end
            else
                warning(['CMDsending == ' num2str(flag) ' ignored'])
            end
        end
       
%         function output_flag(obj, flag)
%             if obj.Flags.connected
%                 if ~obj.Flags.sending
%                    get_handle_position(obj); 
%                 end
%                 flag = logical(flag);
%                 obj.send_cmd(uint8([7 0 flag 0 0]));
%                 obj.Flags.output = flag; %VOLATILE!!!!
%             else
%                 warning(['CMD(output_flag == ' num2str(flag) ') ignored'])
%             end
%         end
        
        function relay_chV(obj, flag)
            if obj.Flags.connected
                flag = logical(flag);
                obj.Flags.relay_chV = flag;
                obj.send_cmd(uint8([10 0 flag 0 0]));
            else
                warning(['CMD relay_chV == ' num2str(flag) ' ignored'])
            end
        end
        
        function relay_zerocap(obj, flag)
            if obj.Flags.connected
                flag = logical(flag);
                obj.Flags.relay_zerocap = flag;
                obj.send_cmd(uint8([3 0 flag 0 0]));
            else
                warning(['CMD relay_zerocap == ' num2str(flag) ' ignored'])
            end
        end
        
        function voltage_set(obj, voltage)
            %FIXME: global V limit check here
            gain = obj.Analog.gain;
            voltage_out = voltage/gain;
            if voltage_out > 10
                warning(['Output voltage limited by 10 V from ' num2str(voltage_out) ' V'])
                voltage_out = 10;
            end
            if voltage_out < -10
                warning(['Output voltage limited by -10 V from ' num2str(voltage_out) ' V'])
                voltage_out = -10;
            end
            if obj.Flags.connected
                [byte_high, byte_low, voltage_out] = voltage2bitcode(voltage_out);
                obj.Analog.voltage_out = voltage_out;
                obj.send_cmd(uint8([8 byte_high byte_low 0 0]));
            else
                warning(['CMD voltage_set == ' num2str(voltage) ' ignored']);
            end
        end
        
        function start_measuring(obj)
            if obj.Flags.connected
                obj.send_cmd(uint8([6 0 0 0 0]));
                obj.Flags.sending = true;
                pause(1.3); %NOTE: same as in avr side
            else
                warning('CMD start_measuring ignored')
            end
        end
        
        function set_amp_and_period(obj, amp, period)
            %FIXME: global V limit check here
            gain = obj.Analog.gain;
            amp_out = amp/gain;
            if amp_out > 10
                warning(['Output amplitude limited by 10 V from ' num2str(amp_out) ' V'])
                amp_out = 10;
            end
            if amp_out < -10
                warning(['Output amplitude limited by -10 V from ' num2str(amp_out) ' V'])
                amp_out = -10;
            end
            if obj.Flags.connected
                [v_byte_high, v_byte_low, voltage] = voltage2bitcode(amp_out); %V
                [p_byte_high, p_byte_low, period] = period2bitcode(period); %s
                obj.send_cmd(uint8([5 v_byte_high v_byte_low p_byte_high p_byte_low]));
                obj.Analog.Amplitude = voltage;
                obj.Analog.Period = period;
            else
                warning(['CMD set_amp_and_period ' num2str(amp) ...
                         ', ' num2str(period) ' ignored'])
            end
        end
        
        function set_wave_form_gen(obj, wave_form)
            if obj.Flags.connected && ~~sum(wave_form == [0, 1, 2])
                obj.send_cmd(uint8([11 0 wave_form 0 0]));
                obj.Analog.Waveform = wave_form;
            else
                warning(['CMD set_wave_form_gen == ' num2str(wave_form) ' ignored'])
            end
        end
        
        function [R, C] = get_handle_position(obj)
            R = -1;
            C = -1;
            if ~obj.Flags.connected
                warning('Could not get handle position: ammeter disconnected')
            elseif ~obj.Flags.sending
                serial_flush(obj.Serial_obj);
                obj.send_cmd(uint8([1 0 0 0 0]));
                [Data, timeout_flag] = obj.get_bytes();
                if timeout_flag
                    warning('receive timeout (in get_handle_position)')
                else
                    [R, C] = get_rc(Data);
                    obj.Analog.res = R;
                    obj.Analog.cap = C;
                end
            else
                warning('Could not get handle position: ammeter is sending data now')
            end
        end
        %----------------------------CMD_END--------------------------------
        
        %----------------------------Getters--------------------------------
        function varargout = show_flags(obj)
            if nargout == 1
                varargout{1} = obj.Flags;
            elseif nargout == 0
                disp(obj.Flags)
            else
                warning('wrong number of output arguments (show_flags)')
            end
        end
        
        function varargout = show_analog(obj)
            if nargout == 1
                varargout{1} = obj.Analog;
            elseif nargout == 0
                disp(obj.Analog)
            else
                warning('wrong number of output arguments (show_analog)')
            end
        end
        
        function set_gain(obj, gain_amp, gain_div)
            if gain_amp < 0 || gain_amp > 10000
                msg = ['Wrong gain_amp settings (ignoreg):' newline ...
                    'input value: ' num2str(gain_amp) newline ...
                    'current value: ' num2str(obj.Analog.gain)];
                warning(msg)
            else
                obj.Analog.gain = gain_amp;
            end

            if gain_div < 0 || gain_div > 10000
                msg = ['Wrong gain_div settings (ignoreg):' newline ...
                    'input value: ' num2str(gain_div) newline ...
                    'current value: ' num2str(obj.Analog.gain_div)];
                warning(msg)
            else
                obj.Analog.gain_div = gain_div;
            end
        end
        
        function name = get_name(obj) %FIXME unused
            name = obj.name;
        end
        %--------------------------Getters_END------------------------------
    end
    
    %-------------------------------PRIVATE--------------------------------
    properties (Access = private)
        name = '';
        COM_port_str = '';
        Serial_obj = [];
        pause_after_reset = 0.5;
        
        Wait_data_timeout = 1; %s
        
        Flags = struct('sending', false, ...
                       'connected', false, ...
                       'relay_chV', false, ...
                       'relay_zerocap', false);
        
        Analog = struct('bias', struct('ch1', -0.0021, 'ch2', -3.8772e-04), ...
                        'voltage_out', 0, ...
                        'Amplitude', 0, ...
                        'Period', 2, ...
                        'Waveform', 0,...
                        'gain', 1, ...
                        'gain_div', 1, ...
                        'res', -1, ...
                        'cap', -1);
        
    end
    
    methods (Access = private)
        function close(obj)
            if obj.Flags.connected
                obj.disconnect();
            end
            disp(['"' obj.name '" Ammeter closed']);
        end
        
        function send_cmd(obj, CMD)
            write(obj.Serial_obj, uint8(CMD), "uint8");
            pause(0.012);
        end
        
        function RESET(obj) %RESET CMD
            send_cmd(obj, uint8([9 0 0 0 0]));
            pause(obj.pause_after_reset);
        end
        
        
        function [Data, timeout_flag] = get_bytes(Obj)
            serial_obj = Obj.Serial_obj;
            Wait_timeout = Obj.Wait_data_timeout;
            timeout_flag = 0;
            stop = 0;
            Time_start = tic;
            while ~stop
                Bytes_count = serial_obj.NumBytesAvailable;
                Bytes_count = floor(Bytes_count/4)*4;
                
                if Bytes_count > 0
                    Data = read(serial_obj, Bytes_count, "uint8");
                    stop = 1;
                end
                
                Time_now = toc(Time_start);
                if Time_now > Wait_timeout
                    stop = 1;
                    timeout_flag = 1;
                    Data = 0;
                end
            end
        end
    end
end


function [R, C] = get_rc(Data)
Data = Data(4);
Cind = bitand(Data, 0b1111) + 1;
Rind = bitshift(Data, -4) + 1;
R_array = [5e9 ,50e6, 510e3, 5.5e3, 400, -1]; %Ohm
C_array = [-1, 10e-12, 100e-12, 1e-9, 100e-9, 10e-6]; %F
R = R_array(Rind);
C = C_array(Cind);
end

function port_name_check(port_name)

Avilable_ports = serialportlist('available');

if ~(sum(Avilable_ports == port_name) == 1)
    Text_ports_list = '';
    for i = 1:numel(Avilable_ports)
        Text_ports_list = [Text_ports_list char(Avilable_ports(i)) newline];
    end
    
    msg = ['ERROR: No such com port name.' newline ...
        'List of avilable ports:' newline ...
        Text_ports_list ...
        'Provided name: ' port_name];
    error(msg)
end

end

function serial_flush(serial_obj)
pause(0.05) %FIXME: why pause?
Bytes_count = serial_obj.NumBytesAvailable;
if Bytes_count > 0
    read(serial_obj, Bytes_count, "uint8");
end
end

function [Value_X, Value_Y, CMD] = unpack_raw_bytes(Data_all)
Bytes_01 = Data_all(1:4:end);
Bytes_02 = Data_all(2:4:end);
Bytes_03 = Data_all(3:4:end);
Bytes_04 = Data_all(4:4:end);
% disp([Bytes_03(1) Bytes_04(1)])%FIXME delete

CMD_ind = find((Bytes_01 == 0x80) & (Bytes_02 == 0x00));
if CMD_ind
    CMD.flag = true;
    CMD.high = Bytes_03(CMD_ind);
    CMD.low = Bytes_04(CMD_ind);
    Bytes_01(CMD_ind) = [];
    Bytes_02(CMD_ind) = [];
    Bytes_03(CMD_ind) = [];
    Bytes_04(CMD_ind) = [];
else
    CMD.flag = false;
    CMD.high = 0;
    CMD.low = 0;
end

Bytes_01(Bytes_01>=128) = Bytes_01(Bytes_01>=128) - 256;
Bytes_03(Bytes_03>=128) = Bytes_03(Bytes_03>=128) - 256;

Value_X = (Bytes_01*256 + Bytes_02)*10/2^15;
Value_Y = (Bytes_03*256 + Bytes_04)*10/2^15;
end

function close_all_ammeters()
input_class_name = 'Ammeter';
baseVariables = evalin('base' , 'whos');
Indexes = string({baseVariables.class}) == input_class_name;
Var_names = string({baseVariables.name});
Var_names = Var_names(Indexes);
Valid = zeros(size(Var_names));
for i = 1:numel(Var_names)
    Valid(i) = evalin('base', ['isvalid(' char(Var_names(i)) ')']);
end
Valid = logical(Valid);
Var_names = Var_names(Valid);
for i = 1:numel(Var_names)
    evalin('base', ['delete(' char(Var_names(i)) ')']);
end
end

function [ch1_mean, ch2_mean] = Ammeter_bias_measure(obj)
Measuring_period = 1; %s
Flags = obj.show_flags;

if ~Flags.connected
    obj.connect('reset');
else
    obj.disconnect();
    pause(0.01);
    obj.connect('reset');
end

obj.voltage_set(0);
obj.relay_chV(false);
obj.relay_zerocap(false);

stream_ch1 = [];
stream_ch2 = [];

obj.sending(1);
timer = tic;
while toc(timer) < Measuring_period
    [part_ch_1, part_ch_2, ~] = obj.read_data();
    stream_ch1 = [stream_ch1 part_ch_1];
    stream_ch2 = [stream_ch2 part_ch_2];
end
obj.sending(false);
obj.disconnect();

ch1_mean = mean(stream_ch1);
ch2_mean = mean(stream_ch2);
end

function [byte_high, byte_low, voltage] = voltage2bitcode(voltage)
high_limit = 10 - 1/2^16;
low_limit = -10;
if voltage > high_limit
    voltage = high_limit;
end
if voltage < low_limit
    voltage = low_limit;
end

bitcode = int16(floor(32768*voltage/10));


bit_set_low = bitget(bitcode, 8:-1:1);
byte_low = uint8(bi2de(flip(bit_set_low)));

bit_set_high = bitget(bitcode, 16:-1:9);
byte_high = uint8(bi2de(flip(bit_set_high)));

end

function [byte_high, byte_low, period] = period2bitcode(period) %s
high_limit = 60;
low_limit = 0.1;
if period > high_limit
    period = high_limit;
end
if period < low_limit
    period = low_limit;
end

Sample_period = 1; % ms
Tick_count = period*1000/Sample_period;

bit_set_low = bitget(Tick_count, 8:-1:1);
byte_low = uint8(bi2de(flip(bit_set_low)));
bit_set_high = bitget(Tick_count, 16:-1:9);
byte_high = uint8(bi2de(flip(bit_set_high)));
end




