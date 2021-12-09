library(data.table)
source("dataFunctions.R")
source("plotFunctions.R")

# Determine the dataDir, which is different betweel local and production server
modevalue = file.access("./data/", mode=2)
if (modevalue == 0) {
	dataDir = "./data/"
} else {
	dataDir = "/home/evan/data/wimbledon/"
}
cat(dataDir)

Rdata538 = paste(dataDir, "table538.Rdata", sep="")
RdataLeagueTable = paste(dataDir, "leagueTable.Rdata", sep="")
RdataLeagueSched = paste(dataDir, "leagueSchedule.Rdata", sep="")
RdataTimestamp = paste(dataDir, "fteUpdateTimestamp.Rdata", sep="")

shouldUpdate = TRUE
if (file.exists(Rdata538) & file.exists(RdataLeagueTable) & file.exists(RdataLeagueSched) & file.exists(RdataTimestamp)) {
	load(Rdata538)
	load(RdataLeagueTable)
	load(RdataLeagueSched)
	load(RdataTimestamp)
	if (exists("table538") & exists("leagueTable") & exists("leagueSchedule") & exists("fteUpdateTimestamp")) {
		shouldUpdate = FALSE
	}
}

if (shouldUpdate) {
	updateData = UpdateFiveThirtyEight(Rdata538, RdataLeagueTable, RdataLeagueSched, RdataTimestamp)
	table538 = updateData[[1]]
	leagueTable = updateData[[2]]
	leagueSchedule = updateData[[3]]
	load(RdataTimestamp)
}

# Load and prepare the rest of the data
xgTable = fread(paste(dataDir, "xg_2021.csv", sep=""))
mergeTable = MergeTables(table538, xgTable)
leagueTable = AddScheduleStrength(leagueTable, leagueSchedule)

# Get all the standard plots
plots538 = make538Plots(mergeTable)
plotsXG = makeXGPlots(mergeTable)
plotsBasic = makeBasicStatPlots(mergeTable)
tablesGame = makeGameTables(mergeTable)
leagueKable = makeLeagueTable(leagueTable)