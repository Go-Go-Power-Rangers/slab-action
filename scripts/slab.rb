require 'net/http'
require 'json'
require 'uri'
require 'date'
require 'time'
require_relative 'methods.rb'
include CommonMethods

module Slab
    # parameters
    # accessToken_slab, accessToken_github, repo_name, repo_owner, external_id_post
    def create_post(accessToken_slab, accessToken_github, repo_name, repo_owner, externalId)
        # --- REQUEST TO GITHUB ---
        
        query = " query {
            repository(owner: \"#{repo_owner}\", name: \"#{repo_name}\") {
                latestRelease {
                    name
                    author
                        {name}
                    createdAt
                    publishedAt
                    description
                    tagName
                }
            }
        }"

        uri = URI("https://api.github.com/graphql")

        res = queryFunc(uri, accessToken_github, query)
        puts(res.body)

        # extract variables from response
        release_hash = JSON.parse(res.body)
        latestRelease = release_hash.fetch("data").fetch("repository").fetch("latestRelease")
        title = Date.parse(latestRelease.fetch("publishedAt")).strftime("%d-%m-%Y")
        release_tag = latestRelease["tagName"]
        
        # --- CALL METHOD(create_markdown_string) HERE ---
        markdown_string = create_markdown_string(latestRelease, repo_name, release_tag)
        puts("markdown_string: \n# #{title} #{markdown_string}")
        markdown_string = "# #{title} #{markdown_string}"

        # --- REQUESTS TO SLAB ---
        
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
        puts("\nSlab api response \n" + res.body)
        json_res = JSON.parse(res.body)
        postIdVar = json_res.dig("data", "syncPost", "id")
        puts("id : #{postIdVar}")

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

    def update_post(accessToken_slab, accessToken_github, repo_name, repo_owner, post_id, externalId)
        # This script should take a post content and insert it the same way as original in MARKDOWN format
        query = " query {
            post (id: \"#{post_id}\") {
                content
            }
        }"
        uri = URI("https://api.slab.com/v1/graphql")
        res = queryFunc(uri, accessToken_slab, query)
        # puts("Slab api response \n" + res.body + "\n \n")
        post_json = JSON.parse(res.body)
        content = JSON.parse(post_json.fetch("data").fetch("post").fetch("content"))

        markdown_string, post_title = create_markdown_from_slabjson(content)

        # --- ADD NEW RELEASE HERE ---
        query = " query {
            repository(owner: \"#{repo_owner}\", name: \"#{repo_name}\") {
                latestRelease {
                    name
                    author
                        {name}
                    createdAt
                    publishedAt
                    description
                    tagName
                }
            }
        }"
        uri = URI("https://api.github.com/graphql")
        res = queryFunc(uri, accessToken_github, query)

        # --- CALL METHOD(create_markdown_string) HERE ---
        release_hash = JSON.parse(res.body)
        puts(res.body)
        release_new = release_hash.fetch("data").fetch("repository").fetch("latestRelease")
        tag_name = release_new["tagName"]
        markdown_string_new = create_markdown_string(release_new, repo_name, tag_name)

        # --- OH YEAH, ITS ALL COMING TOGETHER ---
        markdown_string = "#{post_title} #{markdown_string_new} #{markdown_string}"
        puts "new markdown_string:\n#{markdown_string}"

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
        puts("\nSlab api response on succes\n" + res.body)

        puts("Fishy him")
        return res
    end
end
