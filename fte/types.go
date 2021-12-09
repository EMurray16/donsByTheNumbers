package fte

import "strconv"

var (
	csvURL = "https://projects.fivethirtyeight.com/soccer-api/club/spi_matches_latest.csv"
	spiURL = "https://projects.fivethirtyeight.com/soccer-api/club/spi_global_rankings.csv"

	// notes on column names: team 1 is always the home team
	colNames = []string{"season", "date", "league",
		"team1", "team2", "spi1", "spi2", "prob1", "prob2", "probtie",
		"proj_score1", "proj_score2", "importance1", "importance2",
		"score1", "score2"}

	spiColNames = []string{"name", "league", "spi"}

	// convenience strings
	league1       = "English League One"
	wimbledon     = "AFC Wimbledon"
	currentSeason = "2021"

	colInds    map[string]int
	spiColInds map[string]int

	leagueTable map[string]teamStats
)

type game struct {
	gameDate, opponentTeam                 string
	wimbledonHome                          bool
	wimbledonSPI, opponentSPI              float64
	win, loss, tie, projPoints             float64
	projFor, projAgainst                   float64
	importance                             float64
	actualFor, actualAgainst, actualPoints int
	cumProjPoints                          float64
	cumPoints, goalDiff                    int
}

func (g *game) toStrings() []string {
	out := make([]string, 18)

	out[0] = g.gameDate
	out[1] = g.opponentTeam
	out[2] = strconv.FormatBool(g.wimbledonHome)

	out[3] = strconv.FormatFloat(g.wimbledonSPI, 'f', 4, 64)
	out[4] = strconv.FormatFloat(g.opponentSPI, 'f', 4, 64)

	out[5] = strconv.FormatFloat(g.win, 'f', 4, 64)
	out[6] = strconv.FormatFloat(g.loss, 'f', 4, 64)
	out[7] = strconv.FormatFloat(g.tie, 'f', 4, 64)
	out[8] = strconv.FormatFloat(g.projPoints, 'f', 4, 64)

	out[9] = strconv.FormatFloat(g.projFor, 'f', 4, 64)
	out[10] = strconv.FormatFloat(g.projAgainst, 'f', 4, 64)

	out[11] = strconv.FormatFloat(g.importance, 'f', 4, 64)

	out[12] = strconv.Itoa(g.actualFor)
	out[13] = strconv.Itoa(g.actualAgainst)
	out[14] = strconv.Itoa(g.actualPoints)

	out[15] = strconv.FormatFloat(g.cumProjPoints, 'f', 4, 64)
	out[16] = strconv.Itoa(g.cumPoints)
	out[17] = strconv.Itoa(g.goalDiff)

	return out
}

func (g *game) buildFromRow(row []string, wimbledonHome bool) (err error) {
	// start with the fields that don't depend on which team Wimbledon is
	g.gameDate = row[colInds["date"]]
	g.wimbledonHome = wimbledonHome
	g.tie, err = strconv.ParseFloat(row[colInds["probtie"]], 64)
	if err != nil {
		return err
	}

	parseErrs := make([]error, 8)

	if wimbledonHome {
		g.opponentTeam = row[colInds["team2"]]

		g.wimbledonSPI, parseErrs[0] = strconv.ParseFloat(row[colInds["spi1"]], 64)
		g.opponentSPI, parseErrs[1] = strconv.ParseFloat(row[colInds["spi2"]], 64)

		g.win, parseErrs[2] = strconv.ParseFloat(row[colInds["prob1"]], 64)
		g.loss, parseErrs[3] = strconv.ParseFloat(row[colInds["prob2"]], 64)

		g.projFor, parseErrs[4] = strconv.ParseFloat(row[colInds["proj_score1"]], 64)
		g.projAgainst, parseErrs[5] = strconv.ParseFloat(row[colInds["proj_score2"]], 64)

		if row[colInds["score1"]] != "" {
			// the first game of the season has no importance measure, so ignore the error parsing it
			g.importance, _ = strconv.ParseFloat(row[colInds["importance1"]], 64)
			g.actualFor, parseErrs[6] = strconv.Atoi(row[colInds["score1"]])
			g.actualAgainst, parseErrs[7] = strconv.Atoi(row[colInds["score2"]])
		}
	} else {
		g.opponentTeam = row[colInds["team1"]]

		g.wimbledonSPI, parseErrs[0] = strconv.ParseFloat(row[colInds["spi2"]], 64)
		g.opponentSPI, parseErrs[1] = strconv.ParseFloat(row[colInds["spi1"]], 64)

		g.win, parseErrs[2] = strconv.ParseFloat(row[colInds["prob2"]], 64)
		g.loss, parseErrs[3] = strconv.ParseFloat(row[colInds["prob1"]], 64)

		g.projFor, parseErrs[4] = strconv.ParseFloat(row[colInds["proj_score2"]], 64)
		g.projAgainst, parseErrs[5] = strconv.ParseFloat(row[colInds["proj_score1"]], 64)

		if row[colInds["score1"]] != "" {
			// the first game of the season has no importance measure, so ignore the error parsing it
			g.importance, _ = strconv.ParseFloat(row[colInds["importance2"]], 64)
			g.actualFor, parseErrs[6] = strconv.Atoi(row[colInds["score2"]])
			g.actualAgainst, parseErrs[7] = strconv.Atoi(row[colInds["score1"]])
		}
	}

	// if there are any errors then we need to complain
	for _, e := range parseErrs {
		if e != nil {
			return err
		}
	}

	g.projPoints = g.win*3 + g.tie

	if g.actualFor-g.actualAgainst > 0 {
		g.actualPoints = 3
	} else if g.actualFor == g.actualAgainst {
		g.actualPoints = 1
	}

	// fmt.Println(g)

	return nil
}

