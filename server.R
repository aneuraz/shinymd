library(shiny)
library(stringr)
shinyServer(function(input, output) {
  
  base_folder <- getwd()
  relative_tmp_folder <- "tmp_folder/"
  full_tmp_folder <- paste0(base_folder,'/',relative_tmp_folder)
  tmp_rmd <- paste0(full_tmp_folder,'/torender.Rmd')
  
  preview_height <- '1200px'
  preview_width <- '700px'
  
  torender <- reactive({
    require(input$text)
    if (!is.null(input$biblio)) {
      add_biblio = str_interp('bibliography: ${biblio}', list(biblio = input$biblio$datapath ))
    } else {
      add_biblio = ''
    }
    
    header <- str_interp("---
title: '${title}'
author: '${author}'
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
    cat(input$text, file = tmp_rmd, append = T)
    
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
  
  
})


