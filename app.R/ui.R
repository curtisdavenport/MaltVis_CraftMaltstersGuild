
library(shiny)
library(shinyWidgets)
library(shinythemes)
library(DT)
library(tidyverse)
library(magrittr)
library(plotly)
library(corrplot)
library(caret)
library(missMDA)
library(lares)
library(ggpmisc)
library(shinycssloaders)

ui <- navbarPage(title=div(img(src="cropped-CMG_Web_logo_small.png",
                               style="margin-top: -14px; padding-right:100px;padding-bottom:10px",
                               height = 60)),
                 windowTitle='MaltVis',
                 theme = shinytheme("yeti"),
                 
                 tabPanel("Welcome", 
                          h1("Welcome to",
                             strong("MaltVis")),
                          em("MaltVis is a tool for you to engage with data collected from your malting process and malt quality data supplied by one of our wonderful 3rd party labs.
"),
                          br(),
                          br(),
                          strong("SOP"),"tab contains detailed description and instructions for each function of MaltVis",
                          br(),
                          br(),
                          strong("UPLOAD"), "Use this tab to upload your data as a .csv file into MaltVis. Or, use the sample data set provided. Don't worry, your data will not be collected,stored, or shared.",
                          br(),
                          br(),
                          strong("BATCH SUMMARY/STATS"),"displays a chart and table comparing the malt quality data of a selected batch to previous batches of the same style. Enter a Batch ID, choose the number of previous batches to compare it to, and voila!
",
                          br(),
                          br(),
                          strong("CONTROL CHART TRENDS"),"displays a control chart for any chosen variable/parameter. Includes lines for upper and lower limits at one and two standard deviations, or you can customize your own limits. Data can be subset by malt style and colored by malt style, raw grain lot number, variety, or crop year.
",
                          br(),
                          br(),
                          strong("EXPLORE RELATIONSHIPS"),"Produces a chart displaying the ranked correlations between a chosen variable/parameters and all others. 
",
                          br(),
                          br(),
                          strong("CORRELATION CHART"),"Produces a scatter plot and calculates R-squared value of two chosen variables. Subset data by Style, Crop Year and Variety.
",
                          br(),
                          br(),
                          em('MaltVis was developed by Curtis Davenport and Andrew Caffrey of Admiral Maltings. Feel free to email maltvis@admiralmaltings.com with any questions, comments, or other feedback. Feeling advanced? If you want to run MaltVis locally, or want to contribute new features, find the MaltVis source code on',a(href='https://github.com/curtisdavenport/MaltVis_CraftMaltstersGuild', 'GitHub',target="_blank")),
                          
                          style="margin-right:300px; margin-left:20px"),
                 
                 
                 
                 tabPanel("SOP",
                          tags$iframe(src="Welcome.pdf",height=500,width=850)),
                 
                 
                 tabPanel("Upload",
                          fileInput("file", "Upload .csv of latest data",
                                    accept = c('.csv')
                          ),
                          actionButton("load", "Click Here to Load"),
                          br(),
                          p('Or use this', a(href='https://docs.google.com/spreadsheets/d/11d3_Wv78W6MCjpSPxNk1lTBJmC8mdDpA3aM-Vz5yewQ/edit#gid=0',"link",target="_blank"), 'to download a sample dataset')),
                 
                 
                 
                 tabPanel("BatchVis",
                          textInput("Batch","Batch ID/#"),
                          sliderInput("visnumber","# of last batches to compare with", min=1,max=33,step=1,value =2),
                          actionButton("batchvisgo","Submit"),
                          p(strong("Style:")),
                          textOutput("Style"),
                          plotlyOutput("batchvis"),
                          dataTableOutput("BatchTable")),
                 tabPanel("QC Plot",
                          selectInput("variable","Variable",choices = NULL),
                          textInput("userupperlimit","Upper Limit"),
                          textInput("userlowerlimit", "Lower Limit"),
                          sliderInput("graphbatches","# of last batches",min=1,max=3,value = 2),
                          pickerInput("style2","Style",choices = NULL,
                                      options = list(`actions-box` = TRUE),
                                      multiple = T),
                          selectInput("interests","Coloring",choices = NULL),
                          actionButton("submitqc","Submit"),
                          plotlyOutput("qcplot"),
                          checkboxInput("dashedline", label = "Dashed Line", value = FALSE),
                          checkboxInput("fitline", label = "Fit Line", value = FALSE)),
                 tabPanel("Parameter Correlations",
                          selectInput("Corparam", "Parameter", choices = NULL),
                          pickerInput("corstyle","Style",choices=NULL,
                                      options = list(`actions-box` = TRUE),
                                      multiple = T),
                          pickerInput("paramcropyear","Crop Year",choices = NULL,
                                      options = list(`actions-box` = TRUE),
                                      multiple = T),
                          pickerInput("paramvariety","Variety",choices = NULL,
                                      options = list(`actions-box` = TRUE),
                                      multiple = T),
                          actionButton("CorrGo","Submit"),
                          plotOutput("crosscor")),
                 tabPanel("Visualize",
                          selectInput("columns1", "Select X Columns", choices = NULL),
                          selectInput("columns2", "Select Y Columns", choices = NULL),
                          pickerInput("style","Style",choices = NULL,
                                      options = list(`actions-box` = TRUE),
                                      multiple = T),
                          pickerInput("viscropyear","Crop Year",choices = NULL,
                                      options = list(`actions-box` = TRUE),
                                      multiple = T),
                          pickerInput("visvariety","Variety",choices = NULL,
                                      options = list(`actions-box` = TRUE),
                                      multiple = T),
                          p(strong("R-squared")),
                          textOutput("correlation"),
                          plotlyOutput("visplot")
                 ),
                 tabPanel("Look Up Data",
                          textInput("batch", "Batch #"),
                          pickerInput("style3","Style",choices = NULL,
                                      options = list(`actions-box` = TRUE),
                                      multiple = T),
                          pickerInput("param","Parameter",choices = NULL,
                                      options = list(`actions-box` = TRUE),
                                      multiple = T),
                          dataTableOutput("lookupdata")),
                 
                 tabPanel("Help",
                          tags$iframe(src="Help.pdf",height=800,width=850))
                 
                 
)
