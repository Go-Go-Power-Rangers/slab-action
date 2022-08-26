require 'net/http'
require 'json'
require 'uri'
require 'date'
require_relative 'methods.rb'
include CommonMethods
require_relative 'slab.rb'
include Slab

repo_name = ARGV[0]
repo_owner = ARGV[1]
accessToken_slab = ARGV[2] 
accessToken_github = ARGV[3] 
topicID= "2w941vt0"
puts(accessToken_slab)
puts(accessToken_github)

### The flow so far:
# 1. Check Slab for a post titled with currentDate, and either
# - 1a. Find nil, and create a new syncpost with currentDate as externalId
# - 1b. Find an existing post, extract the content with mads-json-dissection, 
#       merge it with the new content, and override the syncPost by calling it
#       again with the new merged content.
###
 
currentDate = DateTime.now().strftime('%d-%m-%Y').to_s
puts currentDate

query = " query {
    search (
        query: \"#{currentDate}\"
        first: 100
        types: POST
    ) { 
        edges {
            node {
                ... on PostSearchResult {
                    post {
                        title, id, topics{
                            id
                        } 
                    }
                }
            }
        }
    }   
}"
uri = URI("https://api.slab.com/v1/graphql")
res = queryFunc(uri, accessToken_slab, query)
json_res = JSON.parse(res.body)

#Dig out the different edges
edges = json_res.dig("data","search","edges")
posts = []
existing_post_ID = nil

#add each post to the array of posts
edges.each_with_index do |edge,i|
    #add post
    posts.append(edge.dig("node","post"))
    #save important attributes
    post_id = posts[i].fetch("id")
    post_title = posts[i].fetch("title") 
    topics = posts[i].fetch("topics")
    #check if topics exists
    if(topics != nil && post_title == currentDate)
        #check each topic whether it's the right one
        topics.each do |topic|
            id = topic.dig("id")
            #break out of loop if the post with the right topic has been found
            if(id != nil && id == topicID)
                existing_post_ID = post_id
                break
            end
        end
    end
    #break if post is found
    if(existing_post_ID != nil)
        break
    end
end

puts existing_post_ID

if(existing_post_ID == nil)
    res = create_post(accessToken_slab,accessToken_github, repo_name, repo_owner, currentDate)
    puts res
else
    res = update_post(accessToken_slab,accessToken_github, repo_name, repo_owner, existing_post_ID, currentDate)
    puts res
end
