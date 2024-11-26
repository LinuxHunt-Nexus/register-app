FROM tomcat:latest
RUN cp -R  /usr/local/tomcat/webapps.dist/*  /usr/local/tomcat/webapps
COPY /webapp/target/*.war /usr/local/tomcat/webapps
#FROM tomcat:latest
#RUN rm -f /usr/local/tomcat/webapps/webapp.war
#COPY ./webapp/target/webapp.war /usr/local/tomcat/webapps/


