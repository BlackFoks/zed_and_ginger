if __FILE__ == $0
  $stderr.puts "Error: Run via bin/zed_and_ginger.rbw"
  exit
end

t = Time.now

begin
  require 'bundler/setup' unless DEVELOPMENT_MODE or defined?(OSX_EXECUTABLE) or ENV['OCRA_EXECUTABLE'] or defined? Ocra

rescue LoadError
  $stderr.puts "Bundler gem not installed. To install:\n  gem install bundler"
  exit
rescue Exception
  $stderr.puts "Gem dependencies not met. To install:\n  bundle install"
  exit
end

require 'ray'
include Ray

require_relative "games/splash"

background = nil

pre_load_code = lambda {
  require 'yaml'
  require 'logger'
  require 'forwardable'
  require 'json'

  require 'rest-client'
  require 'r18n-desktop'

  require_relative 'log'

  R18n.from_env File.expand_path('config/lang', EXTRACT_PATH), 'en'

  Log.log.info { "Ruby gems loaded in #{Time.now - t}s" }

  t = Time.now

  def require_files(dir, files)
    files.each do |filename|
      require_relative File.join(dir, filename)
    end
  end

  GAME_RESOLUTION = Vector2[96, 60] # Resolution of tiles, at least.

  require_files('mixins', %w[has_status registers])
  require_files('./', %w[log ray_ext maps online_high_scores camera user_data version])
  require_files('scenes', %w[confirm enter_control enter_name game_over high_scores intro_inside intro_outside level options_controls options_multimedia pause main_menu ready_set_go teleporting])
  require_files('gui', %w[button check_button fps_monitor progress_bar radio_group score_card shadow_text timer tool_tip])
  require_files('standard_ext', %w[hash])
  require_files('games', %w[error_window my_game splash])
  require_files('particles', %w[particle_generator])

  Log.log.info { "Game files loaded in #{Time.now - t}s" }
  t = Time.now

  # Do some pre-loading for the main menu, so it isn't blank before it appears!
  background = Starscape.new

  Log.log.info { "Background created in #{Time.now - t}s" }
}

Splash.new(File.expand_path("media/images/window_icon.png", EXTRACT_PATH), pre_load_code, size: [256, 256]).run

# After all files are included, we don't need to go further for Ocra.
exit if defined? Ocra

CLASSES_WITH_TIME_SHADERS = [SlowFloor, SlowSplat, Teleporter, Teleporting]
CLASSES_WITH_SHADERS = CLASSES_WITH_TIME_SHADERS + [ZedEssenceOutside, GlueFloor]

SCENE_CLASSES = [Confirm, EnterControl, EnterName, GameOver, HighScores, IntroInside, IntroOutside, Level, OptionsControls, OptionsMultimedia, Pause, MainMenu, ReadySetGo, Teleporting]

$create_game_with_scene = :main_menu unless defined? $create_game_with_scene # To allow tests not to open a window.
while $create_game_with_scene
  begin
    game = MyGame.new(R18n.get.t.window.title, SCENE_CLASSES, background, initial_scene: $create_game_with_scene)
    game.run

  rescue => exception
    game.window.close if game

    ErrorWindow.new("Zed and Ginger - Error", exception, size: [640, 480]).run
  end
end