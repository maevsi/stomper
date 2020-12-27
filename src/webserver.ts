const finalhandler = require('finalhandler')
const http = require('http')
const path = require('path')
const serveStatic = require('serve-static')

const serve = serveStatic(path.join(__dirname, 'assets'))

const server = http.createServer(function onRequest (req: any, res: any) {
  serve(req, res, finalhandler(req, res))
})

export function startWebserver (port: number) {
  console.log(`Starting webserver on port ${port}.`)
  server.listen(port)
}
