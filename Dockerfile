FROM ruby:3.0

COPY test.rb /test.rb

RUN chmod +x test.rb

ENTRYPOINT ["ruby", "/test.rb"]
