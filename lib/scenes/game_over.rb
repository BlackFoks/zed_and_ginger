require_relative "dialog_scene"

class GameOver < DialogScene
  TEXT_SIZE = 6
  BUTTON_Y = 46

  HARDCORE_MULTIPLIER = 1.2
  INVERSION_MULTIPLIER = 1.2

  TIME_MULTIPLIER = 10 # Speed of counting off time.
  SCORE_PER_S = 2000 # Score you get for each remaining second.

  def setup(previous_scene, winner)
    super(previous_scene, cursor_shown: false)

    @winner = winner

    gui_controls << Polygon.rectangle([0, 0, GAME_RESOLUTION.width, GAME_RESOLUTION.height * 0.9], Color.new(150, 150, 150))
    gui_controls.last.blend_mode = :multiply

    @buttons = []
    @buttons << Button.new(t.button.menu.string, at: [GAME_RESOLUTION.width * 0.3, BUTTON_Y], size: TEXT_SIZE, auto_center: [0.5, 0],
                           tip: t.button.menu.tip) do
      pop_scene :menu
    end

    @buttons << Button.new(t.button.restart.string, at: [GAME_RESOLUTION.width * 0.5, BUTTON_Y], size: TEXT_SIZE, auto_center: [0.5, 0],
                           tip: t.button.restart.tip) do
      pop_scene :restart
    end

    @next_button = Button.new(t.button.next.string, at: [GAME_RESOLUTION.width * 0.7, BUTTON_Y], size: TEXT_SIZE, auto_center: [0.5, 0],
                              tip: t.button.next.tip) do
      pop_scene :next
    end

    @buttons << @next_button

    @button_background = Polygon.rectangle([0, @buttons.last.y - 1, GAME_RESOLUTION.width, @buttons.last.height + 2],
                                           Color.new(0, 0, 0, 100))

    @big_score = ShadowText.new("%07d" % @winner.score, at: [GAME_RESOLUTION.width / 2, GAME_RESOLUTION.height * 0.58], size: 20, blend_mode: :add,
                                color: Color.new(150, 150, 255, 200), shadow_color: Color.new(0, 0, 0, 200), auto_center: [0.5, 0.5])

    gui_controls << @big_score


    @all_time_removed = false
  end

  def register
    super
    on :key_press, key(:escape) do
      pop_scene :menu if previous_scene.timer.out_of_time?
    end

    event_group :buttons do
      @buttons.each {|b| b.register self, group: :buttons }
    end

    disable_event_group :buttons
  end

  def remove_all_time
    remove_time previous_scene.timer.remaining
  end

  # @param duration [Object]
  def remove_time(duration)
    duration = [duration, previous_scene.timer.remaining].min
    previous_scene.timer.decrease duration, finished: true
    @winner.score += SCORE_PER_S * duration
    previous_scene.update_score_cards
  end

  def update
    super

    # Empty out all the remaining time in the timer and convert to points, before finishing.
    if previous_scene.timer.out_of_time? or @winner.dead?
      unless @all_time_removed
        @all_time_removed = true

        # Add modifiers based on mutators.
        @winner.score *= HARDCORE_MULTIPLIER if previous_scene.hardcore?
        @winner.score *= INVERSION_MULTIPLIER if previous_scene.inversion?

        begin
          record_high_score(@winner.score.to_i, previous_scene.level_number)
        rescue OnlineHighScores::NetworkError
          log.warn "Network failed when posting new score."
        end

        # It is possible to get a high score without finishing and vice versa.
        if @winner.finished? and not user_data.finished_level?(previous_scene.level_number)
          user_data.finish_level(previous_scene.level_number)
        end

        @next_button.enabled = user_data.level_unlocked?(previous_scene.level_number + 1)

        self.cursor_shown = true
        gui_controls << @button_background
        self.gui_controls += @buttons

        enable_event_group :buttons
      end
    else
      remove_time frame_time * TIME_MULTIPLIER
    end

    @big_score.string = "%07d" % @winner.score
end

  def record_high_score(score, level)
    if score > previous_scene.high_score or game.online_high_scores.high_score?(level, score)
      run_scene :enter_name, self do |name|
        if name
          # Record local high score. Just one is stored.
          if score > previous_scene.high_score
            user_data.set_high_score(level, name, score, user_data.mode)
            previous_scene.update_high_score
          end

          # Record online high-score.
          if game.online_high_scores.high_score?(level, score)
            t = Time.now

            score_accepted = game.online_high_scores.add_score(level, name, score, user_data.mode)
            log.info do
              if score_accepted
                "Posted online high-score: #{name} scored #{score} on level #{level} at position #{score_accepted.position}"
              else
                "Failed to post online high-score: #{name} scored #{score} on level #{level}, but this was not high enough"
              end + " (Took: #{Time.now - t}s to update)"
            end
          end
        end
      end
    end
  end
end

