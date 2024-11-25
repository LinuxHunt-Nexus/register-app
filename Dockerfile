#FROM tomcat:latest
#RUN cp -R  /usr/local/tomcat/webapps.dist/*  /usr/local/tomcat/webapps
#COPY /home/ubuntu/workspace/register-app-ci/webapp/target/webapp.war /usr/local/tomcat/webapps/
FROM tomcat:latest
# remove the webapp.war if it's already there
RUN rm -f /usr/local/tomcat/webapps/webapp.war
COPY ./webapp/target/webapp.war /usr/local/tomcat/webapps/


