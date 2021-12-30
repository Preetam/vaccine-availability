# COVID-19 Vaccine availability

_**Note:**_ This repository is archived.

This repo has an automated workflow and script to find COVID-19 vaccine appointment slots in Santa Clara county. It updates this README file and publishes to Discord.

### How it works

The script (in `script.sh`) scrapes `https://schedulecare.sccgov.org` for several locations, parses out the JSON response, inserts into a SQLite table, then prints the output to the README file.

The same README is used as the Discord message content.

### Screenshot

![image](https://user-images.githubusercontent.com/379404/147778333-8a6c399b-82f6-4008-b2d0-d87e2eb715e9.png)
