# The classifier

This is a basic implementation of the classifier.
It's a simple Naive Bayes classifier. I'll later also implement a bag of words feature extractor that use negated words.
This "combo" seems to be the most rewarding with regards to the compromise of ease of implementation to precision of analysis.


But for the moment, this shall be enough.


The algo part seems to work well enough. I still need to implement the rest of the analysis part. That means a sinatra app that consume the database of tweets from the dashboard part, analyse it, and save the results in a second database to be later consumed by the third part of the project.
