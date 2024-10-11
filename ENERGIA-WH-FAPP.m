% --- Load the datasets ---
data_wm = readtable('new_washingmachine.csv');
washingmachine = data_wm.Washingmachine;
time_wm = data_wm.Time; % Datetime vector

data_dw = readtable('new_dishwasher.csv');
dishwasher = data_dw.Dishwasher;
time_dw = data_dw.Time; % Datetime vector

% --- Convert power to energy (Wh) ---
time_interval_hours = 8 / 3600;  % 8 seconds = 8/3600 hours
energy_wm = washingmachine * time_interval_hours;  % Energy in Wh for washing machine
energy_dw = dishwasher * time_interval_hours;  % Energy in Wh for dishwasher

% --- Preallocation with an estimate of the maximum number of elements ---
max_elements_wm = length(energy_wm);
max_elements_dw = length(energy_dw);

% Preallocation of space for filtered vectors
filtered_energy_wm = zeros(max_elements_wm, 1);
filtered_time_wm = datetime(zeros(max_elements_wm, 1), 'ConvertFrom', 'posixtime');
filtered_energy_dw = zeros(max_elements_dw, 1);
filtered_time_dw = datetime(zeros(max_elements_dw, 1), 'ConvertFrom', 'posixtime');

% Counters to keep track of actual length
count_wm = 0;
count_dw = 0;

% --- Filtering for energy_wm (washing machine) ---
above_threshold_wm = energy_wm >= (20 * time_interval_hours);  % Applying the power threshold (500W)
change_idx_wm = [true; diff(above_threshold_wm) ~= 0; true];  % Add true at the extremes
group_boundaries_wm = find(change_idx_wm);

for i = 1:length(group_boundaries_wm)-1
    group_start = group_boundaries_wm(i);
    group_end = group_boundaries_wm(i+1) - 1;
    
    if above_threshold_wm(group_start) && (group_end - group_start + 1) >= 3
        num_elements = group_end - group_start + 1;
        filtered_energy_wm(count_wm+1:count_wm+num_elements) = energy_wm(group_start:group_end);
        filtered_time_wm(count_wm+1:count_wm+num_elements) = time_wm(group_start:group_end);
        count_wm = count_wm + num_elements;
    end
end

% Resize the vectors to remove unused space
filtered_energy_wm = filtered_energy_wm(1:count_wm);
filtered_time_wm = filtered_time_wm(1:count_wm);

% --- Filtering for energy_dw (dishwasher) ---
above_threshold_dw = energy_dw >= (10 * time_interval_hours);  % Applying the power threshold (700W)
change_idx_dw = [true; diff(above_threshold_dw) ~= 0; true];  % Add true at the extremes
group_boundaries_dw = find(change_idx_dw);

for i = 1:length(group_boundaries_dw)-1
    group_start = group_boundaries_dw(i);
    group_end = group_boundaries_dw(i+1) - 1;
    
    if above_threshold_dw(group_start) && (group_end - group_start + 1) >= 225
        num_elements = group_end - group_start + 1;
        filtered_energy_dw(count_dw+1:count_dw+num_elements) = energy_dw(group_start:group_end);
        filtered_time_dw(count_dw+1:count_dw+num_elements) = time_dw(group_start:group_end);
        count_dw = count_dw + num_elements;
    end
end

% Resize the vectors to remove unused space
filtered_energy_dw = filtered_energy_dw(1:count_dw);
filtered_time_dw = filtered_time_dw(1:count_dw);

% --- Extract day of the week and hour for the filtered appliances ---
day_of_week_wm = weekday(filtered_time_wm); % Returns a number from 1 (Sunday) to 7 (Saturday)
hour_of_day_wm = hour(filtered_time_wm); % Returns the hour of the day (0-23)

day_of_week_dw = weekday(filtered_time_dw); % Returns a number from 1 (Sunday) to 7 (Saturday)
hour_of_day_dw = hour(filtered_time_dw); % Returns the hour of the day (0-23)

% --- Preallocate for storing energy values per hour for washing machine and dishwasher ---
energy_per_hour_wm = cell(7, 24);  % Each cell stores the energy for the respective hour of each day
energy_per_hour_dw = cell(7, 24);

% --- Preallocate for storing the means and variance ---
mean_energy_consumption_wm = zeros(7, 24);  % Mean of means for energy consumption washing machine
variance_energy_consumption_wm = zeros(7, 24);  % Variance for washing machine

mean_energy_consumption_dw = zeros(7, 24);  % Mean of means for energy consumption dishwasher
variance_energy_consumption_dw = zeros(7, 24);  % Variance for dishwasher

% --- Collect energy values for washing machine across multiple days ---
unique_dates_wm = unique(dateshift(filtered_time_wm, 'start', 'day'));
for day_idx = 1:length(unique_dates_wm)
    current_day_wm = unique_dates_wm(day_idx);
    current_day_mask_wm = (dateshift(filtered_time_wm, 'start', 'day') == current_day_wm);
    day_of_week_current_wm = weekday(current_day_wm); 
    hours_in_day_wm = hour_of_day_wm(current_day_mask_wm);
    
    for hour = 0:23  % Iterate over each hour in the day
        hour_mask_wm = (hours_in_day_wm == hour);
        
        if any(hour_mask_wm)
            idx_wm = find(current_day_mask_wm & (hour_of_day_wm == hour));
            energy_data_wm = filtered_energy_wm(idx_wm);
            
            % Store the energy values for this hour
            energy_per_hour_wm{day_of_week_current_wm, hour+1} = [energy_per_hour_wm{day_of_week_current_wm, hour+1}; sum(energy_data_wm)];
        end
    end
