require 'rubygems'
require 'multi_json'
require 'mongoid'
require 'httparty'
require_relative 'naive_bayes.rb'
# require_relative 'rottent.rb'

# Load the configuration file for accessing the db
# The environment is explicit, else mongoid throw an error
Mongoid.load!("mongoid.yml", :development)

# Initialise the categories for the classifier
categories = ["positive", "negative"]

# Initialise the classifier with the previous categories
naive = NaiveBayes.new(categories)

# Train the classifier by iterating over the training corpus
categories.each do |category|
  naive.corpus_train(category)
end

# The document model for the twitter query
class Movie
  include Mongoid::Document
  field :mt, as: :movie_title, type: String
  field :tweets, type: Hash
  field :status_analysis, type: Boolean, default: false
end

# The document model for the results of the analysis
class Stat
  include Mongoid::Document
  field :title, type: String    # Different name to avoid confusion
  field :total_count, type: Integer
  field :stat_positive, type: Integer
  field :stat_negative, type: Integer
  field :movie_poster, type: String
  field :trailer, type: String
  field :release_date, type: String, default: '2013'
  field :director, type: String
  field :runtime, type: String, default: 'not available'
  field :plot, type: String
end

# Return movies document that are not analysed
movies = Movie.where(:status_analysis => false)

# Iterate over each of them
movies.each do |movie|

  # Initialise the variables for the statistics
  @count_tweets = 0
  @count_positive = 0
  @count_negative = 0
  @count_neutral = 0

  # Iterates over the tweets and analyses them
  movie.tweets.each do |tweet|
    result = naive.classify(tweet)
    if result == :positive
      @count_positive += 1
    elsif result == :negative
      @count_negative += 1
    else
      @count_neutral += 1
    end
    @count_tweets += 1
  end

  # Return a nice readable result in the form XX%
  stat_positive = ((@count_positive.to_f / @count_tweets.to_f) * 100).round.to_s
  stat_negative = ((@count_negative.to_f / @count_tweets.to_f) * 100).round.to_s

  # Initialise a new Stat document for saving the results of the analysis
  stats = Stat.new(:title => movie.mt,
                   :total_count => @count_tweets,
                   :stat_positive => stat_positive,
                   :stat_negative => stat_negative)

  # Rottenization of the movie infos
  # To Do With IMDB API, which is more complete, this is just a test
  # And highly suseptible to changes
  # This is bad ugly placeholder code not intended to stay
  # more than a few days

  mt = movie.mt
  options = {:query => {:t => mt,
                        :r => 'JSON',
                        :plot => 'full',
                        }}

  response = HTTParty.get("http://omdbapi.com", options)
  results = JSON.parse(response.body)

  if results['Poster'] == "N/A"
    poster = "/img/poster_default.gif"
    stats.set(:movie_poster, poster)
  elsif results
    poster = results['Poster']
    release = results['Released']
    director = results['Director']
    runtime = results['Runtime']
    plot = results['Plot']

    stats.set(:movie_poster, poster)
    stats.set(:release_date, release)
    stats.set(:runtime, runtime)
    stats.set(:director, director)
    stats.set(:plot, plot)
  else
    puts "No Infos for " + movie.mt + ", continuing..."
  end

  if stats.save
    puts "Save successful for " + movie.mt + "!"
  else
    puts "Error while saving"
  end

  # Update the status of the Movie document
  movie.set(:status_analysis, true)
end
