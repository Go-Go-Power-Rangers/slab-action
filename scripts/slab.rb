require_relative 'methods.rb'
include HelperMethods

module Slab
    def create_post(accessToken_slab, repo_name, externalId, latest_release)        

        # extract variables from latest_release
        release_hash = JSON.parse(latest_release.body)
        latestRelease = release_hash.fetch("data").fetch("repository").fetch("latestRelease")
        title = Date.parse(latestRelease.fetch("publishedAt")).strftime("%d-%m-%Y")
        release_tag = latestRelease["tagName"]
        
        markdown_string = create_markdown_string(latestRelease, repo_name, release_tag)
        markdown_string = "# #{title} #{markdown_string}"
        
        query = " mutation {
            syncPost(
                externalId: \"#{externalId}\"
                content: \"#{markdown_string}\"
                format: MARKDOWN
                editUrl: \"https://\"
            )
            {title, id}
        }"

        uri = URI("https://api.slab.com/v1/graphql")
        res = queryFunc(uri, accessToken_slab, query)
        json_res = JSON.parse(res.body)
        postIdVar = json_res.dig("data", "syncPost", "id")

        query= " mutation {
            addTopicToPost(
                postId: \"#{postIdVar}\"
                topicId: \"2w941vt0\"       
            ) {
                name
            }
        }"
        res = queryFunc(uri, accessToken_slab, query)
        return res
    end

    # update_post returns response from request to slab with updated markdown string
    def update_post(accessToken_slab, repo_name, post_id, externalId, latest_release)
        # This script takes post content from slab, reformats the json to markdown
        # and adds new markdown all together, then sends it in a query to slab

        query = " query {
            post (id: \"#{post_id}\") {
                content
            }
        }"
        uri = URI("https://api.slab.com/v1/graphql")
        res = queryFunc(uri, accessToken_slab, query)
        post_json = JSON.parse(res.body)
        post_content = JSON.parse(post_json.fetch("data").fetch("post").fetch("content"))
        markdown_string, post_title = create_markdown_from_slabjson(post_content)

        # creates markdown string from new release
        release_hash = JSON.parse(latest_release.body)
        release_new = release_hash.fetch("data").fetch("repository").fetch("latestRelease")
        tag_name = release_new["tagName"]
        markdown_string_new = create_markdown_string(release_new, repo_name, tag_name)

        

        # combine the post title, current post content and new post content, insert at top
        markdown_string = "#{post_title} #{markdown_string_new} #{markdown_string}"

        # --- REQUEST TO UPDATE POST WITH NEW MARKDOWN STRING ---
        query = " mutation {
            syncPost(
                externalId: \"#{externalId}\"
                content: \"#{markdown_string}\"
                format: MARKDOWN
                editUrl: \"https://\"
            )
            {title, id}
        }"
        uri = URI("https://api.slab.com/v1/graphql")
        res = queryFunc(uri, accessToken_slab, query)
        return res
    end

    # searches for a post with current date and returns id if found, otherwise nil
    def search_post_exists(accessToken_slab, currentDate, topicID)
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
            if(!!topics && post_title == currentDate)
                #check each topic whether it's the right one
                topics.each do |topic|
                    id = topic.dig("id")
                    #break out of loop if the post with the right topic has been found
                    if(!!id && id == topicID)
                        existing_post_ID = post_id
                        break
                    end
                end
            end
            #break if post is found
            if(!!existing_post_ID)
                break
            end
        end
        return existing_post_ID
    end
end
