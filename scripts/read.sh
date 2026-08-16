#!/bin/bash

while read -r linie
do
    read -r level message <<< "$linie"

    echo "Sending [$level] $message"

    response=$(curl -s -X POST http://localhost:3000/logs \
        -H "Content-Type: application/json" \
        -d "{\"level\":\"$level\",\"message\":\"$message\"}")

    echo "$(date "+%Y-%m-%d %H:%M:%S") -> $level -> $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/logs) -> $response" >> script.log

done < logs.txt