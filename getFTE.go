package main

/*
#define USE_RINTERNALS
#include <Rinternals.h>
#cgo CFLAGS: -I/Library/Frameworks/R.framework/Headers/ -I/usr/share/R/include/
*/
import "C"

import (
	"donsByTheNumbers/fte"
	"donsByTheNumbers/rsexp"
	"time"
)

//export UpdateFiveThirtyEight
func UpdateFiveThirtyEight() C.SEXP {
	outGames, outTable, outSched, err := fte.GetSPILatest()
	if err != nil {
		// return the error as a string
		outString := rsexp.CharacterToRSEXP([]string{err.Error()})
		out, _ := rsexp.Export[C.SEXP](outString)
		return out
	}

	// build an R data.frame from the games
	sexpSlice1 := make([]*rsexp.RSEXP, 18)
	names1 := []string{"date","opponent","home","wimbledonSPI","opponentSPI","winProb","lossProb","tieProb",
		"projPoints","pgFor","pgOpp","importance","gFor","gOpp","points",
		"cumProjPoints","cumPoints","goalDiff"}

	sexpSlice1[0] = rsexp.CharacterToRSEXP(outGames.Dates)
	sexpSlice1[1] = rsexp.CharacterToRSEXP(outGames.Opponents)
	sexpSlice1[2] = rsexp.NumericToRSEXP(outGames.Home)
	sexpSlice1[3] = rsexp.NumericToRSEXP(outGames.WimbledonSPI)
	sexpSlice1[4] = rsexp.NumericToRSEXP(outGames.OpponentSPI)
	sexpSlice1[5] = rsexp.NumericToRSEXP(outGames.WinProb)
	sexpSlice1[6] = rsexp.NumericToRSEXP(outGames.LossProb)
	sexpSlice1[7] = rsexp.NumericToRSEXP(outGames.TieProb)
	sexpSlice1[8] = rsexp.NumericToRSEXP(outGames.ProjPoints)
	sexpSlice1[9] = rsexp.NumericToRSEXP(outGames.ProjGoalsFor)
	sexpSlice1[10] = rsexp.NumericToRSEXP(outGames.ProjGoalsAgainst)
	sexpSlice1[11] = rsexp.NumericToRSEXP(outGames.Importance)
	sexpSlice1[12] = rsexp.NumericToRSEXP(outGames.GoalsFor)
	sexpSlice1[13] = rsexp.NumericToRSEXP(outGames.GoalsAgainst)
	sexpSlice1[14] = rsexp.NumericToRSEXP(outGames.Points)
	sexpSlice1[15] = rsexp.NumericToRSEXP(outGames.CumProjPoints)
	sexpSlice1[16] = rsexp.NumericToRSEXP(outGames.CumPoints)
	sexpSlice1[17] = rsexp.NumericToRSEXP(outGames.CumGoalDiff)

	dataFrame1, err := rsexp.MakeDataFrame([]string{}, names1, sexpSlice1...)
	if err != nil {
		outString := rsexp.CharacterToRSEXP([]string{err.Error()})
		out, _ := rsexp.Export[C.SEXP](outString)
		return out
	}

	// build an R data.frame from the league table
	sexpSlice2 := make([]*rsexp.RSEXP, 7)
	names2 := []string{"team","matchesPlayed","points","goalDiff",
		"pointPercentage","goalPercentage","spi"}
	sexpSlice2[0] = rsexp.CharacterToRSEXP(outTable.Teams)
	sexpSlice2[1] = rsexp.NumericToRSEXP(outTable.MatchesPlayed)
	sexpSlice2[2] = rsexp.NumericToRSEXP(outTable.Points)
	sexpSlice2[3] = rsexp.NumericToRSEXP(outTable.GoalDiff)
	sexpSlice2[4] = rsexp.NumericToRSEXP(outTable.PointPercentage)
	sexpSlice2[5] = rsexp.NumericToRSEXP(outTable.GoalPercentage)
	sexpSlice2[6] = rsexp.NumericToRSEXP(outTable.SPI)

	dataFrame2, err := rsexp.MakeDataFrame([]string{}, names2, sexpSlice2...)
	if err != nil {
		// return the error as a string
		outString := rsexp.CharacterToRSEXP([]string{err.Error()})
		out, _ := rsexp.Export[C.SEXP](outString)
		return out
	}

	// build an R data.frame from the schedule table
	sexpSlice3 := make([]*rsexp.RSEXP, 4)
	names3 := []string{"team","opponent","isHome","hasHappened"}
	sexpSlice3[0] = rsexp.CharacterToRSEXP(outSched.Team)
	sexpSlice3[1] = rsexp.CharacterToRSEXP(outSched.Opponent)
	sexpSlice3[2] = rsexp.NumericToRSEXP(outSched.IsHome)
	sexpSlice3[3] = rsexp.NumericToRSEXP(outSched.HasHappened)

	dataFrame3, err := rsexp.MakeDataFrame([]string{}, names3, sexpSlice3...)
	if err != nil {
		outString := rsexp.CharacterToRSEXP([]string{err.Error()})
		out, _ := rsexp.Export[C.SEXP](outString)
		return out
	}

	// the last element is a string with the timestamp
	t := time.Now()
	timeStampString := t.Format("3:04:05 PM MST, Monday Jan 2, 2006")
	dateSEXP := rsexp.CharacterToRSEXP([]string{timeStampString})

	// export a named list
	outList, err := rsexp.MakeNamedList([]string{"wimbledonGames","leagueTable","leagueSchedule","fteUpdateTimestamp"},
		dataFrame1, dataFrame2, dataFrame3, dateSEXP)
	if err != nil {
		outString := rsexp.CharacterToRSEXP([]string{err.Error()})
		out, _ := rsexp.Export[C.SEXP](outString)
		return out
	}

	out, err := rsexp.Export[C.SEXP](outList)
	if err != nil {
		outString := rsexp.CharacterToRSEXP([]string{err.Error()})
		out, _ := rsexp.Export[C.SEXP](outString)
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
