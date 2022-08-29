require_relative 'methods.rb'
include HelperMethods

module Slab
    def create_post(accessToken_slab, accessToken_github, repo_name, repo_owner, externalId)        
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

        # extract variables from response
        release_hash = JSON.parse(res.body)
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
    def update_post(accessToken_slab, accessToken_github, repo_name, repo_owner, post_id, externalId)
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

        # creates markdown string from new release
        release_hash = JSON.parse(res.body)
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
end