type GameExport struct {
	Dates, Opponents                       []string
	Home                                   []int
	WimbledonSPI, OpponentSPI              []float64
	WinProb, LossProb, TieProb, ProjPoints []float64
	ProjGoalsFor, ProjGoalsAgainst         []float64
	Importance                             []float64
	GoalsFor, GoalsAgainst, Points         []int
	CumProjPoints                          []float64
	CumPoints, CumGoalDiff                 []int
}

func (ge *GameExport) BuildFromGameSlice(gameSlice []game) {
	nGames := len(gameSlice)

	ge.Dates = make([]string, nGames)
	ge.Opponents = make([]string, nGames)

	ge.Home = make([]int, nGames)

	ge.WimbledonSPI = make([]float64, nGames)
	ge.OpponentSPI = make([]float64, nGames)

	ge.WinProb = make([]float64, nGames)
	ge.LossProb = make([]float64, nGames)
	ge.TieProb = make([]float64, nGames)
	ge.ProjPoints = make([]float64, nGames)

	ge.ProjGoalsFor = make([]float64, nGames)
	ge.ProjGoalsAgainst = make([]float64, nGames)

	ge.Importance = make([]float64, nGames)

	ge.GoalsFor = make([]int, nGames)
	ge.GoalsAgainst = make([]int, nGames)
	ge.Points = make([]int, nGames)

	ge.CumProjPoints = make([]float64, nGames)
	ge.CumPoints = make([]int, nGames)
	ge.CumGoalDiff = make([]int, nGames)

	for i, g := range gameSlice {
		ge.Dates[i] = g.gameDate
		ge.Opponents[i] = g.opponentTeam

		// false is 0, so we only need to update this when Wimbledon is home
		if g.wimbledonHome {
			ge.Home[i] = 1
		}

		ge.WimbledonSPI[i] = g.wimbledonSPI
		ge.OpponentSPI[i] = g.opponentSPI

		ge.WinProb[i] = g.win
		ge.LossProb[i] = g.loss
		ge.TieProb[i] = g.tie
		ge.ProjPoints[i] = g.projPoints

		ge.ProjGoalsFor[i] = g.projFor
		ge.ProjGoalsAgainst[i] = g.projAgainst

		ge.Importance[i] = g.importance

		ge.GoalsFor[i] = g.actualFor
		ge.GoalsAgainst[i] = g.actualAgainst
		ge.Points[i] = g.actualPoints

		ge.CumProjPoints[i] = g.cumProjPoints
		ge.CumPoints[i] = g.cumPoints
		ge.CumGoalDiff[i] = g.goalDiff
	}
}

type scheduleGame struct {
	date, homeTeam, awayTeam string
	hasHappened              bool
	homeGoals, awayGoals     int
}

type teamStats struct {
	name                                 string
	matchesPlayed, points, goalDiff      int
	goalsFor, goalsAgainst               int
	spi, pointPercentage, goalPercentage float64
}

type TableExport struct {
	Teams                                []string
	MatchesPlayed, Points, GoalDiff      []int
	SPI, PointPercentage, GoalPercentage []float64
}

func (TE *TableExport) BuildFromLeagueTable(leagueTable map[string]teamStats) {
	nTeams := len(leagueTable) // this should always be 24, but we'll calculate it to be sure

	// allocate the slices
	TE.Teams = make([]string, 0, nTeams)
	TE.MatchesPlayed = make([]int, 0, nTeams)
	TE.Points = make([]int, 0, nTeams)
	TE.GoalDiff = make([]int, 0, nTeams)
	TE.SPI = make([]float64, 0, nTeams)
	TE.PointPercentage = make([]float64, 0, nTeams)
	TE.GoalPercentage = make([]float64, 0, nTeams)

	for team, stats := range leagueTable {
		TE.Teams = append(TE.Teams, team)
		TE.MatchesPlayed = append(TE.MatchesPlayed, stats.matchesPlayed)
		TE.Points = append(TE.Points, stats.points)
		TE.GoalDiff = append(TE.GoalDiff, stats.goalDiff)
		TE.SPI = append(TE.SPI, stats.spi)
		TE.PointPercentage = append(TE.PointPercentage, stats.pointPercentage)
		TE.GoalPercentage = append(TE.GoalPercentage, stats.goalPercentage)
	}
}

type ScheduleExport struct {
	Team, Opponent []string
	// These could be bools, but ints are easier to pass into R
	IsHome, HasHappened []int
}

func (SE *ScheduleExport) BuildFromScheduleSlice(schedSlice []scheduleGame) {
	nGames := len(schedSlice)

	SE.Team = make([]string, 0, nGames*2)
	SE.Opponent = make([]string, 0, nGames*2)
	SE.IsHome = make([]int, 0, nGames*2)
	SE.HasHappened = make([]int, 0, nGames*2)

	for _, match := range schedSlice {
		var hasHappenedInt int = 0
		if match.hasHappened {
			hasHappenedInt = 1
		}

		SE.Team = append(SE.Team, []string{match.homeTeam, match.awayTeam}...)
		SE.Opponent = append(SE.Opponent, []string{match.awayTeam, match.homeTeam}...)
		SE.IsHome = append(SE.IsHome, []int{1, 0}...)
		SE.HasHappened = append(SE.HasHappened, []int{hasHappenedInt, hasHappenedInt}...)
	}
}
