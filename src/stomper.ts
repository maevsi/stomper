import { Client } from '@stomp/stompjs'

import { sendAccountPasswordResetRequestMail, sendAccountRegisterMail, sendInvitationMail } from './smtp'
import { startWebserver } from './webserver'

const consola = require('consola')
const fs = require('fs')

const WEBSERVER_PORT = 3000

Object.assign(global, { WebSocket: require('websocket').w3cwebsocket })

if (
  process.env.RABBITMQ_USER_FILE === undefined ||
  process.env.RABBITMQ_PASS_FILE === undefined
) {
  consola.error('Missing environment variables!')
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
      consola.log(str)
    }
  }
})

client.onConnect = function (_frame) {
  [
    { queueName: 'account_password_reset_request', function: sendAccountPasswordResetRequestMail },
    { queueName: 'account_register', function: sendAccountRegisterMail },
    { queueName: 'invitation', function: sendInvitationMail }
  ].forEach((queueToFunctionMapping) => {
    client.subscribe(`/queue/${queueToFunctionMapping.queueName}`, function (message) {
      if (message.body) {
        consola.log('got message with body ' + message.body)
      } else {
        consola.log('got empty message')
      }

      try {
        queueToFunctionMapping.function(JSON.parse(message.body))
        message.ack()
      } catch (e) {
        consola.error(e)
      }
    }, { ack: 'client' })
  })
}

client.onStompError = function (frame) {
  consola.log('Broker reported error: ' + frame.headers.message)
  consola.log('Additional details: ' + frame.body)
  process.exit(1)
}

client.activate()

startWebserver(WEBSERVER_PORT)
