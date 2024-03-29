
<!-- README.md is generated from README.Rmd. Please edit that file -->

# omdbr <img src="man/figures/logo.png" height="170px" align="right" style="float:right; height:170px;"/>

<!-- badges: start -->

[![R build
status](https://github.com/inSileco/omdbr/workflows/R-CMD-check/badge.svg)](https://github.com/inSileco/omdbr/actions)
[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/omdbr)](https://cran.r-project.org/package=omdbr)
[![License: GPL
v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![r-universe](https://insileco.r-universe.dev/badges/omdbr)](https://insileco.r-universe.dev/ui#builds)
<!-- badges: end -->

The package `omdbr` is an R client to the [OMDb
API](http://www.omdbapi.com). User can retrieve information on movies
(title, actors, year, genres, etc.) and download cover (if available)
using the [YTS API](https://yts.mx/api/v2/).

## Prerequisites

This package uses the [OMDb API](http://www.omdbapi.com) which requires
an **API Key**. You can freely obtain your own
[here](http://www.omdbapi.com/apikey.aspx). When you’ll use the package
`omdbr` for the first time, you’ll be guided on how to store your
personal API key.

## Installation

To install the `omdbr` package, run the following command:

``` r
remotes::install_github("inSileco/omdbr")
```

and load the package:

``` r
library(omdbr)
```

<br />

<p align="center">
<img src="man/figures/tt0128445.jpg" width="12.5%" /><img src="man/figures/tt0265666.jpg" width="12.5%" /><img src="man/figures/tt0362270.jpg" width="12.5%" /><img src="man/figures/tt0838221.jpg" width="12.5%" /><img src="man/figures/tt0432283.jpg" width="12.5%" /><img src="man/figures/tt1748122.jpg" width="12.5%" /><img src="man/figures/tt2278388.jpg" width="12.5%" /><img src="man/figures/tt5104604.jpg" width="12.5%" />
</p>

## Example

> **Objective**: Getting information and cover for [*The Darjeeling
> Limited*](https://imdb.com/title/tt0838221) movie directed by [Wes
> Anderson](https://en.wikipedia.org/wiki/Wes_Anderson).

**STEP 1**: Find the IMDb identifier of the movie

The package `omdbr` uses the IMDb ID the retrieves information and cover
of a movie. The function `find_imdb_id()` tries to find this ID.

``` r
x <- find_imdb_id("The Darjeeling Limited")
## ────────────────────────────────────────────────────────────────────────────────
## ℹ Searching 'The Darjeeling Limited' in movies title...
## ✔ 2 matches found!
##   Returning the 2 best matches
## ────────────────────────────────────────────────────────────────────────────────
```

``` r
str(x)
## 'data.frame':    2 obs. of  3 variables:
##  $ title : chr  "The Darjeeling Limited" "The Darjeeling Limited (2007)"
##  $ year  : chr  "2007" "2007"
##  $ imdbid: chr  "tt0838221" "tt24819872"
```

    ##                           title year     imdbid
    ## 1        The Darjeeling Limited 2007  tt0838221
    ## 2 The Darjeeling Limited (2007) 2007 tt24819872

:bulb: The argument `year` can be used to reduce results.

:bulb: You can also find this ID by searching the movie title on the
[IMDb website](https://imdb.com) and extract it from the URL. The URL of
*The Darjeeling Limited* is: <https://imdb.com/title/tt0838221>.

**STEP 2**: Get movie information

To retrieve information about the movie we will use the function
`get_details()`:

``` r
x <- get_details(imdb_id = "tt0838221")
```

    ## ────────────────────────────────────────────────────────────────────────────────
    ## 
    ## - imdbid: tt0838221
    ##   type: movie
    ##   title: The Darjeeling Limited
    ##   year: 2007.0
    ##   runtime: 91.0
    ##   director: Wes Anderson
    ##   writer:
    ##     - Wes Anderson
    ##     - Roman Coppola
    ##     - Jason Schwartzman
    ##   actors:
    ##     - Owen Wilson
    ##     - Adrien Brody
    ##     - Jason Schwartzman
    ##   genre:
    ##     - Adventure
    ##     - Comedy
    ##     - Drama
    ##   plot: A year after their father's funeral, three brothers travel across India by train
    ##     in an attempt to bond with each other.
    ##   language:
    ##     - English
    ##     - Hindi
    ##     - German
    ##     - Punjabi
    ##     - Tibetan
    ##     - French
    ##   country:
    ##     - United States
    ##     - India
    ##   imdbrating: 7.2
    ##   slug: the-darjeeling-limited-2007
    ## 
    ## ────────────────────────────────────────────────────────────────────────────────

``` r
class(x)
## [1] "data.frame"
```

    ##      imdbid  type                  title year runtime     director
    ## 1 tt0838221 movie The Darjeeling Limited 2007      91 Wes Anderson
    ##                                           writer
    ## 1 Wes Anderson, Roman Coppola, Jason Schwartzman
    ##                                         actors                    genre
    ## 1 Owen Wilson, Adrien Brody, Jason Schwartzman Adventure, Comedy, Drama
    ##                                                                                                                      plot
    ## 1 A year after their father's funeral, three brothers travel across India by train in an attempt to bond with each other.
    ##                                           language              country
    ## 1 English, Hindi, German, Punjabi, Tibetan, French United States, India
    ##   imdbrating                        slug
    ## 1        7.2 the-darjeeling-limited-2007

:bulb: Results are stored in `data/tt0838221.yml` (path can be changed
by using the argument `path`).

If you want to get access to these data you can use the function
`read_details()`:

``` r
x <- read_details(imdb_id = "tt0838221")
```

    ##      imdbid  type                  title year runtime     director
    ## 1 tt0838221 movie The Darjeeling Limited 2007      91 Wes Anderson
    ## 2 tt0838221 movie The Darjeeling Limited 2007      91 Wes Anderson
    ##                                           writer
    ## 1 Wes Anderson, Roman Coppola, Jason Schwartzman
    ## 2 Wes Anderson, Roman Coppola, Jason Schwartzman
    ##                                                      actors
    ## 1 Owen Wilson, Adrien Brody, Jason Schwartzman, Amara Karan
    ## 2              Owen Wilson, Adrien Brody, Jason Schwartzman
    ##                      genre
    ## 1 Adventure, Comedy, Drama
    ## 2 Adventure, Comedy, Drama
    ##                                                                                                                      plot
    ## 1 A year after their father's funeral, three brothers travel across India by train in an attempt to bond with each other.
    ## 2 A year after their father's funeral, three brothers travel across India by train in an attempt to bond with each other.
    ##                                           language              country
    ## 1 English, Hindi, German, Punjabi, Tibetan, French                  USA
    ## 2 English, Hindi, German, Punjabi, Tibetan, French United States, India
    ##   imdbrating                        slug
    ## 1        7.2 the-darjeeling-limited-2007
    ## 2        7.2 the-darjeeling-limited-2007

**STEP 3**: Get movie cover

Now, we can try to download the movie cover with the function
`get_cover()`:

``` r
get_cover(imdb_id = "tt0838221")
```

    ## ✔ Cover found for 'tt0838221' !

<p align="center">
<img src="man/figures/tt0838221.jpg" width="50%" />
</p>

:bulb: Results are stored as follow:

``` r
.
├── covers
│   └──tt0838221.jpg
└── data
    └──tt0838221.yml

2 directories, 2 files
```

## Code of Conduct

Please note that the `omdbr` project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
