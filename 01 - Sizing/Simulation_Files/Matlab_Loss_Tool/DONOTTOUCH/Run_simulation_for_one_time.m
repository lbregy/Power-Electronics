clear
clc
original_dir = pwd;
cd('..');  % Go to parent directory where .slx files are located
SIM.File = 'converter_2021b';     % Simulink file name   
open_system(SIM.File);
load (fullfile(original_dir, "DeviceLibrary_2026.mat"))          % All the specs for the semiconductors are stored here
%%%%%%%%%%%%%%%%%%%%%%
%    DAB DATA  
%%%%%%%%%%%%%%%%%%%%%%
CONV.U_out = 24;                      % [V]
CONV.f_sw  = 250e3;                   % [Hz]
CONV.L     = 1.2000e-05;              % [H]
CONV.C_out = 5.2357e-6;               % [F]
CONV.C_in  = 6.2500e-4;               % [F]
CONV.N_p   = 2;
CONV.N_s   = 1;
CONV.Deadtime = 50e-9;                % [s]
MOSF_types = [3, 3, 3, 3, 10, 10, 10, 10];
IGBT_types = [];  
DIOD_types = [];
%% === SINGLE OPERATING POINT ===
CONV.U_in  = 30;      % [V]  <-- choose value
CONV.P_out = 60;      % [W]  <-- choose value

%% Simulation Parameters
SIM.Time         = 5*1000/CONV.f_sw;
SIM.WindowLength = 100/CONV.f_sw;
SIM.Ts           = 1/(100*CONV.f_sw);
SIM.NOS          = round(SIM.WindowLength/SIM.Ts);

Sim_counter = 1;
tStart = tic;

%% Device setup
IGBT_types = [];
DIOD_types = [];
number_devices = [length(IGBT_types) length(MOSF_types) length(DIOD_types)];

for IG_Nr = 1:length(IGBT_types)
    IGBTs{IG_Nr}.Specs = DeviceLibrary.IGBT.type(IGBT_types(IG_Nr));
end

for MO_Nr = 1:length(MOSF_types)
    MOSFETs{MO_Nr}.Specs = DeviceLibrary.MOSFET.type(MOSF_types(MO_Nr));
end

for DI_Nr = 1:length(DIOD_types)
    DIODEs{DI_Nr}.Specs = DeviceLibrary.DIODE.type(DIOD_types(DI_Nr));
end

%% === Operating point calculations ===
CONV.I_out  = CONV.P_out / CONV.U_out;
CONV.R_load = CONV.U_out^2 / CONV.P_out;

syms phi
phi_sol = double(solve( ...
    CONV.P_out == ...
    (CONV.N_p/CONV.N_s)*CONV.U_in*CONV.U_out*phi*(pi-abs(phi)) ...
    /(CONV.L*2*pi^2*CONV.f_sw), phi));

phi_sol = phi_sol(phi_sol >= 0 & phi_sol <= pi/2);
CONV.Phase_PU = phi_sol(1)/(2*pi);

fprintf('Running single simulation\n');
fprintf('U_in:  %g V\n', CONV.U_in);
fprintf('P_out: %g W\n', CONV.P_out);

%% === Run simulation ONCE ===
options = simset( ...
    'Solver','ode45', ...
    'MaxStep',SIM.Ts, ...
    'InitialStep',SIM.Ts, ...
    'SrcWorkspace','current', ...
    'DstWorkspace','base');

NOS=SIM.NOS;
Ts =SIM.Ts;
sim(SIM.File, [0 SIM.Time], options);

%% === Store results ===
FileName = 'SIM_Nr1';

for IG_Nr = 1:number_devices(1)
    IGBTs{IG_Nr}.Data.(FileName) = eval(['SIM_IGBT' num2str(IG_Nr) '_Data']);
    clear(['SIM_IGBT' num2str(IG_Nr) '_Data'])
end

for MO_Nr = 1:number_devices(2)
    MOSFETs{MO_Nr}.Data.(FileName) = eval(['SIM_MOSFET' num2str(MO_Nr) '_Data']);
    clear(['SIM_MOSFET' num2str(MO_Nr) '_Data'])
end

