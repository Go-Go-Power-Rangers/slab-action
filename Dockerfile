FROM ruby:3.0

COPY scripts /scripts

RUN chmod +x /scripts/main.rb

RUN timedatectl

ENTRYPOINT ["ruby", "/scripts/main.rb"]
