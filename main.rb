# -*- coding: utf-8 -*-
require 'rubygems'
require 'multi_json'
require 'mongoid'
require_relative 'naive_bayes.rb'

# Load the configuration file for accessing the db
# The environment is explicit, else mongoid throw an error
Mongoid.load!("mongoid.yml", :development)

CORPUS =
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

# Initialise the categories for the classifier
categories = [:positive, :negative]
# Initialise the classifier with the previous categories
naive = NaiveBayes.new(categories)

# Train the classifier by iterating over the training corpus
categories.each do |category|
  CORPUS[category].each do |tweet|
    naive.train(category, tweet)
  end
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
  field :runtime, type: String
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

  if stats.save
    puts "Save successful for " + movie.mt + "!"
  else
    puts "Error while saving"
  end

  # Update the status of the Movie document
  movie.set(:status_analysis, true)
end
