# References
# https://www.statology.org/r-add-a-column-to-dataframe/#:~:text=How%20to%20Add%20a%20Column%20to%20a%20Data,3%2C%206%2C%207%2C%208%2C%2012%29%202.%20Use%20Brackets
# https://stackoverflow.com/questions/39405628/how-do-i-create-a-new-column-based-on-multiple-conditions-from-multiple-columns
# https://www.statology.org/side-by-side-plots-ggplot2/#:~:text=The%20following%20code%20shows%20how%20to%20create%20two,%23display%20plots%20side%20by%20side%20plot1%20%2B%20plot2.
# https://stackoverflow.com/questions/19778612/change-color-for-two-geom-point-in-ggplot2

########################################
# load libraries
########################################

# load some packages that we'll need
library(tidyverse)
library(scales)

# be picky about white backgrounds on our plots
theme_set(theme_bw())

# load RData file output by load_trips.R
load('trips.RData')


########################################
# plot trip data
########################################

# plot the distribution of trip times across all rides (compare a histogram vs. a density plot)
ggplot(data = trips, mapping = aes(x = tripduration)) + geom_histogram() + scale_x_log10(label = comma) + scale_y_log10(label = comma)
ggplot(data = trips, mapping = aes(x = tripduration)) + geom_density() + scale_x_log10(label = comma) + scale_y_log10(label = comma)
install.packages('patchwork')
library(patchwork)
plot1 <- ggplot(data = trips, mapping = aes(x = tripduration)) + geom_histogram() + scale_x_log10(label = comma) + scale_y_log10(label = comma)
plot2 <- ggplot(data = trips, mapping = aes(x = tripduration)) + geom_density() + scale_x_log10(label = comma) + scale_y_log10(label = comma)
plot1 + plot2
# plot the distribution of trip times by rider type indicated using color and fill (compare a histogram vs. a density plot)
ggplot(data = trips, mapping = aes(x = tripduration)) + geom_histogram(mapping = aes(color = usertype)) + scale_x_log10(label = comma) + scale_y_log10(label = comma)
ggplot(data = trips, mapping = aes(x = tripduration)) + geom_density(mapping = aes(color = usertype)) + scale_x_log10(label = comma) + scale_y_log10(label = comma)
# plot the total number of trips on each day in the dataset
num_rides_per_day <- group_by(trips, ymd) %>% summarize(num_rides = n())
ggplot(num_rides_per_day, aes(x = ymd, y = num_rides)) + geom_point()
# plot the total number of trips (on the y axis) by age (on the x axis) and gender (indicated with color)
age <- mutate(trips, age = 2022 - birth_year)
ggplot(data = age, aes(x = age)) + geom_histogram(mapping = aes(color = gender))
# plot the ratio of male to female trips (on the y axis) by age (on the x axis)
# hint: use the pivot_wider() function to reshape things to make it easier to compute this ratio
# (you can skip this and come back to it tomorrow if we haven't covered pivot_wider() yet)
trips <- mutate(trips, age = 2022 - birth_year)
trips_by_bd_gender <- trips %>% group_by(age, gender) %>% summarize(count = n())
trips_by_bd_gender <- pivot_wider(trips_by_bd_gender, names_from = gender, values_from = count)
trips_by_bd_gender <- select(trips_by_bd_gender, age, Male, Female)
trips_by_bd_gender <- mutate(trips_by_bd_gender, ratio = Male / Female)
ggplot(data = trips_by_bd_gender, mapping = aes(x = age, y = ratio)) + geom_point()

########################################
# plot weather data
########################################
# plot the minimum temperature (on the y axis) over each day (on the x axis)
day <- mutate(weather, day = substr(weather$date, 9, 10))
ggplot(data = day, mapping = aes(x = day, y = tmin)) + geom_point()
# plot the minimum temperature and maximum temperature (on the y axis, with different colors) over each day (on the x axis)
# hint: try using the pivot_longer() function for this to reshape things before plotting
# (you can skip this and come back to it tomorrow if we haven't covered reshaping data yet)
min_max_day <- weather %>% group_by(ymd, tmin, tmax) %>% summarize()
ggplot(data = min_max_day) + geom_point(mapping = aes(x = ymd, y = tmin, color = 'min')) +
 geom_point(mapping = aes(x = ymd, y = tmax, color = 'max')) +
  scale_colour_manual(name="",values = c("min"="blue", "max"="red")) +
   scale_y_continuous("Temperature") +
    xlab('Day')

########################################
# plot trip and weather data
########################################

# join trips and weather
trips_with_weather <- inner_join(trips, weather, by="ymd")

# plot the number of trips as a function of the minimum temperature, where each point represents a day
# you'll need to summarize the trips and join to the weather data to do this
by_day <- group_by(trips_with_weather, date) %>% summarize(count = n())
by_t_and_d <- group_by(trips_with_weather, ymd, tmin) %>% summarize()
new_col <- select(by_day, count)
x <- cbind(by_t_and_d, new_col)
ggplot(data = x, mapping = aes(x = tmin, y = ymd)) + geom_point(aes(size = count))
# repeat this, splitting results by whether there was substantial precipitation or not
# you'll need to decide what constitutes "substantial precipitation" and create a new T/F column to indicate this
trips_with_weather_and_p <- trips_with_weather
trips_with_weather_and_p$sub_prcp <- with(trips_with_weather, ifelse(prcp > 1.50, "T", "F"))
a <- group_by(trips_with_weather_and_p, ymd, sub_prcp) %>% summarize(count = n())
new_col <- select(a, sub_prcp)
new_x <- cbind(x, new_col)
ggplot(data = new_x, mapping = aes(x = tmin, y = ymd...1)) + geom_point(aes(size = count, color = sub_prcp))
# add a smoothed fit on top of the previous plot, using geom_smooth
ggplot(data = new_x, mapping = aes(x = tmin, y = ymd...1)) + geom_point(aes(size = count, color = sub_prcp)) + geom_smooth()
# compute the average number of trips and standard deviation in number of trips by hour of the day
# hint: use the hour() function from the lubridate package
trips_hour <- mutate(trips, hour = hour(starttime))
trips_by_hour <- trips_hour %>% group_by(ymd, hour) %>% summarize(count = n())
hour_total <- group_by(trips_by_hour, hour) %>% summarize(avg = mean(count), std_dev = sd(count))
# plot the above
ggplot(data = hour_total) + geom_line(mapping = aes(x = hour, y = avg)) + geom_ribbon(mapping = aes(x = hour, ymin = avg - std_dev, ymax = avg + std_dev), alpha = 0.2)
# repeat this, but now split the results by day of the week (Monday, Tuesday, ...) or weekday vs. weekend days
# hint: use the wday() function from the lubridate package
trips_hour <- mutate(trips_hour, day = wday(ymd))
trips_hour <- mutate(trips_hour, day=factor(day, levels=c(1,2,3,4,5,6,7), labels=c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")))
trips_by_day <- trips_hour %>% group_by(ymd, day) %>% summarize(count = n())
day_total <- group_by(trips_by_day, day) %>% summarize(avg = mean(count), std_dev = sd(count))
ggplot(data = day_total) + geom_point(mapping = aes(x = day, y = avg))
ggplot(data = day_total) + geom_point(mapping = aes(x = day, y = std_dev))