# encoding: UTF-8

require_relative "dialog_scene"

class EnterName < DialogScene
  BLANK_CHAR = '.'
  MAX_CHARS = 3

  def setup(previous_scene)
    super(previous_scene, cursor_shown: false)

    gui_controls << ShadowText.new(t.label.high_score, at: [GAME_RESOLUTION.width / 2, 1.25], size: 12, color: Color.red,
                                  auto_center: [0.5, 0])

    gui_controls << ShadowText.new(t.label.enter_name, at: [GAME_RESOLUTION.width / 2, 12], size: 6,
                                  auto_center: [0.5, 0])
    @entry = text BLANK_CHAR * MAX_CHARS, at: [GAME_RESOLUTION.width / 2, 18], size: 11.25, auto_center: [0.5, 0]

    width, height = @entry.rect.width + 4, @entry.rect.height
    gui_controls << Polygon.rectangle([@entry.x - width / 2.0, @entry.y + 1.5, width, height], Color.new(0, 0, 0, 150))
    gui_controls << @entry

    @key_press_sound = sound sound_path("key_press.ogg")
    @key_press_sound.volume = 50 * (user_data.effects_volume / 50.0)
  end

  def register
    # Enter the name.
    on :text_entered do |char|
      char = Ray::TextHelper.convert(char).upcase

      case char
        when 'A'..'Z', '0'..'9', '-', '.'
          first_blank_index = @entry.string.index(BLANK_CHAR)
          if first_blank_index
            name = @entry.string
            name[first_blank_index] = char
            @entry.string = name
            @key_press_sound.play
          end
      end
    end

    # Accept the name.
    [:return].each do |key_code|
      on(:key_press, key(key_code)) { accept_name }
    end

    # Delete last character.
    [:delete, :backspace].each do |key_code|
      on(:key_press, key(key_code)) { delete_last_char }
    end
  end

  def accept_name
    unless @entry.string.include? BLANK_CHAR
      @key_press_sound.play
      pop_scene @entry.string
    end
  end

  def delete_last_char
    @entry.string.chars.reverse_each.with_index do |char, i|
      if char !=  BLANK_CHAR
        name = @entry.string
        name[MAX_CHARS - 1 - i] = BLANK_CHAR
        @entry.string = name

        @key_press_sound.play

        break
      end
    end
  end
end
