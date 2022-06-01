import consola from 'consola'

import fs from 'fs'
import pg from 'pg'

const secretPostgresDbPath = '/run/secrets/postgres_db'
const secretPostgresRoleMaevsiTusdPasswordPath =
  '/run/secrets/postgres_role_maevsi-stomper_password'

const pool = new pg.Pool({
  database: fs.existsSync(secretPostgresDbPath)
    ? fs.readFileSync(secretPostgresDbPath, 'utf-8')
    : undefined,
  host: 'postgres',
  password: fs.existsSync(secretPostgresRoleMaevsiTusdPasswordPath)
    ? fs.readFileSync(secretPostgresRoleMaevsiTusdPasswordPath, 'utf-8')
    : undefined,
  user: 'maevsi_stomper', // lgtm [js/hardcoded-credentials]
})

export function ack(id: number, isAcknowledged = true): Promise<unknown> {
  return new Promise((resolve, reject) => {
    pool.query(
      'SELECT maevsi.notification_acknowledge($1, $2)',
      [id, isAcknowledged],
      (err) => {
        if (err) {
          consola.error(err)
          reject(err)
          return
        }

        resolve(true)
      },
    )
  })
}
