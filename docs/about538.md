FiveThirtyEight's Club Soccer Model calculates the strength of pretty much every club team in the world and uses those ratings to make predictions, including game-by-game odds of winning and league table predictions. This page covers only Wimbledon-specific results and doesn't include odds related to promotion and relegation. [Head to fivethirtyeight directly to get that information](https://projects.fivethirtyeight.com/soccer-predictions/league-one/). 

FiveThirtyEight is [very transparent about their methods](https://fivethirtyeight.com/methodology/how-our-club-soccer-predictions-work/), but the highlights will be covered here.

___

#### Soccer Power Index (SPI)

> At the heart of our club soccer forecasts are FiveThirtyEight’s SPI ratings, which are our best estimate of a team’s overall strength. In our system, every team has an offensive rating that represents the number of goals it would be expected to score against an average team on a neutral field, and a defensive rating that represents the number of goals it would be expected to concede. These ratings, in turn, produce an overall SPI rating, which represents the percentage of available points — a win is worth 3 points, a tie worth 1 point, and a loss worth 0 points — the team would be expected to take if that match were played over and over again.

In general, a League One side has an SPI in the range of 15-35, while a Premier League team will be above sixty, with the "Big Six" normally in the neighborhood of 90. 

A team's SPI is based on the value of their players (via [transfermarkt](https://www.transfermarkt.com/)), their performance the previous season, and, as the season progresses, how they do in matches relative to their expectations. A team that consistently beats their SPI projections will see their SPI increase over time, and a team that consistently underperforms their SPI will see their SPI decrease over time.

It's important to note that the model updates SPI based on how a team performs *relative to expectations*, not just based on wins and losses. If Wimbledon beat a team destined for relegation we should not expect their SPI to move much. If they beat a strong team destined for promotion (especially if they play well in that game rather than getting lucky), then we can expect to see their SPI increase.

#### Forecasting Games

The FiveThirtyEight model uses the SPI of team, plus their offense and defense ratings, to forecast the average score of each game - this is like a projected version of expected goals. From there, they create a score distribution for each team, turn this into a matrix, account for the fact that draws are more likely than they "ought" to be, and then turn these into win, loss, and draw probabilities.

#### Forecasting Seasons

Once every game in a season has been forecasted, the FiveThirtyEight model runs a Monte Carlo simulation, where the season is played out 20,000 times based on the individual game forecasts. The results for every team in each season are recorded, and then probabilities of certain events (like promotion and relegation) are recorded.

FiveThirtyEight's publicly available data includes all the information needed to assemble a Monte Carlo simulation and calculate the same probabilities they publish in their [league tables](https://projects.fivethirtyeight.com/soccer-predictions/league-one/), but this is computationally expensive and not worth doing. This is why this app doesn't include odds related to the league table, such as promotion and relegation chances. 