package fte

import (
	"encoding/csv"
	"errors"
	"io"
	"net/http"
	"strconv"
)

func GetSPILatest() (wimbledonGameExport GameExport, leagueTableExport TableExport, scheduleExport ScheduleExport, err error) {
	gameSlice, leagueTable, schedule, err := getFTE()
	if err != nil {
		return wimbledonGameExport, leagueTableExport, scheduleExport, err
	}

	// handle Wimbledon's information
	wimbledonGameExport.BuildFromGameSlice(gameSlice)

	// handle the league table
	leagueTableExport.BuildFromLeagueTable(leagueTable)

	// handle the schedule
	scheduleExport.BuildFromScheduleSlice(schedule)

	return wimbledonGameExport, leagueTableExport, scheduleExport, nil
}

func gameResultFromRow(row []string) (goal1, goal2 int) {
	goal1, err := strconv.Atoi(row[colInds["score1"]])
	if err != nil {
		return -1, -1
	}
	goal2, err = strconv.Atoi(row[colInds["score2"]])
	if err != nil {
		return -1, -1
	}

	return goal1, goal2
}

func getFTE() (wimbledonGames []game, leagueTable map[string]teamStats, schedule []scheduleGame, err error) {
	resp538, err := http.Get(csvURL)
	if err != nil {
		return wimbledonGames, leagueTable, schedule, err
	}
	defer resp538.Body.Close()

	read538 := csv.NewReader(resp538.Body)

	// get the header
	header, err := read538.Read()
	if err != nil {
		return wimbledonGames, leagueTable, schedule, err
	}

	// parse the header for the columns we want
	colInds = make(map[string]int, len(colNames))
	for _, checkName := range colNames {
		for ind, name := range header {
			if name == checkName {
				colInds[checkName] = ind
				continue
			}
		}
	}

	wimbledonGames = make([]game, 0, 46)
	leagueTable = make(map[string]teamStats, 24)
	schedule = make([]scheduleGame, 0, 24*23)

	for {
		row, err := read538.Read()
		if err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			return wimbledonGames, leagueTable, schedule, err
		}

		// eliminate rows that don't apply
		if row[colInds["league"]] != league1 || row[colInds["season"]] != currentSeason {
			continue
		}

		// we know this is a league one game, so we can build the team stats
		goal1, goal2 := gameResultFromRow(row)
		// a value of -1 for goal1 means the game hasn't happened
		if goal1 == -1 {
			schedule = append(schedule, scheduleGame{
				date:        row[colInds["date"]],
				homeTeam:    row[colInds["team1"]],
				awayTeam:    row[colInds["team2"]],
				homeGoals:   goal1,
				awayGoals:   goal2,
				hasHappened: false,
			})
		}
		if goal1 != -1 {
			schedule = append(schedule, scheduleGame{
				date:        row[colInds["date"]],
				homeTeam:    row[colInds["team1"]],
				awayTeam:    row[colInds["team2"]],
				homeGoals:   goal1,
				awayGoals:   goal2,
				hasHappened: true,
			})

			// fmt.Println(team1, goal1, team2, goal2)
			team1stats := leagueTable[row[colInds["team1"]]]
			team2stats := leagueTable[row[colInds["team2"]]]

			team1stats.matchesPlayed++
			team2stats.matchesPlayed++

			team1stats.goalDiff += goal1 - goal2
			team2stats.goalDiff += goal2 - goal1

			team1stats.goalsFor += goal1
			team2stats.goalsAgainst += goal1
			team1stats.goalsAgainst += goal2
			team2stats.goalsFor += goal2

			if goal1 > goal2 {
				team1stats.points += 3
			} else if goal2 > goal1 {
				team2stats.points += 3
			} else {
				team1stats.points += 1
				team2stats.points += 1
			}

			leagueTable[row[colInds["team1"]]] = team1stats
			leagueTable[row[colInds["team2"]]] = team2stats
		}

		if !(row[colInds["team1"]] == wimbledon || row[colInds["team2"]] == wimbledon) {
			continue
		}

		var rowGame game

		// if we get here, then we've found a Wimbledon game
		if row[colInds["team1"]] == wimbledon {
			err := rowGame.buildFromRow(row, true)
			if err != nil {
				return wimbledonGames, leagueTable, schedule, err
			}
		} else {
			err := rowGame.buildFromRow(row, false)
			if err != nil {
				return wimbledonGames, leagueTable, schedule, err
			}
		}

		wimbledonGames = append(wimbledonGames, rowGame)
	}

	// loop through all the games and add up the points
	// this assumes the fivethirtyeight sheet is in date order
	for i, g := range wimbledonGames {
		if i == 0 {
			g.cumPoints = g.actualPoints
			g.cumProjPoints = g.projPoints
			g.goalDiff = g.actualFor - g.actualAgainst
			wimbledonGames[i] = g
			continue
		}
		g.cumPoints = wimbledonGames[i-1].cumPoints + g.actualPoints
		g.cumProjPoints = wimbledonGames[i-1].cumProjPoints + g.projPoints
		g.goalDiff = wimbledonGames[i-1].goalDiff + g.actualFor - g.actualAgainst

		wimbledonGames[i] = g
	}

	// add SPI to the leage table and calculate points per game
	respSPI, err := http.Get(spiURL)
	if err != nil {
		return wimbledonGames, leagueTable, schedule, err
	}
	defer respSPI.Body.Close()

	readSPI := csv.NewReader(respSPI.Body)

	// get the header
	headerSPI, err := readSPI.Read()
	if err != nil {
		return wimbledonGames, leagueTable, schedule, err
	}

	// parse the header for the columns we want
	spiColInds = make(map[string]int, len(spiColNames))
	for _, checkName := range spiColNames {
		for ind, name := range headerSPI {
			if name == checkName {
				spiColInds[checkName] = ind
				continue
			}
		}
	}

	for {
		row, err := readSPI.Read()
		if err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			return wimbledonGames, leagueTable, schedule, nil
		}

		if row[colInds["league"]] != league1 {
			continue
		}

		spi, err := strconv.ParseFloat(row[spiColInds["spi"]], 64)
		if err != nil {
			return wimbledonGames, leagueTable, schedule, err
		}

		teamRow := leagueTable[row[spiColInds["name"]]]
		teamRow.spi = spi
		teamRow.pointPercentage = (float64(teamRow.points) / float64(teamRow.matchesPlayed*3)) * 100.0
		teamRow.goalPercentage = float64(teamRow.goalsFor) / float64(teamRow.goalsFor+teamRow.goalsAgainst) * 100.0
		leagueTable[row[spiColInds["name"]]] = teamRow
	}

	return wimbledonGames, leagueTable, schedule, nil
}
