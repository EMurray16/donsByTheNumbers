Winning odds are calculated based on expected goals. In this app, they are either forecasted average goals before the game is played or true expected goals after the game has been played. For more information on how expected goals are calculated, visit the "FiveThirtyEight" and "Expected Goals" sections of this site. 

Why are these win probabilities helpful? Basically, they summarize both what the expectations were going into the game, and how well Wimbledon actually played. Viewing through the lens of probability is much more succinct and interpretable than through other measures like possession and shot share.

### From goals to probability

Goals are converted to an outcome distribution using the Poisson distribution. FiveThirtyEight has a [very good explanation for how they forecast matches](https://fivethirtyeight.com/methodology/how-our-club-soccer-predictions-work/#:~:text=than%204-0.-,Forecasting%20matches,-Given%20two%20teams). It's far better than anything I can do here.

The quick version is that the Poisson process is used to calculate the expected distribution of goals for each team. Each team's distribution is calculated to create a matrix of possibilities, an adjustment is applied to account for the increased likelihood of ties, and then the cases are summed to calculate odds of each team winning.

### Score-Adjusted xG Model

When mapping expected goals to probability of winning, it's important to account for *score effects*, or the notion that the score affects how the game is played. The cliche adage "goals change games" is cliche because it's true.

When a team is winning, they generally play a more defensive style. This will lead to them conceding more possession, shots, and expected goals, but if they play good defense this doesn't actually hurt their chances of winning - it increases it. Therefore, we should take expected goals when teams are ahead or behind with a grain of salt. 

Score-adjusted xG reduces a team's xG by the time they are trailing in the second half. The longer they're trailing, the more their xG is reduced. When their odds of victory are calculated using the Poisson method based on this reduced xG, we get a more realistic picture of how the game actually went. Another way to think about this is that the score-adjusted xG model gives more credit for generating offense in the first half, or while leading or tied in the second half, than generating offense in the second half when trailing.

It's important to note that this score-adjusted xG is not useful for evaluating how a team played offensively or defensively. Expected goals are expected goals whether they occur in the 10th minute or the 80th minute. Instead, it is only useful when mapping these expected goals to win probabilities.