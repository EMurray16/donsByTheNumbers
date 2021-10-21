# This file contains functions related to the data tables used in the Dons By The Numbers app

UpdateFiveThirtyEight <- function(tableFilename, timestampFilename) {
	# load the shared library if needed
	if (!is.loaded("UpdateFiveThirtyEight")) {
		dyn.load("getFTE.so")
	}
	
	res = .Call("UpdateFiveThirtyEight")
	if (length(res) == 1) {
		stop(paste("UpdateFiveThirtyEight encountered error:", res[[1]]))
	}
	
	# Create a data.table from the results
	table538 = data.table(date          = res[[1]],
												opponent      = res[[2]],
												home          = as.logical(res[[3]]),
												wimbledonSPI  = res[[4]],
												opponentSPI   = res[[5]],
												winProb       = res[[6]],
												lossProb      = res[[7]],
												tieProb       = res[[8]],
												projPoints    = res[[9]],
												pgFor         = res[[10]],
												pgOpp         = res[[11]],
												importance    = res[[12]],
												gFor          = res[[13]],
												gOpp          = res[[14]],
												points        = res[[15]],
												cumProjPoints = res[[16]],
												cumPoints     = res[[17]],
												goalDiff      = res[[18]]
	)
	
	# Grab the timestamp as the last element
	fteUpdateTimestamp = res[[19]]
	
	# write the table538 to an Rdata file
	save(table538, file=tableFilename)
	save(fteUpdateTimestamp, file=timestampFilename)
	
	# return the table as well
	return(table538)
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
# Normally, using mean(values, na.rm=TRUE) would suffice, but data.table interpets this to mean 
# the entire column and put that in every cell when using `:=`, which we don't want. A quick 
# google didn't turn up an elegant solution, so we're writing an inefficient but simple to implement solution
naTolAvg <- function(value1, value2) {
	if (length(value1) != length(value2)) {
		stop("input vectors must be the same length")
	}
	outvec = vector(mode="double", length=length(value1))
	
	for (i in 1:length(value1)) {
		if (is.na(value1[i])) {
			# throw in some rounding for convenience
			outvec[i] = round(value2[i], 4)
		} else if (is.na(value2[i])) {
			outvec[i] = round(value1[i], 4)
		} else {
			outvec[i] = round(0.5 * (value1[i]+value2[i]), 4)
		}
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
	
	# Calculate cumulative statistics
	mergeTable[,cumXGFor_footystats := cumsum(xgFor_footystats)]
	mergeTable[,cumXGOpp_footystats := cumsum(xgOpp_footystats)]
	mergeTable[,cumXGFor_footballxg := cumsum(xgFor_footballxg)]
	mergeTable[,cumXGOpp_footballxg := cumsum(xgOpp_footballxg)]
	mergeTable[,cumGFor := cumsum(gFor)]
	mergeTable[,cumGOpp := cumsum(gOpp)]
	
	mergeTable[,cumLuckOff_footystats := cumGFor / cumXGFor_footystats]
	mergeTable[,cumLuckDef_footystats := cumXGOpp_footystats / cumGOpp]
	mergeTable[,cumLuckCom_footystats := 0.5 * (cumLuckOff_footystats + cumLuckDef_footystats)]
	
	mergeTable[,cumLuckOff_footballxg := cumGFor / cumXGFor_footballxg]
	mergeTable[,cumLuckDef_footballxg := cumXGOpp_footballxg / cumGOpp]
	mergeTable[,cumLuckCom_footballxg := 0.5 * (cumLuckOff_footballxg + cumLuckDef_footballxg)]
	mergeTable[,cumPossess := cumsum(possessionFor) / seq_along(possessionFor)]
	mergeTable[,cumShotShare := cumsum(shotShare) / seq_along(shotShare)]
	mergeTable[,cumGDAE_footystats := cumsum(gdae_footystats)]
	mergeTable[,cumGDAE_footballxg := cumsum(gdae_footballxg)]
	
	# Add a string for the game location
	mergeTable$Location = as.character(mergeTable$home)
	mergeTable[Location == "TRUE","Location"] = "Plough Lane"
	mergeTable[Location == "FALSE","Location"] = "Away"
	mergeTable[,gameDesc := paste(date, ifelse(home, "vs", "@"), opponent)]
	mergeTable[,home := NULL]
	
	# "deserved xg"
	mergeTable[,adjXGFor := naTolAvg(xgFor_footystats * 90 / (90 + timeTrailingSecondHalf), xgFor_footballxg * 90/(90+timeTrailingSecondHalf))]
	mergeTable[,adjXGOpp := naTolAvg(xgOpp_footystats * 90 / (90 + timeLeadingSecondHalf), xgOpp_footballxg * 90/(90+timeLeadingSecondHalf))]
	
	# xg win probabilities
	mergeTable[hasHappened == TRUE,xgW_footballxg := xgOdds(xgFor_footballxg, xgOpp_footballxg, "win")]
	mergeTable[hasHappened == TRUE,xgL_footballxg := xgOdds(xgFor_footballxg, xgOpp_footballxg, "loss")]
	mergeTable[hasHappened == TRUE,xgT_footballxg := xgOdds(xgFor_footballxg, xgOpp_footballxg, "tie")]
	
	mergeTable[hasHappened == TRUE,xgW_footystats := xgOdds(xgFor_footystats, xgOpp_footystats, "win")]
	mergeTable[hasHappened == TRUE,xgL_footystats := xgOdds(xgFor_footystats, xgOpp_footystats, "loss")]
	mergeTable[hasHappened == TRUE,xgT_footystats := xgOdds(xgFor_footystats, xgOpp_footystats, "tie")]
	
	mergeTable[hasHappened == TRUE,adjXGWin := xgOdds(adjXGFor, adjXGOpp, "win")]
	mergeTable[hasHappened == TRUE,adjXGLoss := xgOdds(adjXGFor, adjXGOpp, "loss")]
	mergeTable[hasHappened == TRUE,adjXGTie := xgOdds(adjXGFor, adjXGOpp, "tie")]
	
	
	mergeTable[hasHappened == TRUE, xgWin := naTolAvg(xgW_footballxg, xgW_footystats)]
	mergeTable[hasHappened == TRUE, xgLoss := naTolAvg(xgL_footballxg, xgL_footystats)]
	mergeTable[hasHappened == TRUE, xgTie := naTolAvg(xgT_footballxg, xgT_footystats)]
	mergeTable[,c("xgW_footballxg","xgL_footballxg","xgT_footballxg","xgW_footystats","xgL_footystats","xgT_footystats") := NULL]
	
	mergeTable[,xgPoints := xgWin * 3 + xgTie]
	mergeTable[,cumXGPoints := cumsum(xgPoints)]
	mergeTable[,adjXGPoints := adjXGWin * 3 + adjXGTie]
	mergeTable[,adjCumXGPoints := cumsum(adjXGPoints)]
	
	return(mergeTable)
}
