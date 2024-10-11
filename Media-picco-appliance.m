% --- Load the datasets ---
data_wm = readtable('new_washingmachine.csv');
washingmachine = data_wm.Washingmachine;
time_wm = data_wm.Time; % Datetime vector

data_dw = readtable('new_dishwasher.csv');
dishwasher = data_dw.Dishwasher;
time_dw = data_dw.Time; % Datetime vector

% --- Preallocation with an estimate of the maximum number of elements ---
max_elements_wm = length(washingmachine);
max_elements_dw = length(dishwasher);

% Preallocation of space for filtered vectors
filtered_washingmachine = zeros(max_elements_wm, 1);
filtered_time_wm = datetime(zeros(max_elements_wm, 1), 'ConvertFrom', 'posixtime');
filtered_dishwasher = zeros(max_elements_dw, 1);
filtered_time_dw = datetime(zeros(max_elements_dw, 1), 'ConvertFrom', 'posixtime');

% Counters to keep track of actual length
count_wm = 0;
count_dw = 0;

% --- Filtering for washingmachine ---
above_threshold_wm = washingmachine >= 500;  % Soglia 500W per lavatrice
change_idx_wm = [true; diff(above_threshold_wm) ~= 0; true];  % Add true at the extremes
group_boundaries_wm = find(change_idx_wm);

for i = 1:length(group_boundaries_wm)-1
    group_start = group_boundaries_wm(i);
    group_end = group_boundaries_wm(i+1) - 1;
    
    if above_threshold_wm(group_start) && (group_end - group_start + 1) >= 3
        num_elements = group_end - group_start + 1;
        filtered_washingmachine(count_wm+1:count_wm+num_elements) = washingmachine(group_start:group_end);
        filtered_time_wm(count_wm+1:count_wm+num_elements) = time_wm(group_start:group_end);
        count_wm = count_wm + num_elements;
    end
end

% Resize the vectors to remove unused space
filtered_washingmachine = filtered_washingmachine(1:count_wm);
filtered_time_wm = filtered_time_wm(1:count_wm);

% --- Filtering for dishwasher ---
above_threshold_dw = dishwasher >= 700;  % Soglia 700W per lavastoviglie
change_idx_dw = [true; diff(above_threshold_dw) ~= 0; true];  % Add true at the extremes
group_boundaries_dw = find(change_idx_dw);

for i = 1:length(group_boundaries_dw)-1
    group_start = group_boundaries_dw(i);
    group_end = group_boundaries_dw(i+1) - 1;
    
    if above_threshold_dw(group_start) && (group_end - group_start + 1) >= 3
        num_elements = group_end - group_start + 1;
        filtered_dishwasher(count_dw+1:count_dw+num_elements) = dishwasher(group_start:group_end);
        filtered_time_dw(count_dw+1:count_dw+num_elements) = time_dw(group_start:group_end);
        count_dw = count_dw + num_elements;
    end
end

% Resize the vectors to remove unused space
filtered_dishwasher = filtered_dishwasher(1:count_dw);
filtered_time_dw = filtered_time_dw(1:count_dw);

% --- Extract day of the week and hour for the filtered appliances ---
day_of_week_wm = weekday(filtered_time_wm); % Returns a number from 1 (Sunday) to 7 (Saturday)
hour_of_day_wm = hour(filtered_time_wm); % Returns the hour of the day (0-23)

day_of_week_dw = weekday(filtered_time_dw); % Returns a number from 1 (Sunday) to 7 (Saturday)
hour_of_day_dw = hour(filtered_time_dw); % Returns the hour of the day (0-23)

% --- Preallocate for mean and variance of peak consumption ---
mean_peak_consumption_wm = zeros(7, 24); % 7 days, 24 hours for Washingmachine
variance_peak_consumption_wm = zeros(7, 24); % Variance for Washingmachine
mean_peak_consumption_dw = zeros(7, 24); % 7 days, 24 hours for Dishwasher
variance_peak_consumption_dw = zeros(7, 24); % Variance for Dishwasher

mean_consumption_wm = zeros(7, 24); % Mean of means for Washingmachine
mean_consumption_dw = zeros(7, 24); % Mean of means for Dishwasher

