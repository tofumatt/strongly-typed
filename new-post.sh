postname="$(date +'%Y')-$(date +'%m')-$(date +'%d')-$1"

echo ""
echo "✎ _posts/$postname.md"
echo ""

cp .new-post-template.md _posts/$postname.md
mkdir assets/article_images/$postname

perl -pi -e "s/POSTNAME/$postname/g" _posts/$postname.md
perl -pi -e "s/POSTTITLE/$1/g" _posts/$postname.md

atom _posts/$postname.md
