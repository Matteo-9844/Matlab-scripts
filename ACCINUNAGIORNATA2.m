% --- Load the dataset ---
data = readtable('new_washingmachine.csv');
washingmachine=data.Washingmachine;
time = data.Time; % Datetime vector

% --- Set the thresholds and minimum duration to consider a switch-on ---
threshold_washingmachine = 20;  % Threshold for the washingmachine
min_duration_samples = 15;   % Corresponds to 24 seconds (3 samples of 8s each)

% --- Convert the time vector into weekday and hour of the day ---
weekdays = weekday(time);   % Returns a number between 1 (Sunday) and 7 (Saturday)
hours_of_day = hour(time);  % Returns the hour of the day (0-23)

% --- Count the switch-ons for each appliance ---
switch_ons_washingmachine = count_switch_ons(washingmachine, threshold_washingmachine, min_duration_samples, weekdays, hours_of_day);

% --- Calculate the average switch-ons for the washingmachine ---
average_switch_ons_washingmachine = zeros(7, 24);
for day = 1:7
    valid_hours = switch_ons_washingmachine(day,:) > 0; % Only consider hours with activations
    if any(valid_hours)
        average_switch_ons_washingmachine(day, valid_hours) = switch_ons_washingmachine(day, valid_hours) / sum(valid_hours);
    end
end


% --- Define day names ---
day_names = {'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'};

% --- Display the average results with bar plots for the first 4 days for Washingmachine ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]); % Set figure with taller aspect ratio
for day = 1:4
    subplot(4, 1, day); % 4 rows, 1 column, one subplot per day
    bar(0:23, average_switch_ons_washingmachine(day, :), 'FaceColor', 'b');
    title(['Average Washingmachine Switch-ons - ', day_names{day}]);
    xlabel('Hour of the day');
    ylabel('Average Number of Switch-ons');
    ylim([0, max(max(average_switch_ons_washingmachine))]); % Set uniform y-axis limit across all plots
end


% --- Display the average results with bar plots for the remaining 3 days for Washingmachine ---
figure('Units', 'normalized', 'Position', [0, 0, 0.5, 1.5]); % Set figure with taller aspect ratio
for day = 5:7
    subplot(3, 1, day-4); % 3 rows, 1 column, one subplot per day (adjust index for the next 3 days)
    bar(0:23, average_switch_ons_washingmachine(day, :), 'FaceColor', 'b');
    title(['Average Washingmachine Switch-ons - ', day_names{day}]);
    xlabel('Hour of the day');
    ylabel('Average Number of Switch-ons');
    ylim([0, max(max(average_switch_ons_washingmachine))]); % Set uniform y-axis limit across all plots
end


% --- Function to detect switch-on cycles based on threshold and consecutive samples ---
function switch_ons_per_hour = count_switch_ons(consumption, threshold, min_duration, days, hours)
    switch_ons_per_hour = zeros(7, 24); % Initialize the matrix to store switch-ons
    switch_on_duration = 0;             % Counter for the switch-on duration
    switch_on_in_progress = false;      % Flag to track if an activation is in progress

    % Iterate through the consumption data
    for i = 1:length(consumption)
        if consumption(i) >= threshold
            switch_on_duration = switch_on_duration + 1;
            if switch_on_duration >= min_duration && ~switch_on_in_progress
                % Count the switch-on only when reaching min_duration and no switch-on was recorded yet
                day = days(i);
                hour = hours(i);
                switch_ons_per_hour(day, hour + 1) = switch_ons_per_hour(day, hour + 1) + 1;
                switch_on_in_progress = true; % Mark that an activation is now in progress
            end
        else
            % Reset the switch-on duration and flag when consumption drops below threshold
            switch_on_duration = 0;
            switch_on_in_progress = false; % The appliance is considered off
        end
    end
end




