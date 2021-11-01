# These functions are used to generate plots for Dons by the Numbers
library(ggplot2)
library(ggtext)
library(data.table)
library(knitr)
library(kableExtra)
library(patchwork)
library(ggiraph)

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
		c("FiveThirtyEight"="#ed713a", "Wimbledon"="#0000ff", # 538 points plot
			"Goals For" = rgb(0,0.45,0.7), "Goals Against" = rgb(0.8,0.4,0), "Net Goal Difference" = "#fff200", # goals plots
			"xG For" = rgb(0.35,0.7,0.9), "xG Against" = rgb(0.9,0.6,0), #xG and goals plots
			"Cumulative"=rgb(0.9,0.8,1), # gdae plots
			"Offense" = rgb(0.35,0.7,0.9), "Defense" = rgb(0.9,0.6,0), "Combined" = "black", #luck plots
			"Possession" = rgb(0.35,0.6,0.5), "Shot Share" = rgb(0.35,0.7,0.9), 
			"Avg Possession" = "darkgreen", "Avg Shot Share" = rgb(0,0.45,0.7),
			"Loss" = rgb(0.8,0.4,0), "Win" = rgb(0,0.6,0.5), "Tie" = rgb(0.5,0.5,0.5), # game card outcome probabilities
			"Plough Lane" = "#0000ff", "Away" = "#fff200", "Opponent" = rgb(0.5,0.5,0.5),
			"Promotion Playoffs" = rgb(0,0.75,0.5), "Relegation" = rgb(1, 0.1, 0),
			"Average xG" = rgb(0.35,0.7,0.9), "Score-Adjusted xG" = rgb(0,0.6,0.5)
		))
}

gameCardTheme <- function() {
	baseSize = 12
	baseTextElem = element_text(size=baseSize)
	
	return(
		theme_bw() + theme(legend.position="none") +
			theme(plot.caption=element_markdown(size=baseSize), plot.subtitle = element_markdown(size=baseSize)) +
			theme(axis.text=baseTextElem, legend.text=baseTextElem, strip.text=baseTextElem) +
			theme(plot.title=element_text(size=baseSize+2))
	)
}

make538Plots <- function(mergeTable) {
	# start by plotting points vs projected points
	runningAhead = round(mergeTable$adjProjPoints[nrow(mergeTable)] - mergeTable$cumProjPoints[nrow(mergeTable)], 2)
	if (runningAhead > 0.25) {
		pointsCaption = paste("The Dons are currently running **", runningAhead, " points ahead** of FiveThirtyEight's projection.",sep="")
	} else if (runningAhead < 0.25) {
		pointsCaption = paste("The Dons are currently running **", -runningAhead, " points behind** FiveThirtyEight's projection.", sep="")
	} else {
		pointsCaption = paste("The Dons are *on pace* with FiveThirtyEight's projections.")
	}
	
	g1 = ggplot(mergeTable) + baseTheme() +
		geom_line(aes(x=date, y=cumProjPoints, color="FiveThirtyEight"), size=1) +
		geom_line(aes(x=date, y=adjProjPoints), color="grey", size=0.5) +
		geom_line(data=mergeTable[hasHappened == TRUE,], aes(x=date, y=cumPoints, color="Wimbledon"), size=1) +
		ggtitle("Point accumulation versus FiveThirtyEight projections") +
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
		labs(x=NULL, y="FiveThirtyEight SPI", caption=spiCaption) + 
		ylim(0,50) + xlim(as.Date("2021-08-01"), as.Date("2022-05-01")) +
		ggtitle("Wimbledon's Soccer Power Index through the season")
	
	g3 = ggplot(mergeTable[hasHappened == TRUE,], aes(x=date)) + baseTheme() +
		geom_line(aes(y=relegationOdds, color="Relegation")) +
		geom_line(aes(y=promotionPlayoffOdds, color="Promotion Playoffs")) +
		ggtitle("FiveThirtyEight's Relegation and Promotion Playoff Odds") +
		labs(x=NULL, y="Percent Chance") + ylim(0, 100) +
		scale_color_manual(values = masterColorList()) + 
		xlim(as.Date("2021-08-01"), as.Date("2022-05-01"))
	
	g4 = ggplot(mergeTable[hasHappened == TRUE,]) + baseTheme() +
		geom_bar(aes(x=date, y=importance), fill="black", stat="identity") +
		labs(x=NULL, y="Importance") + ggtitle("FiveThirtyEight Importance of each game")
	
	return(list(g1, g2, g3, g4))
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
		ggtitle("Cumulative RAGE", subtitle="**R**atio of **A**ctual **G**oals to **E**xpected")
	
	pastGameTable = mergeTable[hasHappened == TRUE,]
	pointMax = max(c(pastGameTable$cumXGPoints, pastGameTable$adjCumXGPoints, pastGameTable$cumPoints, pastGameTable$cumProjPoints))
	g4 = ggplot(pastGameTable, aes(x=date)) + baseTheme() +
		geom_line(aes(y=cumXGPoints, color="Average xG"), size=1) +
		geom_line(aes(y=adjCumXGPoints, color="Score-Adjusted xG"), size=1) +
		geom_line(aes(y=cumPoints, color="Wimbledon"), size=1.5) +
		geom_point(aes(y=cumPoints, color="Wimbledon"), size=2.5) +
		geom_line(aes(x=date, y=cumProjPoints, color="FiveThirtyEight"), size=1) +
		ggtitle("Point accumulation versus xG Models") +
		labs(x=NULL, y="Points") + ylim(0, pointMax + 3) +
		scale_color_manual(values=masterColorList())

	return(list(g1,g2,g3,g4))
}

