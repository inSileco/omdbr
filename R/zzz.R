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


get_torrent <- function(imdb_id, path = ".") {

  if (missing(imdb_id)) {
    stop("Argument 'imdb_id' is required.")
  }

  if (is.null(imdb_id)) {
    stop("Argument 'imdb_id' cannot be NULL.")
  }

  if (length(imdb_id) != 1) {
    stop("Argument 'imdb_id' must be a character of length 1.")
  }

  if (!is.character(imdb_id)) {
    stop("Argument 'imdb_id' must be a character of length 1.")
  }

  if (!sum(grep("^tt[0-9]{7}$", imdb_id))) {
    stop("Invalid 'imdb_id' format.")
  }

  if (!dir.exists(path)) {
    stop(paste("Directory <", path, "> does not exist."))
  }

  dir.create(file.path(path, "torrents"), showWarnings = FALSE)

  request  <- yts_full_url(
    "list_movies.json",
    "?query_term=",
    imdb_id
  )


  ## YTS API Communication ----

  response <- send_request(request)

  content  <- parse_response(response, api = "yts")


  ## Download Movie Cover ----

  attempt <- NULL

  if (length(content)) {

    torrents <- content$data$movies$torrents
    torrents <- do.call(rbind.data.frame, torrents)
    rownames(torrents) <- NULL

    if (nrow(torrents)) {

      print(torrents[ , c("quality", "type", "seeds", "peers", "size")])

      number <- readline("\n  Which one would you like? ")

      if (number %in% (1:nrow(torrents))) {

        torrent <- torrents[number, ]
        usethis::ui_info(
          paste(
            "You have selected:",
            usethis::ui_value(
              paste0(torrent[1, "quality"], " (", torrent[1, "type"], ")")
            ),
            "with",
            usethis::ui_value(torrent[1, "seeds"]), "(seeds)",
            "and",
            usethis::ui_value(torrent[1, "peers"]), "(peers)",
            "for a total size of",
            usethis::ui_value(torrent[1, "size"])
          )
        )

        attempt <- tryCatch({
          utils::download.file(
            url      = torrent$"url",
            destfile = file.path(path, "torrents", paste0(imdb_id, ".torrent")),
            quiet    = TRUE
          )},
          error = function(e){}
        )

        if (is.null(attempt)) {

          usethis::ui_oops("Unable to download the torrent file.")

        } else {

          usethis::ui_done(
            paste(
              "Torrent file has been successfully stored in",
              usethis::ui_value(
                file.path(path, "torrents", paste0(imdb_id, ".torrent"))
              )
            )
          )
        }

      } else {

        torrent <- data.frame()
        usethis::ui_info("No torrent selected.")
      }

    } else {

      usethis::ui_oops(
        paste(
          "No torrent found for",
          usethis::ui_value(imdb_id)
        )
      )
    }

  } else {

    usethis::ui_oops(
      paste(
        "No torrent found for",
        usethis::ui_value(imdb_id)
      )
    )
  }
}


yml_to_list <- function(filename) {

  data <- yaml::read_yaml(filename)
  data <- jsonlite::toJSON(data)
  data <- jsonlite::fromJSON(data)

  as.data.frame(data, stringsAsFactors = FALSE)
}


find_pattern <- function(data, pattern, field) {

  search <- pattern

  search_in <- unlist(
    lapply(
      data[ , field],
      function(x) paste0(x, collapse = " ")
    )
  )

  search_in <- gsub("[[:punct:]]", "", tolower(search_in))
  pattern   <- gsub("[[:punct:]]", "", tolower(pattern))

  pattern <- paste0(pattern, collapse = "|")

  selected <- data[grep(pattern, search_in), ]

  if (!nrow(selected)) {

    selected <- data.frame()

    usethis::ui_oops(
      paste(
        "No match for",
        usethis::ui_value(search),
        "in",
        usethis::ui_field(field)
      )
    )

  }

  selected
}
