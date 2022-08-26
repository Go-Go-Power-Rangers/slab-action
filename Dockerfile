FROM ruby:3.0

COPY scripts /.

RUN chmod +x /scripts

ENTRYPOINT ["ruby", "./scripts/check_post_exists.rb"]
