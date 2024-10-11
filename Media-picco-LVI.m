% --- Load the dataset ---
data = readtable('new_aggregato.csv');
aggregate = data.Aggregate; 
time = data.Time;

% --- Extract day of the week and hour for Aggregate ---
day_of_week = weekday(time);  % Returns a number from 1 (Sunday) to 7 (Saturday)
hour_of_day = hour(time);  % Returns the hour of the day (0-23)

% --- Preallocate for mean peak consumption and variance ---
mean_peak_consumption = zeros(7, 24); % Preallocate for mean of peaks
variance_peak_consumption = zeros(7, 24); % Preallocate for variance of peaks
peaks_aggregate = cell(7, 24); % Preallocate cell array for storing peak values per hour

% --- Preallocate for mean aggregate to store mean consumption per unique day of the week ---
mean_aggregate = cell(7, 24); % Preallocate cell array to store mean consumption for each hour of each day of the week

% --- Collect peak values for Aggregate and collect mean consumption ---
unique_dates = unique(dateshift(time, 'start', 'day')); % Get all unique days
for day_idx = 1:length(unique_dates)
    current_day = unique_dates(day_idx);
    
    % Create a logical mask for the current day
    current_day_mask = (dateshift(time, 'start', 'day') == current_day);

    % Extract the day of the week and hour for the current day
    day_of_week_current = weekday(current_day); % Returns 1 (Sunday) to 7 (Saturday)
    hours_in_day = hour_of_day(current_day_mask); % Get the hours for the current day
    
    for hour = 0:23 % Iterate over each hour in the day
        hour_mask = (hours_in_day == hour); % Logical mask for current hour
        
        if any(hour_mask)
            % Filter the data for the current day and hour
            idx = find(current_day_mask & (hour_of_day == hour));
            data_at_hour = aggregate(idx);
            
            % Store the mean consumption for the current day and hour
            mean_aggregate{day_of_week_current, hour+1} = [mean_aggregate{day_of_week_current, hour+1}; mean(data_at_hour)];
            
            % Store the peak value (maximum) for this hour
            peaks_aggregate{day_of_week_current, hour+1} = [peaks_aggregate{day_of_week_current, hour+1}; max(data_at_hour)];
        end
    end
end

% --- Calculate the mean and variance of the peaks and consumption for Aggregate ---
mean_consumption = zeros(7, 24); % Preallocate for storing the final mean consumption
variance_consumption = zeros(7, 24); % Preallocate for storing the variance of consumption

for day = 1:7 % Days of the week (1 = Sunday, 7 = Saturday)
    for hour = 1:24 % Hours of the day (1-24)
        if ~isempty(mean_aggregate{day, hour})
            % Calculate the mean of the mean consumption values stored for this combination of day and hour
            mean_consumption(day, hour) = mean(mean_aggregate{day, hour});
            variance_consumption(day, hour) = var(mean_aggregate{day, hour}); % Calculate variance of the mean consumption
        end
        
        if ~isempty(peaks_aggregate{day, hour})
            % Calculate the mean of the peak values stored for this combination of day and hour
            mean_peak_consumption(day, hour) = mean(peaks_aggregate{day, hour});
            variance_peak_consumption(day, hour) = var(peaks_aggregate{day, hour}); % Calculate variance of peaks
        end
    end
end

