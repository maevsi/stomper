import consola from 'consola'
import express from 'express'
import serveStatic from 'serve-static'

import path = require('path')

const app = express()

export function startWebserver(port: number): void {
  consola.log(`Starting webserver on port ${port}.`)
  app.use(serveStatic(path.join(__dirname, 'assets')))
  app.listen(port)
}
