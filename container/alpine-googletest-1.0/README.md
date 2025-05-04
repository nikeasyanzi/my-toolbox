# Universal linter
This repository provides the following thins.
  
  * A **docker file** is to create a universal linter container image for code formatting and code analysis. 
  * A **pre-commit-config.yaml** as golden recipe for git pre-commit hook configuration. Currently, it supports **C, Python, Shell Script**

## How to use

+ Get the container image by following either one of the following steps.
  - Pull from docker hub
  - Use the dockerfile to build a container image. 

+ Customize a pre-commit-config.yaml for your repository.
  * Reference the pre-commit-config.yaml in this repository to generate a pre-commit-config.yaml for your project

+ Run the command to format and scan your code
```
docker run -it --rm -v $(pwd):/workdir  URL_TO_DOCKERHUB/alpine-googletest:1.0 run.sh YOUR_REPO_NAME
```

## Reference

https://github.com/srz-zumix/docker-googletest/blob/master/alpine/Dockerfile
