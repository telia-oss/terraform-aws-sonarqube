FROM sonarqube:7.9-community
USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -L https://github.com/telia-oss/aws-env/releases/download/v0.3.0/aws-env-linux-amd64 > /usr/local/bin/aws-env && \
      echo f80addd4adf9aa8d4ecf1b16de402ba4  /usr/local/bin/aws-env | md5sum -c && \
      chmod +x /usr/local/bin/aws-env
RUN curl -L https://binaries.sonarsource.com/Distribution/sonar-auth-github-plugin/sonar-auth-github-plugin-1.5.0.870.jar > /opt/sonarqube/extensions/plugins/sonar-auth-github-plugin-1.5.0.870.jar && \
      echo 59d98c94277e5faa8377ba521e440eba  /opt/sonarqube/extensions/plugins/sonar-auth-github-plugin-1.5.0.870.jar | md5sum -c

RUN chown -R sonarqube:sonarqube "$SONARQUBE_HOME"
COPY post-init.sh start.sh start-with-params.sh entrypoint.sh ./

USER sonarqube
ENTRYPOINT ["./entrypoint.sh"]