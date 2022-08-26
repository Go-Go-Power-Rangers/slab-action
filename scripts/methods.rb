# release_body is json returned from github release
module CommonMethods
    # comment here
    def create_markdown_string (release_description, repo_name, tag_name)
        markdown_string = ""        
        ul_items = release_description["description"].split("\r").collect(&:strip)
        markdown_string += "\\n## #{repo_name} - #{tag_name} \\n"
    
        ul_items.each do |i|
            ex_uri = URI.extract(i, ['http', 'https'])
    
            if ex_uri.any?
                # add code here if cases with a line having multiple uri appears
                # ex_uri.each do |uri|
                # end
    
                normal_text = "#{i.gsub("#{ex_uri[0]}", "")}"
                hyperlink = "[##{ex_uri[0].split('/')[-1]}](#{ex_uri[0]})"
                markdown_string += " - #{normal_text} #{hyperlink} \\n"
            else
                markdown_string += " - #{i} \\n"
            end
            ex_uri.clear()
            end
        return markdown_string
    end

    # comment here
    def queryFunc(exUri, accessToken, query)
        uri = exUri
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
            req = Net::HTTP::Post.new(uri)
            req['Content-Type'] = "application/json"
            req['Authorization'] = accessToken
            # request body
            req.body = JSON[{'query' => query}]
            http.request(req)
        end
        return res
    end

    # comment here
    def create_markdown_from_slabjson(json_content)
        markdown_string = ""
        item_string = ""
        post_title = ""
        index = 1
        json_content.each do |item|
            if item.fetch("insert") == "\n"

                item_string += "#{item}"
                item_string = " {\"item\"=>[#{item_string}]}"
                from_string = JSON.parse(item_string.gsub('=>', ':'))
                # puts "\ncompleted hash from string #{index}:\n#{from_string["item"]}"

                insert_text = Array.new
                from_string["item"].each_with_index do |i, index|
                    insert_text.append("#{i["insert"]}")

                    # check if insert is a header
                    if i["attributes"]["header"] != nil
                        case i["attributes"]["header"]
                        # header 1 - return as post_title
                        when 1
                            post_title = "# #{insert_text[0]}"
                            insert_text.delete_at(0)
                        # header 2
                        when 2
                            insert_text[0] = "\\n## #{insert_text[0]}"
                        end
                    # checks if insert text is bold
                    end
                    if i["attributes"]["bold"] != nil
                        insert_text[index] = "**#{i["insert"]}**"
                    end
                    # check if insert text is a link and creates hyperlink
                    if i["attributes"]["link"] != nil
                        insert_text[index] = "[#{insert_text[index]}](#{(i["attributes"]["link"])})"
                    end
                    # check if insert text is a bullet
                    if i["attributes"]["list"] != nil
                        insert_text[0] = "#{" - " + insert_text[0]}"
                    end
                    # check if insert text is an indent (typically only with bullets) 
                    # normal indents create code block
                    if i["attributes"]["indent"] != nil
                        insert_text[0] = "#{"   " + insert_text[0]}"
                    end
                end
                # puts insert_text

                # joins strings in insert_text array to one string and formats \n
                markdown_string += insert_text.join("").gsub("\n", "\\n")

                # variables for creating hash from json (return content from slab)
                item_string = ""
                index += 1
            else
                item_string += "#{item},"  
            end
        end
        return markdown_string, post_title
    end
end