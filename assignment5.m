close all; clear; clc;

% Parameters (must be in workspace before Simulink runs)
r  = 0.5;   % intrinsic growth rate [1/day]
K  = 290;   % carrying capacity [cells/0.5 mL]
N0 = 1.2;   % initial population [cells/0.5 mL]

% Open Simulink model for editing
% (K, r, N0 are now in workspace so Gain blocks will not show errors)
model_name = 'logistic_growth_model';
open_system(model_name);

% ---- After building and saving the model, run the section below ----
% (Run this file a second time once the slx model is complete)

% Simulation settings
step_size = 0.1;  % [day]
sim_time  = 27;   % [day]

set_param(model_name, ...
    'StopTime',  num2str(sim_time), ...
    'FixedStep', num2str(step_size));

% Run simulation
simOut = sim(model_name);

% Get results
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