end

% --- Collect energy values for dishwasher across multiple days ---
unique_dates_dw = unique(dateshift(filtered_time_dw, 'start', 'day'));
for day_idx = 1:length(unique_dates_dw)
    current_day_dw = unique_dates_dw(day_idx);
    current_day_mask_dw = (dateshift(filtered_time_dw, 'start', 'day') == current_day_dw);
    day_of_week_current_dw = weekday(current_day_dw); 
    hours_in_day_dw = hour_of_day_dw(current_day_mask_dw);
    
    for hour = 0:23  % Iterate over each hour in the day
        hour_mask_dw = (hours_in_day_dw == hour);
        
        if any(hour_mask_dw)
            idx_dw = find(current_day_mask_dw & (hour_of_day_dw == hour));
            energy_data_dw = filtered_energy_dw(idx_dw);
            
            % Store the energy values for this hour
            energy_per_hour_dw{day_of_week_current_dw, hour+1} = [energy_per_hour_dw{day_of_week_current_dw, hour+1}; sum(energy_data_dw)];
        end
    end
end

% --- Calculate mean and variance for energy consumption for washing machine and dishwasher ---
for day = 1:7  % Days of the week (1 = Sunday, 7 = Saturday)
    for hour = 1:24  % Hours of the day (1-24)
        if ~isempty(energy_per_hour_wm{day, hour})
            % Mean of means and variance for energy consumption washing machine
            mean_energy_consumption_wm(day, hour) = mean(energy_per_hour_wm{day, hour});
            variance_energy_consumption_wm(day, hour) = var(energy_per_hour_wm{day, hour});
        end
        
        if ~isempty(energy_per_hour_dw{day, hour})
            % Mean of means and variance for energy consumption dishwasher
            mean_energy_consumption_dw(day, hour) = mean(energy_per_hour_dw{day, hour});
            variance_energy_consumption_dw(day, hour) = var(energy_per_hour_dw{day, hour});
        end
    end
end

% --- Visualization of mean and variance for energy consumption for washing machine (First 4 days) ---
days_names = {'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'};
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]);
for day = 1:4
    subplot(4, 1, day);
    bar(0:23, mean_energy_consumption_wm(day, :), 'FaceColor', 'b');
    ylabel('Mean Energy Consumption (Wh)');
    
    % Calculate "mean - std deviation" and "mean + std deviation" for energy consumption
    lower_bound_wm = mean_energy_consumption_wm(day, :) - sqrt(variance_energy_consumption_wm(day, :));
    upper_bound_wm = mean_energy_consumption_wm(day, :) + sqrt(variance_energy_consumption_wm(day, :));
    
    hold on;
    % Add markers for mean - std deviation and mean + std deviation
    plot(0:23, lower_bound_wm, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean - std deviation)
    plot(0:23, upper_bound_wm, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean + std deviation)
    title(['Mean and Std of Energy Consumption Washing Machine - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance for energy consumption for washing machine (Remaining 3 days) ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]);
for day = 5:7
    subplot(3, 1, day-4);
    bar(0:23, mean_energy_consumption_wm(day, :), 'FaceColor', 'b');
    ylabel('Mean Energy Consumption (Wh)');
    
    % Calculate "mean - std deviation" and "mean + std deviation" for energy consumption
    lower_bound_wm = mean_energy_consumption_wm(day, :) - sqrt(variance_energy_consumption_wm(day, :));
    upper_bound_wm = mean_energy_consumption_wm(day, :) + sqrt(variance_energy_consumption_wm(day, :));
    
    hold on;
    % Add markers for mean - std deviation and mean + std deviation
    plot(0:23, lower_bound_wm, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean - std deviation)
    plot(0:23, upper_bound_wm, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean + std deviation)
    title(['Mean and Std of Energy Consumption Washing Machine - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance for energy consumption for dishwasher (First 4 days) ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]);
for day = 1:4
    subplot(4, 1, day);
    bar(0:23, mean_energy_consumption_dw(day, :), 'FaceColor', 'b');
    ylabel('Mean Energy Consumption (Wh)');
    
    % Calculate "mean - std deviation" and "mean + std deviation" for energy consumption
    lower_bound_dw = mean_energy_consumption_dw(day, :) - sqrt(variance_energy_consumption_dw(day, :));
    upper_bound_dw = mean_energy_consumption_dw(day, :) + sqrt(variance_energy_consumption_dw(day, :));
    
    hold on;
    % Add markers for mean - std deviation and mean + std deviation
    plot(0:23, lower_bound_dw, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean - std deviation)
    plot(0:23, upper_bound_dw, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean + std deviation)
    title(['Mean and Std of Energy Consumption Dishwasher - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance for energy consumption for dishwasher (Remaining 3 days) ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]);
for day = 5:7
    subplot(3, 1, day-4);
    bar(0:23, mean_energy_consumption_dw(day, :), 'FaceColor', 'b');
    ylabel('Mean Energy Consumption (Wh)');
    
    % Calculate "mean - std deviation" and "mean + std deviation" for energy consumption
    lower_bound_dw = mean_energy_consumption_dw(day, :) - sqrt(variance_energy_consumption_dw(day, :));
    upper_bound_dw = mean_energy_consumption_dw(day, :) + sqrt(variance_energy_consumption_dw(day, :));
    
    hold on;
    % Add markers for mean - std deviation and mean + std deviation
    plot(0:23, lower_bound_dw, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean - std deviation)
    plot(0:23, upper_bound_dw, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean + std deviation)
    title(['Mean and Std of Energy Consumption Dishwasher - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end


