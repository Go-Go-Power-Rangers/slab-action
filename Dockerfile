FROM ruby:3.0

COPY scripts /scripts

RUN ls

RUN chmod +x /scripts/check_post_exists.rb

ENTRYPOINT ["ruby", "./scripts/check_post_exists.rb"]
