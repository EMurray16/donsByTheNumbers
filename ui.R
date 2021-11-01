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
						 plotOutput("plotBasic_2"),
						 plotOutput("plotBasic_3")
		),

		tabPanel("FiveThirtyEight",
						 bsCollapsePanel("What is FiveThirtyEight's model?",
						 								includeMarkdown("docs/about538.md")
						 ),
						 mainPanel(
						 	plotOutput("plot538_1"),
						 	plotOutput("plot538_2"),
						 	plotOutput("plot538_3"),
						 	plotOutput("plot538_4")
						 )
	  ),
		
		tabPanel("Expected Goals",
						 bsCollapsePanel("What are expected goals?", 
						 								withMathJax(includeMarkdown("docs/aboutXG.md"))
						 ),
						 mainPanel(width=12,
						 		plotOutput("plotXG_1"),
						 		plotOutput("plotXG_2"),
						 		plotOutput("plotXG_3"),
						 		plotOutput("plotXG_4")
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
						 									p(" - I would like to add tooltips to the plots include details of each game"),
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