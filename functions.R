get_documents <- function(query, cn, config) {
  res <-r(config$rdb_name, config$rdb_table)$filter(query)$run(cn$raw_connection)
  cursor_to_tibble(res, character())
}