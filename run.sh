# Requires docker. But Installing TinyOS and TOSSIM manually isn't required.

docker run -it --rm=true -v $(pwd):/app -w /app ucmercedandeslab/tinyos:tossim bash -c 'make micaz sim && python ./simulate.py'

