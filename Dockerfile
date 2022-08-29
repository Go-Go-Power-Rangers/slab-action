FROM ruby:3.0

COPY scripts /scripts

RUN ls

RUN ls scripts

RUN chmod +x /scripts/main.rb

ENTRYPOINT ["ruby", "/scripts/main.rb"]
