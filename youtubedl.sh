#!/bin/bash

if [ -z ${@} ] ; then
    set -- UUk0fGHsCEzGig-rSzkfCjMw UUc1ufNROdAxto9Fr0jnEE2Q UUpDl4WPpgvvOeZFpw4ewycA UU4AkVj-qnJxNtKuz3rkq16A UUcbf8wnyVJl631LAmAbo7nw
	echo "Using Default Playlists defined in youtubedl.sh"
fi

for i in ${@};
do
youtube-dl \
-i \
-o '/mnt/d/YouTube/%(uploader)s/%(title)s %(upload_date)s.%(ext)s' \
 --write-description --write-info-json --write-annotations --write-sub \
 --write-thumbnail --download-archive '/mnt/d/downloadedlist.txt' -r 2m \
 'https://www.youtube.com/playlist?list='"$i"
done
