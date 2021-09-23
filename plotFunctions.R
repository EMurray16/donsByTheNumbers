# These functions are used to generate plots for Dons by the Numbers
library(ggplot2)
library(ggtext)
library(data.table)
library(knitr)
library(kableExtra)

baseTheme = function() {
	baseSize = 14
	baseTextElem = element_text(size=baseSize)
	
	return(
		theme_bw() + theme(legend.title=element_blank(), legend.position="bottom") +
		theme(plot.caption=element_markdown(size=baseSize), plot.subtitle = element_markdown(size=baseSize)) +
		theme(axis.text=baseTextElem, legend.text=baseTextElem, strip.text=baseTextElem) +
		theme(plot.title=element_text(size=baseSize+6))
	)
}

masterColorList = function() {
	return(
		c("fivethirtyeight"="#ed713a", "Wimbledon"="#0000ff", # 538 points plot
			"Goals For" = rgb(0,0.45,0.7), "Goals Against" = rgb(0.8,0.4,0), "Net Goal Difference" = "#fff200", # goals plots
			"xG For" = rgb(0.35,0.7,0.9), "xG Against" = rgb(0.9,0.6,0), #xG and goals plots
			"Cumulative"=rgb(0.9,0.8,1), # gdae plots
			"Offense" = rgb(0.35,0.7,0.9), "Defense" = rgb(0.9,0.6,0), "Combined" = "black", #luck plots
			"Possession" = rgb(0.35,0.6,0.5), "Shot Share" = rgb(0.35,0.7,0.9), 
			"Avg Possession" = "darkgreen", "Avg Shot Share" = rgb(0,0.45,0.7),
			"Loss" = rgb(0.8,0.4,0), "Win" = rgb(0,0.6,0.5), "Tie" = rgb(0.5,0.5,0.5), # game card outcome probabilities
			"Plough Lane" = "#0000ff", "Away" = "#fff200", "Opponent" = rgb(0.5,0.5,0.5)
			
		))
}

make538Plots <- function(mergeTable) {
	# start by plotting points vs projected points
	runningAhead = round(mergeTable$adjProjPoints[nrow(mergeTable)] - mergeTable$cumProjPoints[nrow(mergeTable)], 2)
	if (runningAhead > 0.25) {
		pointsCaption = paste("The Dons are currently running **", runningAhead, " points ahead** of fivethirtyeight's projection.",sep="")
	} else if (runningAhead < 0.25) {
		pointsCaption = paste("The Dons are currently running **", -runningAhead, " points behind** fivethirtyeight's projection.", sep="")
	} else {
		pointsCaption = paste("The Dons are *on pace* with fivethirtyeight's projections.")
	}
	
	g1 = ggplot(mergeTable) + baseTheme() +
		geom_line(aes(x=date, y=cumProjPoints, color="fivethirtyeight"), size=1) +
		geom_line(aes(x=date, y=adjProjPoints), color="grey", size=0.5) +
		geom_line(data=mergeTable[hasHappened == TRUE,], aes(x=date, y=cumPoints, color="Wimbledon"), size=1) +
		ggtitle("Point accumulation versus fivethirtyeight projections") +
		labs(x=NULL, y="Points", caption=pointsCaption) + 
		ylim(0, 100) +
		geom_hline(yintercept=75, color=rgb(0,0.75,0.5), linetype="dashed") +
		geom_hline(yintercept=50, color=rgb(1, 0.1, 0), linetype="dashed") +
		scale_color_manual(values=masterColorList())
	
	spiPercentIncrease = round((mergeTable$wimbledonSPI[nrow(mergeTable)] - mergeTable$wimbledonSPI[1]) / mergeTable$wimbledonSPI[1] * 100, 2)
	if (spiPercentIncrease > 0) {
		spiCaption = paste("AFC Wimbledon's SPI has **increased ", spiPercentIncrease, "%** since the start of the season, from ",
											 mergeTable$wimbledonSPI[1], " to ", mergeTable$wimbledonSPI[nrow(mergeTable)], ".", sep="")
	} else if (spiPercentIncrease < 0) {
		spiCaption = paste("AFC Wimbledon's SPI has **decreased ", spiPercentIncrease, "%** since the start of the season, from ",
											 mergeTable$wimbledonSPI[1], " to ", mergeTable$wimbledonSPI[nrow(mergeTable)], ".", sep="")
	} else {
		spiCaption = paste("AFC Wimbledon's SPI is the same as it was at the start of the season - ", mergeTable$wimbledonSPI[1], ".", sep="")
	}
	
	g2 = ggplot(mergeTable[hasHappened == TRUE,]) + baseTheme() +
		geom_line(aes(x=date, y=wimbledonSPI), color="#0000ff") +
		geom_hline(yintercept=35, color=rgb(0,0.75,0.5), linetype="dashed") +
		geom_hline(yintercept=15.75, color=rgb(1, 0.1, 0), linetype="dashed") +
		labs(x=NULL, y="fivethirtyeight SPI", caption=spiCaption) + 
		ylim(0,50) + xlim(as.Date("2021-08-01"), as.Date("2022-05-01")) +
		ggtitle("Wimbledon's Soccer Power Index through the season")
	
	g3 = ggplot(mergeTable[hasHappened == TRUE,]) + baseTheme() +
		geom_bar(aes(x=date, y=importance), fill="black", stat="identity") +
		labs(x=NULL, y="Importance") + ggtitle("Importance of each game")
	
	return(list(g1, g2, g3))
}

