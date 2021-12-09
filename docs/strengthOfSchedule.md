In order to better contextualize the League One table, especially the races to avoid relegation at the bottom and get promoted (or at least make the playoff) at the top, it's nice to have a sense for how tough a team's schedule has been and will be. 

For example, Wimbledon were only a few points clear of relegation heading into the November international break. But they'd played almost every team in the top 10, and most of their games against weaker opponents they would expect to beat, like Morecambe and Shrewsbury, were on the road. Fans were getting impatient, but I never saw it mentioned that they had one of the toughest early-season schedules in League One. As I write this now, Wimbledon have finally had an easier run of games, gotten 7 points in their last 3 games (Crewe, Fleetwood, and Accrington) and sit 6 points clear of relegation. 

### Individual Team Strength

The first step to creating a metric for strength of schedule is coming up with a strength metric for every team. An obvious place to start is FiveThirtyEight's SPI, which attempts to do this exact thing. They even say so themselves:

> At the heart of our club soccer forecasts are FiveThirtyEight’s SPI ratings, which are our best estimate of a team’s overall strength.

But FiveThirtyEight's SPI can't be the only metric used, for a few reasons. First, it's a lagging indicator. It has short-term predictive power for individual matches, but FiveThirtyEight's SPI increases only once a team is consistently beating expectations. Second, it primarily uses past data, both in terms of player value and team performance, to assign SPI. While SPI is adjusted according to how a team plays, it will always have some component of preseason expectations built in. 

Therefore, we also want to use measures that are a little bit more aggressive in responding to a team's form, and which are only concerned with on-pitch results from the current season. Therefore, we calculate a team's strength using two percentage stats from the current season only.

1. The percentage a possible points a team has accumulated in the table
2. The percentage of goals they've scored in all of their games. 

These measure have an added bonus because FiveThirtyEight's SPI is, at its core, a percentage stat. SPI is the percent of possible points a team is expected to get when playing a globally average club team on a neutral pitch. 

A team's strength rating is a slightly modified average of these three percentage stats. In general, point percentage ranges from 30-60%, goal percentage ranges from 35-65%, and FiveThirtyEight's SPI ranges from 15-35% for League One. In order to make sure all the percentage stats are weighted approximately equally, SPI is doubled in the strength calculation:

$$
Strength = (pointPercentage + goalPercentage + 2*SPI) / 3
$$

It's important to note here that the doubling of SPI *does not* mean it's weighted twice as much as the other stats. 

Overall, team strengths in League One vary from 30 to 65, with an average of roughly 45.5. Why 45.5 and not 50? Intuitively, the best way to understand this average is to think of the averagest of all average teams - one that wins a third of its games, loses another third, and ties the final third. We can calculate the expected percentage of points in the table they'll get:

$$
pointPercentage = (1/3 * 3 + 1/3 * 1) / 3 = 0.333 + 0.111 = 44.4%
$$
From here, the extra bit to move from 44.4 to 45.5 comes from the fact that the goal share will generally be close to 50%. In practice, the interpretation of team strength is never this clean, but it's a good way to build intuition nonetheless.

### Strength of Schedule

Once every team's strength has been measured, strength of schedule is easy to calculate. It's simply the mean strength of all the opponents on the schedule. 

There is one adjustment made in the calculations: home-field advantage. In every match, the home team's strength is increased by 15%, while the away team's is decreased by 15%. I chose this 15% more or less arbitrarily, but it's fairly close to the size of home-field advantage in League One both in terms of [point percentage](https://www.soccerstats.com/table.asp?league=england3&tid=ha) and [expected goals](https://footystats.org/england/efl-league-one/home-advantage-table).

Because the average team strength in League One is about 45, the average schedule difficulty is about 45 as well. However, the average strength of every team's strength will not be the same. The reason for this is obvious: weak teams have tougher schedules because they don't get to play themselves twice, while strong teams have weaker schedules because they don't have to play themselves twice. 
