# Release Schedule

A small app using the Wikidata API to show upcoming movies.

You can try out the live web version at [daniel-michel.github.io/release_schedule](https://daniel-michel.github.io/release_schedule).

Android, Linux and Web builds can be found in the latest [CI run](https://github.com/daniel-michel/release_schedule/actions/workflows/ci.yml).

## Overview

There are two screens that show upcoming movies and bookmarked movies:

<img src="screenshots/upcoming.png" width="300">
<img src="screenshots/bookmarks.png" width="300">

The floating button at the bottom right of the upcoming movies list can be used to load new upcoming movies. The menu at the top right can be used to clear some or all of the cached movies.

The movies that are cached as well as other movies can be searched with the search field at the top:

<img src="screenshots/search.png" width="300">

## Wikidata API

The Implementation can be found at [./lib/api/wikidata_movie_api.dart](./lib/api/wikidata_movie_api.dart).

To get information about the upcoming movies multiple APIs are used.

First the SPARQL API is used to retrieve upcoming movies using the endpoint "https://query.wikidata.org/sparql" with the following query:

```sql
SELECT
  ?movie
  (MIN(?releaseDate) as ?minReleaseDate)
WHERE {
  ?movie wdt:P31 wd:Q18011172;
         p:P577/psv:P577 [wikibase:timePrecision ?precision];
         wdt:P577 ?releaseDate.
  FILTER (xsd:date(?releaseDate) >= xsd:date("$date"^^xsd:dateTime))
  FILTER (?precision >= 10)
}
GROUP BY ?movie
ORDER BY ?minReleaseDate
LIMIT $limit
```

Where `$limit` is the maximum number of movies that are retrieved and `$date` the starting date from which movies are retrieved.
`$limit` is currently set to 100 and `$date` one week before the current one.
However, because there are multiple publication dates for most movies, the retrieved movies just need to have one publication date that is on or after `$date` for the movie to be included in the result. The `minReleaseDate` is not necessarily the release date displayed in the app, therefore some movies in the app might show up as having been released a long time ago.

The wd:Q18011172 is a "film project" these are films that are unpublished uor unfinished, but films that release soon are usually finished and might already be released in some countries and might instead be wd:Q11424 "film". Therefore the query is run for each of these categories.

To get additional information about the movies and all release dates (in case some are before `$date` and some after) the API endpoint "https://www.wikidata.org/w/api.php?action=wbgetentities" is used.