% --- Preallocate for storing peak values and mean consumption ---
peaks_wm = cell(7, 24); % Each cell stores the peaks for the respective hour of each day for Washingmachine
peaks_dw = cell(7, 24); % Same for Dishwasher

mean_appliance_wm = cell(7, 24); % Mean values for Washingmachine
mean_appliance_dw = cell(7, 24); % Mean values for Dishwasher

variance_consumption_wm = zeros(7, 24); % Variance for Washingmachine
variance_consumption_dw = zeros(7, 24); % Variance for Dishwasher

% --- Collect peak values and mean consumption for Washingmachine across multiple weeks ---
unique_dates_wm = unique(dateshift(filtered_time_wm, 'start', 'day'));
for day_idx = 1:length(unique_dates_wm)
    current_day_wm = unique_dates_wm(day_idx);
    current_day_mask_wm = (dateshift(filtered_time_wm, 'start', 'day') == current_day_wm);
    day_of_week_current_wm = weekday(current_day_wm); 
    hours_in_day_wm = hour_of_day_wm(current_day_mask_wm);
    
    for hour = 0:23 % Iterate over each hour in the day
        hour_mask_wm = (hours_in_day_wm == hour);
        
        if any(hour_mask_wm)
            idx_wm = find(current_day_mask_wm & (hour_of_day_wm == hour));
            data_wm = filtered_washingmachine(idx_wm);
            
            % Store the mean consumption
            mean_appliance_wm{day_of_week_current_wm, hour+1} = [mean_appliance_wm{day_of_week_current_wm, hour+1}; mean(data_wm)];
            
            % Store the peak value
            peaks_wm{day_of_week_current_wm, hour+1} = [peaks_wm{day_of_week_current_wm, hour+1}; max(data_wm)];
        end
    end
end

% --- Collect peak values and mean consumption for Dishwasher across multiple weeks ---
unique_dates_dw = unique(dateshift(filtered_time_dw, 'start', 'day'));
for day_idx = 1:length(unique_dates_dw)
    current_day_dw = unique_dates_dw(day_idx);
    current_day_mask_dw = (dateshift(filtered_time_dw, 'start', 'day') == current_day_dw);
    day_of_week_current_dw = weekday(current_day_dw); 
    hours_in_day_dw = hour_of_day_dw(current_day_mask_dw);
    
    for hour = 0:23 % Iterate over each hour in the day
        hour_mask_dw = (hours_in_day_dw == hour);
        
        if any(hour_mask_dw)
            idx_dw = find(current_day_mask_dw & (hour_of_day_dw == hour));
            data_dw = filtered_dishwasher(idx_dw);
            
            % Store the mean consumption
            mean_appliance_dw{day_of_week_current_dw, hour+1} = [mean_appliance_dw{day_of_week_current_dw, hour+1}; mean(data_dw)];
            
            % Store the peak value
            peaks_dw{day_of_week_current_dw, hour+1} = [peaks_dw{day_of_week_current_dw, hour+1}; max(data_dw)];
        end
    end
end

% --- Calculate mean and variance for peak consumption and mean of means for Washingmachine and Dishwasher ---
for day = 1:7 % Days of the week (1 = Sunday, 7 = Saturday)
    for hour = 1:24 % Hours of the day (1-24)
        if ~isempty(mean_appliance_wm{day, hour})
            % Mean of means and variance for Washingmachine
            mean_consumption_wm(day, hour) = mean(mean_appliance_wm{day, hour});
            variance_consumption_wm(day, hour) = var(mean_appliance_wm{day, hour});
        end
        if ~isempty(peaks_wm{day, hour})
            % Mean and variance of peaks for Washingmachine
            mean_peak_consumption_wm(day, hour) = mean(peaks_wm{day, hour});
            variance_peak_consumption_wm(day, hour) = var(peaks_wm{day, hour});
        end
        
        if ~isempty(mean_appliance_dw{day, hour})
            % Mean of means and variance for Dishwasher
            mean_consumption_dw(day, hour) = mean(mean_appliance_dw{day, hour});
            variance_consumption_dw(day, hour) = var(mean_appliance_dw{day, hour});
        end
        if ~isempty(peaks_dw{day, hour})
            % Mean and variance of peaks for Dishwasher
            mean_peak_consumption_dw(day, hour) = mean(peaks_dw{day, hour});
            variance_peak_consumption_dw(day, hour) = var(peaks_dw{day, hour});
        end
    end
