#!/bin/sh
#
# Kayhan Kaynar , Nisan 24, 2021
# Youtube List Downloader V2.0
# kayhan.kaynar@hotmail.com

trap bashtrap INT

PATH=$PATH:"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SOURCE=$(dirname "$0")
dropboxfolder="SarkilarBiziSoyler_KayhanKaynar"

Projectname="POLLPROD"
URL="https://www.youtube.com/playlist?list=PLk4iMx0kM9Mx5z-IMp9E9bL55jXNyr9_u"
temp="/tmp/$Projectname"
original="/mnt/ExtHDD/SARKILARBIZISOYLER"

startfile=$SOURCE/start.txt
files=$SOURCE/files.txt
links=$SOURCE/links.txt
notfoundfiles=$SOURCE/notfoundfiles.txt

start(){
mkdir $temp
youtube-dl -i -v --flat-playlist --skip-download --get-title --get-id "$URL" > $startfile
}

countvideoslocal(){
n=$(ls -lrt $original | wc -l)
n=$((n-1))
echo $n
}

countvideosonline(){
youtube-dl -i -v --flat-playlist --skip-download "$URL" | while read line
do
    case "$line" in
        *"Downloading video 1 of"* )
        videocount=$(echo $line | awk '{print $6}' )
        echo $videocount
        ;;
  esac
done
}

striplist(){
n=0
cat $startfile  | while read line
do
    case "$line" in
    * )
    n=$((n+1))
    if [  $(( n % 2 )) -eq "1" ]
        then
        file=$line
        echo "$line" >> $files
        else
        link=$line 
        echo "$line" >> $links
    fi
    ;;
  esac
done
}

iffiledownloaded() {
counter=0
cat files.txt  | while read line
do
    case "$line" in
    * )
    counter=$((counter+1))
    ls -lrt $original | grep "$line" > /dev/null
    status=$?
    if [ $status -eq 1 ]
        then
        echo "$counter"
    fi
    ;;
  esac
done > $notfoundfiles
}

downloadit(){
cat $notfoundfiles  | while read line
do
    case "$line" in
    * )
    youtube-dl --playlist-start $line --playlist-end $line -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0  -o  "$
temp/%(title)s.%(ext)s" $URL
    ;;
  esac
done
}


time(){
echo "$(date +%d).$(date +%m).$(date +%Y)  $(date +%H):$(date +%M)"
}

copydownloaded(){
iftempempty
cp $temp/* $original
}

dropboxupload(){
iftempempty
dropbox.sh upload $temp/* $dropboxfolder
}

iftempempty(){
    if [ -z "$(ls -A $temp)" ]; then
        echo "Yüklenecek herhangi bir dosya bulunamadı."
        rm $startfile $files $links $notfoundfiles
        rm -rf $temp
        time
        exit 0
    fi
}

bashtrap()
{
        check_part_files
        copydownloaded
        dropboxupload
        rm $startfile $files $links $notfoundfiles
        rm -rf $temp
        time
        echo "CTRL+C Detected! Youtube Downloads Sonlandırılıyor..."
        exit 0
}

check_part_files(){

if [ -z "$original" ]; then
find $original -type f -name "*.webm" -exec rm {} \;
find $original -type f -name "*.part" -exec rm {} \;
fi

if [ -z "$temp" ]; then         
find $temp -type f -name "*.webm" -exec rm {} \;
find $temp -type f -name "*.part" -exec rm {} \;
fi

}

time
check_part_files

echo "PROJECT: $Projectname"
echo "YOUTUBEDAKI SAYI: $(countvideosonline)"
echo "LOKALDELI SAYI: $(countvideoslocal)"

start
striplist
iffiledownloaded
downloadit
iftempempty
copydownloaded
dropboxupload
time

rm $startfile $files $links $notfoundfiles
rm -rf $temp

exit 0
