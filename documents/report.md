
# Docker and Salt
Niina Villman  
*Haaga-Helia University of Applied Science*  
*Palvelinten hallinta -course 2019: http://terokarvinen.com/*  

## What is Docker?

- Container platform
- Creates containers which makes it easy to tranfer an application to another environment
- Containers are isolated environments on the host machine


## What is Dockerfile?

- Dockerfile containes instructions for creating an image
- by running the image you can create a container

More information about Docker can be found here:  
https://www.docker.com/why-docker  
https://docker-hy.github.io/part1/  

## Environment

Master:
Droplet on DigitalOcean
OS: Ubuntu 18.04.2 LTS
Intel(R) Xeon(R) CPU E5-2650L v3 @ 1.80GHz
salt version 2017.7.4 (Nitrogen)

Minion:
 Lenovo Thinkpad x250
VirtualBox and Ubuntu 18.04
salt version 2017.7.4
Intel(R) Core(TM) i5-5300U CPU @ 2.30GHz


![](https://github.com/niinavi/salt/blob/master/documents/pics/docker-salt-environment.png)

# Install Docker

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

# Create Dockerfile


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


# Automate installation

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

These were the lines that worked to build image with Saltstack:

 
```
build_image:
  docker_image.present:
    - build: /docker/.
    - tag: apachekontti
    - dockerfile: Dockerfile

```

![](https://github.com/niinavi/salt/blob/master/documents/pics/build_image_docker_success.JPG)

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
I first tried to specify the IP to be localhost, but I got an error that the IP is incorrect. So I just left the ports and it worked. The first port number is the host port and the second container port.

![](https://github.com/niinavi/salt/blob/master/documents/pics/min-kontti-running.JPG)

At this moment the salt state was following:

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

create_directory:
  file.directory:
    - name: /docker/

/docker/Dockerfile:
  file.managed:
    - source: salt://docker/Dockerfile

/docker/index.html:
  file.managed:
    - source: salt://docker/index.html

build_image:
  docker_image.present:
    - build: /docker/.
    - tag: apachekontti
    - dockerfile: Dockerfile

run_container:
  docker_container.running:
    - name: kontti
    - image: build_image
    - port_bindings:
      - 80:80
```

------

# Continue automating and create two containers


However, I wanted to separate the installation of Docker and building and running the container. It would make it possible to create more containers using the same installation state. So the next thing was to try to install and run two Apache2 containers on minion. 

 - one salt state for Docker installation
 - one salt state for building and running a containter
 - change top.sls

I encountered a few errors while trying to build another image and run it. Following error appeared when I had the the same ports defined on the second Apache2 container. This error was better explained when I tried to run Docker container manually on minion. Then I got the exact information about the port that is not available anymore. I needed to change the host port.
```
----------
          ID: run_container2
    Function: docker_container.running
        Name: kontti2
      Result: False
     Comment: Failed to start container 'kontti2': 'Unable to perform start: 500 Server Error: Internal Server Error for url: http+docker://localunixsocket/v1.39/containers/kontti2/start'
     Started: 16:02:22.201252
    Duration: 1065.494 ms
     Changes:
```
```
          ID: run_container2
    Function: docker_container.running
        Name: kontti2
      Result: False
     Comment: Failed to pull apacheimage2: Unable to perform pull: 404 Client Error: Not Found for url: http+docker://localunixsocket/v1.39/images/create?tag=latest&fromImage=apacheimage2
     Started: 20:46:04.347707
    Duration: 2722.205 ms
     Changes:
```

Above error means that I had a wrong name specified on the run function.

![](https://github.com/niinavi/salt/blob/master/documents/pics/bothcontainers-minion.JPG)

# Results

I succesfully installed two containers on minion. However, the salt state that I created is not working perfectly.

I need to run the command ```sudo salt 'dockerminion' state.highstate``` twice. The first time it doesn't build the images and run the containers. The second time the salt state works and the images are created and the containers are running.

I found the problem when I run the salt state on the new and clean minion. I had tried the salt state with one minion and only removed Docker containers and Docker-ce, Docker-ce-cli and containerd.io. I had forgotten to remove pip and docker-py so maybe they have something to do with the error..

I tried to run the salt state with and without pip and docker-py on new minion. 

```
install-python-pip:
  pkg.installed:
    - pkgs:
      - python-pip
      - python3
      - python3-pip

docker-py:
  pip.installed:
    - require:
      - pkg: install-python-pip
```

**1. try:**
```
Summary for dockerminion7
-------------
Succeeded: 12 (changed=12)
Failed:     4
-------------
```

```
"  Comment: State 'docker_container.running' was not found in SLS 'apache2-cont2'
              Reason: 'docker_container' __virtual__ returned False: 'docker.version' is not available."
```

**2. try:**
```
Summary for dockerminion7
-------------
Succeeded: 16 (changed=6)
Failed:     0
-------------
```

I uncommented install-python-pip and docker-py. The failed results was expected since I read they are needed.

**1. try**
```
Summary for dockerminion8
-------------
Succeeded: 10 (changed=10)
Failed:     4
-------------
```
```
  ID: run_container2
    Function: docker_container.running
        Name: kontti2
      Result: False
     Comment: State 'docker_container.running' was not found in SLS 'apache2-cont2'
              Reason: 'docker_container' __virtual__ returned False: 'docker.version' is not available.
     Changes:
```
**2. try**
```
Summary for dockerminion8
-------------
Succeeded: 10 (changed=2)
Failed:     4
-------------
```
```
 ID: run_container2
    Function: docker_container.running
        Name: kontti2
      Result: False
     Comment: State 'docker_container.running' was not found in SLS 'apache2-cont2'
              Reason: 'docker_container' __virtual__ returned False: 'docker.version' is not available.
     Changes:
```



# The final salt state
The salt state can be found here:
https://github.com/niinavi/salt/tree/master/srv

-------

sources:
https://docker-hy.github.io/part1/
https://opsnotice.xyz/docker-with-saltstack/  
https://docs.saltstack.com/en/latest/ref/states/all/salt.states.docker_container.html#salt.states.docker_container.run  
https://github.com/saltstack/salt/issues/40048  
https://stackoverflow.com/questions/33270253/salt-dockerng-virtual-returned-false  
https://docs.saltstack.com/en/latest/ref/states/all/salt.states.docker_image.html  
https://medium.com/faun/how-to-build-a-docker-container-from-scratch-docker-basics-a-must-know-395cba82897b   
https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/  
https://docs.saltstack.com/en/latest/ref/states/all/salt.states.pkgrepo.html  
https://docs.docker.com/install/linux/docker-ce/ubuntu/


