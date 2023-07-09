import { existsSync, readFileSync } from 'fs'

import pg from 'pg'

const secretPostgresDbPath = '/run/secrets/postgres_db'
const secretPostgresRoleMaevsiTusdPasswordPath =
  '/run/secrets/postgres_role_maevsi-stomper_password'

const pool = new pg.Pool({
  database: existsSync(secretPostgresDbPath)
    ? readFileSync(secretPostgresDbPath, 'utf-8')
    : undefined,
  host: 'postgres',
  password: existsSync(secretPostgresRoleMaevsiTusdPasswordPath)
    ? readFileSync(secretPostgresRoleMaevsiTusdPasswordPath, 'utf-8')
    : undefined,
  user: 'maevsi_stomper',
})

export const ack = (id: number, isAcknowledged = true) => {
  return new Promise((resolve, reject) => {
    pool.query(
      'SELECT maevsi.notification_acknowledge($1, $2)',
      [id, isAcknowledged],
      (err: unknown) => {
        if (err) {
          console.error(err)
          reject(err)
          return
        }

        resolve(true)
      },
    )
  })
}
