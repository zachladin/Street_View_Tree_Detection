library(shiny)
library(shinythemes)
library(shinydashboard)
library(webshot)
library(shinyjs)
library(htmltools)
library(ggmap)
library(ggplot2)
library(googleway)
library(jpeg)
library(imager)
library(magick)
library(adimpro)
library(reticulate)
library(raster)
library(leaflet)

source("/Users/zach/Dropbox (ZachTeam)/Projects/Street_View_Shiny_App/New_Street_View/helpers.R")
##############################################################################
#function to capture screenshot and modify image

screenCapture<-function(){
  
new.img<-load.image(paste("/Users/zach/Dropbox (ZachTeam)/Projects/Street_View_Shiny_App/New_Street_View/TOH_yolo/Downloaded_images", paste("screenshot", "jpg",sep="."),sep="/"))
  #plot(new.img)
  
  #crop image
  img.crop<-imsub(new.img,x<=3100,x>1950, y>450, y<690)#First 30 columns and rows
  #plot(img.crop)
  
  #dim(img.crop)
  
  #save image
  jpeg(paste("/Users/zach/Dropbox (ZachTeam)/Projects/Street_View_Shiny_App/New_Street_View/TOH_yolo/Downloaded_images",paste("Image_",1,".jpg",sep=""), sep="/"),
       width=689,quality=1800, res=1200)
  
  par(mar = rep(0, 4),xpd=NA)
  plot(img.crop, axes=FALSE, xaxs="i",yaxs="i")
  
  dev.off()
  
  #read in image as image magick object
  new.img<-image_read(paste("/Users/zach/Dropbox (ZachTeam)/Projects/Street_View_Shiny_App/New_Street_View/TOH_yolo/Downloaded_images",paste("Image_",1,".jpg",sep=""), sep="/"))
  
  new.img.crop<-image_trim(new.img,fuzz=20)
  
  #write image
  image_write(new.img.crop, paste("/Users/zach/Dropbox (ZachTeam)/Projects/Street_View_Shiny_App/New_Street_View/TOH_yolo/Downloaded_images",paste("Image_",1,".jpg",sep=""), sep="/"), quality=100,
              density=1200)
}
################################################################################
ui <- dashboardPage(
  
  skin = "green",
  
  dashboardHeader(title = "BIOVERSE - Google Street View Tree Detector", titleWidth = 450),
  
  dashboardSidebar(
      width = 250,
      useShinyjs(),
      tags$style(appCSS),
      
      textInput("choose_location", "Choose a location:" , "Ex. Newark, DE"),
      
      hr(),
      
      sliderInput("threshold", "Confidence Threshold",
                  min = 0, max = 1, value = 0.1, step=0.05),
      
      hr(),
      
      withBusyIndicatorUI(
        actionButton(
          "screenshot",
          "Run Tree-of-heaven Detector",
          class = "btn-primary"
        )
  ),
  
  hr(),
  
      #actionButton("screenshot","Run tree-of-heaven detector."),
      
      span(textOutput("analysis_message_1"), style="color:green"),
      span(textOutput("analysis_message_2", ), style="color:orange")
        ),
      
  dashboardBody(
    box(width = 6,
        google_mapOutput(outputId = "map")
    ),
    box(width = 6,
        google_mapOutput(outputId = "pano")
    ),
      
    
    conditionalPanel(
      condition = "analysis_message_1" == "    Tree-of-heaven detected!",
        column(plotOutput("image1"),width=6)
    )
    
    
    #plotOutput("distPlot")
    
  )
)

server <- function(input, output, session) {

  if (interactive()) {
    
  #google API key
  set_key("AIzaSyAPrRGk21jtlX5iTUgrLkfqWerUDInSQYo")

    output$map <- renderGoogle_map({
    # Get latitude and longitude
    # Get latitude and longitude
    if(input$choose_location=="Ex. Newark, DE"){
      LAT=39.689349
      LONG=-75.760289
      ZOOM=12
    }else{
      target_pos=geocode(input$choose_location)
      LAT=target_pos$lat
      LONG=target_pos$lon
      ZOOM=12
    }
    
      google_map(location = c(LAT, LONG),
                 zoom = ZOOM,
                 split_view = "pano")
    

  })
  
    #observe event when Run Tree-of-heaven detector is clicked
    observeEvent(input$screenshot,
                 {   
                     output$analysis_message_1 <-
                       renderText({
                         paste("")
                       })
                     
                     output$analysis_message_2 <-
                       renderText({
                         paste("")
                       })
                     
                     #hide("image1")
                     
                 })
    
    observeEvent(input$screenshot,
              {   
              
                withBusyIndicatorServer("screenshot", {
                  Sys.sleep(19)
                })
                
                  #get myThreshold
                  myThreshold<-reactive({
                    input$threshold
                  })
                
                   #first delete Image_1_labeled.jpg
                   img.file.path<-"/Users/zach/Dropbox (ZachTeam)/Projects/Street_View_Shiny_App/New_Street_View/TOH_yolo/Labeled_images"
                   
                   file.remove(dir(  
                     img.file.path, 
                     pattern = "\\.jpg$", 
                     full.names = TRUE
                   ))
                   
                   #run screencapture command from terminal
                   system("screencapture /Users/zach/'Dropbox (ZachTeam)'/Projects/Street_View_Shiny_App/New_Street_View/TOH_yolo/Downloaded_images/screenshot.jpg")
                   
                   #run screenCapture function to process images
                   screenCapture()

                   #run YOLO toh detector
                   print(environment(show))
                   use_python("/usr/local/bin/python3", required=TRUE)
                   
                   source_python("/Users/zach/Dropbox (ZachTeam)/Projects/Street_View_Shiny_App/New_Street_View/TOH_yolo/YOLO_scripts/runYOLO_from_R.py")
                   
                   #run YOLO
                   try(yolo_in_R(myDir="/Users/zach/Dropbox (ZachTeam)/Projects/Street_View_Shiny_App/New_Street_View/TOH_yolo",imageName="Image_1", threshold = myThreshold() ))
                   
                   #Load labeled image
                   tryCatch({
                            new.img.label<-image_read(paste("/Users/zach/Dropbox (ZachTeam)/Projects/Street_View_Shiny_App/New_Street_View/TOH_yolo/Labeled_images", paste(paste("Image_1","_labeled",sep=""), "jpg",sep="."),sep="/"))
                            
                            new.img.label.crop<-image_trim(new.img.label,fuzz=20)
                            
                            output$image1<-renderPlot({
                            par(mar = rep(0, 4),xpd=NA)
                            plot(new.img.label.crop, axes=FALSE, xaxs="i",yaxs="i")
                            })
                            
                            output$analysis_message_1 <- 
                                renderText({
                                  paste("    Tree-of-heaven detected!")
                                  
                              })
                              
                   }, error=function(cond2){
                     output$analysis_message_2 <-
                       renderText({
                         paste("    Tree-of-heaven was not detected.")
                       })
                       cond2
                    })
                     
        })
  }
}



  
shinyApp(ui, server)
  