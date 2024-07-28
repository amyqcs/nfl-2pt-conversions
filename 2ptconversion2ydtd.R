library(tidyverse)
library(nflfastR) # datasets, teams, colors, & logos
library(vip) # variable importance of each variable
library(ggimage) # plot teams
library(dplyr)

# load play by play data (goes back to 1999)
pbp <- load_pbp(2018:2023) # function from nfl package

# create dataset w/ just 2 pt conversions
two_points <- pbp %>%
  # use comma in filter statement if multiple filter conditions
  filter(two_point_attempt == 1, !is.na(play_type)) # don't want any nas for play type, don't want play type that is data error

two_points %>%
  group_by(two_point_conv_result) %>%
  tally(sort = T) # tallies what happens on 2 pt conversions

# convert result to binary
two_points <- two_points %>%
  mutate(two_point_conv_result = ifelse(two_point_conv_result == "success", 1, 0))

# create 2 pt conversion dataframe
team_two_point <- two_points %>%
  # group by possession team
  group_by(posteam) %>%
  summarize(count = n(),
            succ = sum(two_point_conv_result),
            rate = succ/count)

# create dataset w/ td's from 2 yd line

td_points <- pbp %>% 
  filter(yardline_100 == 2, # only want td's from 2 yd line
         two_point_attempt != 1, # don't include 2-pt conversion attempts
         field_goal_attempt != 1, # don't include field goal attempts
         # don't include if na
         !is.na(touchdown),
         !is.na(play_type))

# just for fun, types of touchdowns --> rushing most common
td_points %>% 
  summarize(total_td = sum(touchdown),
            pass = sum(pass_touchdown),
            rush = sum(rush_touchdown),
            return = sum(return_touchdown))

team_td_point <- td_points %>% 
  # group by possession team
  group_by(posteam) %>% 
  summarize(count = n(),
            succ = sum(touchdown),
            rate = succ/count)

# merging 2 pt conversion & 2 yd td datasets
team <- team_two_point$posteam
two_min_td <- team_two_point$rate - team_td_point$rate
two_td_comp <- data.frame(team, two_min_td)

two_td_comp %>%
  ggplot(aes(x = team, y = two_min_td))  +
  # -c(19, 27, 30, 33)] to get rid of repeat team logos
  geom_image(aes(image = teams_colors_logos$team_logo_espn[-c(19, 27, 30, 33)]), asp = 16/9, size = .05) +
  theme_minimal() +
  labs(x = "Team", y = "Difference",
       title = "Difference between 2 Pt Conversion Rate and 2 Yd Td Rate from 2018-2023") +
  geom_hline(yintercept = 0)

mean(team_two_point$rate) # 0.494
mean(team_td_point$rate) # 0.405

sd(team_two_point$rate) # 0.0981
sd(team_td_point$rate) # 0.0638

# test for statistically significant difference
t.test(team_two_point_23$rate, team_td_point_23$rate) # SIGNIFICANT BY WELCH 2 SAMPLE T-TEST
