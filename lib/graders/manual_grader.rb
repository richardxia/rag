class ManualGrader < AutoGrader
  def initialize(submission, grading_rules=nil)
    @submission = submission
    @raw_max = 100 #TODO: Make this configurable
    @raw_score = 0
    @comments = ""
    @assignment_id = assignment_id
    @errors = nil
  end

  def grade!
    puts "----BEGIN STUDENT SUBMISSION----"
    puts "-"*80
    print @submission
    puts "-"*80
    puts "----END STUDENT SUBMISSION----"

    confirm = false
    until confirm
      score = prompt_score
      comments = prompt_comments
      puts
      confirm = prompt_confirm(score, comments)
      puts
    end

    @raw_score += score
    @comments = comments
  end

  private

  def prompt_score
    puts "Please provide a score (max: 100): "
    STDOUT.flush
    score = STDIN.gets.chomp
    score = Integer(score, 10)
    unless (0..@raw_max).include? score
      raise ArgumentError, "Score outside of bounds"
    end
    score
  rescue ArgumentError => e
    puts "Invalid score"
    puts
    retry
  end


  def prompt_comments
    puts "Please provide comments: "
    STDOUT.flush
    comments = STDIN.gets.chomp
  end

  def prompt_confirm(score, comments)
    puts "Are you satisfied with the following score and comments?"
    puts "Score: #{score}"
    puts "Comments: " + comments

    puts "y[es], n[o]"
    STDOUT.flush
    confirm = STDIN.gets.chomp
    unless %w[yes y no n].include? confirm
      raise ArgumentError
    end
    %w[yes y].include? confirm
  rescue
    puts "Please enter yes or no."
    puts
    retry
  end
end
