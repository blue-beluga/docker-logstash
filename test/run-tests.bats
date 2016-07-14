#!/usr/bin/env bats

setup() {
  docker history "$REGISTRY/$REPOSITORY:$TAG" >/dev/null 2>&1
  export IMG="$REGISTRY/$REPOSITORY:$TAG"
  export LOGSTASH_VERSION=$LOGSTASH_VERSION
  export MAX_SIZE=2000000
}

teardown() {
  PID=$(pgrep java) || return 0
  pkill java
}

wait_for_message () {
  local message="$1"
  local logfile="$2"
  local timeout="$3"
  timeout -t "$timeout" -- sh -c "while ! grep -q '$message' '$logfile' ; do sleep 0.1; done"
  grep "$message" "$logfile"
}

wait_for_logstash () {
  /run-logstash.sh --verbose > $BATS_TEST_DIRNAME/logstash.log &
  wait_for_message "startup completed" "$BATS_TEST_DIRNAME/logstash.log" 400
}

@test "checking image size" {
  run docker run --rm --entrypoint=/bin/sh $IMG -c "[[ \"\$(du -d0 / 2>/dev/null | awk '{print \$1; print > \"/dev/stderr\"}')\" -lt \"$MAX_SIZE\" ]]"
  [ $status -eq 0 ]
}

@test "It should install logstash $LOGSTASH_VERSION" {
  run /run-logstash.sh --version
  [[ "$output" =~ "logstash $LOGSTASH_VERSION" ]]
}

@test "It should listen over HTTP on port 80 for POSTs" {
  LOGSTASH_OUTPUT_CONFIG="stdout { codec => rubydebug }" wait_for_logstash
  run curl -XPOST http://localhost --data 'PING'
  run curl -XPUT http://localhost --data 'PONG'

  run wait_for_message "PING" "$BATS_TEST_DIRNAME/logstash.log" 5
  [ "$status" -eq "0" ]

  run wait_for_message "PONG" "$BATS_TEST_DIRNAME/logstash.log" 5
  [ "$status" -eq "1" ]
}

@test "It should be configurable through LOGSTASH_OUTPUT_CONFIG" {
  LOGSTASH_OUTPUT_CONFIG="file {path => '$BATS_TEST_DIRNAME/aptible.log' flush_interval => 0}" wait_for_logstash
  run curl -XPOST http://localhost --data 'PING'
  run wait_for_message "PING" "$BATS_TEST_DIRNAME/aptible.log" 5
  [ "$status" -eq "0" ]
}

@test "It should be configurable through LOGSTASH_FILTER_CONFIG" {
  LOGSTASH_OUTPUT_CONFIG="stdout { codec => rubydebug }" LOGSTASH_FILTER_CONFIG="if [message] == 'PONG' { drop {} }" wait_for_logstash
  run curl -XPOST http://localhost --data 'PING'
  run curl -XPOST http://localhost --data 'PONG'

  run wait_for_message "PING" "$BATS_TEST_DIRNAME/logstash.log" 5
  [ "$status" -eq "0" ]

  run wait_for_message "PONG" "$BATS_TEST_DIRNAME/logstash.log" 5
  [ "$status" -eq "1" ]
}
