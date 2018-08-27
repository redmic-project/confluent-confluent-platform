#!/bin/bash

if [[ "${#}" -lt 1 ]]; then
	echo "You must provide at least one Confluent-Connect node address (hostname:port)"
	exit 1
fi

done=false
addrs="${*}"

while [[ "${done}" = false ]]; do
	for addr in ${addrs}; do
		echo "Trying to connect to host: ${addr}"
		curl -q "http://${addr}/connectors" >& /dev/null

		if [[ "${?}" -eq 0 ]]; then
			done=true

			echo "Connected, creating connectors at host: ${addr}"

			curl -s -X POST -H "Content-Type: application/json" --data \
				"{\"name\": \"jdbc-ais-last-position-sink\", \"config\": {\"name\":\"jdbc-ais-last-position-sink\", \"connector.class\":\"io.confluent.connect.jdbc.JdbcSinkConnector\", \"tasks.max\":\"1\", \"topics\":\"realtime.tracking.vessels\", \"connection.url\": \"jdbc:postgresql://ais-db:5432/ais\", \"connection.password\": \"${POSTGRES_PASS}\", \"connection.user\": \"${POSTGRES_USER}\", \"table.name.format\": \"last_position\", \"auto.evolve\": \"true\", \"insert.mode\": \"upsert\", \"pk.mode\": \"record_value\", \"pk.fields\": \"mmsi\"}}" \
				"http://${addr}/connectors" >& /dev/null

			curl -s -X POST -H "Content-Type: application/json" --data \
				"{\"name\": \"jdbc-ais-last-week-sink\", \"config\": {\"name\":\"jdbc-ais-last-week-sink\", \"connector.class\":\"io.confluent.connect.jdbc.JdbcSinkConnector\", \"tasks.max\":\"1\", \"topics\":\"realtime.tracking.vessels\", \"connection.url\": \"jdbc:postgresql://ais-db:5432/ais\", \"connection.password\": \"${POSTGRES_PASS}\", \"connection.user\": \"${POSTGRES_USER}\", \"table.name.format\": \"last_week\", \"auto.evolve\": \"true\", \"insert.mode\": \"upsert\", \"pk.mode\": \"record_value\", \"pk.fields\": \"mmsi,tstamp\"}}" \
				"http://${addr}/connectors" >& /dev/null
			break
		fi

		sleep 5
	done
done
