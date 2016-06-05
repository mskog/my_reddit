FROM ruby:2.3.1

RUN apt-get update
RUN apt-get install -y git
RUN apt-get update && apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor

RUN gem install bundler --no-rdoc --no-ri

ENV BUNDLE_PATH /bundle

ADD Gemfile /code/Gemfile
ADD start.sh /code/start.sh

WORKDIR /code

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080
CMD /usr/bin/supervisord
