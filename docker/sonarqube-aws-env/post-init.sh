#!/bin/bash
health=$(curl -sL -w "%{http_code}\n" http://localhost:9000/api/system/status -o /dev/null)
while [[ $health -ne "200" ]]; do
    sleep 300
    health=$(curl -sL -w "%{http_code}\\n" http://localhost:9000/api/system/status -o /dev/null)
done
curl -u admin:admin -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "key=sonar.core.serverBaseURL&value=${SONARQUBE_BASE_URL}" http://localhost:9000/api/settings/set
curl -u admin:admin -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "key=sonar.auth.github.enabled&value=${SONARQUBE_GITHUB_AUTH_ENABLED}" http://localhost:9000/api/settings/set
curl -u admin:admin -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "key=sonar.auth.github.clientId.secured&value=${SONARQUBE_GITHUB_CLIENT_ID}" http://localhost:9000/api/settings/set
curl -u admin:admin -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "key=sonar.auth.github.clientSecret.secured&value=${SONARQUBE_GITHUB_CLIENT_SECRET}" http://localhost:9000/api/settings/set
curl -u admin:admin -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "key=sonar.auth.github.organizations&values=${SONARQUBE_GITHUB_ORGANIZATIONS}" http://localhost:9000/api/settings/set
curl -u admin:admin -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "login=${SONARQUBE_ADMIN_USERNAME}&name=Admin&password=${SONARQUBE_ADMIN_PASSWORD}&password_confirmation=${SONARQUBE_ADMIN_PASSWORD}" http://localhost:9000/api/users/create &&
    curl -u admin:admin -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "name=sonar-administrators&login=${SONARQUBE_ADMIN_USERNAME}" http://localhost:9000/api/user_groups/add_user &&
    curl -u "${SONARQUBE_ADMIN_USERNAME}":"${SONARQUBE_ADMIN_PASSWORD}" -H "Content-Type: application/x-www-form-urlencoded" -X POST -d "login=admin" http://localhost:9000/api/users/deactivate
