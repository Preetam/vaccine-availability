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

rm appointments.db queries.txt

for i in "${!PARAMS[@]}"; do 
  curl -s 'https://schedulecare.sccgov.org/MyChartPRD/OpenScheduling/OpenScheduling/GetOpeningsForProvider?noCache=0.07578891619903505' \
  -H "__RequestVerificationToken: $TOKEN" \
  -H "Cookie: $COOKIE" \
  --data-raw "${PARAMS[$i]}&view=grouped&start=2021-04-12" \
  | jq -cr --arg location "${LOCATIONS[$i]}" ".AllDays[]? | .DisplayDate as \$date | .Slots[]? | \"INSERT INTO appointments VALUES ('\(\$location)','\(\$date)','\(.StartTimeISO)');\"" >> queries.txt
done

sqlite3 appointments.db 'CREATE TABLE appointments (location TEXT, date TEXT, time TEXT);'
cat queries.txt | sqlite3 appointments.db

echo "Available appointments:"

sqlite3 -cmd '.width 40 0 0' -column -header appointments.db 'select location, date, count(*) as count from appointments group by 1, 2;'

rm appointments.db queries.txt
