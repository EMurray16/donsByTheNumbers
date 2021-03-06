# This file contains functions related to the data tables used in the Dons By The Numbers app

UpdateFiveThirtyEight <- function(tableFilename, leagueTableFilename, leagueSchedFilename, timestampFilename) {
	# load the shared library if needed
	if (!is.loaded("UpdateFiveThirtyEight")) {
		dyn.load("getFTE.so")
	}
	
	res = .Call("UpdateFiveThirtyEight")
	if (length(res) == 1) {
		stop(paste("UpdateFiveThirtyEight encountered error:", res[[1]]))
	}
	
	wimbledonGames = res[[1]]
	leagueTable = res[[2]]
	leagueSchedule = res[[3]]
	fteUpdateTimestamp = res[[4]]
	
	# Create a data.table from the results
	table538 = data.table(date          = wimbledonGames[[1]],
												opponent      = wimbledonGames[[2]],
												home          = as.logical(wimbledonGames[[3]]),
												wimbledonSPI  = wimbledonGames[[4]],
												opponentSPI   = wimbledonGames[[5]],
												winProb       = wimbledonGames[[6]],
												lossProb      = wimbledonGames[[7]],
												tieProb       = wimbledonGames[[8]],
												projPoints    = wimbledonGames[[9]],
												pgFor         = wimbledonGames[[10]],
												pgOpp         = wimbledonGames[[11]],
												importance    = wimbledonGames[[12]],
												gFor          = wimbledonGames[[13]],
												gOpp          = wimbledonGames[[14]],
												points        = wimbledonGames[[15]],
												cumProjPoints = wimbledonGames[[16]],
												cumPoints     = wimbledonGames[[17]],
												goalDiff      = wimbledonGames[[18]]
	)
	
	# Create the league table
	leagueTable = data.table(team            = leagueTable[[1]],
													 matchesPlayed   = leagueTable[[2]],
													 points          = leagueTable[[3]],
													 goalDiff        = leagueTable[[4]],
													 pointPercentage = round(leagueTable[[5]], 2),
													 goalPercentage  = round(leagueTable[[6]], 2),
													 spi             = leagueTable[[7]]
	 )
	leagueTable[,strength := round((pointPercentage + goalPercentage + 2*spi) / 3, 2)]
	setorderv(leagueTable, cols=c("points","matchesPlayed","goalDiff"), order=c(-1,1,-1))
	
	leagueSchedule = data.table(team        = leagueSchedule[[1]],
															opponent    = leagueSchedule[[2]],
															isHome      = leagueSchedule[[3]],
															hasHappened = leagueSchedule[[4]]
	)

	# write the table538 to an Rdata file
	save(table538, file=tableFilename)
	save(leagueTable, file=leagueTableFilename)
	save(leagueSchedule, file=leagueSchedFilename)
	save(fteUpdateTimestamp, file=timestampFilename)
	
	# return the table as well
	return(list(table538, leagueTable, leagueSchedule))
}

xgOdds <- function(wimbledonXG, opponentXG, mode=c("win","loss","tie")) {
	if (length(wimbledonXG) != length(opponentXG)) {
		stop("length of expected goal vectors does not match")
	}
	
	gVec = 0:9
	
	outVec = vector(mode="double", length=length(wimbledonXG))
	for (i in 1:length(outVec)) {
		dons = wimbledonXG[i]
		opp = opponentXG[i]
		
		# Calculate odds for the first xg model
		goalDistW = dons^gVec / factorial(gVec) * exp(-dons)
		goalDistO = opp^gVec / factorial(gVec) * exp(-opp)
		
		goalMat = goalDistW %*% t(goalDistO)
		diag(goalMat) = diag(goalMat) * 1.1
		matTot = sum(goalMat)
		
		if (mode == "win") {
			outVec[i] = round(sum(goalMat[lower.tri(goalMat, diag=FALSE)]) / matTot, 4)
		} else if (mode == "loss") {
			outVec[i] = round(sum(goalMat[upper.tri(goalMat, diag=FALSE)]) / matTot, 4)
		} else {
			outVec[i] = round(sum(diag(goalMat)) / matTot, 4)
		}
	}
	
	return(outVec)
	#return(c(oddsWin, oddsTie, oddsLoss))
}

