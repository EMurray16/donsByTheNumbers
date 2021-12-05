package main

/*
#define USE_RINTERNALS
#include <Rinternals.h>
#cgo CFLAGS: -I/Library/Frameworks/R.framework/Headers/ -I/usr/share/R/include/
*/
import "C"

import (
	"donsByTheNumbers/fte"
	"github.com/EMurray16/Rgo/rsexp"
	"time"
)

//export UpdateFiveThirtyEight
func UpdateFiveThirtyEight() C.SEXP {
	outGames, outTable, err := fte.GetSPILatest()
	if err != nil {
		errString := err.Error()
		stringSEXP := rsexp.String2sexp([]string{errString})
		return *(*C.SEXP)(stringSEXP.Point)
	}

	// build an R list from the games
	sexpSlice1 := make([]rsexp.GoSEXP, 18)

	sexpSlice1[0] = rsexp.String2sexp(outGames.Dates)
	sexpSlice1[1] = rsexp.String2sexp(outGames.Opponents)
	sexpSlice1[2] = rsexp.Int2sexp(outGames.Home)
	sexpSlice1[3] = rsexp.Float2sexp(outGames.WimbledonSPI)
	sexpSlice1[4] = rsexp.Float2sexp(outGames.OpponentSPI)
	sexpSlice1[5] = rsexp.Float2sexp(outGames.WinProb)
	sexpSlice1[6] = rsexp.Float2sexp(outGames.LossProb)
	sexpSlice1[7] = rsexp.Float2sexp(outGames.TieProb)
	sexpSlice1[8] = rsexp.Float2sexp(outGames.ProjPoints)
	sexpSlice1[9] = rsexp.Float2sexp(outGames.ProjGoalsFor)
	sexpSlice1[10] = rsexp.Float2sexp(outGames.ProjGoalsAgainst)
	sexpSlice1[11] = rsexp.Float2sexp(outGames.Importance)
	sexpSlice1[12] = rsexp.Int2sexp(outGames.GoalsFor)
	sexpSlice1[13] = rsexp.Int2sexp(outGames.GoalsAgainst)
	sexpSlice1[14] = rsexp.Int2sexp(outGames.Points)
	sexpSlice1[15] = rsexp.Float2sexp(outGames.CumProjPoints)
	sexpSlice1[16] = rsexp.Int2sexp(outGames.CumPoints)
	sexpSlice1[17] = rsexp.Int2sexp(outGames.CumGoalDiff)

	// build an R list from the league table
	sexpSlice2 := make([]rsexp.GoSEXP, 6)

	sexpSlice2[0] = rsexp.String2sexp(outTable.Teams)
	sexpSlice2[1] = rsexp.Int2sexp(outTable.MatchesPlayed)
	sexpSlice2[2] = rsexp.Int2sexp(outTable.Points)
	sexpSlice2[3] = rsexp.Int2sexp(outTable.GoalDiff)
	sexpSlice2[4] = rsexp.Float2sexp(outTable.PointPercentage)
	sexpSlice2[5] = rsexp.Float2sexp(outTable.SPI)


	// the last element is a string with the timestamp
	t := time.Now()
	timeStampString := t.Format("3:04:05 PM MST, Monday Jan 2, 2006")
	dateSEXP := rsexp.String2sexp([]string{timeStampString})

	list1 := rsexp.List2sexp(rsexp.NewList(sexpSlice1...))
	list2 := rsexp.List2sexp(rsexp.NewList(sexpSlice2...))

	finalList := rsexp.NewList(list1, list2, dateSEXP)
	outSEXP := rsexp.List2sexp(finalList)

	return *(*C.SEXP)(outSEXP.Point)
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
