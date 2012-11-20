require 'sinatra'

## In some situations you may need to set the :env and :port in this file.
# set :env,       :production
# set :port,      4567
disable :run, :reload
require 'application'
run Sinatra::Application 
