#' @importFrom usethis ui_info ui_done ui_value ui_code
#' @importFrom httr GET status_code content stop_for_status
#' @importFrom utils URLencode
#' @importFrom jsonlite fromJSON
#' @importFrom yaml read_yaml


## URLs Handlers Functions ----

yts_base_url <- function() {

  "https://yts.mx/api/v2/"
}

omdb_base_url <- function() {

  "http://www.omdbapi.com/"
}

yts_full_url <- function(...) {

  paste0(yts_base_url(), ...)
}

omdb_full_url <- function(...) {

  paste0(omdb_base_url(), ...)
}


## Retrieve OMDb API Key ----

omdb_get_token <- function() {

  token <- Sys.getenv("OMDb_KEY")

  if (identical(token, "")) {

    usethis::ui_info(
      paste(
        usethis::ui_value("OMDb_KEY"),
        "environment variable has not been set yet.",
        "\n ",
        "A token is required to use the OMDb API, see",
        "<http://www.omdbapi.com/>"
      )
    )

    omdb_set_token()
    token <- omdb_get_token()
  }

  omdb_check_token(token)

  return(token)
}


## Store OMDb API Key (session only) ----

omdb_set_token <- function() {

  token <- readline("\n  Enter your token without quotes: ")

  if (identical(token, "")) {

    stop("No token has been provided.")

  } else {

    Sys.setenv(OMDb_KEY = token)

    omdb_check_token(token)

    cat("\n")
    usethis::ui_done(
      paste(
        usethis::ui_value("OMDb_KEY"),
        "has been successfully stored for this session."
      )
    )

    cat("\n")
    usethis::ui_info(
      paste(
        "If you want to permanently store this API token, run:",
        "\n  ",
        usethis::ui_code("usethis::edit_r_environ()"),
        "\n  ",
        "and add this line:",
        usethis::ui_value("OMDb_KEY=xxxxx"),
        "(replace xxxxx by your API key)"
      )
    )
  }
}


## Test OMDb API Key Validity ----

omdb_check_token <- function(token) {

  request  <- omdb_full_url("?apikey=", token, "&i=tt0111161")
  response <- httr::GET(request)

  if (httr::status_code(response) != 200) {
    stop("Unauthorized (HTTP 401): invalid OMDb API Key")
  }
}


## API Requests/Parser ----

send_request <- function(request) {

  response <- httr::GET(request)
  httr::stop_for_status(response)

  return(response)
}

parse_response <- function(response, api, search = "title") {

  response <- httr::content(response, as = "text")
  content  <- jsonlite::fromJSON(response)

  if (api == "omdb") {
    if (content$Response == "False" && search != "title") {
      stop("IMDb ID not found.")
    }
  }

  if (api == "yts") {

    if (content$data$movie_count == 0) {

      content <- list()
    }
  }

  return(content)
}


## Strings Functions ----

encode_url <- function(x) {

  utils::URLencode(x)
}

rm_multispaces <- function(x) {

  x <- as.character(x)
  x <- gsub("\\s+", " ", x)
  gsub("^\\s|\\s$", "", x)
}

rm_punctuation <- function(x, separator = "-", lower_case = FALSE,
                          upper_case = FALSE) {

  x <- as.character(x)

  if (lower_case) {
    x <- tolower(x)
  }

  if (upper_case) {
    x <- toupper(x)
  }

  x <- gsub("[[:punct:]]", " ", x)
  x <- rm_multispaces(x)

  gsub("\\s", separator, x)
}

rm_brackets <- function(x) {

  x <- as.character(x)
  x <- unlist(
    lapply(
      strsplit(x, ", ")[[1]],
      function(x) {
        x <- gsub("\\(.+\\)", "", x)
        rm_multispaces(x)
      }
    )
  )

  paste0(x, collapse = ", ")
}


yml_to_list <- function(filename) {

  data <- yaml::read_yaml(filename)
  data <- jsonlite::toJSON(data)
  data <- jsonlite::fromJSON(data)

  as.data.frame(data, stringsAsFactors = FALSE)
}
