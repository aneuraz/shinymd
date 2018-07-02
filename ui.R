
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

preview_height <- '1200px'
preview_width <- '700px'

shinyUI(fluidPage(
  fluidRow(
    column(
      width = 2,
      textInput('title',
                label = 'Title',
                value = "Your title"),
      textInput('authors',
                label = 'Authors',
                value = "me"),
      selectInput(choices=list('HTML'='html', 'PDF'='pdf'),inputId = 'out_format', label= 'Output format'),
      fileInput('biblio', label='Bibtex file')
      
    ),
    column(
      width = 5,
      textAreaInput(
        label='',
        inputId = "text",
        width = preview_width,
        height= preview_height
      )
    ),
    column(
      width = 5,
      htmlOutput('preview',
                 width = preview_width,
                 height= preview_height)
    )
  )
))