for DI_Nr = 1:number_devices(3)
    DIODEs{DI_Nr}.Data.(FileName) = eval(['SIM_DIODE' num2str(DI_Nr) '_Data']);
    clear(['SIM_DIODE' num2str(DI_Nr) '_Data'])
end

fprintf('Simulation completed successfully\n');

%% Calculate Losses for all MOSFETs
fprintf('\n========================================\n');
fprintf('CALCULATING LOSSES\n');
fprintf('========================================\n');

for MO_Nr = 1:number_devices(2)
    FileName = 'SIM_Nr1';
    fprintf('\n--- MOSFET #%d ---\n', MO_Nr);
    
    % Get the loss function from RUN_Loss_Tool.m
    MOSFETs{MO_Nr}.Losses.(FileName) = MOSFET_losses_func_debug(MOSFETs{MO_Nr}.Specs, MOSFETs{MO_Nr}.Data.(FileName), MO_Nr);
    
    fprintf('P_Cond:  %.4f W\n', MOSFETs{MO_Nr}.Losses.(FileName).P_Cond);
    fprintf('P_SW:    %.4f W\n', MOSFETs{MO_Nr}.Losses.(FileName).P_SW);
    fprintf('P_Total: %.4f W\n', MOSFETs{MO_Nr}.Losses.(FileName).P_Total);
end

%% Plot results
fprintf('\n========================================\n');
fprintf('PLOTTING RESULTS\n');
fprintf('========================================\n');

% Plot voltage, current, and switching signals for first MOSFET
MO_Nr = 1;
Data = MOSFETs{MO_Nr}.Data.SIM_Nr1;
time_vec = (0:size(Data,1)-1) * SIM.Ts * 1e6;  % Time in microseconds

figure('Position', [100 100 1200 800]);

subplot(4,1,1);
plot(time_vec, Data(:,1), 'b', 'LineWidth', 1.5);
ylabel('Voltage [V]');
title(sprintf('MOSFET #%d - U_{in}=%.0fV, P_{out}=%.0fW', MO_Nr, CONV.U_in, CONV.P_out));
grid on;

subplot(4,1,2);
plot(time_vec, Data(:,2), 'r', 'LineWidth', 1.5);
ylabel('Current [A]');
grid on;

subplot(4,1,3);
plot(time_vec, Data(:,3), 'g', 'LineWidth', 1.5);
ylabel('S_{on} signal');
ylim([-0.1 1.1]);
grid on;

subplot(4,1,4);
plot(time_vec, Data(:,4), 'm', 'LineWidth', 1.5);
ylabel('S_{off} signal');
xlabel('Time [\mus]');
ylim([-0.1 1.1]);
grid on;

% Summary bar plot
figure('Position', [100 100 800 600]);
bar_data = [];
legend_labels = {};

for MO_Nr = 1:min(4, number_devices(2))  % Plot up to 4 MOSFETs
    Loss = MOSFETs{MO_Nr}.Losses.SIM_Nr1;
    bar_data = [bar_data; Loss.P_Cond, Loss.P_SW, Loss.P_Total];
    legend_labels{end+1} = sprintf('MOSFET %d', MO_Nr);
end

bar(bar_data);
ylabel('Power Loss [W]');
xlabel('MOSFET Number');
title(sprintf('Loss Breakdown - U_{in}=%.0fV, P_{out}=%.0fW', CONV.U_in, CONV.P_out));
legend({'Conduction', 'Switching', 'Total'});
grid on;

