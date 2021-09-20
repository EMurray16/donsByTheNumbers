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
	outGames, err := fte.GetSPILatest()
	if err != nil {
		errString := err.Error()
		stringSEXP := rsexp.String2sexp([]string{errString})
		return *(*C.SEXP)(stringSEXP.Point)
	}

	// build the R list from the games
	sexpSlice := make([]rsexp.GoSEXP, 19)

	sexpSlice[0] = rsexp.String2sexp(outGames.Dates)
	sexpSlice[1] = rsexp.String2sexp(outGames.Opponents)
	sexpSlice[2] = rsexp.Int2sexp(outGames.Home)
	sexpSlice[3] = rsexp.Float2sexp(outGames.WimbledonSPI)
	sexpSlice[4] = rsexp.Float2sexp(outGames.OpponentSPI)
	sexpSlice[5] = rsexp.Float2sexp(outGames.WinProb)
	sexpSlice[6] = rsexp.Float2sexp(outGames.LossProb)
	sexpSlice[7] = rsexp.Float2sexp(outGames.TieProb)
	sexpSlice[8] = rsexp.Float2sexp(outGames.ProjPoints)
	sexpSlice[9] = rsexp.Float2sexp(outGames.ProjGoalsFor)
	sexpSlice[10] = rsexp.Float2sexp(outGames.ProjGoalsAgainst)
	sexpSlice[11] = rsexp.Float2sexp(outGames.Importance)
	sexpSlice[12] = rsexp.Int2sexp(outGames.GoalsFor)
	sexpSlice[13] = rsexp.Int2sexp(outGames.GoalsAgainst)
	sexpSlice[14] = rsexp.Int2sexp(outGames.Points)
	sexpSlice[15] = rsexp.Float2sexp(outGames.CumProjPoints)
	sexpSlice[16] = rsexp.Int2sexp(outGames.CumPoints)
	sexpSlice[17] = rsexp.Int2sexp(outGames.CumGoalDiff)

	// the last element is a string with the timestamp
	t := time.Now()
	timeStampString := t.Format("3:04:05 PM MST, Monday Jan 2, 2006")
	sexpSlice[18] = rsexp.String2sexp([]string{timeStampString})

	list := rsexp.NewList(sexpSlice...)
	outSEXP := rsexp.List2sexp(list)

	return *(*C.SEXP)(outSEXP.Point)
}

// Everything in this function should be commented out when building the shared library
func main() {
	/*games, err := fte.GetSPILatest()
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(games)*/
}
