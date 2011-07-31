require 'yaml'
require 'forwardable'
require 'fileutils'

begin
  require 'bundler/setup' unless DEVELOPMENT_MODE or defined?(OSX_EXECUTABLE) or ENV['OCRA_EXECUTABLE']

rescue LoadError
  $stderr.puts "Bundler gem not installed. To install:\n  gem install bundler"
  exit
rescue Exception
  $stderr.puts "Gem dependencies not met. To install:\n  bundle install"
  exit
end

def require_files(dir, files)
  files.each do |filename|
    require_relative File.join(dir, filename)
  end
end

require_relative 'ray_ext'

GAME_RESOLUTION = Vector2[96, 60] # Resolution of tiles, at least.

require_files('./', %w[log error_window my_game user_data version])
require_files('mixins', %w[has_status registers])
require_files('scenes', %w[confirm enter_control enter_name game_over level options_controls pause main_menu ready_set_go teleporting])
require_files('gui', %w[button check_button fps_monitor progress_bar score_card shadow_text timer])
require_files('standard_ext', %w[hash])

CLASSES_WITH_SHADERS = [SlowFloor, SlowSplat, Teleporter, Teleporting]
SCENE_CLASSES = [Confirm, EnterControl, EnterName, GameOver, Level, OptionsControls, Pause, MainMenu, ReadySetGo, Teleporting]

$create_window = true
while $create_window
  $create_window = false

  begin
    MyGame.new("Zed and Ginger", SCENE_CLASSES).run


  rescue => exception
    ErrorWindow.new("Zed and Ginger", exception, size: [640, 480]).run
  end
end