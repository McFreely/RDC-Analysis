# -*- coding: utf-8 -*-
## BluePrint

# Required Files and Gems
require 'rubygems'
require 'sinatra'
require 'slim'
require 'multi_json'
# require 'httparty'
require 'mongoid'
require_relative 'naive_bayes.rb'

Mongoid.load!("mongoid.yml")


TWEETS =
{:positive => [
"J'ai envie d'aller voir film",
"j'aimerai bien voir film",
"j'ai trop envie d'aller voir film",
"Ceux qui aiment Skrillex et qui ont été voir film savent à quel point ça fait du bien d'entendre ses sons avec le son du ciné.",
"J'ai trop trop hate de voir film ce soir",
"vous savez si film passe encore au ciné ou pas? j'ai envie de retourner le voir.",
"Je viens d'aller voir film il est bien mais y a trop de cul.",
"@drauhlifique aide moi stp j'veux voir film une 2ème fois",
"film jdois ABSOLUMENT le voir au ciné !",
"film est intéressant quand tu y pense, il faut juste arrêter de penser a l'aspect porno et voir plus loin.",
"Il y'a plus que les horaires du soir pour film. J'irais le voir une quatrième et dernière fois. #Addict",
"Hier soir jsuis allé voir film avec mon père, c'était chanme ce film est tellement bien réalisé!",
"Je suis allée voir film Il est trop bien",
"Je viens d'aller voir film Je crois que c'est le film le plus touchant que j'ai vue",
"J'ai été voir film il est grave",
"un #film à voir absolument pour son histoire et la prestation des acteurs. #jevalide",
"film Un film très très bon !!! À voir !!! Et c'est rare que j'conseille des films !",
"film Un film à aller voir IMPÉRATIVEMENT.",
"film super film, bien foutu et tout et tout, à voir d'urgence !",
"MERCI, une tuerie cinématographique ! A voir absolument!",
"Je veux trop voir film, IL PARAIT qu'il est bien !",
"Faut trop que vous alliez voir film l'histoire est géniale elle fait un peut pleurer",
"Sinon moi je veux toujours aller voir film, mais tous mes amis me font défaut",
"Jsuis allée voir film, c'était dar!"
],

:negative => [
"J'ai été voir film hier soir...Bref.",
"Voir une quelconque réflexion sur la jeunesse dans film, c'est comme voir une métaphore des tortures en Irak dans Hostel.",
"film il est bien ou pas? J'hésite à aller le voir..",
"Les américains qui sont pressés d'aller voir film … ils ne savent pas ce qui les attend",
"ma pote a été voir film elle a était très déçue. apparement y'a pas tant de sex que ça les gens. bande de petit",
"Sauf quand j'ai été voir film, j'sais pas comment j'ai fais aha",
"Je viens de voir le pire film de l'histoire de cinéma!",
"film il est trop nul! Heureusement j'ai pas payé pour voir ce film pfff",
"Nan il y'a des gens qui compte encore aller voir spring breakers .. Vous ne savez pas quoi faire de votre argent !",
"Mais pourquoi, pourquoi ai-je voulu aller au ciné voir Spring Breakers ?!",
"Au début je voulais allé voir spring breakers mais cst dla meeeeerde mddr",
"j'ai jamais vu un film aussi nul.",
"j'ai été voir spring breakers et en fait c'est boff, j'ai bien aimé mais y'a largement mieu",
"n'allez surtout pas voir spring breakers! c'est une daube en barre, aucun scénario, dialogue de merde juste vulgaire.",
"film vraiment très NUL, n'allez pas le voir #conseil",
"Je voulais aller voir film mais personne à envie de le voir. Elles veulent aller voir film",
"J'ai été voir film, impression de Oui mais .... Je m'attendais à plus compliqué, avec + de matière à réflexion.",
"Je vous déconseillent d'aller Voir film c'est vraiment pas terrible.",
"Y a mon père, il a le mort parce qu'il est aller voir Cloud Atlas, il durait 3h et il était pérave. Ma mère, elle a dormit tout le long :')",
"Ne jamais aller voir film #nul",
"Tout à l'heure on est parti au ciné voir Cloud Atlas, j'ai dormi pendant tout le film",
"j'irai jamais le voir"
]}


categories = [:positive, :negative]
classifier = NaiveBayes.new(categories)

categories.each do |category|
  TWEETS[category].each do |tweet|
    classifier.train(category, tweet)
  end
end

class Movie
  include Mongoid::Document
  field :mt, as: :movie_title, type: String
  field :tweets, type: Hash
  field :status_analysis, type: Boolean, default: false
end

# get '/' do
#   @movies = Movie.all
#   slim :manage
# end

get '/' do
  movies = Movie.all
  movies.each do |movie|
    @count_tweets_trained = 0
    @count_positive = 0
    @count_negative = 0
    @count_neutral = 0
    puts "*******"
    puts movie.mt
    movie.tweets.each do |tweet|
      result = classifier.classify(tweet)
      if result == :positive
        @count_positive += 1
      elsif result == :negative
        @count_negative += 1
      else
        @count_neutral += 1
      end
      @count_tweets_trained += 1
    end
    puts "GLOBAL RESULTS :"
    puts @count_tweets_trained
    puts @count_positive
    puts @count_negative

    stat_pos = (@count_positive.to_f / @count_tweets_trained.to_f) * 100
    stat_neg = (@count_negative.to_f / @count_tweets_trained.to_f) * 100

    puts "Positive : " + stat_pos.to_s + " %"
    puts "Negative : " + stat_neg.to_s + " %"
  end
end

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


# This script should run by itself every x days
# When the aggregation of tweets will be automated, the script will run more
