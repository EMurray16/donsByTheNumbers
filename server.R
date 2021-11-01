# This is the server for the Dons By the Numbers app
library(shiny)
library(ggiraph)

server <- function(input, output, session) {
	print("Dons by the Numbers")
	# Define this function where output is available
	renderOutputPlots <- function() {
		output$plot538_1 = renderPlot(plots538[[1]])
		output$plot538_2 = renderPlot(plots538[[2]])
		output$plot538_3 = renderPlot(plots538[[3]])
		output$plot538_4 = renderPlot(plots538[[4]])
		
		output$plotXG_1 = renderPlot(plotsXG[[1]])
		output$plotXG_2 = renderPlot(plotsXG[[2]])
		output$plotXG_3 = renderPlot(plotsXG[[3]])
		output$plotXG_4 = renderPlot(plotsXG[[4]])
		
		output$plotBasic_1 = renderGirafe({girafe(ggobj=plotsBasic[[1]], width_svg=9)})
		output$plotBasic_2 = renderPlot(plotsBasic[[2]])
		output$plotBasic_3 = renderPlot(plotsBasic[[3]])
		
		output$fteTimestamp = renderText(fteUpdateTimestamp)
		
		output$tableGame_1 = renderUI(HTML(tablesGame[[1]]))
		output$tableGame_2 = renderUI(HTML(tablesGame[[2]]))
	}
	
	renderOutputPlots()
	
	observeEvent(input$updateFTE, {
			withProgress(value=1, message="Getting and parsing FiveThirtyEight data...",
									 expr = {
									 	# step 1: get the new data
									 	table538 <<- UpdateFiveThirtyEight(Rdata538, RdataTimestamp)
									 	
									 	session$reload()
									 }
			)
	})
	
	observe({
		pastGameRow = mergeTable[gameDesc == input$gameToDisplay,]
		gameDisplays = makeGameReport(pastGameRow)
		output$gameCard = renderPlot(gameDisplays[[1]])
		output$gameCardInfoTable = renderUI(HTML(gameDisplays[[2]]))
	})
}