#' Read Metadata of Movie(s)
#'
#' This function reads YAML files with movie(s) metadata stored by the function
#' `get_details()`
#'
#' @param path The folder containing YAML files (or the root project).
#' @param imdb_id (optional) The IMDb ID(s) of the movie(s).
#' @param print A boolean. If TRUE (default), movie informations are printed (if
#'   one single IMDb ID is required).
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
#' @export
#'
#' @examples
#' \dontrun{
#' x <- read_details()
#' x <- read_details(imdb_id = "tt2278388", print = TRUE)
#' x <- read_details(imdb_id = c("tt2278388", "tt0362270"))
#' }


read_details <- function(path = ".", imdb_id = NULL, print = TRUE) {

  if (!dir.exists(path)) {
    stop(paste("Directory <", path, "> does not exist."))
  }

  filenames <- list.files(
    path       = path,
    pattern    = ".yml$",
    recursive  = TRUE,
    full.names = TRUE
  )

  if (!length(filenames)) {
    stop(paste("No YAML files found in <", path, ">."))
  }

  if (!is.logical(print)) {
    stop("Argument 'print' must be a boolean.")
  }

  if (!is.null(imdb_id)) {

    if (!is.character(imdb_id)) {
      stop("Argument 'imdb_id' must be a character.")
    }

    if (length(grep("^tt[0-9]{7,}$", imdb_id)) != length(imdb_id)) {
      stop("Invalid 'imdb_id' format.")
    }

    imdb_ids <- unlist(
      lapply(
        strsplit(filenames, paste0(.Platform$file.sep, "|\\.yml")),
        function(x) x[length(x)]
      )
    )

    if(sum(imdb_id %in% imdb_ids) != length(imdb_id)) {
      stop(paste("At least one 'imdb_id' is missing in <", path, ">."))
    }

    filenames <- filenames[which(imdb_ids %in% imdb_id)]
  }

  if (length(filenames) > 1) {
    print <- FALSE
  }

  if (print) {
    to_print <- yaml::read_yaml(filenames)
    to_print <- yaml::as.yaml(to_print)
    to_print <- gsub("\\\n  -", "\n    -", to_print)

    cli::cat_rule()
    cli::cat_line()
    cli::cat_line(to_print)
    cli::cat_rule()
  }

  details <- lapply(filenames, yml_to_list)

  do.call(rbind.data.frame, details)
}
