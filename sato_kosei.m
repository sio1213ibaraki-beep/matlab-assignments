% Sato Kosei
% Logistic growth model of Paramecium bursaria
% dN/dt = r * (1 - N/K) * N

close all;
clear;
clc;

%% Parameters (set in m-file as required)
N0 = 1.2;   % initial population [cells/0.5mL]
r  = 0.5;   % intrinsic rate of natural increase [1/day]
K  = 290;   % carrying capacity [cells/0.5mL]

%% Simulation settings
model_name = 'logistic_model';
T_end = 27;    % end time [day]
dt    = 0.1;   % time step [day]

%% Build Simulink model (regenerate every run to avoid stale model)
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end
if exist([model_name, '.slx'], 'file')
    delete([model_name, '.slx']);
end
build_simulink_model(model_name);

%% Configure and run simulation
load_system(model_name);
set_param(model_name, 'StopTime',   num2str(T_end));
set_param(model_name, 'FixedStep',  num2str(dt));
set_param(model_name, 'Solver',     'ode4');
set_param(model_name, 'SolverType', 'Fixed-step');

assignin('base', 'N0', N0);
assignin('base', 'r',  r);
assignin('base', 'K',  K);

try
    sim_out = sim(model_name, 'ReturnWorkspaceOutputs', 'on');
catch ME
    close_system(model_name, 0);
    error('Simulation failed: %s', ME.message);
end

%% Extract time and N(t)
t = sim_out.tout;
N = sim_out.simout;   % Array format from To Workspace block
N = N(:);             % ensure column vector

close_system(model_name, 0);

%% Plot
fig = figure;
plot(t, N, 'b-', 'LineWidth', 1.5);
title('Growth of Paramecium bursaria  Sato Kosei');
xlabel('Time [day]');
ylabel('N [-]');
grid on;
xlim([0, T_end]);

%% Save graph as PNG
saveas(fig, 'sato_kosei_result.png');
disp('Done. Graph saved as sato_kosei_result.png');


%% ---- Helper: build Simulink model programmatically ----
function build_simulink_model(mdl)
    new_system(mdl);
    load_system(mdl);

    % Integrator  (initial condition = N0 from workspace)
    add_block('simulink/Continuous/Integrator', [mdl, '/Integrator'], ...
        'Position',         [500, 165, 540, 205], ...
        'InitialCondition', 'N0');

    % Gain: multiply by r
    add_block('simulink/Math Operations/Gain', [mdl, '/Gain_r'], ...
        'Position', [390, 165, 440, 205], ...
        'Gain',     'r');

    % Product: N(t) * (1 - N/K)
    add_block('simulink/Math Operations/Product', [mdl, '/Product'], ...
        'Position', [300, 160, 340, 210]);

    % Gain: 1/K
    add_block('simulink/Math Operations/Gain', [mdl, '/Gain_invK'], ...
        'Position', [120, 220, 170, 250], ...
        'Gain',     '1/K');

    % Sum: 1 - N/K  (inputs: +-)
    add_block('simulink/Math Operations/Sum', [mdl, '/Sum'], ...
        'Position', [210, 215, 250, 255], ...
        'Inputs',   '+-');

    % Constant: 1
    add_block('simulink/Sources/Constant', [mdl, '/Const1'], ...
        'Position', [120, 185, 170, 215], ...
        'Value',    '1');

    % To Workspace: save N(t) as array named 'simout'
    add_block('simulink/Sinks/To Workspace', [mdl, '/ToWS'], ...
        'Position',    [600, 165, 660, 205], ...
        'VariableName','simout', ...
        'SaveFormat',  'Array');

    % Connections
    add_line(mdl, 'Integrator/1', 'Product/1');
    add_line(mdl, 'Integrator/1', 'Gain_invK/1', 'autorouting', 'on');
    add_line(mdl, 'Integrator/1', 'ToWS/1',      'autorouting', 'on');
    add_line(mdl, 'Const1/1',     'Sum/1');
    add_line(mdl, 'Gain_invK/1',  'Sum/2');
    add_line(mdl, 'Sum/1',        'Product/2',   'autorouting', 'on');
    add_line(mdl, 'Product/1',    'Gain_r/1');
    add_line(mdl, 'Gain_r/1',     'Integrator/1');

    save_system(mdl);
end