makeBasicStatPlots <- function(mergeTable) {
	possTable = mergeTable[hasHappened == TRUE,c("date","possessionFor","gameDesc")]
	setnames(possTable, old="possessionFor", new="Percentage")
	possTable$Type = "Possession"
	shotTable = mergeTable[hasHappened == TRUE,c("date","shotShare","gameDesc")]
	setnames(shotTable, old="shotShare", new="Percentage")
	shotTable$Type = "Shot Share"
	percentageTable = rbind(possTable, shotTable)
	
	g1 = ggplot(mergeTable[hasHappened == TRUE,]) + baseTheme() +
		geom_bar_interactive(stat="identity", position="dodge", data=percentageTable, aes(x=date, y=Percentage, fill=Type, 
																																 tooltip=paste(gameDesc,"\n",Type,": ", Percentage, "%", sep="")) ) + 
		geom_line(aes(x=date, y=cumPossess, color="Avg Possession"), size=1.25) +
		geom_point_interactive(size=1.5,
													 aes(x=date, y=cumPossess, color="Avg Possession", 
													 		tooltip=paste("Cumulative Possession: ", cumPossess, "%", sep=""))) + 
		geom_line(aes(x=date, y=cumShotShare, color="Avg Shot Share"), size=1.25) +
		geom_point_interactive(size=1.5,
													 aes(x=date, y=cumShotShare, color="Avg Shot Share", 
													 		tooltip=paste("Cumulative Shot Share: ", cumShotShare, "%", sep=""))) + 
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
		scale_y_continuous(breaks=seq(-6,6,2), limits=c(-5,5))
	
	return(list(g1,g2,g3))
}

