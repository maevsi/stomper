import { Client } from '@stomp/stompjs'
import consola from 'consola'

import {
  sendAccountPasswordResetRequestMail,
  sendAccountRegistrationMail,
  sendEventInvitationMail,
} from './smtp'
import { startWebserver } from './webserver'

import fs = require('fs')
import websocket = require('websocket')

const WEBSERVER_PORT = 3000

Object.assign(global, { WebSocket: websocket.w3cwebsocket })

if (
  process.env.RABBITMQ_USER_FILE === undefined ||
  process.env.RABBITMQ_PASS_FILE === undefined
) {
  throw new Error('Missing environment variables!')
}

const client = new Client({
  brokerURL: 'ws://rabbitmq:15674/ws',
  connectHeaders: {
    login: fs.readFileSync(process.env.RABBITMQ_USER_FILE, 'utf8'),
    passcode: fs.readFileSync(process.env.RABBITMQ_PASS_FILE, 'utf8'),
  },
  debug: function (str) {
    if (process.env.NODE_ENV !== 'production') {
      consola.log(str)
    }
  },
})

client.onConnect = function () {
  ;[
    {
      queueName: 'account_password_reset_request',
      function: sendAccountPasswordResetRequestMail,
    },
    {
      queueName: 'account_registration',
      function: sendAccountRegistrationMail,
    },
    { queueName: 'event_invitation', function: sendEventInvitationMail },
  ].forEach((queueToFunctionMapping) => {
    client.subscribe(
      `/queue/${queueToFunctionMapping.queueName}`,
      function (message) {
        if (!message.body) {
          consola.error('got empty message')
        }

        consola.log('got message with body ' + message.body)

        try {
          queueToFunctionMapping.function(JSON.parse(message.body))
          message.ack()
        } catch (e) {
          consola.error(e)
        }
      },
      { ack: 'client' },
    )
  })
}

client.onStompError = function (frame) {
  throw new Error(
    'Broker reported error: ' +
      frame.headers.message +
      '\nAdditional details: ' +
      frame.body,
  )
}

client.activate()

startWebserver(WEBSERVER_PORT)
