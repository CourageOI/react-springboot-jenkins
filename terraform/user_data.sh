#!/bin/bash
            sudo apt-get update
            sudo apt install -y docker.io
            docker run -p 8080:8080 -p 50000:50000 -d \
            -v jenkins_home:/var/jenkins_home \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v $(which docker):/usr/bin/docker jenkins/jenkins:lts