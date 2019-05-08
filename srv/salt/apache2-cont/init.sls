
create_directory:
  file.directory:
    - name: /apache2-cont/

/apache2-cont/Dockerfile:
  file.managed:
    - source: salt://apache2-cont/Dockerfile

/apache2-cont/index.html:
  file.managed:
    - source: salt://apache2-cont/index.html

apachekontti:
  docker_image.present:
    - build: /apache2-cont/.
    - tag: apacheimage
    - dockerfile: Dockerfile

run_container:
  docker_container.running:
    - name: kontti
    - image: apachekontti
    - port_bindings:
      - 80:80
