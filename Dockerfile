FROM ruby:3.0

COPY test.rb /test.rb

# RUN command 

ENTRYPOINT ["/test.rb"]