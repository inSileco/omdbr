#' Retrieve the IMDb Identifier of a Movie
#'
#' This function tries to retrieve the IMDb identifier of a movie based on a its
#' title and using the OMDb API <http://www.omdbapi.com/>. User can also
#' specify the release year of the movie. See details below for further
#' informations.
#'
#' @param search A movie title to search for.
#' @param year (optional) The release year of the movie.
#' @param n_max Number of matches to returned (default is 10).
#' @param sleep Time interval between two API requests.
#' @param verbose A boolean. If `TRUE`, prints some informations.
#'
#' @return A data frame with:
#'   - title: the movie title
#'   - year: the year of release
#'   - imdbid: the IMDb ID of the movie
#'
#' @details
#' For better results, you should write the complete movie title with its exact
#' spelling. Results are sorted by their similarity with the search terms.
#'
#' If you don't find the movie you are looking for, you can visit the IMDb
#' website (<https://www.imdb.com>) and get this ID from the movie URL. It
#' is always in the form: tt9999999 (only numbers are specific to the movie; the
#' prefix 'tt' is a constant).
#'
#' For instance, in this URL: <https://www.imdb.com/title/tt5699154/>, the IMDb ID
#' is 'tt5699154'.
#'
#' For non-English movies, the English name might be different from the original
#' title. For example, the English title of the french movie "Le Sens de la
#' fête" (2017) is "C'est la vie!" (IMDb ID = tt5699154).
#'
#' Only movies are currently implemented.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' find_imdb_id(search = "solo a star wars story")
#'
#' find_imdb_id("Star Wars", year = 2018, n_max = 20)
#' }


find_imdb_id <- function(search, year = NULL, n_max = 10, sleep = 0.1,
                         verbose = TRUE) {

  if (missing(search)) {
    stop("Argument 'search' is required.")
  }

  if (is.null(search)) {
    stop("Argument 'search' cannot be NULL.")
  }

  if (length(search) != 1) {
    stop("Argument 'search' must be of length 1.")
  }

  if (!is.character(search)) {
    stop("Argument 'search' must be a character.")
  }

  if (!is.null(year)) {

    if (length(year) != 1) {
      stop("Argument 'year' must be of length 1.")
    }

    if (!sum(grep("[0-9]{4}$", year))) {
      stop("Invalid 'year' format.")
    }
  }

  if (!is.null(n_max)) {

    if (length(n_max) > 1) {
      stop("Argument 'n_max' must be of length 1 (or NULL).")
    }

    if (!is.numeric(n_max)) {
      stop("Argument 'n_max' must be a numeric (or NULL).")
    }

    n_max <- round(n_max)

    if (n_max <= 0) {
      stop("Argument 'n_max' must be positive (or NULL).")
    }
  }

  if (is.null(sleep)) {
    stop("Argument 'sleep' cannot be NULL.")
  }

  if (length(sleep) != 1) {
    stop("Argument 'sleep' must be of length 1.")
  }

  if (!is.numeric(sleep)) {
    stop("Argument 'sleep' must be a numeric.")
  }

  if (sleep < 0) {
    stop("Argument 'sleep' must be positive (or zero).")
  }

  if (!is.logical(verbose)) {
    stop("Argument 'verbose' must be a boolean.")
  }


  if (verbose) {
    cli::cat_rule()
    usethis::ui_info(
      paste(
        "Searching", usethis::ui_value(search), "in movies title..."
      )
    )
  }

  search <- rm_punctuation(search, separator = " ")

  page  <- 1
  infos <- data.frame()

  while (nrow(infos) < n_max) {

    request <- omdb_full_url(
      "?apikey=", omdb_get_token(),
      "&s=", search,
      "&type=movie",
      "&r=json",
      "&page=", page
    )

    if (!is.null(year)) {
      request <- paste0(request, "&y=", year)
    }

    request  <- encode_url(request)

    response <- send_request(request)
    content  <- parse_response(response, api = "omdb")
    names(content) <- tolower(names(content))

    if (content$response == "False") {

      if (verbose) {
        usethis::ui_oops("No movie title matches the request.")
      }
      break
    }

    n_results <- as.numeric(content$totalresults)

    if (n_results == 0) {

      if (verbose) {
        usethis::ui_oops("No movie title matches the request.")
      }
      break
    }

    titles <- content$search$Title
    titles <- rm_punctuation(titles, lower_case = TRUE)
    titles <- unlist(
      lapply(
        strsplit(titles, "-"),
        function(x) paste0(sort(x), collapse = "")
      )
    )

    title <- rm_punctuation(search, lower_case = TRUE)
    title <- unlist(
      lapply(
        strsplit(title, "-"),
        function(x) paste0(sort(x), collapse = "")
      )
    )

    similarity <- stringdist::stringdistmatrix(titles, title, method = "lv")

    infos <- rbind(
      infos,
      data.frame(
        content$search[ , c("Title", "Year", "imdbID")],
        similarity
      )
    )

    if (nrow(infos) == n_results) {
      break
    }

    page <- page + 1
    Sys.sleep(sleep)

  }

  if (nrow(infos)) {

    if (verbose) {

      if (n_results > 1) {

        usethis::ui_done(
          paste(
            usethis::ui_value(n_results),
            "matches found!"
          )
        )

      } else {

        usethis::ui_done(
          paste(
            usethis::ui_value(n_results),
            "match found!"
          )
        )
      }
    }

    colnames(infos) <- tolower(colnames(infos))

    infos <- infos[order(infos[ , "similarity"]), -ncol(infos)]

    if (n_max < nrow(infos)) {

      infos <- infos[1:n_max, ]
    }

    rownames(infos) <- NULL

    if (verbose) {

        if (nrow(infos) > 1) {

        usethis::ui_line(
          paste(
            "  Returning the",
            usethis::ui_value(nrow(infos)),
            "best matches"
          )
        )

      } else {

        usethis::ui_line(paste("  Returning the best match"))
      }
    }
  }

  if (verbose) {
    cli::cat_rule()
  }

  infos
}
