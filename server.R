library(shiny)
library(stringr)
library(shinyAce)
library(rethinker)
library(shiny.collections)

rdb_port = '28015'
rdb_name = "my_db"
rdb_table = "in_db"
doc_id = "projectA"
preview_height <- '800px'
preview_width <- '100%'
base_folder <- getwd()
relative_tmp_folder <- "tmp_folder/"

default_yaml <- "---
title: New project
author: me
---"

connection <- shiny.collections::connect(port = rdb_port, db_name=rdb_name)

shinyServer(function(input, output) {
  
  in_db <- shiny.collections::collection(rdb_table, connection)
  
  r(rdb_name,rdb_table)$insert(
    list(
      id=doc_id,
      value=default_yaml
    ),
    conflict="update"
  )$run(connection$raw_connection) -> ans
  
  full_tmp_folder <- paste0(base_folder,'/',relative_tmp_folder)
  tmp_rmd <- paste0(full_tmp_folder,'/',doc_id,'.Rmd')
  
  torender <- reactive({
    require(input$rmd)
    if (!is.null(input$biblio)) {
      add_biblio = str_interp('bibliography: ${biblio}', list(biblio = input$biblio$datapath ))
    } else {
      add_biblio = ''
    }
    
    header <- str_interp("---
output: ${out_format}_document
${add_biblio}
---
", list(title = input$title, 
        author = input$authors, 
        out_format = input$out_format,
        add_biblio = add_biblio)  
    )
    
    cat(header, file = tmp_rmd)
    cat('\n\n', file = tmp_rmd, append = T)
    cat( in_db$collection$value, file = tmp_rmd, append = T)
    
    return(tmp_rmd)
  })
  

  output$preview <- renderUI({
    
    if(!file.exists(full_tmp_folder))
      dir.create(full_tmp_folder)
    
    temp_file <- str_interp("output.${input$out_format}")
    rmarkdown::render(input=torender(), output_file = paste0(full_tmp_folder,temp_file ))
    print(paste0(relative_tmp_folder,temp_file ))
    addResourcePath('tmp_folder', relative_tmp_folder)
    tags$iframe(src=paste0(relative_tmp_folder,temp_file ),  width = preview_width,
                height= preview_height)
    
  })
  
  observeEvent(input$rmd, {

    bb <- shiny.collections::insert(in_db, list(id = doc_id, value =input$rmd),  conflict="update")
  })
  
  # output$in_db_data <- renderTable({
  #   in_db$collection$value
  # 
  # })
  
  output$aceSync <- renderUI(aceEditor("rmd", mode="markdown",height= preview_height, value = in_db$collection$value))
  
})


