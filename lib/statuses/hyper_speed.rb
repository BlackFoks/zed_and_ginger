require_relative "status"

class Status
  # Speeds up the player, but forces them to run.
  class HyperSpeed < Status
    SPEED = 96
    ACCELERATION = 300

    def default_duration; 3; end

    def setup
      @sound = sound sound_path "speed_pill_taken.ogg"
      @sound.volume = 30 * (scene.user_data.effects_volume / 50.0)
      @sound.play
    end

    def reapply(options = {})
      super(options)
      @sound.play
    end

    def update
      if owner.ok? and not owner.disabled? :controls
        # Make sure the player goes FAST!
        owner.velocity_x = [owner.velocity_x + ACCELERATION * frame_time, SPEED].min if owner.velocity_x < SPEED

        # Create a blurry trail behind the player.
        time = scene.timer.elapsed
        color = Color.from_hsv(360 - ((time * 250) % 360), 1.0, 1.0)
        color.alpha = 50
        owner.scene.create_particle([owner.x - 4, owner.y - 0.1, owner.z + 2],
                                    gravity: 0, scale: 6, fade_duration: 2,
                                    color: color, glow: true)
      else
        owner.remove_status type
      end
   end
  end
end