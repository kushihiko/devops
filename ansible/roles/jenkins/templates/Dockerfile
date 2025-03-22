FROM jenkins/ssh-agent:latest-alpine-jdk21

RUN apk add --no-cache --update \
    docker \
    openrc \
    && rc-update add docker boot

RUN addgroup jenkins docker

CMD ["sh", "-c", "dockerd & exec setup-sshd"]