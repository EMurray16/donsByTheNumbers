# user interface for the Dons By the Numbers shiny app
library(shiny)
library(shinyjs)
library(shinythemes)
library(shinyBS)
library(ggiraph)

shinyUI(
navbarPage(title="Dons By the Numbers", id="navbarID",
		tabPanel("Fixtures & Results",
						 
						 bsCollapse(id="gameCollapse", multiple=TRUE, open=c("Upcoming Matches","Past Matches"),
						 					 bsCollapsePanel("How are odds of victory calculated?",
						 					 								includeMarkdown("docs/calculatingOdds.md")
						 					 ),			 
						 	bsCollapsePanel("Upcoming Matches",
						 									htmlOutput("tableGame_1")
						 	),
						 	bsCollapsePanel("Past Matches",
						 									htmlOutput("tableGame_2")
						 	)
						 )
						 
		 ),
		
		tabPanel("Match Reports",
						 sidebarPanel(
						 		selectInput("gameToDisplay", label="Select Match", choices=rev(mergeTable$gameDesc[mergeTable$hasHappened])),
						 		htmlOutput("gameCardInfoTable"),
						 		width=4
						 ),
						 mainPanel(width=8,
						 					plotOutput("gameCard", height="600px", width="650px")
	 					 )
	  ),

		tabPanel("Basic Stats",
						 girafeOutput("plotBasic_1"),
						 girafeOutput("plotBasic_2"),
						 girafeOutput("plotBasic_3")
		),

		tabPanel("FiveThirtyEight",
						 bsCollapsePanel("What is FiveThirtyEight's model?",
						 								includeMarkdown("docs/about538.md")
						 ),
						 mainPanel(width=12,
						 	girafeOutput("plot538_1"),
						 	girafeOutput("plot538_2"),
						 	girafeOutput("plot538_3"),
						 	girafeOutput("plot538_4")
						 )
	  ),
		
		tabPanel("Expected Goals",
						 bsCollapsePanel("What are expected goals?", 
						 								withMathJax(includeMarkdown("docs/aboutXG.md"))
						 ),
						 mainPanel(width=12,
						 		girafeOutput("plotXG_1"),
						 		girafeOutput("plotXG_2"),
						 		girafeOutput("plotXG_3"),
						 		girafeOutput("plotXG_4")
						 )
	  ),
		
		tabPanel("League Table",
						 bsCollapsePanel("What is team and schedule strength?",
						 								withMathJax(includeMarkdown("docs/strengthOfSchedule.md"))
 						 ),
						 mainPanel(width=12,
						 					htmlOutput("leagueTable"),
						 					htmlOutput("averageStrengthText"),
						 					br() #additional padding at the bottom of the screen
						 )
		 ),
		
		tabPanel("Update Data",
						 p("The last time the FiveThirtyEight data was updated is:"),
						 textOutput("fteTimestamp"),
						 br(),
						 p("In general, FiveThirtyEight updates about an hour after league games, which generally end around 5 PM UTC (12 PM EST) 
								on Saturdays and 10 PM UTC (5 PM EST) on weekdays. Are you sure you want to update the FiveThirtyEight data? Please 
						 	  be considerate of their bandwidth."
					 	 ),
						 actionButton("updateFTE", label="Update FiveThirtyEight Data"),
						 hr(),
						 p("Expected goal models generally lag by 2-3 days and I update them manually.")
		),
		
		tabPanel("About",
						 p("Like what you see? You can find the code and supporting data for this page", 
						 	a("on GitHub.", href="https://github.com/EMurray16/donsByTheNumbers")),
						 bsCollapse(
						 	bsCollapsePanel("Planned Changes",
						 									p(" - Eventually I may have the plots scale more elegantly with the size of the screen 
						 									(may be too lazy to implement this one)")
						 	),
						 	open="Planned Changes"
						 )
	  ),
		
		theme=shinytheme("yeti"), 
		useShinyjs(),
		tags$head(
			tags$link(rel = "stylesheet", type = "text/css", href = "wimbledonTheme.css"),
			tags$link(rel="shortcut icon", href="favicon.png"),
			tags$script(src="fixingExpandedHeader.js")
		)
))