import { Client } from '@stomp/stompjs'

import { sendAccountPasswordResetRequestMail, sendAccountRegisterMail, sendInviteMail } from './aws'

const fs = require('fs')

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
  [
    { queueName: 'account_password_reset_request', function: sendAccountPasswordResetRequestMail },
    { queueName: 'account_register', function: sendAccountRegisterMail },
    { queueName: 'invite', function: sendInviteMail }
  ].forEach((queueToFunctionMapping) => {
    client.subscribe(`/queue/${queueToFunctionMapping.queueName}`, function (message) {
      if (message.body) {
        console.log('got message with body ' + message.body)
      } else {
        console.log('got empty message')
      }

      queueToFunctionMapping.function(JSON.parse(message.body))

      message.ack()
    }, { ack: 'client' })
  })
}

client.onStompError = function (frame) {
  console.log('Broker reported error: ' + frame.headers.message)
  console.log('Additional details: ' + frame.body)
  process.exit(1)
}

client.activate()
