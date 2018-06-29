# Confluent platform

Este proyecto contiene la configuración y despliegue de la plataforma Confluent, para usar **Apache Kafka**.

## Descripción

Se compone de una serie de ficheros *docker-compose*, organizados por niveles:

* zookeeper: Lanza servicios de **Apache Zookeeper** para coordinar a los otros servicios (brokers y workers).
* kafka: Lanza servicios de **Apache Kafka**, que actuan como brokers para comunicar unos servicios con otros.
* workers: Lanza servicios que explotan la red de Kafka y sirven de apoyo a otros servicios.
* uis: Lanza servicios que permiten gestionar visualmente la red de Kafka y sus servicios.

Es importante, en un despliegue desde cero, seguir el orden por niveles expuesto en el listado anterior. Dentro de cada nivel, se puede seguir el orden que se prefiera, no debería haber ningún problema.
Los despliegues, tanto en desarrollo como en producción, se han de ejecutar manualmente (aunque se preparan las tareas automáticamente para ello) desde este repositorio en GitLab.

Hay un caso especial dentro del nivel de *workers*, el servicio **connector-supplier**. Se trata de una imagen propia, encargada de registrar *conectores* en el servicio *connect* de Confluent.
Para definir nuevos conectores, han de añadirse al directorio *scripts* de este repositorio.

Se pueden configurar muchos parámetros de la plataforma a base de variables de entorno. Cada nivel cuenta con un fichero *.env* que define valores por defecto para dichas variables, pero se pueden asignar desde fuera (por ejemplo, desde *.gitlab-ci.yml*).

## Comandos útiles

A continuación, una serie de comandos que pueden resultar de interés como ejemplo.

### Gestión de conectores

```
// primero, entrar a contenedor con acceso a servicio de connect

// crear conector hacia S3
curl -s -X POST -H "Content-Type: application/json" --data \
'{"name": "s3-sink", "config": {"connector.class": "io.confluent.connect.s3.S3SinkConnector", "tasks.max": "1", "topics": "s3_topic", "s3.region": "eu-west-1", "s3.bucket.name": "mediastorage.redmicdev", "s3.part.size": "5242880", "flush.size": "3", "storage.class": "io.confluent.connect.s3.storage.S3Storage", "format.class": "io.confluent.connect.s3.format.avro.AvroFormat", "schema.generator.class": "io.confluent.connect.storage.hive.schema.DefaultSchemaGenerator", "partitioner.class": "io.confluent.connect.storage.partitioner.DefaultPartitioner", "schema.compatibility": "FULL", "name": "s3-sink"}}' \
http://$CONNECT_HOST:8083/connectors

// consultar estado de conector
curl -s -X GET http://$CONNECT_HOST:8083/connectors/s3-sink/status

// eliminar conector
curl -X DELETE $CONNECT_HOST:8083/connectors/s3-sink
```

### Pruebas con esquemas Avro y registro

```
// primero, entrar a contenedor con acceso a servicio de schema-registry

// publicar nuevo esquema 'prueba' al registro
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" \
--data '{"schema": "{\"type\":\"record\",\"name\":\"MessageWrapper\",\"namespace\":\"es.redmic.brokerlib.dto\",\"fields\":[{\"name\":\"content\",\"type\":{\"type\":\"record\",\"name\":\"Object\",\"namespace\":\"java.lang\",\"fields\":[]}},{\"name\":\"userId\",\"type\":\"string\"},{\"name\":\"actionId\",\"type\":[\"string\",\"null\"]}]}"}' \
http://schema-registry:8081/subjects/prueba/versions

// obtener esquemas presentes en el registro
curl -X GET http://schema-registry:8081/subjects
```

Se puede producir y consumir mensajes con las utilidades de Confluent:

```
// primero, entrar a contenedor de schema-registry

// producir mensajes en formato Avro desde consola
kafka-avro-console-producer --broker-list kf-1:9092 \
--property schema.registry.url=http://schema-registry:8081 \
--topic s3_topic --property value.schema=\
'{"type":"record","name":"myrecord","fields":[{"name":"f1","type":"string"}]}'

// valores de ejemplo para poner en consola, tras ejecutar el comando anterior
{"f1": "value1"}
{"f1": "value2"}
{"f1": "value3"}

// consumir mensajes en formato avro desde consola - ojo, falla magic byte!
kafka-avro-console-consumer --bootstrap-server kf-1:9092 \
--property schema.registry.url=http://schema-registry:8081 \
--topic realtime.tracking.vessels
```

O usar la utilidad *kafkacat*:

```
// primero, entrar a contenedor con acceso a servicio de schema-registry ...
kafkacat -P -b kf-1:9092,kf-2:9092,kf-3:9092 -t prueba -K %

// ... o usar esta imagen Docker unida a la red donde está schema-registry
docker run --network kafka-net -it ryane/kafkacat kafkacat -P -b kf-1:9092,kf-2:9092,kf-3:9092 -t prueba -K %

// valores de ejemplo para poner en consola, tras ejecutar uno de los comandos anteriores
clave%valor1
clave%valor2
otraclave%otrovalor

// se puede consumir desde contenedor con acceso a servicio de schema-registry ...
kafkacat -C -b kf-1:9092,kf-2:9092,kf-3:9092 -t prueba -K %

// ... o desde esta imagen Docker unida a la red donde está schema-registry
docker run --network kafka-net -it ryane/kafkacat kafkacat -C -b kf-1:9092,kf-2:9092,kf-3:9092 -t prueba -K %
```
