close all; clear; clc;

% Parameters (set in m-file as required)
r  = 0.5;   % growth rate [1/day]
K  = 290;   % carrying capacity [cells/0.5 mL]
N0 = 1.2;   % initial population

% Simulation settings
model_name = 'logistic_growth_model';
step_size  = 0.1;   % [day]
sim_time   = 27;    % [day]

% Load Simulink model (must be saved as logistic_growth_model.slx)
load_system(model_name);

% Apply solver settings
set_param(model_name, ...
    'SolverType', 'Fixed-step', ...
    'Solver',     'ode4',       ...
    'FixedStep',  num2str(step_size), ...
    'StopTime',   num2str(sim_time));

% Run simulation
simOut = sim(model_name);

% Get results from To Workspace block (variable name: N_out, format: Timeseries)
t = simOut.get('N_out').Time;
N = simOut.get('N_out').Data;

% Plot
figure;
plot(t, N, 'b', 'LineWidth', 1.5);
title('Growth of Midori-Zorimushi Culture  Sato Kosei');
xlabel('Time [day]');
ylabel('N [-]');
grid on;

% Save PNG
saveas(gcf, 'assignment5.png');
