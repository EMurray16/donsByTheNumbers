# This is the server for the Dons By the Numbers app
library(shiny)
library(ggiraph)

server <- function(input, output, session) {
	print("Dons by the Numbers")
	# Define this function where output is available
	renderOutputPlots <- function() {
		output$plot538_1 = renderGirafe({girafe(ggobj=plots538[[1]], width_svg=9)})
		output$plot538_2 = renderGirafe({girafe(ggobj=plots538[[2]], width_svg=9)})
		output$plot538_3 = renderGirafe({girafe(ggobj=plots538[[3]], width_svg=9)})
		output$plot538_4 = renderGirafe({girafe(ggobj=plots538[[4]], width_svg=9)})
		
		output$plotXG_1 = renderGirafe({girafe(ggobj=plotsXG[[1]], width_svg=11, height_svg = 8)})
		output$plotXG_2 = renderGirafe({girafe(ggobj=plotsXG[[2]], width_svg=9)})
		output$plotXG_3 = renderGirafe({girafe(ggobj=plotsXG[[3]], width_svg=11, height_svg = 8)})
		output$plotXG_4 = renderGirafe({girafe(ggobj=plotsXG[[4]], width_svg=11, height_svg = 8)})
		
		output$plotBasic_1 = renderGirafe({girafe(ggobj=plotsBasic[[1]], width_svg=9)})
		output$plotBasic_2 = renderGirafe({girafe(ggobj=plotsBasic[[2]], width_svg=9)})
		output$plotBasic_3 = renderGirafe({girafe(ggobj=plotsBasic[[3]], width_svg=9)})
		
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