require_relative 'game_object'

class FireExhaust < GameObject
  BURN_DURATION = 0.9
  INACTIVE_DURATION = 1.8
  PERIOD = INACTIVE_DURATION + BURN_DURATION

  def to_rect; Rect.new(*(@position - [3, 2]), 6, 4) end

  def time_within_period; scene.timer.elapsed % PERIOD; end
  def collide?(other); other.z < 8 and super(other); end
  def casts_shadow?; true; end

  def initialize(map, tile, position)
    sprite = sprite image_path("fire_exhaust.png"), at: position
    sprite.sheet_size = [8, 1]
    sprite.scale *= 0.75
    color = sprite.color
    color.alpha = 100
    sprite.color = color
    sprite.blend_mode = :add
    sprite.origin = Vector2[sprite.sprite_width / 2, sprite.sprite_height - 1.5]

    super(map.scene, sprite, position)

    @shadow.image = image image_path("glow.png")
    @shadow.color = Color.new(255, 200, 100, 100)
    @shadow.blend_mode = :add
  end

  def update
    if time_within_period < BURN_DURATION
      @sprite.sheet_pos = [(@sprite.sheet_size.x / BURN_DURATION) * time_within_period, 0]
      @burning = true
    else
      @burning = false
    end

    scene.players.each do |player|
      player.burn if player.can_be_hurt? and collide? player
    end

    super
  end

  def draw_shadow_on(win)
    super(win) if @burning
  end

  def draw_on(win)
    super(win) if @burning
  end
end

class FireExhaustShifted < FireExhaust
  def time_within_period; (scene.timer.elapsed + PERIOD / 2) % PERIOD; end
end