package fte

import (
	"encoding/csv"
	"errors"
	"io"
	"net/http"
)

func GetSPILatest() (wimbledonGameExport GameExport, err error) {
	gameSlice, err := getFTE()
	if err != nil {
		return wimbledonGameExport, err
	}

	wimbledonGameExport.BuildFromGameSlice(gameSlice)
	return wimbledonGameExport, nil
}

func getFTE() (wimbledonGames []game, err error) {
	resp538, err := http.Get(csvURL)
	if err != nil {
		return wimbledonGames, err
	}

	defer resp538.Body.Close()
	read538 := csv.NewReader(resp538.Body)

	// get the header
	header, err := read538.Read()
	if err != nil {
		return wimbledonGames, err
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

	for {
		row, err := read538.Read()
		if err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			return wimbledonGames, err
		}

		// eliminate rows that don't apply
		if row[colInds["league"]] != league1 || row[colInds["season"]] != currentSeason {
			continue
		}
		if !(row[colInds["team1"]] == wimbledon || row[colInds["team2"]] == wimbledon) {
			continue
		}

		var rowGame game

		// if we get here, then we've found a Wimbledon game
		if row[colInds["team1"]] == wimbledon {
			err := rowGame.buildFromRow(row, true)
			if err != nil {
				return wimbledonGames, err
			}
		} else {
			err := rowGame.buildFromRow(row, false)
			if err != nil {
				return wimbledonGames, err
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

	return wimbledonGames, nil
}

