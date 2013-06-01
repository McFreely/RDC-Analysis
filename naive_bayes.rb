class NaiveBayes

  # Initialise the classifier given a list of categories
  def initialize(categories)
    @words = Hash.new                # Hash of words in each category
    @categories_trained_words = Hash.new     # Hash of number of words in each category
    @categories_trained_tweets = Hash.new    # Hash of number of tweets trained in each category
    @total_trained_tweets = 0                # Number of tweets trained in total
    @total_trained_words = 0                 # Number of words trained

    categories.each do |category|
      @words[category] = Hash.new    # Create a Hash for each category
      @categories_trained_tweets[category] = 0
      @categories_trained_words[category] = 0
    end
  end



  # Train the classifier given a tweet
  def train(category, tweet)
    word_count(tweet).each do |word, count|
      @words[category][word] ||= 0
      @words[category][word] += count
      @total_trained_words += count
      @categories_trained_words[category] += count
    end
    @categories_trained_tweets[category] += 1
    @total_trained_tweets += 1
  end

  # Helper for reading and training the corpus files
  def corpus_train(categ_name)
    category = File.new("#{categ_name}.txt", 'r')
    while tweet = category.gets
      train("#{categ_name}", tweet)
    end
    category.close
  end

  # Return a Hash containing the probability for each category
  def probabilities(tweet)
    probabilities = Hash.new
    @words.each_key do |category|
      probabilities[category] = probability(category, tweet)
    end
    return probabilities
  end

  # Determine the category of a tweet
  def classify(tweet)
    sorted = probabilities(tweet).sort {|a,b| a[1]<=>b[1]}
    best = sorted.pop
    return best[0]
  end

  private

  # The probability of a word being in a given category
  def word_probability(category, word)
    (@words[category][word].to_f + 1) / @categories_trained_words[category].to_f
  end

  # The probability that the tweet exist given a particular category : P(tweet|category)
  def tweet_probability(category, tweet)
    tweet_prob = 1
    word_count(tweet).each  do |word|
      tweet_prob *= word_probability(category, word[0])
    end
    return tweet_prob
  end

  # The probability that any tweet belong to that category : P(category)
  def category_probability(category)
    @categories_trained_tweets[category].to_f / @total_trained_tweets.to_f
  end

  # The probability of a tweet belonging to that category : P(category|tweet)
  def probability(category, tweet)
    tweet_probability(category, tweet) * category_probability(category)
  end

  # Return a Hash containing the words of the tweet and their occurrences
  def word_count(tweet)
    words = tweet.gsub(/[^\w\s]/,"").split    # REGEX: remove whites spaces and special chars
    d = Hash.new
    words.each do |word|
      word.downcase!  # Replace word with their downcase counterpart
      unless COMMON_WORDS.include?(word) # remove common words
        d[word] ||= 0
        d[word] += 1
      end
    end
    return d
  end

  # To be Completed
  COMMON_WORDS = ['ce', 'film', 'est', 'un']
end
