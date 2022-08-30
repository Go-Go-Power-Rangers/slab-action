require 'net/http'
require 'json'
require 'uri'
require 'date'
require_relative 'slab.rb'
include Slab

repo_name = ARGV[0]
repo_owner = ARGV[1]
accessToken_slab = ARGV[2] 
accessToken_github = ARGV[3] 
# tpoicID does not change and is hardcoded
topicID= "2w941vt0"

### The flow:
# 1. Check Slab for a post titled with currentDate, and either
# - 1a. Find nil, and create a new syncpost with currentDate as externalId
# - 1b. Find an existing post, extract the content with mads-json-dissection, 
#       merge it with the new content, and override the syncPost by calling it
#       again with the new merged content.
###

latest_release = get_latest_release_github(accessToken_github, repo_name, repo_owner)

currentDate = DateTime.now().strftime('%d-%m-%Y').to_s

existing_post_ID = search_post_exists(accessToken_slab, currentDate, topicID)

if(!existing_post_ID)
    res = create_post(accessToken_slab, repo_name,currentDate, latest_release)
else
    res = update_post(accessToken_slab, repo_name, existing_post_ID, currentDate, latest_release)
end
puts("Finito! \nResponse from slab:\n#{res.inspect()}")
