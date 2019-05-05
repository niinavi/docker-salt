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
