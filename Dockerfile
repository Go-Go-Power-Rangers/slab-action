FROM ruby:3.0

COPY scripts /scripts

RUN chmod +x /scripts/main.rb

RUN cat /etc/timezone

RUN date

ENTRYPOINT ["ruby", "/scripts/main.rb"]