makeGameTables <- function(mergeTable) {
	upcomingGames = mergeTable[hasHappened == FALSE,
														 c("date","opponent","Location","wimbledonSPI","opponentSPI","pgFor","pgOpp","winProb","lossProb","tieProb")]
	
	upcomingGames$winProb = cell_spec(upcomingGames$winProb, background=rgb(0,0.6,0.5,alpha=upcomingGames$winProb))
	upcomingGames$lossProb = cell_spec(upcomingGames$lossProb, background=rgb(0.8,0.4,0,alpha=upcomingGames$lossProb))
	upcomingGames$tieProb = cell_spec(upcomingGames$tieProb, background=rgb(0.4,0.4,0.4,alpha=upcomingGames$tieProb))
	
	pastGames = mergeTable[hasHappened == TRUE,
												 c("date","opponent","Location","gFor","gOpp",
												 	"winProb","lossProb","tieProb",
												 	"xgWin","xgLoss","xgTie",
												 	"adjXGWin","adjXGLoss","adjXGTie")]
	
	
	pastGames$winProb = cell_spec(pastGames$winProb, background=rgb(0,0.6,0.5,alpha=pastGames$winProb), 
																bold=pastGames$gFor > pastGames$gOpp)
	pastGames$lossProb = cell_spec(pastGames$lossProb, background=rgb(0.8,0.4,0,alpha=pastGames$lossProb), 
																 bold=pastGames$gFor < pastGames$gOpp)
	pastGames$tieProb = cell_spec(pastGames$tieProb, background=rgb(0.4,0.4,0.4,alpha=pastGames$tieProb), 
																bold=pastGames$gFor == pastGames$gOpp)
	
	# we use an ifelse for the alpha to make sure NA rows don't break the table
	pastGames$xgWin = cell_spec(pastGames$xgWin, background= rgb(0,0.6,0.5,alpha=ifelse(is.na(pastGames$xgWin), 0, pastGames$xgWin)),
															bold=pastGames$gFor > pastGames$gOpp)
	pastGames$xgLoss = cell_spec(pastGames$xgLoss, background=rgb(0.8,0.4,0,alpha=ifelse(is.na(pastGames$xgLoss), 0, pastGames$xgLoss)), 
															 bold=pastGames$gFor < pastGames$gOpp)
	pastGames$xgTie = cell_spec(pastGames$xgTie, background=rgb(0.4,0.4,0.4,alpha=ifelse(is.na(pastGames$xgTie), 0, pastGames$xgTie)), 
															bold=pastGames$gFor == pastGames$gOpp)
	
	pastGames$adjXGWin = cell_spec(pastGames$adjXGWin, background=rgb(0,0.6,0.5,alpha=ifelse(is.na(pastGames$adjXGWin), 0, pastGames$adjXGWin)), 
																 bold=pastGames$gFor > pastGames$gOpp)
	pastGames$adjXGLoss = cell_spec(pastGames$adjXGLoss, background=rgb(0.8,0.4,0,alpha=ifelse(is.na(pastGames$adjXGLoss), 0, pastGames$adjXGLoss)),
																	bold=pastGames$gFor < pastGames$gOpp)
	pastGames$adjXGTie = cell_spec(pastGames$adjXGTie, background=rgb(0.4,0.4,0.4,alpha=ifelse(is.na(pastGames$adjXGTie), 0, pastGames$adjXGTie)),
																 bold=pastGames$gFor == pastGames$gOpp)
	
	k1 = kable(upcomingGames, escape=F,
						 col.names=c("Date","Opponent","Location","Wimbledon","Opponent","Avg Goals For","Avg Goals Against","% Win","% Loss","% Tie")) %>%
		kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), fixed_thead=TRUE) %>%
		add_header_above(c("Game Info"=3, "Soccer Power Index" = 2, "FiveThirtyEight Projection"=5))
	
	k2 = kable(pastGames, escape=F, 
						 col.names=c("Date","Opponent","Location","For","Against",rep(c("% Win","% Loss","% Tie"), 3))) %>%
		kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), fixed_thead=TRUE) %>%
		add_header_above(c("Game Info"=3, "Goals"=2,"FiveThirtyEight Projection"=3,"xG Models"=3,"Score Adjusted xG Model"=3)) %>%
		column_spec(c(3,5,8,11), border_right=TRUE)
	
	g1 = ggplot(mergeTable[hasHappened == TRUE,]) + baseTheme() +
		geom_line(aes(x=date, y=cumXGPoints, color="Average xG"), size=1) +
		geom_line(aes(x=date, y=adjCumXGPoints, color="Score-Adjusted xG"), size=1) +
		geom_line(aes(x=date, y=cumPoints, color="Wimbledon"), size=1) +
		geom_line(aes(x=date, y=cumProjPoints, color="FiveThirtyEight"), size=1) +
		ggtitle("Point accumulation versus xG Models") +
		labs(x=NULL, y="Points") + 
		scale_color_manual(values=masterColorList())
	
	return(list(k1,k2,g1))
}