%% Loss calculation function with DEBUG outputs
function Loss = MOSFET_losses_func_debug(Specs, Data, MO_Nr)
    Son = Data(:,3);
    Soff = Data(:,4);
    Time = evalin('base','SIM.WindowLength');

    fprintf('\n  >> Data size: %d samples\n', size(Data,1));
    fprintf('  >> Time window: %.6f s\n', Time);
    fprintf('  >> Son: min=%.2f, max=%.2f, sum=%d\n', min(Son), max(Son), sum(Son));
    fprintf('  >> Soff: min=%.2f, max=%.2f, sum=%d\n', min(Soff), max(Soff), sum(Soff));
    
    % Voltages
    u = (Data(:,1) >= 0) .* Data(:,1);
    u_on = u .* circshift(Son,-1);
    u_off = u .* circshift(Soff,1);
    
    % Current 
    i  = Data(:,2);
    i_on = i  .* circshift(Son,1);
    i_off = i  .* circshift(Soff,-1);
    
    i_on = circshift(i_on,-2);
    i_off = circshift(i_off,2);
    
    fprintf('  >> u_on: nonzero samples = %d, max=%.2f V\n', sum(u_on~=0), max(u_on));
    fprintf('  >> u_off: nonzero samples = %d, max=%.2f V\n', sum(u_off~=0), max(u_off));
    fprintf('  >> i_on: nonzero samples = %d, max=%.4f A\n', sum(i_on~=0), max(abs(i_on)));
    fprintf('  >> i_off: nonzero samples = %d, max=%.4f A\n', sum(i_off~=0), max(abs(i_off)));
    
    if max(abs(i_on)) == 0 || max(abs(u_on)) == 0
        u_on = 0;
        i_on = 0;
        fprintf('  >> WARNING: i_on or u_on is all zeros!\n');
    end

    if max(abs(i_off)) == 0 || max(abs(u_off)) == 0
        u_off = 0;
        i_off = 0;
        fprintf('  >> WARNING: i_off or u_off is all zeros!\n');
    end

    %% Conduction losses
    i_during_on = i(Son == 1);
    if ~isempty(i_during_on)
        I_Rms_ON = rms(i_during_on);
    else
        I_Rms_ON = 0;
    end
    
    i_reverse_during_off = (Son == 0) & (i < 0);
    if any(i_reverse_during_off)
        I_Avg_reverse = abs(mean(i(i_reverse_during_off)));
    else
        I_Avg_reverse = 0;
    end

    fprintf('  >> I_Rms_ON = %.4f A\n', I_Rms_ON);
    fprintf('  >> I_Avg_reverse = %.4f A\n', I_Avg_reverse);
    fprintf('  >> R_dsOn = %.6f Ohm\n', Specs.R_dsOn);
    
    U_D0 = 0;
    P_Cond_Diode = 0;
    
    Loss.P_Cond = Specs.R_dsOn * I_Rms_ON^2 + U_D0 * I_Avg_reverse + P_Cond_Diode;
    
    fprintf('  >> P_Cond = %.6f W\n', Loss.P_Cond);

    %% Switching Losses
    tir = Specs.t_rI*i_on/Specs.I_test;
    tif = Specs.t_fI*i_off/Specs.I_test;
    tvf = (u_on-Specs.R_dsOn*i_on)*Specs.R_g*Specs.C_rss/(Specs.U_gP-Specs.U_miller);
    tvr = (u_off-Specs.R_dsOn*i_off)*Specs.R_g*Specs.C_rss/(Specs.U_miller-Specs.U_gN);
    
    % Turn-on losses
    Eir = 0.5*u_on.*i_on.*tir;
    Pir = sum(Eir)/Time;
    Evf = 0.5*u_on.*i_on.*tvf;
    Pvf = sum(Evf)/Time;
    P_on = Pir + Pvf;
    
    fprintf('  >> Pir = %.6f W, Pvf = %.6f W, P_on = %.6f W\n', Pir, Pvf, P_on);
    
    % Turn-off losses
    Eif = 0.5*u_off.*i_off.*tif;
    Pif = sum(Eif)/Time;
    Evr = 0.5*u_off.*i_off.*tvr;
    Pvr = sum(Evr)/Time;
    P_off = Pif + Pvr;
    
    fprintf('  >> Pif = %.6f W, Pvr = %.6f W, P_off = %.6f W\n', Pif, Pvr, P_off);
    
    % Reverse recovery losses 
    E_rr = Specs.Q_rr * u_on;
    P_rr = sum(E_rr)/Time;
    
    fprintf('  >> P_rr = %.6f W\n', P_rr);
       
    Loss.P_SW = P_on + P_off + P_rr;
    Loss.P_Total = Loss.P_SW + Loss.P_Cond;
    
    fprintf('  >> P_SW_TOTAL = %.6f W\n', Loss.P_SW);
end