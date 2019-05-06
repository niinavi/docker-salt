# Docker and Salt report


## What is Docker?


## What is Dockerfile?

## Salt State

I started creating salt state for Docker by first installing Docker manually. I followed instructions for manual installation for Docker from their [documentation](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

I had master installed on DigitalOcean and I installed minion on VirtualBox. I installed minion using a shell script that can be found [here](https://github.com/niinavi/salt/blob/master/srv/minion.sh). I accepted the salt-keys on master with command ``` sudo salt-key -A```

First I installed necessary packages (curl, ca-certificates etc) and tried if it worked. I run the salt command ``` sudo salt 'dockerminion' state.highstate```. I imported the docker key, added Docker repository and installed the packages.

This is the salt state that succesfully installed the Docker.

```
install_network_packages:
  pkg.installed:
   - pkgs:
      - curl
      - apt-transport-https
      - ca-certificates
      - gnupg-agent
      - software-properties-common


import-docker-key:
  cmd.run:
    - name: curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  sudo apt-key add -

add-docker-rep:
  cmd.run:
     - name: sudo add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

docker-packages:
  pkg.installed:
    - pkgs:
      - docker-ce
      - docker-ce-cli
      - containerd.io
```

![](https://github.com/niinavi/salt/blob/master/documents/pics/succeeded-docker-inst.JPG)

With following command, I tested if Docker runs correctly on minion.
```
sudo docker run hello-world
```

![](https://github.com/niinavi/salt/blob/master/documents/pics/docker-hello-world-testi.JPG)

-----------

I tried if I can create a different approach for the salt state and use package repositories instead of cmd.run command. I looked some information from here https://docs.saltstack.com/en/latest/ref/states/all/salt.states.pkgrepo.html.  I created a new directory /srv/salt/docker-pkg and add init.sls inside of it.
```
docker-repository:
  pkgrepo.managed:
    - humanname: Docker
    - name: deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable main
    - dist: stable
    - file: /etc/apt/sources.list.d/docker.list
    - gpgcheck: 1
    - key_url: https://download.docker.com/linux/ubuntu/gpg
    - require_in:
       - docker
```

And I created a top.sls
```
base:
  'dockermin':
    - docker-pkg
    - docker
```
Docker init.sls
```
install_network_packages:
  pkg.installed:
   - pkgs:
      - curl
      - apt-transport-https
      - ca-certificates
      - gnupg-agent
      - software-properties-common

docker-packages:
  pkg.installed:
    - pkgs:
      - docker-ce
      - docker-ce-cli
      - containerd.io
```
I uncommented apt-transport-https because I understood it is not needed while using this approach. However, I also tried with it but it didn't get any other results.


RESULTS
```
ID: docker-repository
    Function: pkgrepo.managed
        Name: deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable main
      Result: False
     Comment: Failed to configure repo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable main': E: The repository 'https://download.docker.com/linux/ubuntu stable Release' does not have a Release file.
```

I received this error and decided to see if I need to replace the "name" URL with something else. I tried to use package from here: https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/. I didn't get any better results so I decided to move on and continue with the working salt state.

--------

# Dockerfile


I created Dockerfile that creates a image for ubuntu and Apache2. I followed instructions here: https://medium.com/faun/how-to-build-a-docker-container-from-scratch-docker-basics-a-must-know-395cba82897b 

```
FROM ubuntu:18.04

RUN apt-get update && apt-get install -y apache2 && apt-get clean && rm -rf /var/li$

ENV APACHE_RUN_USER  www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR   /var/log/apache2
ENV APACHE_PID_FILE  /var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR   /var/run/apache2
ENV APACHE_LOCK_DIR  /var/lock/apache2
ENV APACHE_LOG_DIR   /var/log/apache2

RUN mkdir -p $APACHE_RUN_DIR
RUN mkdir -p $APACHE_LOCK_DIR
RUN mkdir -p $APACHE_LOG_DIR

COPY index.html /var/www/html

EXPOSE 80
CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]
```

I tried first locally to build image using the above Dockerfile. I had Dockerfile and index.html on the same folder and I run the command ```sudo docker build .``` I got good results.
```
succesfully built 74501ced4bb6
```
The name of the container is series of numbers and letters so I run the following command to name it: ``` sudo docker build -t apachekontti```.

I got the following error:
```
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.17.0.2. Set the 'ServerName' directive globally to supress this message
```

I need to specify the port. I run the following command: 
```
sudo docker run -p 80:80 apachekontti
```
I managed to make the docker container to work manually. Next thing is to create salt state for it. 

### Automate installation

I need to create a directory on minion where is Dockerfile and index.html. I added following lines to init.sls. 
```
create_directory:
  file.directory:
    - name: /docker/

/docker/Dockerfile:
  file.managed:
    - source: salt://docker/Dockerfile

/docker/index.html:
  file.managed:
    - source: salt://docker/index.html

```
I run the init.sls and succesfylly get the index.html and Dockerfile installed on minion. Next I needed to see if I can build an image using that Dockerfile.

I found some help from Saltstack documentation how to build image. https://docs.saltstack.com/en/latest/ref/states/all/salt.states.docker_image.html

I added following line into init.sls:
```
build_image:
  docker_image.present:
    - build: /docker/image
    - tag: apachekontti
    - dockerfile: Dockerfile.alternative

```

I got following error:
```
-
          ID: build_image
    Function: docker_image.present
      Result: False
     Comment: State 'docker_image.present' was not found in SLS 'docker'
              Reason: 'docker_image' __virtual__ returned False: 'docker.version' is not available.
     Changes:
```

This error is received because I don't have pip and docker-python installed. 

I add the following line to init.sls and hope the best.
https://stackoverflow.com/questions/33270253/salt-dockerng-virtual-returned-false
```
python-pip:
  pkg.installed

docker-py:
  pip.installed:
    - require:
      - pkg: python-pip
```

This didn't succeed and I got a new error to look at. Python-pip didn't get installed.

```
 ID: docker-py
    Function: pip.installed
      Result: False
     Comment: An importable Python 2 pip module is required but could not be found on your system. This usually means that the system's pip package is not installed properly.
     Started: 13:00:27.824419
    Duration: 3.753 ms
     Changes:
```

For the pip.installed I will need python2. I got help from here: https://github.com/saltstack/salt/issues/40048

```
install-python-pip:
  pkg.installed:
    - pkgs:
      - python-pip
      - python3
      - python3-pip
    - reload_modules: true

docker-py:
  pip.installed:
    - require:
      - pkg: install-python-pip
```
I wonder was it after all only about python3..
The following error was received because I had accidentally left the Dockerfile.alternative.

```
 ID: build_image
    Function: docker_image.present
      Result: False
     Comment: Encountered error building /docker/. as build_image:latest: 500 Server Error: Internal Server Error for url: http+docker://localunixsocket/v1.39/build?t=build_image%3Alatest&q=False&nocache=False&rm=True&forcerm=False&pull=False&dockerfile=Dockerfile.alternative
     Started: 14:22:20.002164
    Duration: 177.362 ms
     Changes:
```

These were the working lines to build image with Saltstack:

 
```
build_image:
  docker_image.present:
    - build: /docker/.
    - tag: apachekontti
    - dockerfile: Dockerfile

```

The next thing was to run the container from the image. 

Got some help from here:
https://docs.saltstack.com/en/latest/ref/states/all/salt.states.docker_container.html#salt.states.docker_container.run
```
run_container:
  docker_container.running:
    - name: kontti
    - image: build_image
    - port_bindings:
      - 80:80
```
I first tried to specify the IP to be localhost, but I got an error that the IP is incorrect. So I just left the ports and it worked. The first port number is the container port number and it will be mapped to the second port 80 on Docker host.

## The final salt state
The salt state can be found here:
https://github.com/niinavi/salt/tree/master/srv

-------

sources:

https://opsnotice.xyz/docker-with-saltstack/  
https://docs.saltstack.com/en/latest/ref/states/all/salt.states.docker_container.html#salt.states.docker_container.run  
https://github.com/saltstack/salt/issues/40048  
https://stackoverflow.com/questions/33270253/salt-dockerng-virtual-returned-false  
https://docs.saltstack.com/en/latest/ref/states/all/salt.states.docker_image.html  
https://medium.com/faun/how-to-build-a-docker-container-from-scratch-docker-basics-a-must-know-395cba82897b   
https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/  
https://docs.saltstack.com/en/latest/ref/states/all/salt.states.pkgrepo.html  
https://docs.docker.com/install/linux/docker-ce/ubuntu/


