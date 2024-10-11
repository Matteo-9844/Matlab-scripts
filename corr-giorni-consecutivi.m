% Load the dataset
data = readtable('new_aggregato.csv');
aggregate = data.Aggregate; 
time = data.Time;

% Extract the dates from the timestamp
date = dateshift(time, 'start', 'day');
% Find unique dates within the dataset
unique_dates = unique(date);

% Prepare vectors for daily consumption
daily_consumptions = cell(length(unique_dates), 1);

for i = 1:length(unique_dates)
    current_date = unique_dates(i);
    current_date_indices = find(date == current_date);
    current_day_consumption = aggregate(current_date_indices);
    
    if ~isempty(current_day_consumption)
        daily_consumptions{i} = current_day_consumption;
    end
end

% Calculate the correlation between consumption vectors of consecutive days
correlations = zeros(length(unique_dates) - 1, 1);

for i = 1:length(unique_dates) - 1
    consumption_day1 = daily_consumptions{i};
    consumption_day2 = daily_consumptions{i+1};

    if ~isempty(consumption_day1) && ~isempty(consumption_day2)
        % Interpolation to ensure the vectors have the same length
        maxLength = max(length(consumption_day1), length(consumption_day2));
        
        % Create normalized time vectors for interpolation
        t1 = linspace(1, maxLength, length(consumption_day1));
        t2 = linspace(1, maxLength, length(consumption_day2));
        
        % Interpolate both vectors to the same length
        consumption_day1_interp = interp1(t1, consumption_day1, 1:maxLength, 'linear');
        consumption_day2_interp = interp1(t2, consumption_day2, 1:maxLength, 'linear');
        
        % Calculate correlation between interpolated vectors
        correlations(i) = corr(consumption_day1_interp', consumption_day2_interp');
    end
end

% Visualize the correlations using scatter plot
figure;
scatter(unique_dates(1:end-1), correlations, 'filled');
hold on;

% Calculate and visualize the mean of the absolute correlation values
mean_abs_corr = mean(abs(correlations), 'omitnan');
plot([unique_dates(1), unique_dates(end-1)], [mean_abs_corr, mean_abs_corr], '--', 'LineWidth', 1, 'Color', 'r');

xlabel('Date');
ylabel('Correlation');
title('Correlation Between Daily Consumptions of Consecutive Days');
grid on;

% Display the mean of the absolute correlations
disp('Mean of absolute correlation values:');
disp(mean_abs_corr);

