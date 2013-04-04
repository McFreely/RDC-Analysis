## BluePrint

# Required Files and Gems

# Job 1
# Check for non-analysed Movie Documents in the
# dashboard db
# If a movie document is not analysed, add it to the queue

# Job 2
# For each  Movie document, iterate over the tweets and analyse each one
# Condense results and only keep global statistics results about the movie
# i.e.: The positive and negative percentages over all the tweets

# Job 3
# Get the other info about the movie (poster, synopsis, release year, ...)

# Job 4
# Save all the new date in the pg db "results_db"

# Job 5
# update the movie document to "analysed"


## This script should run by itself every x days
## When the aggregation of tweets will be automated, the script will run more
## often.