end

% --- Visualization of mean and variance for Washingmachine for the first 4 days ---
days_names = {'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'};
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]);
for day = 1:4
    subplot(4, 1, day);
    bar(0:23, mean_consumption_wm(day, :), 'FaceColor', 'b');
    ylabel('Mean Consumption (W)');
    
    % Calculate "mean - std deviation" and "mean + std deviation" for consumption
    lower_bound_wm = mean_consumption_wm(day, :) - sqrt(variance_consumption_wm(day, :));
    upper_bound_wm = mean_consumption_wm(day, :) + sqrt(variance_consumption_wm(day, :));
    
    hold on;
    % Add markers for mean - std deviation and mean + std deviation
    plot(0:23, lower_bound_wm, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean - std deviation)
    plot(0:23, upper_bound_wm, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean + std deviation)
    title(['Mean and Std Consumption Washingmachine - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance for Washingmachine for the remaining 3 days ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]);
for day = 5:7
    subplot(3, 1, day-4);
    bar(0:23, mean_consumption_wm(day, :), 'FaceColor', 'b');
    ylabel('Mean of Means Consumption (W)');
    
    % Calculate "mean - std deviation" and "mean + std deviation" for consumption
    lower_bound_wm = mean_consumption_wm(day, :) - sqrt(variance_consumption_wm(day, :));
    upper_bound_wm = mean_consumption_wm(day, :) + sqrt(variance_consumption_wm(day, :));
    
    hold on;
    % Add markers for mean - std deviation and mean + std deviation
    plot(0:23, lower_bound_wm, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean - std deviation)
    plot(0:23, upper_bound_wm, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean + std deviation)
    title(['Mean and Variance of Means Consumption Washingmachine - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance for Dishwasher for the first 4 days ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]);
for day = 1:4
    subplot(4, 1, day);
    bar(0:23, mean_consumption_dw(day, :), 'FaceColor', 'b');
    ylabel('Mean Consumption (W)');
    
    % Calculate "mean - std deviation" and "mean + std deviation" for consumption
    lower_bound_dw = mean_consumption_dw(day, :) - sqrt(variance_consumption_dw(day, :));
    upper_bound_dw = mean_consumption_dw(day, :) + sqrt(variance_consumption_dw(day, :));
    
    hold on;
    % Add markers for mean - std deviation and mean + std deviation
    plot(0:23, lower_bound_dw, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean - std deviation)
    plot(0:23, upper_bound_dw, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean + std deviation)
    title(['Mean and Std Consumption Dishwasher - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance for Dishwasher for the remaining 3 days ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]);
for day = 5:7
    subplot(3, 1, day-4);
    bar(0:23, mean_consumption_dw(day, :), 'FaceColor', 'b');
    ylabel('Mean of Means Consumption (W)');
    
    % Calculate "mean - std deviation" and "mean + std deviation" for consumption
    lower_bound_dw = mean_consumption_dw(day, :) - sqrt(variance_consumption_dw(day, :));
    upper_bound_dw = mean_consumption_dw(day, :) + sqrt(variance_consumption_dw(day, :));
    
    hold on;
    % Add markers for mean - std deviation and mean + std deviation
    plot(0:23, lower_bound_dw, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean - std deviation)
    plot(0:23, upper_bound_dw, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean + std deviation)
    title(['Mean and Variance of Means Consumption Dishwasher - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance of peak consumption for Washingmachine for the first 4 days ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]); % Set figure with taller aspect ratio
for day = 1:4
    subplot(4, 1, day); % 4 rows, 1 column, one subplot per day
    bar(0:23, mean_peak_consumption_wm(day, :), 'FaceColor', 'b');
    ylabel('Mean Peak Consumption (W)');
    
    % Calculate "mean peak - std deviation" and "mean peak + std deviation" for peak consumption
    lower_bound_peak_wm = mean_peak_consumption_wm(day, :) - sqrt(variance_peak_consumption_wm(day, :));
    upper_bound_peak_wm = mean_peak_consumption_wm(day, :) + sqrt(variance_peak_consumption_wm(day, :));
    
    hold on;
    % Add markers for mean peak - std deviation and mean peak + std deviation
    plot(0:23, lower_bound_peak_wm, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean peak - std deviation)
    plot(0:23, upper_bound_peak_wm, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean peak + std deviation)
    title(['Mean and Std of Peak Consumption Washingmachine - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance of peak consumption for Washingmachine for the remaining 3 days ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]); % Set figure with taller aspect ratio
for day = 5:7
    subplot(3, 1, day-4); % 3 rows, 1 column, one subplot per day
    bar(0:23, mean_peak_consumption_wm(day, :), 'FaceColor', 'b');
    ylabel('Mean Peak Consumption (W)');
    
    % Calculate "mean peak - std deviation" and "mean peak + std deviation" for peak consumption
    lower_bound_peak_wm = mean_peak_consumption_wm(day, :) - sqrt(variance_peak_consumption_wm(day, :));
    upper_bound_peak_wm = mean_peak_consumption_wm(day, :) + sqrt(variance_peak_consumption_wm(day, :));
    
    hold on;
    % Add markers for mean peak - std deviation and mean peak + std deviation
    plot(0:23, lower_bound_peak_wm, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean peak - std deviation)
    plot(0:23, upper_bound_peak_wm, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean peak + std deviation)    
    title(['Mean and Variance of Peak Consumption Washingmachine - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance of peak consumption for Dishwasher for the first 4 days ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]); % Set figure with taller aspect ratio
for day = 1:4
    subplot(4, 1, day); % 4 rows, 1 column, one subplot per day
    bar(0:23, mean_peak_consumption_dw(day, :), 'FaceColor', 'b');
    ylabel('Mean Peak Consumption (W)');
    
    % Calculate "mean peak - std deviation" and "mean peak + std deviation" for peak consumption
    lower_bound_peak_dw = mean_peak_consumption_dw(day, :) - sqrt(variance_peak_consumption_dw(day, :));
    upper_bound_peak_dw = mean_peak_consumption_dw(day, :) + sqrt(variance_peak_consumption_dw(day, :));
    
    hold on;
    % Add markers for mean peak - std deviation and mean peak + std deviation
    plot(0:23, lower_bound_peak_dw, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean peak - std deviation)
    plot(0:23, upper_bound_peak_dw, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean peak + std deviation)
    title(['Mean and Std of Peak Consumption Dishwasher - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end

% --- Visualization of mean and variance of peak consumption for Dishwasher for the remaining 3 days ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]); % Set figure with taller aspect ratio
for day = 5:7
    subplot(3, 1, day-4); % 3 rows, 1 column, one subplot per day
    bar(0:23, mean_peak_consumption_dw(day, :), 'FaceColor', 'b');
    ylabel('Mean Peak Consumption (W)');
    
    % Calculate "mean peak - std deviation" and "mean peak + std deviation" for peak consumption
    lower_bound_peak_dw = mean_peak_consumption_dw(day, :) - sqrt(variance_peak_consumption_dw(day, :));
    upper_bound_peak_dw = mean_peak_consumption_dw(day, :) + sqrt(variance_peak_consumption_dw(day, :));
    
    hold on;
    % Add markers for mean peak - std deviation and mean peak + std deviation
    plot(0:23, lower_bound_peak_dw, 'go', 'MarkerFaceColor', 'g'); % Lower bound (mean peak - std deviation)
    plot(0:23, upper_bound_peak_dw, 'ro', 'MarkerFaceColor', 'r'); % Upper bound (mean peak + std deviation)
    title(['Mean and Variance of Peak Consumption Dishwasher - ', days_names{day}]);
    xlabel('Hour of the day');
    hold off;
end
