server <- function(input, output, session) {
  
  ##Main Data 
  ###Visualize, Lookupdata, Parameter Correlations, and Batchvis use this
  Data<-eventReactive(input$load, {
    inFile <- input$file
    req(inFile)
    D <- read.csv(inFile$datapath, header = TRUE, sep = ",", quote = "'")
    D$Crop.Year<-as.character(D$Crop.Year)
    D
  })
  
  ##Updating Picker/Select Inputs  
  C<-observeEvent(input$load,{
    
    #BatchVis
    updateSliderInput(session,"visnumber","# of last batches", min=0,max=100,step=1,value = 25)
    
    #Visualize
    updateSelectInput(session, "columns1","X variable",
                      choices = colnames(Data()),)
    updateSelectInput(session, "columns2","Y variable",
                      choices = colnames(Data()))
    updatePickerInput(session,inputId = "style","Style",
                      choices =levels(as.factor(Data()$Style)))
    updatePickerInput(session,"viscropyear","Crop Year",
                      choices = levels(as.factor(Data()$Crop.Year)))
    updatePickerInput(session,"visvariety","Variety",
                      choices = levels(as.factor(Data()$Variety)))
    
    #Correlation Parameters
    updateSelectInput(session,"Corparam", "Parameter",
                      choices =colnames(Data()%>%keep(is.numeric)))
    updatePickerInput(session,"corstyle","Style",
                      choices=c(levels(as.factor(Data()$Style))))
    updatePickerInput(session,"paramcropyear","Crop Year",
                      choices = levels(as.factor(Data()$Crop.Year)))
    updatePickerInput(session,"paramvariety","Variety",
                      choices = levels(as.factor(Data()$Variety)))
    
    #Look Up Data
    updatePickerInput(session,"style3","Style",choices = levels(as.factor(Data()$Style)))
    updatePickerInput(session,"param","Parameter",choices = colnames(Data()[3:ncol(Data())]))
  })
  
  ##QCplot
  Data2 <- eventReactive(input$load, {
    interest<-Data()%>%
      colnames(.)%>%
      as.data.frame()%>%
      ####detects columns containing text below
      filter(str_detect(.,"Batch|Variety|Crop|Style|1.Lot"))%>%pull()
    
    D3<-Data()%>%
      select_if(.,is.numeric)%>%
      cbind(Data()[match(interest,names(Data()))],.)
    
    D4<-D3%>%pivot_longer(.,colnames(.[6:ncol(.)]),
                          names_to="Parameter",
                          values_to="Value")
    
    batch<-levels(as.factor(D4$`Batch..`))%>%length()
    pars<-levels(as.factor(D4$Parameter))
    sty<-levels(as.factor(D4$Style))
    
    updateSelectInput(session,"variable","Variable",choices = pars)
    updatePickerInput(session,"style2","Style",choices = sty)
    updateSliderInput(session,"graphbatches","# of Batches to Graph",min=0, max=batch,step=1,value=25)
    updateSelectInput(session,"interests","Coloring",choices = interest[-c(1)])
    
    D4
  })
  
  Upperlimit<-eventReactive(input$submitqc, {
    as.numeric(input$userupperlimit)
  })
  Lowerlimit<-eventReactive(input$submitqc, {
    as.numeric(input$userlowerlimit)
  })
  
  ##BatchVis
  
  #variables to be plotted on BtachVis
  AllParameters<-eventReactive(input$load,{
    c("Batch..","Style","Total.Protein","Soluble.Protein",
      "S.T","pH","Hartwick.Friability","FAN","Extract",
      "DP","Color","B.Glucan","AA")
  })
  
  #normalize data to the mean
  Data4<-eventReactive(input$batchvisgo, {
    Sty<-Data()%>%filter(`Batch..`==input$Batch)%>%pull("Style")
    D15<-Data()%>%
      filter(.,`Style`==Sty)%>%
      slice_tail(n=input$visnumber)%>%
      select(any_of(AllParameters()))%>%
      mutate_at(vars(colnames(.[-c(1:2)])),funs(./mean(.,na.rm = T)))
    D15
  })
  
  #pivot the mean data for ggplot
  Data5<-eventReactive(input$batchvisgo, {
    Data4()%>%slice_tail(.,n=input$visnumber)%>%
      pivot_longer(.,colnames(.[3:ncol(.)]),
                   names_to="Parameter",
                   values_to="Values")
  })
  
  #Plot batch as blue dot
  Data6<-eventReactive(input$batchvisgo, {
    Data4()%>%filter(`Batch..`==input$Batch)%>%
      pivot_longer(.,colnames(.[3:ncol(.)]),
                   names_to="Parameter",
                   values_to="Values")
  })
  
  #Plot SD's as orange and red dots
  Data7<-eventReactive(input$batchvisgo, {
    Data4()[-c(1:2)]%>%summarise_all(.,sd,na.rm=T)%>%
      pivot_longer(.,colnames(.),
                   names_to="Parameter",
                   values_to="Values")%>%
      mutate(.,USD=.$Values+1,LSD=1-.$Values,UUSD=2*.$Values+1,LLSD=1-2*.$Values)
  })
  #Table of actual mean and batch values
  Data8<-eventReactive(input$batchvisgo, {
    
    Sty<-Data()%>%filter(`Batch..`==input$Batch)%>%pull("Style")
    
    D13<-Data()%>%
      filter(.,`Style`==Sty)%>%
      slice_tail(n=input$visnumber)%>%
      select(any_of(AllParameters()[-c(1,2)]))%>%
      summarise_all(.,mean,na.rm=T)%>%
      pivot_longer(.,colnames(.[1:ncol(.)]),
                   names_to="Parameter",
                   values_to="Mean")
    D14<-Data()%>%
      filter(.,`Style`==Sty,`Batch..`==input$Batch)%>%
      slice_tail(n=input$visnumber)%>%
      select(any_of(AllParameters()[-c(1,2)]))%>%
      pivot_longer(.,colnames(.[1:ncol(.)]),
                   names_to="Parameter",
                   values_to="Batch Value")
    
    D16<-Data()%>%filter(.,`Style`==Sty)%>%
      slice_tail(n=input$visnumber)%>%
      select(any_of(AllParameters()[-c(1,2)]))%>%
      summarise_all(.,min,na.rm=T)%>%
      pivot_longer(.,colnames(.[1:ncol(.)]),
                   names_to="Parameter",
                   values_to="Min")
    
    D17<-Data()%>%filter(.,`Style`==Sty)%>%
      slice_tail(n=input$visnumber)%>%
      select(any_of(AllParameters()[-c(1,2)]))%>%
      summarise_all(.,max,na.rm=T)%>%
      pivot_longer(.,colnames(.[1:ncol(.)]),
                   names_to="Parameter",
                   values_to="Max")
    
    D18<-Data()%>%filter(.,`Style`==Sty)%>%
      slice_tail(n=input$visnumber)%>%
      select(any_of(AllParameters()[-c(1,2)]))%>%
      summarise_all(.,sd,na.rm=T)%>%
      pivot_longer(.,colnames(.[1:ncol(.)]),
                   names_to="Parameter",
                   values_to="SD")
    
    D15<-cbind(D14,D13[2],D18[2],D16[2],D17[2])
  })
  #Tells you what style the batch was
  BatchVisStyle<-eventReactive(input$batchvisgo, {
    Sty<-Data()%>%filter(`Batch..`==input$Batch)%>%pull("Style")
  })
  
  
  ##Parameter Correlations
  
  Correlations<-eventReactive(input$CorrGo,{
    
    P<-Data()%>%filter(Style%in%input$corstyle,Crop.Year%in%input$paramcropyear,Variety%in%input$paramvariety)%>%
      keep(is.numeric)%>%
      .[-c(nearZeroVar(.))]
    
    S<-Data()%>%
      filter(Style%in%input$corstyle,Crop.Year%in%input$paramcropyear,Variety%in%input$paramvariety)%>%
      .[1]
    
    C<-cbind(S,P)%>%
      remove_rownames()%>%
      column_to_rownames("Batch..")%>%
      MIPCA(.,ncp=2,nboot = 1)
    
    R<-lapply(C[["res.MI"]],`[`,c(1:ncol(C[["res.MI"]][[1]])))%>%
      map_df(rownames_to_column,"Batch..")%>%
      group_by(`Batch..`)%>%
      summarise_at(.,vars(colnames(.[2:ncol(.)])),funs(mean(.)))%>%
      remove_rownames()%>%
      column_to_rownames("Batch..")
    
    R
  })
  
  Parameter<-eventReactive(input$CorrGo,{
    as.character(input$Corparam)
  })
  
  
  
  ##############Outputs
  
  
  ##Visualize
  output$visplot<-renderPlotly({
    Data()%>%
      filter(`Style`%in%input$style,`Crop.Year`%in%input$viscropyear,`Variety`%in%input$visvariety)%>%
      ggplot(aes(color=`Style`,group=1, label=`Batch..`))+
      geom_point(aes_string(x=input$columns1, y=input$columns2))+
      geom_smooth(aes_string(x=input$columns1, y=input$columns2),se=F,
                  method="lm", 
                  formula = y ~ poly(x, 1))+
      theme(axis.text.x = element_text(angle = 90, size = 6))
  })
  
  output$correlation<-renderText({
    P<-c(input$columns1,input$columns2)
    Data()%>%
      filter(`Style`%in%input$style)%>%
      select(any_of(P))%>%
      remove_missing()%$%
      cor(x=as.numeric(.[[input$columns1]]),
          y=as.numeric(.[[input$columns2]]))
  })
  
  ##QC PLOT
  output$qcplot<-renderPlotly({
    
    Mean<-Data2()%>%
      filter(`Parameter`==input$variable,`Style`%in%c(input$style2))%>%
      slice_tail(.,n=as.integer(input$graphbatches))%>%
      summarise(mean=mean(`Value`,na.rm = T))%>%
      as.numeric()%>%round(.,digits = 2)
    SD<-Data2()%>%
      filter(`Parameter`==input$variable,`Style`%in%input$style2)%>%
      slice_tail(.,n=as.integer(input$graphbatches))%>%
      summarise(sd=sd(`Value`,na.rm = T))%>%
      as.numeric()%>%round(.,digits = 2)
    uppersd2<-Mean+2*SD
    uppersd1<-Mean+SD
    lowersd2<-Mean-2*SD
    lowersd1<-Mean-SD
    
    Data2()%>%
      filter(`Parameter`==input$variable,`Style`%in%input$style2)%>%
      slice_tail(.,n=as.integer(input$graphbatches))%>%
      ggplot(aes(x=`Batch..`,y=`Value`,group=1, label=`Style`))+
      geom_point(aes_string(color=input$interests))+
      geom_hline(yintercept=Mean,linetype="dashed")+
      geom_hline(yintercept = uppersd2,color="red",size=0.25)+
      geom_hline(yintercept = lowersd2,color="red",size=0.25)+
      geom_hline(yintercept = uppersd1,color="orange",size=0.25)+
      geom_hline(yintercept = lowersd1,color="orange",size=0.25)+
      geom_hline(yintercept = Upperlimit(),color="blue",size=0.25)+
      geom_hline(yintercept = Lowerlimit(),color="blue",size=0.25)+
      theme(axis.text.x = element_text(angle = 90, size = 6))+
      theme_bw()+
      (if(input$dashedline) {geom_line(stat="identity",position="identity",
                                       color="purple",linetype=2)
      })+
      (if(input$fitline){geom_smooth(se=T,
                                     color="purple",
                                     size=0.5)})
    
    
  })
  
  ##BatchVis
  output$batchvis<-renderPlotly({
    Data5()%>%
      ggplot(aes(x=`Parameter`,y=`Values`))+
      geom_point(size=0.1)+
      geom_point(data = Data6(),aes(x=`Parameter`,y=`Values`),color="blue",shape="|",size=2)+
      geom_point(data=Data7(),aes(x=`Parameter`,y=`USD`),color="orange",shape="|",size=1)+
      geom_point(data=Data7(),aes(x=`Parameter`,y=`LSD`),color="orange",shape="|",size=1)+
      geom_point(data=Data7(),aes(x=`Parameter`,y=`LLSD`),color="red",shape="|",size=1)+
      geom_point(data=Data7(),aes(x=`Parameter`,y=`UUSD`),color="red",shape="|",size=1)+
      ylim(min=0,max=2)+
      theme_bw()+
      coord_flip()
  })
  
  output$BatchTable<-renderDataTable({
    Data8()%>%
      mutate_if(.,is.numeric,round,digits = 2)}
  )
  
  output$Style<-renderText({
    BatchVisStyle()
  })
  ##Lookupata
  output$lookupdata<-renderDataTable({
    Data()%>%
      filter(str_detect(`Batch..`,input$batch))%>%
      filter(`Style`%in%input$style3)%>%
      select(`Batch..`|`Style`|input$param)%>%
      print()
  })
  
  ##Parameter Correlations
  output$crosscor<-renderPlot({
    corr_cross(Correlations(),type = 1,
               max_pvalue = 0.05,
               top=50,
               contains =Parameter())
  },height = 1000)
  
}