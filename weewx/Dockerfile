ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apt-get update \
    && apt-get install -y sqlite3 wget sudo \
         python-configobj python-cheetah python-pil python-usb python-setuptools \
         supervisor tzdata jq

RUN wget http://weewx.com/downloads/released_versions/weewx-3.9.2.tar.gz -O /tmp/weewx.tgz && \
      cd /tmp && \
      tar zxvf /tmp/weewx.tgz && \
      cd weewx-* ; ./setup.py build ; ./setup.py install --no-prompt

RUN wget https://github.com/eclipse/paho.mqtt.python/archive/v1.4.0.tar.gz -O /tmp/mqtt.tgz && \
      cd /tmp && \
      tar zxvf /tmp/mqtt.tgz && \
      cd paho.mqtt.python-* ; sudo python setup.py build ; sudo python setup.py install

RUN wget http://lancet.mit.edu/mwall/projects/weather/releases/weewx-mqtt-0.19.tgz -O /tmp/weewx-mqtt.tgz && \
      cd /tmp && \
      /home/weewx/bin/wee_extension --install weewx-mqtt.tgz

# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
