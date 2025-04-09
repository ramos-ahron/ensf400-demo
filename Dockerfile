FROM gradle:7.6.1-jdk11 as build

WORKDIR /app
COPY . .
RUN gradle clean build -x test

FROM tomcat:9-jre11

# Remove default Tomcat applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the WAR file
COPY --from=build /app/build/libs/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]