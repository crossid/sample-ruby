require File.expand_path '../main.rb', __FILE__

run Rack::URLMap.new({
  '/' => Login,
  '/protected' => Protected
})