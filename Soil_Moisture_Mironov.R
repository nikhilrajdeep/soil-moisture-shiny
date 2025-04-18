library(shiny)
library(readxl)
library(dplyr)
library(ggplot2)
library(Metrics)
library(shinythemes)

# Mironov constants
nd <- 1.506
nb <- 6.591
nu <- 10.428
wt <- 0.205

calculate_W <- function(epsilon, nd, nb, nu, wt) {
  (nd - sqrt(epsilon) + wt * (nb - nu)) / (1 - nu)
}

ui <- fluidPage(
  theme = shinytheme("cerulean"),
  titlePanel("Soil Moisture Estimation app"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload permittivity data (.xlsx)", 
                accept = c(".xlsx")),
      uiOutput("dataSummary"),
      hr(),
      
      selectInput("angle", "Incidence angle (°):",
                  choices = c("30", "40", "50")),
      
      checkboxInput("applyModel", "Apply Mironov Soil‑Moisture Model", FALSE),
      hr(),
      
      uiOutput("varSelect"),
      width = 3
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Scatter Plot", plotOutput("scatterPlot", height = "500px")),
        tabPanel("Time Series", plotOutput("timeSeries", height = "500px"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  # 1. Read and summarize
  rawData <- reactive({
    req(input$file)
    df <- read_excel(input$file$datapath, sheet = 1) %>% na.omit()
    df$Date <- as.Date(df$TIMESTAMP)
    df
  })
  
  output$dataSummary <- renderUI({
    req(rawData())
    df <- rawData()
    tagList(
      p(strong("Rows:"), nrow(df)),
      p(strong("Columns:"), ncol(df)),
      verbatimTextOutput("colNames")
    )
  })
  output$colNames <- renderPrint({ names(rawData()) })
  
  # 2. Split by angle
  filtered <- reactive({
    df <- rawData()
    switch(input$angle,
           "30" = df %>% filter(Date >= as.Date("2023-06-22") & Date <= as.Date("2023-07-12")),
           "40" = df %>% filter(Date >= as.Date("2023-07-13") & Date <= as.Date("2023-08-03")),
           "50" = df %>% filter(Date >  as.Date("2023-08-03"))
    )
  })
  
  # 3–4. Apply model if checked
  modeled <- reactive({
    df <- filtered()
    if (input$applyModel) {
      df %>%
        mutate(
          W_5cm_H  = calculate_W(Epsilon_H_5cm,  nd, nb, nu, wt)*100,
          W_10cm_H = calculate_W(Epsilon_H_10cm, nd, nb, nu, wt)*100,
          W_30cm_H = calculate_W(Epsilon_H_30cm, nd, nb, nu, wt)*100,
          W_5cm_V  = calculate_W(Epsilon_V_5cm,  nd, nb, nu, wt)*100,
          W_10cm_V = calculate_W(Epsilon_V_10cm, nd, nb, nu, wt)*100,
          W_30cm_V = calculate_W(Epsilon_V_30cm, nd, nb, nu, wt)*100
        )
    } else df
  })
  
  # 5. Let user pick observed vs. predicted
  output$varSelect <- renderUI({
    req(modeled())
    vars <- names(modeled())
    tagList(
      selectInput("obsVar", "Observed:", 
                  choices = vars, selected = "VWC_5cm"),
      selectInput("predVar", "Predicted:", 
                  choices = vars, selected = "W_5cm_H")
    )
  })
  
  # Metrics function
  compute_metrics <- function(obs, pred) {
    rmse_val  <- rmse(obs, pred)
    bias_val  <- mean(pred - obs)
    r2_val    <- cor(obs, pred)^2
    ubrmse_val<- sqrt(rmse_val^2 - bias_val^2)
    list(rmse=rmse_val, bias=bias_val, r2=r2_val, ubrmse=ubrmse_val)
  }
  
  # 6a. Scatter plot
  output$scatterPlot <- renderPlot({
    req(input$applyModel, input$obsVar, input$predVar)
    df <- modeled()
    obs <- df[[input$obsVar]]
    pred<- df[[input$predVar]]
    mets<- compute_metrics(obs, pred)
    
    ggplot(df, aes(x=obs, y=pred)) +
      geom_point(alpha=0.6) +
      geom_abline(slope=1, intercept=0, linetype="dashed") +
      annotate("text", x=Inf, y= -Inf, hjust=1.1, vjust=-0.5,
               label=sprintf("RMSE: %.2f\nBias: %.2f\nR²: %.2f\nubRMSE: %.2f",
                             mets$rmse, mets$bias, mets$r2, mets$ubrmse)) +
      labs(x=input$obsVar, y=input$predVar,
           title=paste("Scatter:", input$obsVar, "vs", input$predVar)) +
      theme_minimal(base_size = 16)
  })
  
  # 6b. Time series line plot
  output$timeSeries <- renderPlot({
    req(input$applyModel, input$obsVar, input$predVar)
    df <- modeled()
    # derive depth for title
    depth <- sub("VWC_|W_|_.*", "", input$obsVar)
    
    ggplot(df, aes(x=TIMESTAMP)) +
      geom_line(aes_string(y=input$obsVar, color=shQuote("Observed"))) +
      geom_line(aes_string(y=input$predVar, color=shQuote("Predicted"))) +
      scale_color_manual(values=c("Observed"="black","Predicted"="red")) +
      labs(title=paste0(depth, " cm Depth"),
           x=NULL, y="Volumetric Water Content", color=NULL) +
      coord_cartesian(ylim=c(10,50)) +
      theme_minimal(base_size = 16) +
      theme(legend.position="bottom")
  })
}

shinyApp(ui, server)
