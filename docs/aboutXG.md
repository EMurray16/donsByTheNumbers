Expected goals (xG) are statistical measures of offense and defense tracked during a game. Essentially, every scoring chance is assigned a probability of turning into a goal based on a number of factors, and every chance is summed across the game to get the number of expected goals. This is considered a better indicator of quality possession than either raw possession or goals because it takes in-game data into consideration and, because it's continuous, is less noisy than just counting goals. While goals measure success and failure, xG measures the long-term predictability of that success or failure.

There are several xG models used around the world and each one considers different factors and weights them differently to produce their xG number. Most are proprietary, but two websites have publicly available xG: [footballxg.com](https://footballxg.com/) and [footystats.org.](https://footystats.org/) They produce different results, so looking at both of them gives a more holistic view of how the Dons are playing, and gives us an intuition for how different xG models can be. More detail on their respective algorithms can be found below.

Something all xG models have in common is that they are **team agnostic.** This means that xG models look at data from all teams in all situations. This is important to keep in mind when looking at xG models in the context of a specific team, because there could be attributes the team has (like a world-class shooter or keeper) that mean the models aren't well calibrated to their particular talent. Right now, Wimbledon have proven to be aces at set pieces and Tzanev has shown to be a great shot stopper, which means, arguably, the Dons should beat the xG models in the long run. Whether this is actually true is up for debate — there is a long history in sports of fans arguing models like xG don't apply to their team, only to be proven wrong in the long run.

___

#### Goal Difference Above Expected

Goal Difference Above Expected (GDAE) is the gap between expected goal difference and actual goal difference. This can be calculated both for individual games and over the course of the season. If GDAE is greater than 0, that means Wimbledon came out *ahead* of the xG model. If it's less than 0, Wimbledon came out *behind* the xG model. If xG models perform well over the long run, then the GDAE trends towards 0 as the season progresses, and can be used as a coarse measure of luck. If GDAE is above 0, perhaps the Dons were lucky, and if GDAE is less than 0, perhaps they were unlucky. In theory, this is true when considering both individual games and the entire seeason.

___

#### Measuring Luck with xG: RAGE

No matter what, measuring luck with xG should be done with some caution. Because xG is based on all teams at all times, it cannot account for the combinations of talents and tactics that any individual team plays with. Nonetheless, it is useful, in part because comparing real results to xG can be a good starting point for deeper analysis of the team.

To that end, coming up with a measure of luck based on xG does have some value, even if it is a blunt instrument at best. GDAE gets at the idea of luck, but it's not very detailed. Goal difference is a combination of offense and defense, and it doesn't give much insight into how each part of the game has really played out. This is where RAGE comes in: **R**atio of **A**ctual **G**oals to **E**xpected. 

RAGE is a coarse measure of luck which can separate out offense and defense. It's calculated based on the following equation:
$$
RAGE=[\frac{G_{for}}{xG_{for}} + \frac{xG_{against}}{G_{against}}] * \frac{1}{2}
$$
RAGE is comprised of two basic terms: the ratio of goals for to expected goals for, and the ratio of expected goals against to goals against. The first term is a measure of offense, and the second of defense. If a team matches their xG model, then the value of both ratios is 1. If they score more than their xG for, then the offensive RAGE pushes above 1, and if they score fewer goals than their xG then the offensive RAGE pushes below 1. The same is true for defense, but flipped - if they allow fewer goals than their xG the defensive RAGE is above 1, and if they allow more goals their defensive RAGE. Finally, there is combined RAGE - this is the average of the two, which is why the RAGE equation has a multiplication by one half. 

In short, RAGE is built so that it should be close to 1 if an xG model is well calibrated, good luck (either scoring a lot on offense of conceding very little on defense) *increases* the value above 1, and bad luck (either not scoring very little or conceding a lot) *decreases* the value to below 1.

RAGE is meant to be interpreted only as a cumulative measure throughout the season - it doesn't apply to individual games. This is because RAGE doesn't capture the difference between when a team scores 0 goals in a game when their xG is 3 versus a game when it's 0.5, even though the former is clearly more unlucky. However, because of its cumulative nature, RAGE becomes a useful measure fairly quickly - after about 7 games. 
___

#### Details of xG Algorithms

##### **footystats.org**

footystats offers a subscription, so their xG model is proprietary. However, they do provide a list of what their xG model accounts for with each shot:

- Assist Type
- Distance from Goal
- Type of Attack
- Shot Angle
- Body Part Used to Shoot

##### **footballxg.com**

footballxg also provide very little transparency on how their xG model works, because they also offer a service gamblers. The best documentation they have is the following paragraph:

> The process for calculating an expected goal from any given chance was originally created by Opta. They reviewed hundreds of thousands of historical shots to then work out the percentage chance of a shot being scored from any particular situation. There are now a range of different models that are getting more and more advanced (taking into account the location of the shot, the position of defenders and goalkeeper, height of shot).

