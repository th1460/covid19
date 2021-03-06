require(bslib)
require(shiny)
require(magrittr)
require(thematic)

drv <-
  RJDBC::JDBC("com.ibm.db2.jcc.DB2Driver", "jars/db2jcc4.jar")

db2 <-
  DBI::dbConnect(drv,
                 Sys.getenv("DB2_HOST"),
                 user = Sys.getenv("DB2_USER"),
                 password = Sys.getenv("DB2_PASSWORD"))

# theme
theme <- bs_theme(
  bg = "#0b3d91", fg = "white", primary = "#FCC780",
  base_font = font_google("Space Mono"),
  code_font = font_google("Space Mono")
)

thematic_on(
  bg = "auto", 
  fg = "auto", 
  accent = "auto", 
  font = "auto"
)

# ui
ui <- fluidPage(
  navbarPage("Covid 19"),
  theme = theme,
  sidebarLayout(
    sidebarPanel(
      selectizeInput("country", "País:",
                     dplyr::tbl(db2, "AVG_SA_COVID19") %>% 
                       dplyr::distinct(COUNTRY) %>% 
                       dplyr::pull()),
      dateInput("data", "Data")
      
    ),
    
    mainPanel(
      uiOutput("summarybox"),
      tabsetPanel(id = "panel",
                  tabPanel("Plot", 
                           tags$h4("Distribuição do número médio de mortes"),
                           plotOutput("delta_plot")),
                  tabPanel("Mapa", 
                           tags$h4("Variação % comparando semana anterior"),
                           leaflet::leafletOutput("mapa")))
    )
  )
)

# server
server <- function(input, output) {
  
  output$delta_plot <- renderPlot({
    
    data_avg <- dplyr::tbl(db2, "AVG_SA_COVID19") %>% 
      dplyr::as_tibble()
    
    last <- 
      data_avg %>% 
      dplyr::filter(COUNTRY == input$country,
                    WEEK == lubridate::week(input$data), 
                    YEAR == lubridate::year(input$data)) %>% 
      dplyr::select(YEAR, WEEK, AVG_VALUE)
    
    data_avg %>% 
      dplyr::filter(COUNTRY == input$country) %>% 
      ggplot2::ggplot(ggplot2::aes(WEEK, AVG_VALUE)) + 
      ggplot2::geom_line() +
      ggplot2::labs(x = "Semanas", y = "Número médio de mortes") +
      ggplot2::geom_label(data = last, ggplot2::aes(WEEK, AVG_VALUE, label = round(AVG_VALUE, 0))) +
      ggplot2::facet_grid(~YEAR)
    
  })
  
  delta_avg_sa <- reactive({
    
    dplyr::tbl(db2, "AVG_SA_COVID19") %>% 
      dplyr::as_tibble() %>% 
      dplyr::filter(WEEK == lubridate::week(input$data), YEAR == lubridate::year(input$data))
    
  })
  
  
  output$mapa <- leaflet::renderLeaflet({
    
    conpal <- 
      leaflet::colorNumeric(palette = "Reds", 
                            domain = delta_avg_sa()$DELTA, 
                            na.color = "black")
    
    delta_avg_sa() %>% 
      leaflet::leaflet() %>% 
      leaflet::addProviderTiles("CartoDB.DarkMatter") %>% 
      leaflet::addCircleMarkers(~LONG, ~LAT, 
                                label = paste(delta_avg_sa()$COUNTRY, "|", 
                                              round(delta_avg_sa()$DELTA, 1)), 
                                color = ~conpal(delta_avg_sa()$DELTA)) %>% 
      leaflet::addLegend(position = "bottomleft", 
                         title = "Delta %",
                         pal = conpal, 
                         values = delta_avg_sa()$DELTA,
                         opacity = 0.5)
    
  })
  
  output$summarybox <- 
    renderUI({ 
      
      sa <- dplyr::tbl(db2, "SA_COVID19") %>% 
        dplyr::as_tibble() %>% 
        dplyr::filter(COUNTRY == input$country) %>% 
        dplyr::slice(dplyr::n())
        
      
      fluidRow(
        summaryBox::summaryBox("Última atualização", sa$DATE, width = 3, icon = "fas fa-calendar", style = "info"),
        summaryBox::summaryBox("Número de mortes no último dia", sa$VALUE, width = 3, icon = "fas fa-chart-bar", style = "warning"),
        summaryBox::summaryBox("Número total de mortes", sa$CUMULATE, width = 3, icon = "fas fa-chart-bar", style = "danger")
      )})
  
}

shinyApp(ui, server)


