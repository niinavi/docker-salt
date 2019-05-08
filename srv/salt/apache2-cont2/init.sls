
create_directory2:
  file.directory:
    - name: /apache2-cont2/

/apache2-cont2/Dockerfile:
  file.managed:
    - source: salt://apache2-cont2/Dockerfile

/apache2-cont2/index.html:
  file.managed:
    - source: salt://apache2-cont2/index.html

apachekontti2:
  docker_image.present:
    - build: /apache2-cont2/.
    - tag: apacheimage2
    - dockerfile: Dockerfile

run_container2:
  docker_container.running:
    - name: kontti2
    - image: apachekontti2
    - port_bindings:
      - 88:80
