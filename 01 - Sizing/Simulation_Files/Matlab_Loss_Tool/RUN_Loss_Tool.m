%% Loss calculation
% Only change necessary stuff
% Note: it is necessary to have PLECS Blockset package installed and launch
% it
clc
clear
close all

addpath('./DONOTTOUCH');
SIM.File = 'converter_2021b';     % Simulink file name   
open_system(SIM.File);
load ("DeviceLibrary_2026.mat")   % All the specs for the semiconductors are stored here

%% Converter Data
% Here you can change the parameters so they match your converter!

%%%%%%%%%%%%%%%%%%%%%%
%    DAB DATA  
%%%%%%%%%%%%%%%%%%%%%%
CONV.U_out = 12;  % [V]   Output voltage
CONV.f_sw = 80e3;% [Hz]  Switching frequency
CONV.L = 2.604167e-05;% [H]   Transformer magnetizing inductance
CONV.C_out = 1.527198e-04;% [F]   Output capacitance
CONV.C_in = 635.14e-6;% [F]   Input capacitance
CONV.U_in_range = [30 60];% [V]   Input voltage range
CONV.P_out_range = [10 50];% [W]   Output power
CONV.N_p = 4.1667;% [1]   Transformer primary-side windings
CONV.N_s = 1;% [1]   Transformer secondary-side windings
CONV.Deadtime = 0.01*(1/1e4);% [s]   Switching deadtime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Specify the Semiconductors    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Type in the number of your semiconductor, same as in the report
MOSF_types = [6, 6, 6, 6, 10, 10, 10, 10]; % The number of both your MOSFETs    [P, P, P, P, S, S, S, S] e.g [1, 1, 1, 1, 2, 2, 2, 2]
% Better change nothing from here on

%% Simulation Parameters

SIM.Time = 1000/CONV.f_sw;                      % Simulation time    
SIM.WindowLength = 100/CONV.f_sw;               % Recording length (Should catch at least one period of fundamental or more)
SIM.Ts = 1/(100*CONV.f_sw);                     % Sampling time (usually 1e-6)    
SIM.NOS = round(SIM.WindowLength/SIM.Ts);       % Number of samples to be recorded, Must be as high as feasible, at least 100x fsw, better 1000

Sim_counter = 1;                                % Simulation Counter
tStart=tic;

% Variations 
CONV.U_in_vec = linspace(CONV.U_in_range(1),CONV.U_in_range(2),7);      % Seven steps in variation of U
CONV.P_out_vec = linspace(CONV.P_out_range(1),CONV.P_out_range(2),3);   % Three steps in variation of P
Num_of_sim = length(CONV.U_in_vec) * length(CONV.P_out_vec) ;

% Really don't change stuff anymore
% Better call a TA who advises you on how to fix a problem

%% Run the simulations
% assigning the specs to the devices
% IGBT is down here for less confusion (hopefully)
IGBT_types = [];        % only empty is zero
DIOD_types = [];             % The number of your rectifying DIODE      [Y]
number_devices = [length(IGBT_types) length(MOSF_types) length(DIOD_types)];


for IG_Nr = 1 : length (IGBT_types)
    if isempty(DeviceLibrary.IGBT.type(IGBT_types(IG_Nr)))
        fprintf ('Please add the selected device to the library first')
    end
    IGBTs{IG_Nr}.Specs = DeviceLibrary.IGBT.type(IGBT_types(IG_Nr));
end

for MO_Nr = 1 : length (MOSF_types)
    if isempty(DeviceLibrary.MOSFET.type(MOSF_types(MO_Nr)))
        fprintf ('Please add the selected Mosfet to the device library first')
    end
    MOSFETs{MO_Nr}.Specs = DeviceLibrary.MOSFET.type(MOSF_types(MO_Nr));
end

for DI_Nr = 1 : length (DIOD_types)
    if isempty(DeviceLibrary.DIODE.type(DIOD_types(DI_Nr)))
        fprintf ('Please add the selected diode to the device library first')
    end
    DIODEs{DI_Nr}.Specs = DeviceLibrary.DIODE.type(DIOD_types(DI_Nr));
end

