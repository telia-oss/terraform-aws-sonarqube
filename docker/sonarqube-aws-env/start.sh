#!/bin/bash
java -jar lib/sonar-application-$SONAR_VERSION.jar \
  -Dsonar.log.console=true \
  -Dsonar.jdbc.username="$SONARQUBE_JDBC_USERNAME" \
  -Dsonar.jdbc.password="$SONARQUBE_JDBC_PASSWORD" \
  -Dsonar.jdbc.url="$SONARQUBE_JDBC_URL" \
  -Dsonar.core.serverBaseURL="$SONAR_BASE_URL" \
  -Dsonar.auth.github.enabled="$SONAR_GITHUB_AUTH_ENABLED"
  -Dsonar.auth.github.clientId.secured="$SONAR_GITHUB_CLIENT_ID" \
  -Dsonar.auth.github.clientSecret.secured="$SONARQUBE_GITHUB_CLIENT_SECRET" \
  -Dsonar.auth.github.organizations="$SONARQUBE_GITHUB_ORGANIZATIONS" \
  -Dsonar.web.javaAdditionalOpts="$SONARQUBE_WEB_JVM_OPTS -Djava.security.egd=file:/dev/./urandom" \
  "$@"