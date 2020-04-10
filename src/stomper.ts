import { Client } from '@stomp/stompjs'

import { trigger } from './aws'

import fs = require('fs')

Object.assign(global, { WebSocket: require('websocket').w3cwebsocket })

if (
  process.env.RABBITMQ_USER_FILE === undefined ||
  process.env.RABBITMQ_PASS_FILE === undefined
) {
  console.error('Missing environment variables!')
  process.exit(1)
}

const client = new Client({
  brokerURL: 'ws://rabbitmq:15674/ws',
  connectHeaders: {
    login: fs.readFileSync(process.env.RABBITMQ_USER_FILE, 'utf8'),
    passcode: fs.readFileSync(process.env.RABBITMQ_PASS_FILE, 'utf8')
  },
  debug: function (str) {
    if (process.env.NODE_ENV !== 'production') {
      console.log(str)
    }
  }
})

client.onConnect = function (frame) {
  client.subscribe('/queue/message_queue', function (message) {
    // JSON.parse(message.body)
    if (message.body) {
      console.log('got message with body ' + message.body)
    } else {
      console.log('got empty message')
    }

    trigger(message.body)

    message.ack()
  }, { ack: 'client' })
}

client.onStompError = function (frame) {
  console.log('Broker reported error: ' + frame.headers.message)
  console.log('Additional details: ' + frame.body)
  process.exit(1)
}

client.activate()