% Start simulating 

testing = 0;

for i= 1:length(CONV.P_out_vec)
    if testing == 1 
        break
    end
    CONV.P_out = CONV.P_out_vec(i);
    for j= 1:length(CONV.U_in_vec)
        CONV.U_in = CONV.U_in_vec(j);

        CONV.I_out = CONV.P_out / CONV.U_out;
        CONV.R_load = CONV.U_out^2/CONV.P_out;
        syms CONV_phi
        CONV_phi = double(solve(CONV.P_out == (CONV.N_p/CONV.N_s)*CONV.U_in*CONV.U_out*CONV_phi*(pi-abs(CONV_phi)) / (CONV.L*2*pi^2*CONV.f_sw), CONV_phi));
        CONV_phi = CONV_phi(CONV_phi >= 0 & CONV_phi <= pi/2); % Filter to keep solutions in [0, pi/2]
        CONV.Phase_PU = CONV_phi/(2*pi);

        Per_compl = 100 * (Sim_counter - 1) / Num_of_sim;
        tCalc = toc(tStart);
        fprintf('Simulating... Run %g out of %g \n',Sim_counter, Num_of_sim)
        fprintf('U_in:         %g V \n',CONV.U_in)
        fprintf('P_out:        %g W \n',CONV.I_out*CONV.U_out) % Yanick: Added from I to P
        fprintf('Completed:    %g %% \n',round(Per_compl,2)) % Yanick: Two digits after the comma seem to be sufficient...
        fprintf('Time passed:  %g s \n',round(tCalc,2)) % Yanick: Added
        fprintf('...................................\n');
        

        NOS=SIM.NOS;
        Ts =SIM.Ts;

        options = simset('Solver','ode45','MaxStep',SIM.Ts,'InitialStep',SIM.Ts,'SrcWorkspace','current','DstWorkspace','base');
        sim(SIM.File,[0 SIM.Time],options); 
        
        for IG_Nr = 1 : number_devices(1)
            FileName = ['SIM_Nr' num2str(Sim_counter)];
            IGBTs{IG_Nr}.Data.(FileName) = eval(['SIM_IGBT' num2str(IG_Nr) '_Data']);
            clear (['SIM_IGBT' num2str(IG_Nr) '_Data'])
        end
        
        for MO_Nr = 1 : number_devices(2)
            FileName = ['SIM_Nr' num2str(Sim_counter)];
            MOSFETs{MO_Nr}.Data.(FileName) = eval(['SIM_MOSFET' num2str(MO_Nr) '_Data']);
            clear (['SIM_MOSFET' num2str(MO_Nr) '_Data'])
        end
        
        for DI_Nr = 1 : number_devices(3)
            FileName = ['SIM_Nr' num2str(Sim_counter)];
            DIODEs{DI_Nr}.Data.(FileName) = eval(['SIM_DIODE' num2str(DI_Nr) '_Data']);
            clear (['SIM_DIODE' num2str(DI_Nr) '_Data'])
        end

        Sim_counter = Sim_counter +1;
    end
end

fprintf('Done...100 Percent of Simulation completed\n');
fprintf('...................................\n');
fprintf('...................................\n');

%% Calculate the losses
Sim_counter = 1;                                                            % Simulation Counter

