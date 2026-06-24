close all; clear; clc;

% Parameters
r  = 0.5;   % intrinsic growth rate [1/day]
K  = 290;   % carrying capacity [cells/0.5 mL]
N0 = 1.2;   % initial population [cells/0.5 mL]

% Simulation settings
model_name = 'logistic_growth_model';
step_size  = 0.1;   % [day]
sim_time   = 27;    % [day]

% Run Simulink model
% (Set StopTime and FixedStep via set_param so slx file does not need editing)
load_system(model_name);
set_param(model_name, ...
    'StopTime',  num2str(sim_time), ...
    'FixedStep', num2str(step_size));
simOut = sim(model_name);

% Get results
% Requires a "To Workspace" block in the model named "N_out" (timeseries)
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
