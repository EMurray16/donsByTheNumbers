# user interface for the Dons By the Numbers shiny app
library(shiny)
library(shinyjs)
library(shinythemes)
library(shinyBS)

shinyUI(
navbarPage(title="Dons By the Numbers", id="navbarID",
		tabPanel("Games",
						 bsCollapse(id="gameCollapse", multiple=TRUE, open=c("Upcoming Games","Past Games"),
						 	bsCollapsePanel("Upcoming Games",
						 									htmlOutput("tableGame_1")
						 	),
						 	bsCollapsePanel("Past Games",
						 									htmlOutput("tableGame_2")
						 	)
						 )
						 
		 ),
		tabPanel("Basic Stats",
						 plotOutput("plotBasic_1"),
						 plotOutput("plotBasic_2"),
						 plotOutput("plotBasic_3")
		),
		tabPanel("FiveThirtyEight",
						 bsCollapsePanel("What is FiveThirtyEight's Model?",
						 								includeMarkdown("docs/about538.md")
 						 ),
						 mainPanel(
						 	plotOutput("plot538_1"),
						 	plotOutput("plot538_2"),
						 	plotOutput("plot538_3")
						 )
	  ),
		
		tabPanel("Expected Goals",
						 bsCollapsePanel("What Are Expected Goals?", 
						 								withMathJax(includeMarkdown("docs/aboutXG.md"))
 						 ),
						 mainPanel(width=12,
						 		plotOutput("plotXG_1"),
						 		plotOutput("plotXG_2"),
						 		plotOutput("plotXG_3")
						 ),
	  ),
		
		tabPanel("Update FiveThirtyEight Data",
						 p("The last time the FiveThirtyEight data was updated is:"),
						 textOutput("fteTimestamp"),
						 br(),
						 p("In general, FiveThirtyEight updates about an hour after league games, which generally end around 5 PM UTC (12 PM EST) 
								on Saturdays and 10 PM UTC (5 PM EST) on weekdays. Expected goal models generally lag by 2-3 days and are updated 
						 		manually."),
						 p("Are you sure you want to update the FiveThirtyEight data? Please be considerate of their bandwidth."),
						 actionButton("updateFTE", label="Update FiveThirtyEight Data")
		),
		
		tabPanel("Planned Changes",
						 p(" - This isn't a change, but it's worth mentioning the source code for this app is", 
						 			 a("on GitHub", href="https://github.com/EMurray16/donsByTheNumbers")
						 	),
						 p(" - I would like to add tooltips to the plots include details of each game"),
						 p(' - I would like to add "game cards" for each game, with a breakdown of the statistics for past games, and the forecasts
						 	for future games'),
						 p(" - Eventually I may have the plots scale more elegantly with the size of the screen (may be too lazy to implement this 
						 	one)"),
						 p(" - I would like to make some plots comparing how Wimbledon performs in xG relative to FiveThirtyEight's projected goals.")
	  ),
		
		theme=shinytheme("yeti"), 
		useShinyjs(),
		tags$head(
			tags$link(rel = "stylesheet", type = "text/css", href = "wimbledonTheme.css"),
			tags$link(rel="shortcut icon", href="favicon.png")
		)
))