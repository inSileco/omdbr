#' Retrieve Metadata of a Movie
#'
#' This function retrieves movie metadata (title, actors, year, genres, etc.)
#' using the OMDb API <http://www.omdbapi.com/>. Results are exported in a
#' YAML file and returned as a data frame. See details below for further
#' informations.
#'
#' @param imdb_id The IMDb ID of the movie.
#' @param path The folder to store results.
#' @param print A boolean. If TRUE (default), movie informations are printed.
#'
#' @return A data frame with:
#'   - imdbid: the IMDb ID of the movie
#'   - type: the category (e.g. movie)
#'   - title: the movie title
#'   - year: the year of release
#'   - runtime: the movie runtime (in minutes)
#'   - director: a vector of directors
#'   - writer: a vector of writers
#'   - actors: a vector of main actors
#'   - genre: a vector of genres
#'   - plot: a short plot of the movie
#'   - language: a vector of spoken languages
#'   - country: a vector of the countries
#'   - imdbrating: the IMDb rating (in date of the request)
#'   - slug: a unique identifier (titre + year)
#'
#' @details
#' An (free) API key is required to use the OMDb API. You can register on
#' <http://www.omdbapi.com/>. When using this package for the first time,
#' you'll be asked for setting your own API key (just follow instructions).
#'
#' The request is performed using the IMDb identifier of the movie. To find this
#' ID you can use the function `find_imdb_id()`.
#'
#' If you can't retrieve the IMDb ID, visit the IMDb website
#' (<https://www.imdb.com>) and get this ID from the movie URL. It is always
#' in the form: tt9999999 (only numbers are specific to the movie; the prefix
#' 'tt' is a constant).
#'
#' For instance, in this URL: <https://www.imdb.com/title/tt5699154/>, the IMDb ID
#' is 'tt5699154'.
#'
#' For non-English movies, the English name might be different from the original
#' title. For instance, the English title of the french movie "Le Sens de la
#' fête" (2017) is "C'est la vie!" (IMDb ID = tt5699154).
#'
#' Only movies are currently implemented.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' x <- get_details("tt0120863", path = ".", print = TRUE)
#' }


get_details <- function(imdb_id, path = "./details", print = TRUE) {

  if (missing(imdb_id)) {
    stop("Argument 'imdb_id' is required.")
  }

  if (is.null(imdb_id)) {
    stop("Argument 'imdb_id' cannot be NULL.")
  }

  if (length(imdb_id) != 1 | !is.character(imdb_id)) {
    stop("Argument 'imdb_id' must be a character of length 1.")
  }


  if (!sum(grep("^tt[0-9]{7,}$", imdb_id))) {
    stop("Invalid 'imdb_id' format.")
  }

  if (!is.logical(print)) {
    stop("Argument 'print' must be a boolean.")
  }

  if (!dir.exists(path)) dir.create(path, showWarnings = FALSE)

  request  <- omdb_full_url(
    "?apikey=", omdb_get_token(),
    "&i=", imdb_id
  )


  ## OMDb API communication ----

  response <- send_request(request)

  content  <- parse_response(response, api = "omdb")
  names(content) <- tolower(names(content))


  if (content$type != "movie") {
    stop("Only movie method is currently implemented.")
  }


  ## Select informations ----

  infos <- c(
    "imdbid", "type", "title", "year", "runtime", "director", "writer",
    "actors", "genre", "plot", "language", "country", "imdbrating"
  )
  content <- content[infos]


  ## Burst collapsed informations ----

  string_to_vector <- c(
    "director", "writer", "actors", "genre", "language", "country"
  )

  for (name in string_to_vector) {

    content[[name]] <- rm_brackets(content[[name]])
    content[[name]] <- strsplit(content[[name]], ", ")[[1]]
  }


  ## Clean other informations ----

  content$"title"      <- gsub("\"", "'", content$"title")
  content$"year"       <- as.numeric(content$"year")
  content$"runtime"    <- as.numeric(gsub(" min", "", content$"runtime"))
  content$"plot"       <- gsub("\"", "'", content$"plot")
  content$"imdbrating" <- as.numeric(content$"imdbrating")


  ## Create another key ----

  content$"slug" <- paste(
    rm_punctuation(content$"title", lower_case = TRUE),
    content$"year",
    sep = "-"
  )


  ## Export to YAML ----

  to_store <- yaml::as.yaml(content, indent.mapping.sequence = TRUE)
  to_store <- gsub("\\\n", "\n  ", to_store)
  to_store <- gsub("imdbid:", "- imdbid:", to_store)
  to_store <- gsub("\\\n  $", "\n", to_store)

  cat(to_store, file = file.path(path, paste0(imdb_id, ".yml")))


  ## Convert to data frame ----

  content <- yaml::yaml.load(to_store)
  content <- jsonlite::toJSON(content)
  content <- jsonlite::fromJSON(content)
  content <- as.data.frame(content, stringsAsFactors = FALSE)


  if (print) {

    cli::cat_rule()
    cli::cat_line()
    cli::cat_line(to_store)
    cli::cat_rule()
  }

  return(content)
}