makeXGPlots <- function(mergeTable) {
	footystatsTable = mergeTable[hasHappened == TRUE,
															 c("date","gFor","gOpp","xgFor_footystats","xgOpp_footystats","gdae_footystats","cumGDAE_footystats")]
	setnames(footystatsTable, old=c("xgFor_footystats","xgOpp_footystats","gdae_footystats","cumGDAE_footystats"), 
					 new=c("xgFor","xgOpp","GDAE","cumGDAE"))
	footystatsTable[,Model := "footystats.org"]
	
	footballxgTable = mergeTable[hasHappened == TRUE,
															 c("date","gFor","gOpp","xgFor_footballxg","xgOpp_footballxg","gdae_footballxg","cumGDAE_footballxg")]
	setnames(footballxgTable, old=c("xgFor_footballxg","xgOpp_footballxg","gdae_footballxg","cumGDAE_footballxg"), 
					 new=c("xgFor","xgOpp","GDAE","cumGDAE"))
	footballxgTable[,Model := "footballxg.com"]
	
	xgPlotTable = rbind(footystatsTable, footballxgTable)
	
	footystatsTable2 = mergeTable[hasHappened == TRUE,
																c("date","cumLuckOff_footystats","cumLuckDef_footystats","cumLuckCom_footystats")]
	setnames(footystatsTable2, old=c("cumLuckOff_footystats","cumLuckDef_footystats","cumLuckCom_footystats"), 
					 new=c("luckOff","luckDef","luckComb"))
	footystatsTable2[,Model := "footystats.org"]
	
	footballxgTable2 = mergeTable[hasHappened == TRUE,
																c("date","cumLuckOff_footballxg","cumLuckDef_footballxg","cumLuckCom_footballxg")]
	setnames(footballxgTable2, old=c("cumLuckOff_footballxg","cumLuckDef_footballxg","cumLuckCom_footballxg"), 
					 new=c("luckOff","luckDef","luckComb"))
	footballxgTable2[,Model := "footballxg.com"]
	
	luckPlotTable = rbind(footystatsTable2, footballxgTable2)
	
	g1 = ggplot(xgPlotTable) + baseTheme() +
		geom_hline(yintercept=0) +
		geom_bar(aes(x=date, y=gFor, fill="Goals For"), stat="identity") +
		geom_bar(aes(x=date, y=0-gOpp, fill="Goals Against"), stat="identity") +
		geom_line(aes(x=date, y=xgFor, color="xG For"),size=1) +
		geom_line(aes(x=date, y=0-xgOpp, color="xG Against"), size=1) +
		geom_point(aes(x=date, y=xgFor, color="xG For"), size=2) +
		geom_point(aes(x=date, y=0-xgOpp, color="xG Against"), size=2) +
		ggtitle("Expected Goals versus Actual Goals") +
		labs(x=NULL, y=NULL) + 
		scale_fill_manual(values=masterColorList()) +
		scale_color_manual(values=masterColorList()) +
		facet_grid(~Model) +
		scale_y_continuous(breaks=seq(-6,6,2), labels=c(6,4,2,0,2,4,6), limits=c(-5,5))
	
	g2 = ggplot(xgPlotTable) + baseTheme() +
		geom_line(aes(x=date, y=GDAE), color=rgb(0.8,0.6,0.7), size=2) +
		geom_point(aes(x=date, y=GDAE), color=rgb(0.8,0.6,0.7), size=2) +
		geom_line(aes(x=date, y=cumGDAE, color="Cumulative"), size=2) +
		geom_point(aes(x=date, y=cumGDAE, color="Cumulative"), size=2) +
		geom_hline(yintercept=0) + 
		labs(x=NULL, y="GDAE") +
		ggtitle("Goal Difference Above Expected") +
		scale_color_manual(values=masterColorList()) +
		facet_grid(~Model)
	
	g3 = ggplot(luckPlotTable) + baseTheme() +
		geom_hline(yintercept=1) + 
		geom_line(aes(x=date, y=luckOff, color="Offense")) + 
		geom_line(aes(x=date, y=luckDef, color="Defense")) +
		geom_line(aes(x=date, y=luckComb, color="Combined")) +
		geom_point(aes(x=date, y=luckOff, color="Offense")) + 
		geom_point(aes(x=date, y=luckDef, color="Defense")) +
		geom_point(aes(x=date, y=luckComb, color="Combined")) +
		labs(x=NULL, y="Luck") +
		scale_color_manual(values=masterColorList()) +
		facet_grid(~Model) +
		ggtitle("RAGE", subtitle="**R**atio of **A**ctual **G**oals to **E**xpected")
	
	return(list(g1,g2,g3))
}

