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

curl -XPOST "https://api.github.com/repos/Preetam/vaccine-availability/issues" \
	-H "Authorization: Bearer $GITHUB_TOKEN" \
	-H "Content-Type: application/json" \
	-d '{"title": "TEST", "body": "Test issue. Please ignore."}'

rm -f appointments.db queries.txt

for i in "${!PARAMS[@]}"; do 
  curl -s 'https://schedulecare.sccgov.org/MyChartPRD/OpenScheduling/OpenScheduling/GetOpeningsForProvider?noCache=0.07578891619903505' \
  -H "__RequestVerificationToken: $TOKEN" \
  -H "Cookie: $COOKIE" \
  --data-raw "${PARAMS[$i]}&view=grouped&start=2021-04-15" \
  | jq -cr --arg location "${LOCATIONS[$i]}" ".AllDays[]? | .DisplayDate as \$date | .Slots[]? | \"INSERT INTO appointments VALUES ('\(\$location)','\(\$date)','\(.StartTimeISO)');\"" >> queries.txt
done

if [ ! -s queries.txt ]; then
  echo "No appointments starting on the 15th"
  exit 0
fi

sqlite3 appointments.db 'CREATE TABLE appointments (location TEXT, date TEXT, time TEXT);'
cat queries.txt | sqlite3 appointments.db

echo "# Available appointments starting April 15:" > README.md
echo '```' >> README.md
sqlite3 -cmd '.width 32 0 0' -column appointments.db 'select location, date, count(*) as count from appointments group by 1, 2;' >> README.md
echo '```' >> README.md

MESSAGE=$(cat README.md)
PAYLOAD=$(jq -n --arg content "$MESSAGE" '{content: $content}')
curl -i -XPOST "$DISCORD_WEBHOOK" \
-H "Content-Type: application/json" \
-d "$PAYLOAD"
