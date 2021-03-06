class Button
  include Helper
  extend Forwardable
  include Registers

  attr_accessor :data

  def_delegators :'@text.rect', :x, :y, :height, :width

  def under_mouse?; @under_mouse; end
  def enabled?; @enabled; end

  COLOR = Color.white
  DISABLED_COLOR = Color.new(100, 100, 100)
  HOVER_COLOR =  Color.new(175, 175, 255)
  SHORTCUT_COLOR = Color.cyan

  def initialize(text, options = {}, &handler)
    raise "#{self.class} must have handler" unless block_given?

    options = {
        enabled: true,
        color: COLOR.dup,
        disabled_color: DISABLED_COLOR,
        hover_color: HOVER_COLOR,
        shortcut_color: SHORTCUT_COLOR,
        brackets: true,
    }.merge! options

    text = text.to_s

    @color = options[:color].dup
    @disabled_color = options[:disabled_color].dup
    @hover_color = options[:hover_color].dup

    @tip = options[:tip]

    @shortcut = options.has_key?(:shortcut) ? options[:shortcut] : text[0].downcase.to_sym

    @data = options[:data]
    text = "[#{text}]" if options[:brackets]
    @text = Text.new text, options
    @handler = handler

    @shortcut_text = if @shortcut
      overlay = ' ' * text.length
      index = text.index /[#{@shortcut}]/i
      overlay[index] = text[index]
      Text.new overlay, options.merge(color: options[:shortcut_color].dup)
    else
      nil
    end

    self.enabled = options[:enabled]

    update_contents
  end

  def tip
    if @tip.respond_to? :call
      @tip.call
    else
      @tip
    end
  end

  def register(scene, options = {})
    options = {
        group: :default,
    }.merge! options

    super(scene)

    event_group options[:group] do
      if @shortcut
        on(:key_press, key(@shortcut)) { activate }
      end

      on :mouse_press do |button, pos|
        activate if button == :left and enabled? and @text.to_rect.contain?(pos / scene.user_data.scaling)
      end

      # Handle mouse hovering.
      @under_mouse = false
      on :mouse_motion do |pos|
        if enabled? and @text.to_rect.contain?(pos / scene.user_data.scaling)
          unless @under_mouse
            @under_mouse = true
            raise_event :mouse_hover, self
            update_contents
          end
        else
          if @under_mouse
            @under_mouse = false
            update_contents
            raise_event :mouse_unhover, self
          end
        end
      end

      on :mouse_unhover, self do |pos|
        @under_mouse = false
        update_contents
      end
    end
  end

  def update_contents
    @text.color = current_color
  end

  def unhover
    @under_mouse = false
    update_contents
  end

  def enabled=(enabled)
    @enabled = enabled
    raise_event :mouse_unhover, self if under_mouse? and not enabled # Ensure that if we have issued a tool-tip, it is cleared.
    @under_mouse = false unless @enabled
    update_contents
    @enabled
  end

  def current_color
    @enabled ? (@under_mouse ? @hover_color : @color) : @disabled_color
  end

  def activate
    @handler.call self
  end

  def draw_on(win)
    @text.draw_on win
    @shortcut_text.draw_on win if @shortcut and enabled?
  end
end