PARAMS=(
    'id=132871&vt=1277&dept=101064006'
    'id=132277&vt=1277&dept=101001072'
    'id=132234&vt=1277&dept=101008002'
    'id=132268&vt=1277&dept=101064007'
    'id=132980&vt=1277&dept=101064008'
    'id=132472&vt=1277&dept=101064001'
    'id=132726&vt=1277&dept=101064002'
    'id=132723&vt=1277&dept=101064004'
    'id=132694&vt=1277&dept=101064003'
)

LOCATIONS=(
    "Emmanuel Baptist Church"
    "Valley Specialty Center"
    "Valley Health Center Tully"
    "Valley Health Center East Valley"
    "Gilroy High School"
    "Mountain View Community Center"
    "Fairgrounds Expo Hall"
    "Levis Stadium"
    "Berger Auditorium"
)

for i in "${!PARAMS[@]}"; do 
  curl -s 'https://schedulecare.sccgov.org/MyChartPRD/OpenScheduling/OpenScheduling/GetOpeningsForProvider?noCache=0.07578891619903505' \
  -H "__RequestVerificationToken: $TOKEN" \
  -H "Cookie: $COOKIE" \
  --data-raw "${PARAMS[$i]}&view=grouped" \
  | jq -cr --arg location "${LOCATIONS[$i]}" \
  --arg link "https://schedulecare.sccgov.org/mychartprd/SignupAndSchedule/EmbeddedSchedule?${PARAMS[$i]}" \
  ".AllDays[]? | .DisplayDate as \$date | .Slots[]? | \"INSERT INTO appointments VALUES ('\(\$location)','\(\$link)','\(\$date)','\(.StartTimeISO)');\"" >> queries.txt
done

echo "# Available appointments:" > README.md
echo >> README.md

if [ ! -s queries.txt ]; then
  echo "No appointments available. Check back in a few hours." >> README.md
  rm -f queries.txt
  exit 0
fi

sqlite3 appointments.db 'CREATE TABLE appointments (location TEXT, link TEXT, date TEXT, time TEXT);'
cat queries.txt | sqlite3 appointments.db

echo "Available appointments:" > README.md
echo >> README.md

sqlite3 -cmd '.separator ", "' appointments.db 'with data as (select "* [" || location || "](" || link || ")" as location, date, count(*) || " slots" as count from appointments group by 1, 2) select location, group_concat(date || " (" || count || ")", "; ") from data group by location;' >> README.md

rm -f appointments.db queries.txt

MESSAGE=$(cat README.md)
PAYLOAD=$(jq -n --arg content "$MESSAGE" '{embeds: [{"description": $content}]}')

curl -i -XPOST "$DISCORD_WEBHOOK" \
-H "Content-Type: application/json" \
-d "$PAYLOAD"

curl -i -XPOST "$DISCORD_WEBHOOK_TWO" \
-H "Content-Type: application/json" \
-d "$PAYLOAD"

curl -i -XPOST "$DISCORD_WEBHOOK_THREE" \
-H "Content-Type: application/json" \
-d "$PAYLOAD"

### Post an issue if there are appointments on the 15th.
if matches_filter=$(cat README.md | grep "April 15"); then
  curl -XPOST "https://api.github.com/repos/Preetam/vaccine-availability/issues" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title": "April 15 appointments available", "body": "There are appointments available on the 15th. Check the README!"}'
fi
