# Build stage
FROM maven:3.8.6-eclipse-temurin-17-alpine as builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Run stage
FROM eclipse-temurin:17-jdk-alpine
EXPOSE 8080
ENV APP_HOME /usr/src/app
COPY --from=builder /app/target/*.jar $APP_HOME/app.jar
WORKDIR $APP_HOME
CMD ["java", "-jar", "app.jar"]

