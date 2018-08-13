FROM teliaoss/docker-sonarqube:7.2.1

RUN curl -L https://github.com/telia-oss/aws-env/releases/download/v0.3.0/aws-env-linux-amd64 > /usr/local/bin/aws-env && \
      echo f80addd4adf9aa8d4ecf1b16de402ba4  /usr/local/bin/aws-env | md5sum -c && \
      chmod +x /usr/local/bin/aws-env

COPY start.sh start-with-params.sh entrypoint.sh ./
COPY sonar-auth-github-plugin-1.4.0.695.jar /opt/sonarqube/extensions/plugins/

ENTRYPOINT ["./entrypoint.sh"]