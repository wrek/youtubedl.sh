# youtubedl.sh
Script to help automate and simplify youtube-dl

This script will download some of the more interesting things to me if I don't supply it with a new playlist link/code.

When I find a playlist on YouTube I think I can learn something from, I'll archive the entire playlist into an archive for later reference.
Usually I download entire channels by pasting the playlist code for they're "Play All" link.

I do that like this:
./youtubedl.sh [playlist code from url] 
ie:
./youtubedl.sh UUTiL1q9YbrVam5nP2xzFTWQ

How to find the code:
Go to the youtube channel page you're interested in.
>> https://www.youtube.com/user/Suspicious0bservers/videos

Click on Videos
Click on Play All
The url is displayed: https://www.youtube.com/watch?v=ihNPcRxqlAA&list=UUTiL1q9YbrVam5nP2xzFTWQ&index=1
You want the bit after "list=" and before the next "&". A clever person will set up the script to detect the list=* & portion.

The script will then download the videos etc., to a location hard-coded in the script. It would be nice to have a config file to load these things from.

This script allows me to download all videos for any playlist I supply OR it will update all of the hard-coded example playlists.

Something I'd like to add is the ability to automatically save new playlists I send via command line into a file which it can then use to read new "defaults" to update.
youtubedl.sh [newplaylistcode] = adds this playlist to the top of the list in the playlists.txt file then it loads the file as an array and downloads those lists.
This way, I don't have to maintain anything.

So in the future, I hope this script will allow me a lot more configurability.
