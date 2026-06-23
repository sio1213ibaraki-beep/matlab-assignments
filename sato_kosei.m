% Sato Kosei
% Logistic growth model of Paramecium bursaria (Midori-zorimushi)
% dN/dt = r * (1 - N/K) * N

close all;
clear;
clc;

%% Parameters
N0 = 1.2;   % initial number of cells [cells/0.5mL]
r  = 0.5;   % intrinsic rate of natural increase [1/day]
K  = 290;   % carrying capacity [cells/0.5mL]

%% Simulink model settings
model_name = 'logistic_model';
T_end      = 27;    % simulation end time [day]
dt         = 0.1;   % time step [day]

%% Create Simulink model (always regenerate to apply latest settings)
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end
if exist([model_name, '.slx'], 'file')
    delete([model_name, '.slx']);
end
create_logistic_simulink_model(model_name);

%% Load model and configure
load_system(model_name);

set_param(model_name, 'StopTime',    num2str(T_end));
set_param(model_name, 'FixedStep',   num2str(dt));
set_param(model_name, 'Solver',      'ode4');
set_param(model_name, 'SolverType',  'Fixed-step');

%% Assign workspace variables used inside the model
assignin('base', 'N0', N0);
assignin('base', 'r',  r);
assignin('base', 'K',  K);

%% Run simulation
try
    sim_out = sim(model_name);
catch ME
    close_system(model_name, 0);
    error('Simulation failed: %s', ME.message);
end

%% Extract results
t = sim_out.tout;
% Try multiple output formats depending on MATLAB/Simulink version
if isfield(sim_out, 'simout')
    raw = sim_out.simout;
    if isstruct(raw) && isfield(raw, 'signals')
        N = raw.signals.values;
    else
        N = raw;
    end
elseif isfield(sim_out, 'yout')
    try
        N = sim_out.yout{1}.Values.Data;
    catch
        N = sim_out.yout;
    end
else
    % Fall back to base workspace variable set by To Workspace block
    N = evalin('base', 'simout');
    if isstruct(N) && isfield(N, 'signals')
        N = N.signals.values;
    end
end
N = N(:);

close_system(model_name, 0);

%% Plot
fig = figure;
plot(t, N, 'b-', 'LineWidth', 1.5);
title('Growth of Paramecium bursaria  Sato Kosei');
xlabel('Time [day]');
ylabel('N [-]');
grid on;
xlim([0, T_end]);

%% Save PNG
saveas(fig, 'sato_kosei_result.png');
disp('Simulation complete. Graph saved as sato_kosei_result.png');


%% ---- helper function to build the Simulink model ----
function create_logistic_simulink_model(mdl)
    new_system(mdl);
    load_system(mdl);

    % ----- Block positions (x1 y1 x2 y2) -----
    % Integrator (1/s)
    add_block('simulink/Continuous/Integrator', [mdl, '/Integrator'], ...
        'Position', [500, 165, 540, 205], ...
        'InitialCondition', 'N0');

    % Gain r
    add_block('simulink/Math Operations/Gain', [mdl, '/Gain_r'], ...
        'Position', [390, 165, 440, 205], ...
        'Gain', 'r');

    % Product  N(t) * (1 - N/K)
    add_block('simulink/Math Operations/Product', [mdl, '/Product'], ...
        'Position', [300, 160, 340, 210]);

    % Gain 1/K
    add_block('simulink/Math Operations/Gain', [mdl, '/Gain_invK'], ...
        'Position', [120, 220, 170, 250], ...
        'Gain', '1/K');

    % Sum  1 - N/K
    add_block('simulink/Math Operations/Sum', [mdl, '/Sum'], ...
        'Position', [210, 215, 250, 255], ...
        'Inputs', '+-');

    % Constant 1
    add_block('simulink/Sources/Constant', [mdl, '/Const_1'], ...
        'Position', [120, 185, 170, 215], ...
        'Value', '1');

    % Scope
    add_block('simulink/Sinks/To Workspace', [mdl, '/ToWS'], ...
        'Position', [600, 165, 660, 205], ...
        'VariableName', 'simout', ...
        'SaveFormat', 'Array');

    % ----- Connections -----
    % Integrator output -> Product input 1
    add_line(mdl, 'Integrator/1', 'Product/1');
    % Integrator output -> Gain_invK input
    add_line(mdl, 'Integrator/1', 'Gain_invK/1', 'autorouting', 'on');
    % Integrator output -> Scope
    add_line(mdl, 'Integrator/1', 'ToWS/1', 'autorouting', 'on');

    % Const_1 -> Sum input 1
    add_line(mdl, 'Const_1/1', 'Sum/1');
    % Gain_invK -> Sum input 2
    add_line(mdl, 'Gain_invK/1', 'Sum/2');
    % Sum -> Product input 2
    add_line(mdl, 'Sum/1', 'Product/2', 'autorouting', 'on');

    % Product -> Gain_r
    add_line(mdl, 'Product/1', 'Gain_r/1');
    % Gain_r -> Integrator
    add_line(mdl, 'Gain_r/1', 'Integrator/1');

    save_system(mdl);
end
