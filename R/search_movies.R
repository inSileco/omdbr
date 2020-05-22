#' Search for Movies
#'
#' This function searches for movies for which details have been stored. User
#' can search in title, year, etc.
#'
#' @param title Terms to search for in title field.
#' @param year Year(s) to search for in year field.
#' @param genre Terms to search for in genres field.
#' @param director Name(s) to search for in director field.
#' @param writer Name(s) to search for in writer field.
#' @param actors Name(s) to search for in actors field.
#' @param country Country names to search for in country field.
#' @param language Language name(s) to search for in language field.
#' @param path The folder containing YAML files (or the root project).
#'
#' @return A data frame.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' search_movies(title = "Hotel")
#' search_movies(year = 2014:2016)
#' search_movies(actors = "Bill Murray")
#' }


search_movies <- function(title, year, genre, director, writer, actors, country,
                          language, path = ".") {

  if (!missing(year)) {
    if (length(grep("[0-9]{4}$", year)) != length(year)) {
      stop("Invalid 'year' format.")
    }
  }

  fields  <- c(
    "imdbid", "title", "year", "director", "writer", "actors", "genre",
    "language", "country"
  )

  details <- read_details(path = path, print = FALSE)

  data <- data.frame()


  if (!missing(title)) {

    selected <- find_pattern(details, pattern = title, field = "title")

    if (nrow(selected)) {
      data <- rbind(data, selected[ , fields])
    }
  }


  if (!missing(year)) {

    selected <- find_pattern(details, pattern = year, field = "year")

    if (nrow(selected)) {
      data <- rbind(data, selected[ , fields])
    }
  }


  if (!missing(genre)) {

    selected <- find_pattern(details, pattern = genre, field = "genre")

    if (nrow(selected)) {
      data <- rbind(data, selected[ , fields])
    }
  }


  if (!missing(director)) {

    selected <- find_pattern(details, pattern = director, field = "director")

    if (nrow(selected)) {
      data <- rbind(data, selected[ , fields])
    }
  }


  if (!missing(writer)) {

    selected <- find_pattern(details, pattern = writer, field = "writer")

    if (nrow(selected)) {
      data <- rbind(data, selected[ , fields])
    }
  }


  if (!missing(actors)) {

    selected <- find_pattern(details, pattern = actors, field = "actors")

    if (nrow(selected)) {
      data <- rbind(data, selected[ , fields])
    }
  }


  if (!missing(country)) {

    selected <- find_pattern(details, pattern = country, field = "country")

    if (nrow(selected)) {
      data <- rbind(data, selected[ , fields])
    }
  }


  if (!missing(language)) {

    selected <- find_pattern(details, pattern = language, field = "language")

    if (nrow(selected)) {
      data <- rbind(data, selected[ , fields])
    }
  }


  if (nrow(data)) {

    data <- data[!duplicated(data$"imdbid"), ]
    rownames(data) <- NULL

    usethis::ui_done(
      paste(
        "Found",
        usethis::ui_value(nrow(data)),
        "movies matching your query."
      )
    )
  }

  data
}