makeGameReport <- function(pastGameRow) {
	totalGoals = pastGameRow$gFor + pastGameRow$gOpp
	pastGameRow[,xgShare_footystats := round(xgFor_footystats / (xgFor_footystats+xgOpp_footystats) * 100, 2)]
	pastGameRow[,xgShare_footballxg := round(xgFor_footballxg / (xgFor_footballxg+xgOpp_footballxg) * 100, 2)]
	pastGameRow[,gShare := ifelse(totalGoals == 0, 50, round(gFor / totalGoals * 100, 2))]
	
	gMax = max(c(3, ceiling(pastGameRow$xgFor_footballxg), ceiling(pastGameRow$xgFor_footystats),
							 ceiling(pastGameRow$xgOpp_footballxg), ceiling(pastGameRow$xgOpp_footystats),
							 pastGameRow$gFor, pastGameRow$gOpp))
	
	percentPlot = ggplot(pastGameRow) + 	gameCardTheme() + coord_flip() +
		geom_bar(aes(x="Possession", y=possessionFor, fill=Location), stat="identity") +
		geom_bar(aes(x="Possession", y=-100+possessionFor, fill="Opponent"), stat="identity") + 
		geom_bar(aes(x="Shot Share", y=shotShare, fill=Location), stat="identity") + 
		geom_bar(aes(x="Shot Share", y=-100+shotShare, fill="Opponent"), stat="identity") + 
		geom_bar(aes(x="footystats xG Share", y=xgShare_footystats, fill=Location), stat="identity") +
		geom_bar(aes(x="footystats xG Share", y=-100+xgShare_footystats, fill="Opponent"), stat="identity") +
		geom_bar(aes(x="footballxg xG Share", y=xgShare_footballxg, fill=Location), stat="identity") +
		geom_bar(aes(x="footballxg xG Share", y=-100+xgShare_footballxg, fill="Opponent"), stat="identity") +
		geom_bar(aes(x="Goal Share", y=gShare, fill=Location), stat="identity") +
		geom_bar(aes(x="Goal Share", y=-100+gShare, fill="Opponent"), stat="identity") +
		labs(x=NULL, y="Percentage") + ggtitle("Percentage Stats") + 
		scale_y_continuous(breaks=seq(-100,100,20), labels=c(seq(100,0,-20), seq(20,100,20)), limits=c(-100,100)) +
		scale_fill_manual(values = masterColorList())+
		geom_hline(yintercept=-50) + geom_hline(yintercept=50) +
		scale_x_discrete(limits=c("Goal Share","footystats xG Share","footballxg xG Share","Shot Share","Possession"))
	
	gTable = data.table(Stat = c(rep("Actual Goals",2), rep("xG footystats", 2),rep("xG footballxg",2),rep("FiveThirtyEight Projection", 2)),
											Club = rep(c(pastGameRow$Location,"Opponent"), 4),
											Count = c(pastGameRow$gFor, pastGameRow$gOpp, 
																pastGameRow$xgFor_footystats, pastGameRow$xgOpp_footystats,
																pastGameRow$xgOpp_footballxg, pastGameRow$xgOpp_footballxg,
																pastGameRow$pgFor, pastGameRow$pgOpp)
	)
	maxGoals = max(c(gTable$Count, 4), na.rm=TRUE)
	
	goals = ggplot(gTable) + 
		geom_bar(aes(x=Stat, y=Count, fill=Club), position = "dodge", stat="identity") +
		labs(x=NULL, y=NULL) + ggtitle("Goal Stats") + gameCardTheme() + coord_flip() +
		scale_fill_manual(values=masterColorList()) +
		ylim(0, maxGoals) +
		scale_x_discrete(limits=c("Actual Goals", "xG footystats", "xG footballxg", "FiveThirtyEight Projection"))
	
	winPlot = ggplot(pastGameRow) +
		geom_bar(aes(x="FiveThirtyEight", y=lossProb + tieProb + winProb, fill="Win"), stat="identity") +
		geom_bar(aes(x="FiveThirtyEight", y=lossProb + tieProb, fill="Tie"), stat="identity") +
		geom_bar(aes(x="FiveThirtyEight", y=lossProb, fill="Loss"), stat="identity") +
		geom_bar(aes(x="Avg xG Model", y=xgLoss + xgTie + xgWin, fill="Win"), stat="identity") +
		geom_bar(aes(x="Avg xG Model", y=xgLoss + xgTie, fill="Tie"), stat="identity") +
		geom_bar(aes(x="Avg xG Model", y=xgLoss, fill="Loss"), stat="identity") +
		geom_bar(aes(x="Score-Adjusted xG", y=adjXGLoss + adjXGTie + adjXGWin, fill="Win"), stat="identity") +
		geom_bar(aes(x="Score-Adjusted xG", y=adjXGLoss + adjXGTie, fill="Tie"), stat="identity") +
		geom_bar(aes(x="Score-Adjusted xG", y=adjXGLoss, fill="Loss"), stat="identity") +
		gameCardTheme() + coord_flip() + labs(x=NULL, y="Chance of Victory") +
		ggtitle("Modeled Outcome Probabilities") +
		scale_fill_manual(values=masterColorList()) +
		geom_hline(yintercept=0.5) +
		scale_y_continuous(breaks=c(seq(0,0.4,0.2), 0.5, seq(0.6,1,0.2)), labels=c(seq(0,40,20), '50%', seq(40,0,-20)), limits=c(0,1)) +
		scale_x_discrete(limits=c("Score-Adjusted xG", "Avg xG Model", "FiveThirtyEight")) +
		annotate("text", y=0.05, x="FiveThirtyEight", label="Loss") +
		annotate("text", y=0.95, x="FiveThirtyEight", label="Win")
	
	spiPlotTable = data.table(Club=c(pastGameRow$Location,pastGameRow$opponent), 
														SPI=c(pastGameRow$wimbledonSPI, pastGameRow$opponentSPI),
														Fill=c(pastGameRow$Location, "Opponent"))
	spiUpperLim = max(c(35, spiPlotTable$SPI))
	
	spi = ggplot(spiPlotTable, aes(x=Club, y=SPI, fill=Fill)) +
		geom_bar(stat="identity") +
		gameCardTheme() + coord_flip() + labs(x=NULL, y=NULL) + 
		ggtitle("Soccer Power Index") + ylim(0,spiUpperLim) +
		scale_fill_manual(values=masterColorList()) +
		theme(axis.text.y=element_blank())
	
	finalPlot = spi / percentPlot / goals / winPlot + 
		plot_annotation(paste("Game Report:", pastGameRow$gameDesc), 
										theme=theme(plot.title=element_text(size=20, hjust=0.5, face="bold"))) +
		plot_layout(heights=c(2,5,5,3))
		
	
	if (pastGameRow$Location == "Away") {
		basicTable = data.table(Team = c(pastGameRow$opponent,"AFC Wimbledon"), Score = c(pastGameRow$gOpp, pastGameRow$gFor))
		basicTable$Colour = cell_spec("Space", 
																	background=ifelse(basicTable$Team=="AFC Wimbledon", "#fff200", rgb(0.5,0.5,0.5)),
																	color=ifelse(basicTable$Team=="AFC Wimbledon", "#fff200", rgb(0.5,0.5,0.5)))
	} else {
		basicTable = data.table(Team = c("AFC Wimbledon",pastGameRow$opponent), Score = c(pastGameRow$gFor, pastGameRow$gOpp))
		basicTable$Colour = cell_spec("Space", 
																	background=ifelse(basicTable$Team=="AFC Wimbledon", "#0000ff", rgb(0.5,0.5,0.5)),
																	color=ifelse(basicTable$Team=="AFC Wimbledon", "#0000ff", rgb(0.5,0.5,0.5)))
	}
	
	gameKable = kable(basicTable, escape=FALSE) %>% kable_styling(bootstrap_options ="condensed", full_width = FALSE)
	return(list(finalPlot,gameKable))
}