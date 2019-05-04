# Docker and Salt report


## What is Docker?


## What is Dockerfile?

## Salt State

I started creating salt state for Docker by first installing Docker manually. I followed instructions for manual installation for Docker [here](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

This is the first salt state I created and it succesfully installed the Docker.

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
    - name: curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-$
import-docker-key2:
  cmd.run:
     - name: sudo add-apt-repository "deb [arch=amd64] https://download.docker.$docker-packages:
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


