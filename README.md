i have tried to copy over exactly what travis-hub and travis-worker are doing wrt amqp publishing/consuming.

interestingly, both producer and consumer pick up the connection correctly using this test script.

one difference is that in travis-worker we spin up 3 subscriptions in parallel.
