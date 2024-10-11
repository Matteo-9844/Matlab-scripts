% Load the dataset
data = readtable('new_aggregato.csv');
aggregate = data.Aggregate; 
time = data.Time;

% Convert the timestamp to datetime format
time = datetime(time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');

% Get the days of the week (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
days_of_week = weekday(time);
unique_days_of_week = unique(days_of_week);

% Group the data by week
weeks = week(time);
unique_weeks = unique(weeks);
num_weeks = numel(unique_weeks);

% Preallocate a matrix to store weekly consumption for each day of the week
weekly_consumption_by_day = cell(7, num_weeks);

for i = 1:7 % days of the week
    for j = 1:num_weeks % weeks
        day_indices = (days_of_week == i) & (weeks == unique_weeks(j));
        weekly_consumption_by_day{i, j} = aggregate(day_indices);
    end
end

% Calculate the correlation between consecutive days of the week using linear interpolation
correlations = nan(7, num_weeks - 1);

for i = 1:7 % days of the week
    for j = 1:num_weeks - 1 % weeks
        consumption_week1 = weekly_consumption_by_day{i, j};
        consumption_week2 = weekly_consumption_by_day{i, j + 1};
        
        % Check that the data is not empty
        if ~isempty(consumption_week1) && ~isempty(consumption_week2)
            % Determine the maximum length of the two vectors
            max_length = max(length(consumption_week1), length(consumption_week2));
            
            % Create a normalized vector for interpolation
            x1 = linspace(1, max_length, length(consumption_week1));
            x2 = linspace(1, max_length, length(consumption_week2));
            
            % Interpolate both vectors to the same length
            consumption_week1_interp = interp1(x1, consumption_week1, 1:max_length, 'linear');
            consumption_week2_interp = interp1(x2, consumption_week2, 1:max_length, 'linear');
            
            % Calculate the correlation
            correlations(i, j) = corr(consumption_week1_interp', consumption_week2_interp');
        end
    end
end

% Display the correlations
disp(correlations)

% Calculate the mean of the absolute correlation values for each day of the week
mean_abs_corr = mean(abs(correlations), 2, 'omitnan');

% Print the means of the absolute correlations
disp('Mean of absolute correlations for each day of the week:');
day_names = {'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'};
for i = 1:7
    fprintf('%s: %.4f\n', day_names{i}, mean_abs_corr(i));
end

% Plot the correlation in a scatter plot
figure;
hold on;
colors = lines(7); % 7 colors for 7 days of the week
for i = 1:7
    scatter(1:(num_weeks - 1), correlations(i, :), 'filled', 'MarkerFaceColor', colors(i,:));
end

% Add the means of absolute correlations to the plot as horizontal lines
for i = 1:7
    plot([1, num_weeks - 1], [mean_abs_corr(i), mean_abs_corr(i)], 'Color', colors(i,:), 'LineStyle', '--', 'LineWidth', 1);
end

xlabel('Week Index');
ylabel('Correlation');
title('Correlation between Same Days of Consecutive Weeks');
legend(day_names, 'Location', 'Best');
grid on;
hold off;