makeBasicStatPlots <- function(mergeTable) {
	possTable = mergeTable[hasHappened == TRUE,c("date","possessionFor")]
	setnames(possTable, old="possessionFor", new="Percentage")
	possTable$Type = "Possession"
	shotTable = mergeTable[hasHappened == TRUE,c("date","shotShare")]
	setnames(shotTable, old="shotShare", new="Percentage")
	shotTable$Type = "Shot Share"
	percentageTable = rbind(possTable, shotTable)
	
	g1 = ggplot(mergeTable[hasHappened == TRUE,]) + baseTheme() +
		geom_bar(data=percentageTable, aes(x=date, y=Percentage, fill=Type), stat="identity", position="dodge") + 
		geom_line(aes(x=date, y=cumPossess, color="Avg Possession"), size=1.25) +
		geom_point(aes(x=date, y=cumPossess, color="Avg Possession"), size=1.5) + 
		geom_line(aes(x=date, y=cumShotShare, color="Avg Shot Share"), size=1.25) +
		geom_point(aes(x=date, y=cumShotShare, color="Avg Shot Share"), size=1.5) + 
		labs(x=NULL, y="Percentage") + 
		geom_hline(yintercept=50) +
		scale_color_manual(values=masterColorList()) + scale_fill_manual(values=masterColorList()) +
		scale_y_continuous(breaks=c(0,20,40,60,80,100), limits=c(0,100)) +
		ggtitle("Ball Possession and Shot Share")
	
	g2 = ggplot(mergeTable[hasHappened == TRUE,]) + baseTheme() + 
		geom_line(aes(x=date, y=cumGFor, color="Goals For")) +
		geom_point(aes(x=date, y=cumGFor, color="Goals For")) +
		geom_line(aes(x=date, y=cumGOpp, color="Goals Against")) +
		geom_point(aes(x=date, y=cumGOpp, color="Goals Against")) +
		labs(x=NULL, y="Goals") + 
		scale_color_manual(values=masterColorList()) +
		ggtitle("Season Total Goals For and Against") + ylim(0,max(c(mergeTable$cumGFor, mergeTable$cumGOpp)))
	
	g3 = ggplot(mergeTable[hasHappened == TRUE,]) + baseTheme() + 
		geom_bar(aes(x=date, y=gFor, fill="Goals For"), stat="identity") +
		geom_bar(aes(x=date, y=0-gOpp, fill="Goals Against"), stat="identity") +
		geom_hline(yintercept=0) +
		geom_line(aes(x=date, y=goalDiff, color="Net Goal Difference"), size=2) +
		geom_point(aes(x=date, y=goalDiff, color="Net Goal Difference"), size=3) +
		labs(x=NULL, y="Goals") + 
		scale_fill_manual(values=masterColorList()) + scale_color_manual(values=masterColorList()) +
		ggtitle("Goal Difference") +
		scale_y_continuous(breaks=seq(-6,6,2), labels=c(6,4,2,0,2,4,6), limits=c(-5,5))
	
	return(list(g1,g2,g3))
}

