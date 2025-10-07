namespace :quiz do
  desc "Load questions from JSON file"
  task load_questions: :environment do
    json_file = ENV["JSON_FILE"] || "questions.json"

    unless File.exist?(json_file)
      puts "Error: File not found - #{json_file}"
      puts "Usage: rake quiz:load_questions JSON_FILE=path/to/questions.json"
      exit 1
    end

    begin
      json_data = JSON.parse(File.read(json_file))

      unless json_data.is_a?(Array)
        puts "Error: JSON file must contain an array of questions"
        exit 1
      end

      ActiveRecord::Base.transaction do
        json_data.each_with_index do |question_data, index|
          Question.create!(
            content: question_data["content"],
            correct_answer: question_data["correct_answer"],
            position: index + 1,
            duration_seconds: question_data["duration_seconds"] || 10
          )
        end
      end

      puts "Successfully loaded #{json_data.size} questions"
    rescue JSON::ParserError => e
      puts "Error: Invalid JSON format - #{e.message}"
      exit 1
    rescue ActiveRecord::RecordInvalid => e
      puts "Error: Failed to create question - #{e.message}"
      exit 1
    end
  end

  desc "Start quiz (activate quiz state)"
  task start: :environment do
    begin
      state = QuizStateManager.start_quiz
      puts "Quiz started successfully"
      puts "Quiz active: #{state.quiz_active}"
    rescue StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end
  end

  desc "Start a specific question by POSITION or auto-start next question"
  task start_question: :environment do
    position = ENV["POSITION"]

    begin
      state = CurrentQuizState.instance

      # Check if previous question has ended
      if state.active_question_id.present? && state.question_ends_at.present?
        if Time.current < state.question_ends_at
          puts "Error: Current question has not ended yet"
          puts "Current question ends at: #{state.question_ends_at}"
          puts "Remaining seconds: #{state.remaining_seconds}"
          exit 1
        end
      end

      # Determine which question to start
      if position
        question = Question.find_by(position: position)
        unless question
          puts "Error: Question not found with position #{position}"
          exit 1
        end
      else
        # Auto-determine next question
        if state.active_question_id.present?
          current_question = Question.find(state.active_question_id)
          next_position = current_question.position + 1
          question = Question.find_by(position: next_position)
          unless question
            puts "Error: No next question found after position #{current_question.position}"
            exit 1
          end
        else
          # Start from the first question
          question = Question.order(:position).first
          unless question
            puts "Error: No questions found"
            exit 1
          end
        end
      end

      state = QuizStateManager.start_question(question.id)
      puts "Question started successfully"
      puts "Position: #{question.position}"
      puts "Active question ID: #{state.active_question_id}"
      puts "Question started at: #{state.question_started_at}"
      puts "Question ends at: #{state.question_ends_at}"
      puts "Duration: #{state.duration_seconds} seconds"
    rescue StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end
  end

  desc "Reset quiz (delete all answers, players, and reset quiz state)"
  task reset: :environment do
    print "Are you sure you want to reset the quiz? This will delete all answers and players. (y/N): "
    confirmation = STDIN.gets.chomp

    unless confirmation.downcase == "y"
      puts "Reset cancelled"
      exit 0
    end

    begin
      ActiveRecord::Base.transaction do
        Answer.delete_all
        Player.delete_all
        state = CurrentQuizState.instance
        state.update!(
          quiz_active: false,
          active_question_id: nil,
          question_started_at: nil,
          question_ends_at: nil,
          duration_seconds: nil
        )

        puts "Quiz reset successfully"
        puts "- Deleted #{Answer.count} answers"
        puts "- Deleted #{Player.count} players"
        puts "- Reset quiz state"
      end
    rescue StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end
  end

  desc "Reset all (delete questions, answers, players, and reset quiz state)"
  task reset_all: :environment do
    print "Are you sure you want to reset everything? This will delete ALL data including questions. (y/N): "
    confirmation = STDIN.gets.chomp

    unless confirmation.downcase == "y"
      puts "Reset cancelled"
      exit 0
    end

    begin
      ActiveRecord::Base.transaction do
        Answer.delete_all
        Player.delete_all
        Question.delete_all
        state = CurrentQuizState.instance
        state.update!(
          quiz_active: false,
          active_question_id: nil,
          question_started_at: nil,
          question_ends_at: nil,
          duration_seconds: nil
        )

        puts "Everything reset successfully"
        puts "- Deleted all questions"
        puts "- Deleted all answers"
        puts "- Deleted all players"
        puts "- Reset quiz state"
      end
    rescue StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end
  end
end