# naTolAvg calculates the average of a list of values, tolerating and ignoring NAs
# Normally, using mean(values, na.rm=TRUE) would suffice, but data.table interprets this to mean 
# the entire column and put that in every cell when using `:=`, which we don't want. A quick 
# google didn't turn up an elegant solution, so we're writing an inefficient but simple to implement solution
naTolAvg <- function(value1, value2, value3) {
	if (length(value1) != length(value2) || length(value1) != length(value3)) {
		stop("input vectors must be the same length")
	}
	outvec = vector(mode="double", length=length(value1))
	
	for (i in 1:length(value1)) {
		outvec[i] = round(mean(c(value1[i], value2[i], value3[i]), na.rm=T), 4)
	}
	
	return(outvec)
}

MergeTables <- function(table538, xgTable) {
	table538$date = as.character(table538$date)
	xgTable$date = as.character(xgTable$date)
	mergeTable = merge(xgTable, table538, by=c("date","opponent"))
	
	mergeTable[,hasHappened := !is.na(possessionFor)]
	
	# Add an adjusted projection to the fivethirtyeight data that accounts for Wimbledon's current points
	mergeTable[,adjPoints := projPoints]
	mergeTable$adjPoints[mergeTable$hasHappened] = mergeTable$points[mergeTable$hasHappened]
	mergeTable[,adjProjPoints := cumsum(adjPoints)]
	
	mergeTable[,date := as.Date(date)]
	
	mergeTable[,gdae_footystats := (gFor - gOpp) - (xgFor_footystats - xgOpp_footystats)]
	mergeTable[,gdae_footballxg := (gFor - gOpp) - (xgFor_footballxg - xgOpp_footballxg)]
	mergeTable[,gdae_experimental361 := (gFor - gOpp) - (xgFor_experimental361 - xgOpp_experimental361)]
	
	# Calculate cumulative statistics
	mergeTable[,cumXGFor_footystats := cumsum(xgFor_footystats)]
	mergeTable[,cumXGOpp_footystats := cumsum(xgOpp_footystats)]
	mergeTable[,cumXGFor_footballxg := cumsum(xgFor_footballxg)]
	mergeTable[,cumXGOpp_footballxg := cumsum(xgOpp_footballxg)]
	mergeTable[,cumXGFor_experimental361 := cumsum(xgFor_experimental361)]
	mergeTable[,cumXGOpp_experimental361 := cumsum(xgOpp_experimental361)]
	mergeTable[,cumGFor := cumsum(gFor)]
	mergeTable[,cumGOpp := cumsum(gOpp)]
	
	mergeTable[,cumLuckOff_footystats := cumGFor / cumXGFor_footystats]
	mergeTable[,cumLuckDef_footystats := cumXGOpp_footystats / cumGOpp]
	mergeTable[,cumLuckCom_footystats := 0.5 * (cumLuckOff_footystats + cumLuckDef_footystats)]
	
	mergeTable[,cumLuckOff_footballxg := cumGFor / cumXGFor_footballxg]
	mergeTable[,cumLuckDef_footballxg := cumXGOpp_footballxg / cumGOpp]
	mergeTable[,cumLuckCom_footballxg := 0.5 * (cumLuckOff_footballxg + cumLuckDef_footballxg)]
	
	mergeTable[,cumLuckOff_experimental361 := cumGFor / cumXGFor_experimental361]
	mergeTable[,cumLuckDef_experimental361 := cumXGOpp_experimental361 / cumGOpp]
	mergeTable[,cumLuckCom_experimental361 := 0.5 * (cumLuckOff_experimental361 + cumLuckDef_experimental361)]
	
	mergeTable[,cumPossess := round(cumsum(possessionFor) / seq_along(possessionFor), 1)]
	mergeTable[,cumShotShare := round(cumsum(shotShare) / seq_along(shotShare), 1)]
	mergeTable[,cumGDAE_footystats := cumsum(gdae_footystats)]
	mergeTable[,cumGDAE_footballxg := cumsum(gdae_footballxg)]
	mergeTable[,cumGDAE_experimental361 := cumsum(gdae_experimental361)]
	
	# Add a string for the game location
	mergeTable$Location = as.character(mergeTable$home)
	mergeTable[Location == "TRUE","Location"] = "Plough Lane"
	mergeTable[Location == "FALSE","Location"] = "Away"
	mergeTable[,gameDesc := paste(date, ifelse(home, "vs", "@"), opponent)]
	mergeTable[,home := NULL]
	
	# "deserved xg"
	mergeTable[,adjXGFor := naTolAvg(xgFor_footystats * 90 / (90 + timeTrailingSecondHalf), 
																	 xgFor_footballxg * 90/(90+timeTrailingSecondHalf),
																	 xgFor_experimental361 * 90/(90+timeTrailingSecondHalf))]
	mergeTable[,adjXGOpp := naTolAvg(xgOpp_footystats * 90 / (90 + timeLeadingSecondHalf), 
																	 xgOpp_footballxg * 90/(90+timeLeadingSecondHalf),
																	 xgOpp_experimental361 * 90/(90+timeLeadingSecondHalf))]
	
	# xg win probabilities
	mergeTable[hasHappened == TRUE,xgW_footballxg := xgOdds(xgFor_footballxg, xgOpp_footballxg, "win")]
	mergeTable[hasHappened == TRUE,xgL_footballxg := xgOdds(xgFor_footballxg, xgOpp_footballxg, "loss")]
	mergeTable[hasHappened == TRUE,xgT_footballxg := xgOdds(xgFor_footballxg, xgOpp_footballxg, "tie")]
	
	mergeTable[hasHappened == TRUE,xgW_footystats := xgOdds(xgFor_footystats, xgOpp_footystats, "win")]
	mergeTable[hasHappened == TRUE,xgL_footystats := xgOdds(xgFor_footystats, xgOpp_footystats, "loss")]
	mergeTable[hasHappened == TRUE,xgT_footystats := xgOdds(xgFor_footystats, xgOpp_footystats, "tie")]
	
	mergeTable[hasHappened == TRUE,xgW_experimental361 := xgOdds(xgFor_experimental361, xgOpp_experimental361, "win")]
	mergeTable[hasHappened == TRUE,xgL_experimental361 := xgOdds(xgFor_experimental361, xgOpp_experimental361, "loss")]
	mergeTable[hasHappened == TRUE,xgT_experimental361 := xgOdds(xgFor_experimental361, xgOpp_experimental361, "tie")]
	
	mergeTable[hasHappened == TRUE,adjXGWin := xgOdds(adjXGFor, adjXGOpp, "win")]
	mergeTable[hasHappened == TRUE,adjXGLoss := xgOdds(adjXGFor, adjXGOpp, "loss")]
	mergeTable[hasHappened == TRUE,adjXGTie := xgOdds(adjXGFor, adjXGOpp, "tie")]
	
	mergeTable[hasHappened == TRUE, xgWin := naTolAvg(xgW_footballxg, xgW_footystats, xgW_experimental361)]
	mergeTable[hasHappened == TRUE, xgLoss := naTolAvg(xgL_footballxg, xgL_footystats, xgL_experimental361)]
	mergeTable[hasHappened == TRUE, xgTie := naTolAvg(xgT_footballxg, xgT_footystats, xgT_experimental361)]
	mergeTable[,c("xgW_footballxg","xgL_footballxg","xgT_footballxg",
								"xgW_footystats","xgL_footystats","xgT_footystats",
								"xgW_experimental361","xgL_experimental361","xgT_experimental361") := NULL]
	
	mergeTable[,xgPoints := xgWin * 3 + xgTie]
	mergeTable[,cumXGPoints := cumsum(xgPoints)]
	mergeTable[,adjXGPoints := adjXGWin * 3 + adjXGTie]
	mergeTable[,adjCumXGPoints := cumsum(adjXGPoints)]
	
	return(mergeTable)
}

AddScheduleStrength <- function(leagueTable, leagueSchedule) {
	leagueSchedule = merge(leagueSchedule, leagueTable[,c("team","strength")], by.x="opponent", by.y="team")
	# Adjust the opponent strength up for away games
	leagueSchedule[isHome == 0,adjStrength := strength * 1.15]
	# and adjust the opponent strength down for home games
	leagueSchedule[isHome == 1,adjStrength := strength * 0.85]
	
	strengthPlayed = leagueSchedule[hasHappened == 1,.(strengthPlayed = round(mean(adjStrength), 2)), by="team"]
	strengthToCome = leagueSchedule[hasHappened == 0,.(strengthToCome = round(mean(adjStrength), 2)), by="team"]
	
	strengthTable = merge(strengthPlayed, strengthToCome, by="team")
	
	leagueTable = merge(leagueTable, strengthTable, by="team")
	setorderv(leagueTable, cols=c("points","matchesPlayed","goalDiff"), order=c(-1,1,-1))
	
	return(leagueTable)
}