makeGameTables <- function(mergeTable) {
	upcomingGames = mergeTable[hasHappened == FALSE,c("date","opponent","opponentSPI","home","pgFor","pgOpp","winProb","lossProb","tieProb")]
	pastGames = mergeTable[hasHappened == TRUE,c("date","opponent","opponentSPI","home","gFor","gOpp","winProb","lossProb","tieProb")]
	
	setnames(upcomingGames, old=c("date","opponent","opponentSPI","home","winProb","lossProb","tieProb","pgFor","pgOpp"),
					 new=c("Date","Opponent","SPI","Location","% Win","% Loss","% Tie","Goals For","Goals Against"))
	setnames(pastGames, old=c("date","opponent","opponentSPI","home","winProb","lossProb","tieProb","gFor","gOpp"),
					 new=c("Date","Opponent","SPI","Location","% Win","% Loss","% Tie","Goals For","Goals Against"))
	
	upcomingGames$Location = as.character(upcomingGames$Location)
	pastGames$Location = as.character(pastGames$Location)
	upcomingGames[Location == "TRUE","Location"] = "Plough Lane"
	pastGames[Location == "TRUE","Location"] = "Plough Lane"
	upcomingGames[Location == "FALSE","Location"] = "Away"
	pastGames[Location == "FALSE","Location"] = "Away"
	
	
	upcomingGames$`% Win` = cell_spec(upcomingGames$`% Win`, background=rgb(0,0.6,0.5,alpha=upcomingGames$`% Win`))
	upcomingGames$`% Loss` = cell_spec(upcomingGames$`% Loss`, background=rgb(0.8,0.4,0,alpha=upcomingGames$`% Loss`))
	upcomingGames$`% Tie` = cell_spec(upcomingGames$`% Tie`, background=rgb(0.5,0.5,0.5,alpha=upcomingGames$`% Tie`))
	
	k1 = kable(upcomingGames, escape=FALSE) %>%
		kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), fixed_thead=TRUE)
	
	pastGames$`% Win` = cell_spec(pastGames$`% Win`, background=rgb(0,0.6,0.5,alpha=pastGames$`% Win`), 
																bold=pastGames$`Goals For` > pastGames$`Goals Against`)
	pastGames$`% Loss` = cell_spec(pastGames$`% Loss`, background=rgb(0.8,0.4,0,alpha=pastGames$`% Loss`), 
																 bold=pastGames$`Goals For` < pastGames$`Goals Against`)
	pastGames$`% Tie` = cell_spec(pastGames$`% Tie`, background=rgb(0.5,0.5,0.5,alpha=pastGames$`% Tie`), 
																bold=pastGames$`Goals For` == pastGames$`Goals Against`)
	k2 = kable(pastGames, escape=F) %>%
		kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), fixed_thead=TRUE)
	
	return(list(k1,k2))
}