#' Count Movies by Field (by Actor, by Genre, by Year, etc.)
#'
#' This function counts movies by category: genre, year, actors, director,
#' writer, language or country.
#'
#' @param count_by The field to count movies by.
#' @param path The folder containing YAML files (or the root project).
#'
#' @return A 2-columns data frame.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' count_movies()
#' count_movies(count_by = "genre")
#' count_movies(count_by = "actors")
#' }


count_movies <- function(count_by = NULL, path = ".") {


  categories <- c(
    "genre", "year", "actors", "director", "writer", "language", "country"
  )


  if (!is.null(count_by)) {

    count_by <- tolower(count_by)

    if (length(count_by) != 1) {
      stop("Argument 'count_by' must be of length 1.")
    }

    if (!is.character(count_by)) {
      stop("Argument 'count_by' must be a character.")
    }

    if (!(count_by %in% categories)) {
      stop(
        paste0(
          "Argument 'count_by' must be one of '",
          paste0(categories, collapse = "', '"), "'."
        )
      )
    }

    if (is.na(count_by)) {
      count_by <- NULL
    }
  }


  data <- read_details(path = path, print = FALSE)

  if (is.null(count_by)) {

    return(nrow(data))

  } else {

    data <- data.frame(table(unlist(data[ , count_by])))

    colnames(data) <- c(count_by, "n_movies")

    data <- data[order(data[ , "n_movies"], decreasing = TRUE), ]
    rownames(data) <- NULL

    return(data)
  }
}
