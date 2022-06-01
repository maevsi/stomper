// eslint-disable-next-line import/default
import stompJs from '@stomp/stompjs'
import consola from 'consola'
import fs from 'fs'
import websocket from 'websocket'

import {
  sendAccountPasswordResetRequestMail,
  sendAccountRegistrationMail,
  sendEventInvitationMail,
} from './smtp.js'

Object.assign(global, { WebSocket: websocket.w3cwebsocket })

if (
  process.env.RABBITMQ_USER_FILE === undefined ||
  process.env.RABBITMQ_PASS_FILE === undefined
) {
  throw new Error('Missing environment variables!')
}

const client = new stompJs.Client({
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
          const notification = JSON.parse(message.body)
          queueToFunctionMapping.function(
            notification.id,
            JSON.parse(notification.payload),
          )
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
