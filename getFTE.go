package main

/*
#define USE_RINTERNALS
#include <Rinternals.h>
#cgo CFLAGS: -I/Library/Frameworks/R.framework/Headers/ -I/usr/share/R/include/
*/
import "C"

import (
	"donsByTheNumbers/fte"
	"github.com/EMurray16/rgo/v2"
	"time"
)

//export UpdateFiveThirtyEight
func UpdateFiveThirtyEight() C.SEXP {
	outGames, outTable, outSched, err := fte.GetSPILatest()
	if err != nil {
		// return the error as a string
		outString := rgo.CharacterToRSEXP([]string{err.Error()})
		out, _ := rgo.ExportRSEXP[C.SEXP](outString)
		return out
	}

	// build an R data.frame from the games
	sexpSlice1 := make([]*rgo.RSEXP, 18)
	names1 := []string{"date", "opponent", "home", "wimbledonSPI", "opponentSPI", "winProb", "lossProb", "tieProb",
		"projPoints", "pgFor", "pgOpp", "importance", "gFor", "gOpp", "points",
		"cumProjPoints", "cumPoints", "goalDiff"}

	sexpSlice1[0] = rgo.CharacterToRSEXP(outGames.Dates)
	sexpSlice1[1] = rgo.CharacterToRSEXP(outGames.Opponents)
	sexpSlice1[2] = rgo.NumericToRSEXP(outGames.Home)
	sexpSlice1[3] = rgo.NumericToRSEXP(outGames.WimbledonSPI)
	sexpSlice1[4] = rgo.NumericToRSEXP(outGames.OpponentSPI)
	sexpSlice1[5] = rgo.NumericToRSEXP(outGames.WinProb)
	sexpSlice1[6] = rgo.NumericToRSEXP(outGames.LossProb)
	sexpSlice1[7] = rgo.NumericToRSEXP(outGames.TieProb)
	sexpSlice1[8] = rgo.NumericToRSEXP(outGames.ProjPoints)
	sexpSlice1[9] = rgo.NumericToRSEXP(outGames.ProjGoalsFor)
	sexpSlice1[10] = rgo.NumericToRSEXP(outGames.ProjGoalsAgainst)
	sexpSlice1[11] = rgo.NumericToRSEXP(outGames.Importance)
	sexpSlice1[12] = rgo.NumericToRSEXP(outGames.GoalsFor)
	sexpSlice1[13] = rgo.NumericToRSEXP(outGames.GoalsAgainst)
	sexpSlice1[14] = rgo.NumericToRSEXP(outGames.Points)
	sexpSlice1[15] = rgo.NumericToRSEXP(outGames.CumProjPoints)
	sexpSlice1[16] = rgo.NumericToRSEXP(outGames.CumPoints)
	sexpSlice1[17] = rgo.NumericToRSEXP(outGames.CumGoalDiff)

	dataFrame1, err := rgo.MakeDataFrame([]string{}, names1, sexpSlice1...)
	if err != nil {
		outString := rgo.CharacterToRSEXP([]string{err.Error()})
		out, _ := rgo.ExportRSEXP[C.SEXP](outString)
		return out
	}

	// build an R data.frame from the league table
	sexpSlice2 := make([]*rgo.RSEXP, 7)
	names2 := []string{"team", "matchesPlayed", "points", "goalDiff",
		"pointPercentage", "goalPercentage", "spi"}
	sexpSlice2[0] = rgo.CharacterToRSEXP(outTable.Teams)
	sexpSlice2[1] = rgo.NumericToRSEXP(outTable.MatchesPlayed)
	sexpSlice2[2] = rgo.NumericToRSEXP(outTable.Points)
	sexpSlice2[3] = rgo.NumericToRSEXP(outTable.GoalDiff)
	sexpSlice2[4] = rgo.NumericToRSEXP(outTable.PointPercentage)
	sexpSlice2[5] = rgo.NumericToRSEXP(outTable.GoalPercentage)
	sexpSlice2[6] = rgo.NumericToRSEXP(outTable.SPI)

	dataFrame2, err := rgo.MakeDataFrame([]string{}, names2, sexpSlice2...)
	if err != nil {
		// return the error as a string
		outString := rgo.CharacterToRSEXP([]string{err.Error()})
		out, _ := rgo.ExportRSEXP[C.SEXP](outString)
		return out
	}

	// build an R data.frame from the schedule table
	sexpSlice3 := make([]*rgo.RSEXP, 4)
	names3 := []string{"team", "opponent", "isHome", "hasHappened"}
	sexpSlice3[0] = rgo.CharacterToRSEXP(outSched.Team)
	sexpSlice3[1] = rgo.CharacterToRSEXP(outSched.Opponent)
	sexpSlice3[2] = rgo.NumericToRSEXP(outSched.IsHome)
	sexpSlice3[3] = rgo.NumericToRSEXP(outSched.HasHappened)

	dataFrame3, err := rgo.MakeDataFrame([]string{}, names3, sexpSlice3...)
	if err != nil {
		outString := rgo.CharacterToRSEXP([]string{err.Error()})
		out, _ := rgo.ExportRSEXP[C.SEXP](outString)
		return out
	}

	// the last element is a string with the timestamp
	t := time.Now()
	timeStampString := t.Format("3:04:05 PM MST, Monday Jan 2, 2006")
	dateSEXP := rgo.CharacterToRSEXP([]string{timeStampString})

	// export a named list
	outList, err := rgo.MakeNamedList([]string{"wimbledonGames", "leagueTable", "leagueSchedule", "fteUpdateTimestamp"},
		dataFrame1, dataFrame2, dataFrame3, dateSEXP)
	if err != nil {
		outString := rgo.CharacterToRSEXP([]string{err.Error()})
		out, _ := rgo.ExportRSEXP[C.SEXP](outString)
		return out
	}

	out, err := rgo.ExportRSEXP[C.SEXP](outList)
	if err != nil {
		outString := rgo.CharacterToRSEXP([]string{err.Error()})
		out, _ := rgo.ExportRSEXP[C.SEXP](outString)
		return out
	}

	return out
}

// Everything in this function should be commented out when building the shared library
func main() {
	/*games, table, err := fte.GetSPILatest()
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(len(games.Dates))
	fmt.Println(table.SPI)*/
}
