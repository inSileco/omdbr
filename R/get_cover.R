#' Retrieve Cover/Poster of a Movie
#'
#' This function retrieves movie cover using the YTS API
#' \url{https://yts.mx/api}. No API key is required but not all movies listed in
#' the IMDb/OMDb databases are available on YTS \url{https://yts.mx}.
#'
#' @param imdb_id The IMDb ID of the movie.
#' @param path The folder to save cover.
#'
#' @importFrom utils download.file
#' @importFrom usethis ui_done ui_oops ui_value
#'
#' @export
#'
#' @examples
#' \dontrun{
#' get_cover(imdb_id = "tt0120863", path = ".")
#' }


get_cover <- function(imdb_id, path = ".") {

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

  dir.create(file.path(path, "covers"), showWarnings = FALSE)

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

    image_url <- content$data$movies$large_cover_image

    if (!is.null(image_url)) {

      attempt <- tryCatch({
        utils::download.file(
          url      = image_url,
          destfile = file.path(path, "covers", paste0(imdb_id, ".jpg")),
          quiet    = TRUE
        )},
        error = function(e){}
      )

    }
  }

  if (is.null(attempt)) {

    usethis::ui_oops(
      paste(
        "No cover found for",
        usethis::ui_value(imdb_id)
      )
    )

  } else {

    usethis::ui_done(
      paste(
        "Cover found for",
        usethis::ui_value(imdb_id),
        "!"
      )
    )
  }
}