% --- Visualization of mean consumption (Mean of Means) with variance for the first 4 days ---
days_names = {'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'};
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]); % Set figure with taller aspect ratio
for day = 1:4
    subplot(4, 1, day); % 4 rows, 1 column, one subplot per day
    bar(0:23, mean_consumption(day, :), 'FaceColor', 'b');
    ylabel('Mean Consumption (W)');
    
    % Calculate "mean - std deviation" and "mean + std deviation" for consumption
    lower_bound = mean_consumption(day, :) - sqrt(variance_consumption(day, :));
    upper_bound = mean_consumption(day, :) + sqrt(variance_consumption(day, :));
    
    hold on;
    % Add markers for "mean - std deviation" and "mean + std deviation"
    plot(0:23, lower_bound, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean - std deviation)
    plot(0:23, upper_bound, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean + std deviation)
    title(['Mean and Std Consumption Aggregate - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean consumption (Mean of Means) with variance for the remaining 3 days ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]); % Set figure with taller aspect ratio
for day = 5:7
    subplot(3, 1, day-4); % 3 rows, 1 column, one subplot per day
    bar(0:23, mean_consumption(day, :), 'FaceColor', 'b');
    ylabel('Mean Consumption (W)');
    
    % Calculate "mean - std deviation" and "mean + std deviation" for consumption
    lower_bound = mean_consumption(day, :) - sqrt(variance_consumption(day, :));
    upper_bound = mean_consumption(day, :) + sqrt(variance_consumption(day, :));
    
    hold on;
    % Add markers for "mean - std deviation" and "mean + std deviation"
    plot(0:23, lower_bound, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean - std deviation)
    plot(0:23, upper_bound, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean + std deviation)
    title(['Mean and Std Consumption Aggregate - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end


% --- Visualization of mean and variance of peak consumption for Aggregate for the first 4 days ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]); % Set figure with taller aspect ratio
for day = 1:4
    subplot(4, 1, day); % 4 rows, 1 column, one subplot per day
    bar(0:23, mean_peak_consumption(day, :), 'FaceColor', 'b');
    ylabel('Mean Peak Consumption (W)');
    
    % Calculate "mean peak - std deviation" and "mean peak + std deviation"
    lower_bound_peak = mean_peak_consumption(day, :) - sqrt(variance_peak_consumption(day, :));
    upper_bound_peak = mean_peak_consumption(day, :) + sqrt(variance_peak_consumption(day, :));
    
    hold on;
    % Add markers for "mean peak - std deviation" and "mean peak + std deviation"
    plot(0:23, lower_bound_peak, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean peak - std deviation)
    plot(0:23, upper_bound_peak, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean peak + std deviation)
    title(['Mean and Std Peak Consumption Aggregate - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance of peak consumption for Aggregate for the remaining 3 days ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]); % Set figure with taller aspect ratio
for day = 5:7
    subplot(3, 1, day-4); % 3 rows, 1 column, one subplot per day
    bar(0:23, mean_peak_consumption(day, :), 'FaceColor', 'b');
    ylabel('Mean Peak Consumption (W)');
    
    % Calculate "mean peak - std deviation" and "mean peak + std deviation"
    lower_bound_peak = mean_peak_consumption(day, :) - sqrt(variance_peak_consumption(day, :));
    upper_bound_peak = mean_peak_consumption(day, :) + sqrt(variance_peak_consumption(day, :));
    
    hold on;
    % Add markers for "mean peak - std deviation" and "mean peak + std deviation"
    plot(0:23, lower_bound_peak, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean peak - std deviation)
    plot(0:23, upper_bound_peak, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean peak + std deviation)
    title(['Mean and Std Peak Consumption Aggregate - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Extraction of dates ---
date = dateshift(time, 'start', 'day'); % Day
unique_days = unique(date);

% --- Calculate total consumption for each day ---
standard_deviation_per_day = zeros(length(unique_days), 1);
mean_per_day = zeros(length(unique_days), 1);
ratio_std_mean_day = zeros(length(unique_days), 1);
sum_ratio_std_mean_day = 0;

for i = 1:length(unique_days)
    current_date = unique_days(i);
    current_date_indices = find(date == current_date);
    current_day_consumption = aggregate(current_date_indices);

    if ~isempty(current_day_consumption)
        standard_deviation_per_day(i) = std(current_day_consumption);
        mean_per_day(i) = mean(current_day_consumption);
        
        if mean_per_day(i) ~= 0
            ratio_std_mean_day(i) = standard_deviation_per_day(i) / mean_per_day(i);
            sum_ratio_std_mean_day = sum_ratio_std_mean_day + ratio_std_mean_day(i);
        end
    end
end

daily_load = sum_ratio_std_mean_day;

% --- Create daily consumption graph ---
figure; 
plot(unique_days, ratio_std_mean_day);
xlabel('Date');
ylabel('Daily LVI');
title('Daily Load Variability Index over Time');
