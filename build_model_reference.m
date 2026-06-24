close all; clear; clc;

% Parameters
r  = 0.5;
K  = 290;
N0 = 1.2;

model_name = 'logistic_growth_model';

% Close if already open
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end

% Create new model
new_system(model_name);
open_system(model_name);

% Solver settings
set_param(model_name, ...
    'SolverType', 'Fixed-step', ...
    'Solver',     'ode4',       ...
    'FixedStep',  '0.1',        ...
    'StopTime',   '27');

% ========== ADD BLOCKS ==========

% Constant: 1
add_block('simulink/Sources/Constant', [model_name '/Const1'], ...
    'Value', '1', ...
    'Position', [75 110 115 140]);

% Gain: 1/K
add_block('simulink/Math Operations/Gain', [model_name '/Gain_K'], ...
    'Gain', '1/K', ...
    'Position', [75 260 130 290]);

% Sum: 1 - N/K
add_block('simulink/Math Operations/Sum', [model_name '/Sum1'], ...
    'Inputs', '+-', ...
    'Position', [205 200 245 250]);

% Product: (1-N/K) * N(t)
add_block('simulink/Math Operations/Product', [model_name '/Product1'], ...
    'Inputs', '**', ...
    'Position', [325 205 375 245]);

% Gain: r
add_block('simulink/Math Operations/Gain', [model_name '/Gain_r'], ...
    'Gain', 'r', ...
    'Position', [445 205 505 245]);

% Constant: N0 (initial condition)
add_block('simulink/Sources/Constant', [model_name '/N0_block'], ...
    'Value', 'N0', ...
    'Position', [550 310 610 340]);

% Integrator (external initial condition)
add_block('simulink/Continuous/Integrator', [model_name '/Integrator'], ...
    'InitialConditionSource', 'external', ...
    'Position', [580 195 630 255]);

% Scope
add_block('simulink/Sinks/Scope', [model_name '/Scope'], ...
    'Position', [760 210 800 250]);

% To Workspace
add_block('simulink/Sinks/To Workspace', [model_name '/ToWS'], ...
    'VariableName', 'N_out', ...
    'SaveFormat',   'timeseries', ...
    'Position', [760 270 870 300]);

% ========== CONNECT BLOCKS ==========

% Const1 -> Sum (+)
add_line(model_name, 'Const1/1',      'Sum1/1');

% Gain_K -> Sum (-)
add_line(model_name, 'Gain_K/1',      'Sum1/2');

% Sum -> Product (input 1)
add_line(model_name, 'Sum1/1',        'Product1/1');

% Product -> Gain_r
add_line(model_name, 'Product1/1',    'Gain_r/1');

% Gain_r -> Integrator (signal input)
add_line(model_name, 'Gain_r/1',      'Integrator/1');

% N0 -> Integrator (initial condition port)
add_line(model_name, 'N0_block/1',    'Integrator/2');

% Integrator -> Scope
add_line(model_name, 'Integrator/1',  'Scope/1');

% Integrator -> To Workspace
add_line(model_name, 'Integrator/1',  'ToWS/1');

% Feedback: Integrator -> Gain_K (N/K)
add_line(model_name, 'Integrator/1',  'Gain_K/1');

% Feedback: Integrator -> Product (input 2 = N(t))
add_line(model_name, 'Integrator/1',  'Product1/2');

% ========== SAVE ==========
save_system(model_name, [model_name '.slx']);
disp('Model built and saved as logistic_growth_model.slx');
disp('Use this as a reference to build your own model manually.');
