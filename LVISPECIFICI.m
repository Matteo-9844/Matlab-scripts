% Load the dataset
data = readtable('new_aggregato.csv');
aggregate = data.Aggregate; 
time = data.Time;

% Convert the time column to datetime format
time = datetime(time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss'); % Replace with the correct format 

% Define the starting point for the two-week interval
startDate = datetime(2024, 8, 1); % Replace with the desired start date

% Calculate the end date (two weeks after the start date)
endDate = startDate + days(14);

% Filter the data for the two-week interval
mask = (time >= startDate) & (time < endDate);
filteredAggregate = aggregate(mask);
filteredTime = time(mask);

% Load variability index: daily load
% Extraction of days from timestamp
date = dateshift(filteredTime, 'start', 'day');
% Find unique dates within the dataset
uniqueDates = unique(date);
% Calculate total consumption for each day
daily_std_dev = zeros(length(uniqueDates),1);
daily_mean = zeros(length(uniqueDates),1);
ratio_std_mean_day = zeros(length(uniqueDates),1);
sum_ratio_std_mean_day = 0;

for i = 1:length(uniqueDates)
    current_date = uniqueDates(i);
    current_date_indices = find(date == current_date);
    current_day_consumption = filteredAggregate(current_date_indices);

    if ~isempty(current_day_consumption)
        daily_std_dev(i) = std(current_day_consumption);
        daily_mean(i) = mean(current_day_consumption);
        
        if daily_mean(i) ~= 0
            ratio_std_mean_day(i) = daily_std_dev(i) / daily_mean(i);
            sum_ratio_std_mean_day = sum_ratio_std_mean_day + ratio_std_mean_day(i);
        end
    end
end

daily_load = sum_ratio_std_mean_day;
% Create daily consumption graph
figure; plot(uniqueDates, ratio_std_mean_day);
xlabel('Weeks with high correlation');
ylabel('Daily LVI');

% Define the starting point for the two-week interval
startDate2 = datetime(2024, 1, 19); % Replace with the desired start date and time

% Calculate the end date (two weeks after the start date)
endDate2 = startDate2 + days(14);

% Filter the data for the two-week interval
mask2 = (time >= startDate2) & (time < endDate2);
filteredAggregate2 = aggregate(mask2);
filteredTime2 = time(mask2);

% Load variability index: daily load
% Extraction of days from timestamp
date2 = dateshift(filteredTime2, 'start', 'day');
% Find unique dates within the dataset
uniqueDates2 = unique(date2);
% Calculate total consumption for each day
daily_std_dev2 = zeros(length(uniqueDates2),1);
daily_mean2 = zeros(length(uniqueDates2),1);
ratio_std_mean_day2 = zeros(length(uniqueDates2),1);
sum_ratio_std_mean_day2 = 0;

for i = 1:length(uniqueDates2)
    current_date2 = uniqueDates2(i);
    current_date_indices2 = find(date2 == current_date2);
    current_day_consumption2 = filteredAggregate2(current_date_indices2);

    if ~isempty(current_day_consumption2)
        daily_std_dev2(i) = std(current_day_consumption2);
        daily_mean2(i) = mean(current_day_consumption2);
        
        if daily_mean2(i) ~= 0
            ratio_std_mean_day2(i) = daily_std_dev2(i) / daily_mean2(i);
            sum_ratio_std_mean_day2 = sum_ratio_std_mean_day2 + ratio_std_mean_day2(i);
        end
    end
end

daily_load2 = sum_ratio_std_mean_day2;
% Create daily consumption graph
figure; plot(uniqueDates2, ratio_std_mean_day2);
xlabel('Weeks with low correlation');
ylabel('Daily LVI');

% Define the starting point for the two-week interval
startDate3 = datetime(2024, 1, 26); % Replace with the desired start date and time

% Calculate the end date (two weeks after the start date)
endDate3 = startDate3 + days(14);

% Filter the data for the two-week interval
mask3 = (time >= startDate3) & (time < endDate3);
filteredAggregate3 = aggregate(mask3);
filteredTime3 = time(mask3);

% Load variability index: daily load
% Extraction of days from timestamp
date3 = dateshift(filteredTime3, 'start', 'day');
% Find unique dates within the dataset
uniqueDates3 = unique(date3);
% Calculate total consumption for each day
daily_std_dev3 = zeros(length(uniqueDates3),1);
daily_mean3 = zeros(length(uniqueDates3),1);
ratio_std_mean_day3 = zeros(length(uniqueDates3),1);
sum_ratio_std_mean_day3 = 0;

for i = 1:length(uniqueDates3)
    current_date3 = uniqueDates3(i);
    current_date_indices3 = find(date3 == current_date3);
    current_day_consumption3 = filteredAggregate3(current_date_indices3);

    if ~isempty(current_day_consumption3)
        daily_std_dev3(i) = std(current_day_consumption3);
        daily_mean3(i) = mean(current_day_consumption3);
        
        if daily_mean3(i) ~= 0
            ratio_std_mean_day3(i) = daily_std_dev3(i) / daily_mean3(i);
            sum_ratio_std_mean_day3 = sum_ratio_std_mean_day3 + ratio_std_mean_day3(i);
        end
    end
end

daily_load3 = sum_ratio_std_mean_day3;
% Create daily consumption graph
figure; plot(uniqueDates3, ratio_std_mean_day3);
xlabel('Weeks with medium correlation');
ylabel('Daily LVI');



















