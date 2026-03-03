%% ADD DEVICES to the library

MO_Nr  = 10 ;
if  isfinite(MO_Nr)
    DeviceLibrary.MOSFET.type(MO_Nr).Name = 'IRLB8743PbF';
    DeviceLibrary.MOSFET.type(MO_Nr).R_dsOn = 4e-3; % [Ohm] Switch on-state resistance @ 125°C
    DeviceLibrary.MOSFET.type(MO_Nr).C_rss = 600e-12 ; % [F]   Gate-drain capacitance when off
    DeviceLibrary.MOSFET.type(MO_Nr).I_test = 32 ; % [A]   Switch test current from datasheet  
    DeviceLibrary.MOSFET.type(MO_Nr).R_g = 1.8 ;  % [Ohm] Total gate resistance (Rg + Rg_ext)
    DeviceLibrary.MOSFET.type(MO_Nr).t_rI = 92e-9; % [s]   Current rise time from datasheet
    DeviceLibrary.MOSFET.type(MO_Nr).t_fI = 36e-9 ; % [s]   Current fall time from datasheet    
    DeviceLibrary.MOSFET.type(MO_Nr).U_gN = 0; % [V]   Gate-driver negative voltage
    DeviceLibrary.MOSFET.type(MO_Nr).U_gP = 4.5; % [V]   Gate-driver positive voltage
    DeviceLibrary.MOSFET.type(MO_Nr).U_miller = 3 ; % [V]   Miller plateau voltage 
    DeviceLibrary.MOSFET.type(MO_Nr).Q_rr = 74e-9; % % [C]   MOSFET body-diode reverse Reverse Recovery Charge 
    DeviceLibrary.MOSFET.type(MO_Nr).U_D = 1.0;    % [V] body diode forward voltage drop 
end

% DI_Nr = 5;
% if  isfinite (DI_Nr)
%     DeviceLibrary.DIODE.type(DI_Nr).Name = 'MBR10100G';
%     DeviceLibrary.DIODE.type(DI_Nr).R_dsOn = 0.0025;    % [Ohm] Switch on-state resistance @ 125°C
%     DeviceLibrary.DIODE.type(DI_Nr).U_D0 = 0 ;          % [V]   Diode forward voltage
% end