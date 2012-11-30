require 'rubygems'
require 'sinatra'
require 'plist'
require 'time'
require 'erb'

# this is the new feature branch

helpers do 
  def load_users
    # Set Print Service Quota Stats plist file location
    # Parse plist to array
    if Sinatra::Application.environment().to_s == 'production'
      @file = printServiceQuotaFile = '/Library/Preferences/com.apple.printservicequotastats.plist'
    else
      @file = printServiceQuotaFile = File.dirname(__FILE__) + '/public/printservicequotastats.sample.plist'
    end
    results = Plist::parse_xml(printServiceQuotaFile)

    # Return users from PrintServices Plist
    user_array = results['byuser']

    # Set users to empty hash incase hash no users are ever loaded
    users   = {}

    # Change array of print users to hash
    # FORMAT: name => { 'printed' => x, 'lastmod' => lastmod_date, 'start' => start_date }
    # NOTE: This does not take into account mutliple quotas for multiple queues
    user_array.each do |user|
      newUser = { 
        user['name'] => { 
          'printed' => user['quotastats']['default']['printed'], 
          'lastmod' => user['quotastats']['default']['lastmod'],
          'start' => user['quotastats']['default']['start'] 
        } 
      }
     users = users.merge(newUser)
    end
    
    return users
  end
  
  def user(name)
    load_users[name]
  end
  
  def anchors
    # Set intial variables
    # characters array includes '#' to represent 0-9
    # this will always fail the conditional below, but will result in '#top' being set as the link
    characters    = [ '#','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z']
    user_anchors  = []
    anchors       = []
    prev_user     = ""
    prev_anchor   = "top"
    
    load_users.sort.each do |user|
      user_anchors << user[0][0].chr.downcase if user[0][0].chr.downcase != prev_user
      prev_user = user[0][0].chr.downcase
    end
    
    characters.each do |anchor|
      if user_anchors.include?(anchor)  
        anchors << "<a href='##{anchor}'>#{anchor}</a>"
        prev_anchor = anchor 
      else
        anchors << "<a class='none' href='##{prev_anchor}'>#{anchor}</a>" 
      end
    end
    
    return anchors
  end
  
  def pretty_time(time)
    time.strftime("%B %d, %Y at %I:%M %p")
  end
end


get '/' do
  @users = load_users
  
  # Sets minimum number of users before anchors are displayed.
  # Set to 0 (or remove conditional) to always show anchors.
  # Comment out line to always hide anchors.
  @showAnchors = true if @users.size > 20
  
  # Render view
  erb :index
end

get '/view/:user' do
  @user = user(params[:user])
  pass if @user == nil
  @header = "Quota information for #{params[:user]}"
  
  # Render view
  erb :show
end

get '/view/:invalid_user' do
  # Not found message
  "No user information found for #{params[:invalid_user]}"
end

not_found do
  # Not using a 404 page, but simply redirecting to root
  redirect '/'
end