for i= 1:length(CONV.P_out_vec)
    CONV.P_out = CONV.P_out_vec(i);
    for j= 1:length(CONV.U_in_vec)
        CONV.U_in = CONV.U_in_vec(j);

        CONV.I_out = CONV.P_out / CONV.U_out;

        
        Per_compl = 100 * (Sim_counter - 1) / Num_of_sim;
        tCalc = toc(tStart);
                    
        fprintf('Processing Semiconductor Losses... Run %g out of %g \n',Sim_counter, Num_of_sim)
        fprintf('U_in:         %g V \n',CONV.U_in)
        fprintf('P_out:        %g W \n',CONV.I_out*CONV.U_out) % Yanick: Changed from I to P
        fprintf('Completed:    %g %% \n',round(Per_compl,2)) % Yanick: Two digits after the comma seem to be sufficient...
        fprintf('Time passed:  %g s \n',round(tCalc,2)) % Yanick: Added
        fprintf('...................................\n');
        
        for IG_Nr = 1 : number_devices(1)
            FileName = ['SIM_Nr' num2str(Sim_counter)];
            IGBTs{IG_Nr}.Losses.(FileName) = IGBT_losses_func (IGBTs{IG_Nr}.Specs, IGBTs{IG_Nr}.Data.(FileName));
        end
        
        for MO_Nr = 5 : 8    % 1 : number_devices(2)
            FileName = ['SIM_Nr' num2str(Sim_counter)];
            MOSFETs{MO_Nr}.Losses.(FileName) = MOSFET_losses_func (MOSFETs{MO_Nr}.Specs, MOSFETs{MO_Nr}.Data.(FileName));
        end
        
        for DI_Nr = 1 : number_devices(3)
            FileName = ['SIM_Nr' num2str(Sim_counter)];
            DIODEs{DI_Nr}.Losses.(FileName) = DIODE_losses_func (DIODEs{DI_Nr}.Specs, DIODEs{DI_Nr}.Data.(FileName));
        end

        Sim_counter = Sim_counter + 1;   
    end
end

fprintf('Done... 100 %% completed, Semiconductor losses are calculated. \n'); %Jules: adding of \n
fprintf('...................................\n');
fprintf('...................................\n');


%% Plot the losses
f = figure;


Sim_counter = 1;
plotdata = zeros(length(CONV.P_out_vec),length(CONV.U_in_vec),5);

for i = 1:length(CONV.P_out_vec) 
    
    for j = 1:length(CONV.U_in_vec)
        Loss.SW             = 0;
        Loss.Cond_IGBT      = 0;
        Loss.Cond_MOSF      = 0;
        Loss.Cond_DIOD      = 0;
        Loss.Total          = 0;

        for IG_Nr = 1 : number_devices(1)
            FileName = ['IGBTs' num2str(IG_Nr) '.Losses.SIM_Nr' num2str(Sim_counter)];
            Loss.Cond_IGBT = Loss.Cond_IGBT + eval([FileName '.P_Cond']);
            Loss.SW = Loss.SW + eval([FileName '.P_SW']);
            Loss.Total = Loss.Total + eval([FileName '.P_Total']);
        end

        for MO_Nr = 1 : number_devices(2)
            FileName = ['MOSFETs{' num2str(MO_Nr) '}.Losses.SIM_Nr' num2str(Sim_counter)];
            Loss.Cond_MOSF = Loss.Cond_MOSF + eval([FileName '.P_Cond']);
            Loss.SW = Loss.SW + eval([FileName '.P_SW']);
            Loss.Total = Loss.Total + eval([FileName '.P_Total']);
        end

        for DI_Nr = 1 : number_devices(3)
            FileName = ['DIODEs{' num2str(DI_Nr) '}.Losses.SIM_Nr' num2str(Sim_counter)];
            Loss.Cond_DIOD = Loss.Cond_DIOD + eval([FileName '.P_Cond']);
            Loss.SW = Loss.SW + eval([FileName '.P_SW']);
            Loss.Total = Loss.Total + eval([FileName '.P_Total']);
        end
        
        plotdata(i,j,:) = [Loss.Cond_IGBT Loss.Cond_MOSF Loss.Cond_DIOD Loss.SW Loss.Total];

        Sim_counter = Sim_counter +1;
    end
    hold on
    % Plotting
    if i == 1
        tiledlayout(length(CONV.P_out_vec),2)
    end
