require_relative "disabling_status"

class Status
  # Relies on the "thrower" to apply the force.
  # Disables you until you hit the ground again.
  class Thrown < DisablingStatus
    SPIN_FREQUENCY = 5.0
    Z_OFFSET = 4
    SQUASHED_DURATION = 0.25

    # Duration is based on time of flight, not an overall time.
    def default_duration; Float::INFINITY; end

    def setup
      @start = Time.now

      # Prevent immediate landing.
      owner.z = 0.00001 if owner.z == 0

      @original_origin = owner.origin
      owner.sheet_pos = owner.class::THROWN_SPRITE

      owner.origin = Vector2[owner.sprite_width, owner.sprite_height] * 0.5
    end

    def update
      if owner.z > 0
        owner.angle = (scene.timer.elapsed * 360 * SPIN_FREQUENCY) % 360
      else
        owner.remove_status(:thrown)
      end
    end

    def clean_up
      owner.sheet_pos = owner.class::AFTER_THROWN_SPRITE
      owner.angle = 0
      owner.origin = @original_origin
      owner.apply_status(:squashed, duration: SQUASHED_DURATION)
    end
  end
end