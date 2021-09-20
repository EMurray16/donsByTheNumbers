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
	
	return(mergeTable)
}