end
t = tiledlayout(length(CONV.P_out_vec),2);
t.Padding = 'compact';
t.TileSpacing = 'compact';
for i = 1:length(CONV.P_out_vec)
    nexttile

    plotthis = squeeze(plotdata(i,:,4));
    legendthis = ["Switching Losses"];

    if ~isempty(IGBT_types)
        plotthis = [plotthis; squeeze(plotdata(i,:,1))];
        legendthis = [legendthis, "IGBT Conduction Losses"];  
    end
    if ~isempty(MOSF_types)
        plotthis = [plotthis; squeeze(plotdata(i,:,2))];
        legendthis = [legendthis, "MOSFET Conduction Losses"];
    end
    if ~isempty(DIOD_types)
        plotthis = [plotthis; squeeze(plotdata(i,:,3))];
        legendthis = [legendthis, "DIODE Conduction Losses"];
    end

    hBar = bar(CONV.U_in_vec, plotthis,'stacked');

    title(['P_{out} = ',num2str(CONV.P_out_vec(i)),' W']);
    xlabel('U_{in} [V]');
    grid on;
    ylabel('Power Losses [W]');

    if i == 1
        lgd=legend(legendthis,'Location','northoutside');
        lgd.Orientation = 'horizontal';
    end    
       
    ylim ([0 1.1*max(plotdata(:,:,5),[],"all")])

    % Efficencey
    nexttile

    eff=100 - 100.* plotdata(i,:,5)./(CONV.P_out_vec(i));
    plot(CONV.U_in_vec,eff, '*--','MarkerSize',9,'Color',[0.6 0.8 1],'MarkerEdgeColor',[0 0.2 1]);
    ylim([0.99*min(eff), 1.01*max(eff)]);
    title(['P_{out} = ',num2str(CONV.P_out_vec(i)),' W']);
    xlabel('U_{in} [V]');
    ylabel('Efficiency \eta [%]');
    grid on;
end
    


       



%% --------------------------------
%% Functions

function Loss = IGBT_losses_func (Specs, Data)
    

end

function Loss = MOSFET_losses_func (Specs, Data)
    Son = Data(:,3);
    Soff = Data(:,4);
    Time = evalin('base','SIM.WindowLength');

    % Define the incoming Data
    % Voltages
    u = (Data(:,1) >= 0) .* Data(:,1);
    
    % Current 
    i  = Data(:,2); % Bidirectional current (can be positive or negative)
    
    % Son and Soff are ALREADY edge signals:
    % Son = 1 at turn-on edge (gate 0->1)
    % Soff = 1 at turn-off edge (gate 1->0)
    
    % For switching loss, need both voltage and current at the transition
    % Pattern from debug: 
    % - At turn-on: i[edge], u[edge-1]
    % - At turn-off: i[edge-1], u[edge]
    
    u_on = zeros(size(u));
    u_off = zeros(size(u));
    i_on = zeros(size(i));
    i_off = zeros(size(i));
    
    idx_on = find(Son == 1);
    idx_off = find(Soff == 1);
    
    % Turn-on: current at edge, voltage before edge
    for k = 1:length(idx_on)
        if idx_on(k) > 1
            i_on(idx_on(k)) = abs(i(idx_on(k)));
            u_on(idx_on(k)) = u(idx_on(k)-1);
        end
    end
    
    % Turn-off: current before edge, voltage at edge  
    for k = 1:length(idx_off)
        if idx_off(k) > 1
            i_off(idx_off(k)) = abs(i(idx_off(k)-1));
            u_off(idx_off(k)) = u(idx_off(k));
        end
    end
        
    if max(abs(i_on)) == 0 || max(abs(u_on)) == 0
        u_on = 0;
        i_on = 0;
    end

    if max(abs(i_off)) == 0 || max(abs(u_off)) == 0
        u_off = 0;
        i_off = 0;
    end

   

    %% Calculate
    % Conduction losses: P_Cond = R_dsON * I_Rms_ON^2
    
    % Reconstruct gate state from Son and Soff edges
    gate_state = zeros(size(Son));
    current_state = 0;
    for k = 1:length(Son)
        if Son(k) == 1
            current_state = 1;
        elseif Soff(k) == 1
            current_state = 0;
        end
        gate_state(k) = current_state;
    end
    
    % Calculate RMS: use current only during ON, but normalize by full period
    i_squared_sum = sum(i(gate_state == 1).^2);
    I_Rms_ON = sqrt(i_squared_sum / length(i));
    
    Loss.P_Cond = Specs.R_dsOn * I_Rms_ON^2;

        % Switching Losses 


        % current rise time
        %tir_2 = Specs.R_g*Specs.Ciss*log((Specs.Vgs - Specs.Vth + (Specs.Vgs - Specs.Vth)*Specs.gfs*Specs.Lp/(Specs.R_g*Specs.Ciss))/(Specs.Vgs - Specs.Vgp));
        tir = Specs.t_rI*i_on/Specs.I_test; %According to the datasheet, and slides for PE course. Rise-time is provided for the test current Idt, which is to be scaled to i_MOSFET_on
        
        
        % current fall time
        %tif_2 = Specs.R_g*Specs.C_rss*log((Specs.U_gp*(1 + Specs.gfs*Specs.Lp/(Specs.R_g*Specs.Ciss))/(Specs.Vth)));
        tif = Specs.t_fI*i_off/Specs.I_test;
        
        % voltage fall time
        %tvf = Specs.C_rss*Specs.R_g./(Specs.Vgs - Specs.Vth - i_MOSFET_on/Specs.gfs);
        tvf = (u_on-Specs.R_dsOn*i_on)*Specs.R_g*Specs.C_rss/(Specs.U_gP-Specs.U_miller);
        
        % voltage rise time
        %tvr = Specs.C_rss*Specs.R_g./(Specs.Vth + i_on/Specs.gfs);
        tvr = (u_off-Specs.R_dsOn*i_off)*Specs.R_g*Specs.C_rss/(Specs.U_miller-Specs.U_gN);
        
        % turn-on losses
        Eir = 0.5*u_on.*i_on.*tir;
        Pir = sum(Eir)/Time;
        
        Evf = 0.5*u_on.*i_on.*tvf;
        Pvf = sum(Evf)/Time;
        
        P_on = Pir + Pvf;                                                                          % turn-on losses
        
        
        % turn-off losses
        Eif = 0.5*u_off.*i_off.*tif;
        Pif = sum(Eif)/Time;
        
        Evr = 0.5*u_off.*i_off.*tvr;
        Pvr = sum(Evr)/Time;
        
        P_off = Pif + Pvr;                                                                         % turn-off losses
        
        % reverse recovery losses 
        E_rr = Specs.Q_rr * u_on; % times 1/2 ? including a factor like t_rr/Ts ? 
        P_rr = sum(E_rr)/Time; 

        
        % if max(i_on) > 0
        %     Err = i_on .* u_on * Specs.trr + Specs.Q_rr * u_on;
        %     Prr = sum(Err)/Time;
        %     P_rr = Prr;
        % else
        %     P_rr = 0;
        % end
           
    Loss.P_SW = (P_on + P_off + P_rr) * 1;  % Multiplied by 10 for visualization
    Loss.P_Total = Loss.P_SW + Loss.P_Cond;

