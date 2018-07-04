library(shiny)
library(stringr)
library(shinyAce) # devtools::install_github("aneuraz/shinyAce")
library(rethinker)
library(shiny.collections)

config <- new.env()

config$rdb_port = '28015'
config$rdb_name = "my_db"
config$rdb_table = "in_db"
config$preview_height <- '800px'
config$preview_width <- '100%'
config$base_folder <- getwd()
config$relative_tmp_folder <- "tmp_folder/"

debug <- FALSE
user = 'antoine'
#doc_id = "0005"
doc_name = 'my_name'

default_yaml <- "---
title: New project
author: me
---"

connection <- shiny.collections::connect(port = config$rdb_port, db_name=config$rdb_name)

shinyServer(function(input, output, session) {
  
  # define temp folders
  full_tmp_folder <- paste0(config$base_folder,'/',config$relative_tmp_folder)
  tmp_rmd <- reactive({paste0(full_tmp_folder,'/',input$doc_id,'.Rmd')})
  
  # define session vars
  sessionVar = reactiveValues()
  observe({sessionVar$active <- input$doc_id})
  
  # get documents from db for a user 
  in_db <- shiny.collections::collection(rdb_table, connection, 
                                         post_process = function(q) q$filter(list(user=user)))
  
  # New document
  observeEvent(input$new_doc, {
    new_id <- as.character(max(as.numeric(in_db$collection$id),na.rm = T)+1)
    if (is.na (new_id)) new_id <- 1
    insert(in_db, list(
      id= new_id,
      value=default_yaml,
      user = user
    ),
    conflict="update")
    
    sessionVar$active <- new_id
    
  })
  
  # generate md file to render 
  torender <- reactive({
    req(input$rmd)
    input$doc_id
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
    cat(header, file = tmp_rmd())
    cat('\n\n', file = tmp_rmd(), append = T)
    cat( in_db$collection$value[in_db$collection$id == input$doc_id], file = tmp_rmd(), append = T)
    
    return(tmp_rmd())
  })
  
  # update db when the input changes in the editor
  observeEvent(input$rmd, {
    if (input$rmd != "") {
      shiny.collections::insert(in_db, list(id = input$doc_id, value =input$rmd),  conflict="update")
    }
  })
  
  # update editor when change is detected in the db or input$doc_id changes 
   observeEvent({in_db$collection$value
                  input$doc_id}, {
                    
     req(input$doc_id)
     updateAceEditor(session,"rmd", value = in_db$collection$value[in_db$collection$id == input$doc_id])
   })
   
   
   # UI 
   output$doc_list <- renderUI({
     selectInput('doc_id', label="document list", choices = in_db$collection$id, selected = sessionVar$active)
   })
   
   
   
   output$preview <- renderUI({
     
     if(!file.exists(full_tmp_folder))
       dir.create(full_tmp_folder)
     
     temp_file <- str_interp("output.${input$out_format}")
     rmarkdown::render(input=torender(), output_file = paste0(full_tmp_folder,temp_file ))
     print(paste0(config$relative_tmp_folder,temp_file ))
     addResourcePath('tmp_folder', config$relative_tmp_folder)
     tags$iframe(src=paste0(config$relative_tmp_folder,temp_file ),  width = config$preview_width,
                 height= config$preview_height)
     
   })
   
   
   # Debug outputs 
   if (debug) {
     output$in_db_data <- renderTable({
       req(input$doc_id)
       in_db$collection$value[in_db$collection$id == input$doc_id]
     })
     
     output$active <- renderText(paste(input$doc_id))
     
   }
   
   
   
})


