# Factorio Docker Image

```bash
docker pull tynril/factorio
docker run -it --rm --name factorio -p 34197:34197/udp \
	-e GDRIVE_REFRESH_TOKEN='<a Google Drive refresh token for the GDrive application>' \
	tynril/factorio
```