end

function Loss = DIODE_losses_func (Specs, Data)
    Son = Data(:,3);
    Soff = Data(:,4);

    % Define the incoming Data
    % Voltages
    u = (Data(:,1) >= 0) .* Data(:,1);
    u_on = u .* circshift(Son,-1);
    u_off = u .* circshift(Soff,1);
    
    
    % Current (Diodes conduct only in one direction, hence rectified)
    i  = (Data(:,2) >= 0) .* Data(:,2);
    i_on = i  .* circshift(Son,1);
    i_off = i  .* circshift(Soff,-1);
    
    i_on = circshift(i_on,-2);
    i_off = circshift(i_off,2);

        
    if max(abs(i_on)) == 0 || max(abs(u_on)) == 0
        u_on = 0;
        i_on = 0;
    end

    if max(abs(i_off)) == 0 || max(abs(u_off)) == 0
        u_off = 0;
        i_off = 0;
    end

   

    %% Calculate
    % Conduction losses: P_Cond = R_dsON * I_Rms ^2 + U_Do * I_Avg
                                          
    I_Avg_ON = mean(i(i~= 0));           % while on                       
    I_Avg = mean(i);
    I_Rms_ON = rms(i(i~= 0));   % while on
    I_Rms = rms(i); % rms value of MOSFET current;

    Loss.P_Cond = Specs.R_dsOn * I_Rms ^2 + Specs.U_D0 * I_Avg;

    Loss.P_SW = 0;
    Loss.P_Total = Loss.P_SW + Loss.P_Cond;

end