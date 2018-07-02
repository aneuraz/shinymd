
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinyAce)

editor_height <- '800px'
editor_width <- '100%'

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
      aceEditor("rmd", mode="markdown", height = editor_height)
    ),
    column(
      width = 5,
      htmlOutput('preview',
                 width = editor_width,
                 height= editor_height)
    )
  )
))
