close all; clear; clc;

% Parameters set in m-file as required
r  = 0.5;   % intrinsic growth rate [1/day]
K  = 290;   % carrying capacity [cells/0.5 mL]
N0 = 1.2;   % initial population [cells/0.5 mL]

% Simulation settings
model_name = 'logistic_growth_model';
sim_time   = 27;   % duration [day]
step_size  = 0.1;  % fixed step [day]

% ---- Build Simulink model programmatically ----
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end
new_system(model_name);
open_system(model_name);

% Solver: fixed-step Euler (ode1) with step = 0.1 day
set_param(model_name, ...
    'SolverType',      'Fixed-step', ...
    'Solver',          'ode4', ...
    'FixedStep',       num2str(step_size), ...
    'StopTime',        num2str(sim_time));

% Block positions [left top right bottom]
pos_const1      = [100 130 130 150];
pos_gain_K      = [100 220 160 250];
pos_sum1        = [230 170 260 210];
pos_product1    = [340 170 380 210];
pos_gain_r      = [450 170 510 210];
pos_integrator  = [590 165 640 215];
pos_N0_block    = [490 290 540 320];
pos_scope       = [720 170 760 210];
pos_to_ws       = [720 240 800 270];

% Constant: 1
add_block('simulink/Sources/Constant', [model_name '/Const1'], ...
    'Value', '1', 'Position', pos_const1);

% Gain: 1/K  (computes N/K)
add_block('simulink/Math Operations/Gain', [model_name '/Gain_K'], ...
    'Gain', '1/K', 'Position', pos_gain_K);

% Sum: 1 - N/K
add_block('simulink/Math Operations/Sum', [model_name '/Sum1'], ...
    'Inputs', '+-', 'Position', pos_sum1);

% Product: (1 - N/K) * N
add_block('simulink/Math Operations/Product', [model_name '/Product1'], ...
    'Inputs', '2', 'Position', pos_product1);

% Gain: r
add_block('simulink/Math Operations/Gain', [model_name '/Gain_r'], ...
    'Gain', 'r', 'Position', pos_gain_r);

% Integrator with external initial condition port
add_block('simulink/Continuous/Integrator', [model_name '/Integrator'], ...
    'InitialConditionSource', 'external', ...
    'Position', pos_integrator);

% N0 constant block (supplies initial condition)
add_block('simulink/Sources/Constant', [model_name '/N0_block'], ...
    'Value', 'N0', 'Position', pos_N0_block);

% Scope
add_block('simulink/Sinks/Scope', [model_name '/Scope'], ...
    'Position', pos_scope);

% To Workspace (to retrieve data in m-file)
add_block('simulink/Sinks/To Workspace', [model_name '/ToWS'], ...
    'VariableName', 'N_out', ...
    'SaveFormat',   'timeseries', ...
    'Position', pos_to_ws);

% ---- Connect blocks ----
% Constant 1 -> Sum (+)
add_line(model_name, 'Const1/1',     'Sum1/1');
% Gain_K (N/K) -> Sum (-)
add_line(model_name, 'Gain_K/1',     'Sum1/2');
% Sum (1-N/K) -> Product port 1
add_line(model_name, 'Sum1/1',       'Product1/1');
% Product -> Gain_r
add_line(model_name, 'Product1/1',   'Gain_r/1');
% Gain_r -> Integrator input
add_line(model_name, 'Gain_r/1',     'Integrator/1');
% N0 block -> Integrator initial condition port
add_line(model_name, 'N0_block/1',   'Integrator/2');
% Integrator output N(t) -> Scope
add_line(model_name, 'Integrator/1', 'Scope/1');
% Integrator output N(t) -> ToWorkspace
add_line(model_name, 'Integrator/1', 'ToWS/1');
% Feedback: N(t) -> Gain_K
add_line(model_name, 'Integrator/1', 'Gain_K/1');
% Feedback: N(t) -> Product port 2
add_line(model_name, 'Integrator/1', 'Product1/2');

% Save slx file
save_system(model_name, 'logistic_growth_model.slx');

% ---- Run simulation ----
simOut = sim(model_name);

% Retrieve results from simulation output
t = simOut.tout;
N = simOut.get('N_out').Data;

% ---- Plot ----
figure;
plot(t, N, 'b', 'LineWidth', 1.5);
title('Growth of Midori-Zorimushi Culture  Sato Kosei');
xlabel('Time [day]');
ylabel('N [-]');
grid on;

% Save PNG
saveas(gcf, 'assignment5.png');
disp('Done. Files saved: logistic_growth_model.slx, assignment5.png');
