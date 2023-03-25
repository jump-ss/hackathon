# Dockerfile

FROM ruby:3.1.2

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client espeak
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean

RUN mkdir /hackathon
WORKDIR /hackathon
COPY Gemfile /hackathon/Gemfile
COPY Gemfile.lock /hackathon/Gemfile.lock
RUN bundle install
COPY . /hackathon

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 5000

CMD ["rails", "server", "-b", "0.0.0.0"]
