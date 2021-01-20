import { MaevsiContact, MaevsiEvent, MaevsiInvitation } from './types'

const consola = require('consola')
const fs = require('fs')
const { DatabaseError, Pool } = require('pg')

const secretPostgresDbPath = '/run/secrets/postgres_db'
const secretPostgresRoleMaevsiTusdPasswordPath =
  '/run/secrets/postgres_role_maevsi-stomper_password'

const pool = new Pool({
  database: fs.existsSync(secretPostgresDbPath)
    ? fs.readFileSync(secretPostgresDbPath, 'utf-8')
    : undefined,
  host: 'postgres',
  password: fs.existsSync(secretPostgresRoleMaevsiTusdPasswordPath)
    ? fs.readFileSync(secretPostgresRoleMaevsiTusdPasswordPath, 'utf-8')
    : undefined,
  user: 'maevsi_stomper' // lgtm [js/hardcoded-credentials]
})

export function getContact (id: BigInt): Promise<MaevsiContact> {
  return new Promise((resolve, reject) => {
    pool.query(
      'SELECT * FROM maevsi.contact WHERE id = $1',
      [id],
      (err: typeof DatabaseError, queryRes: any) => {
        if (err) {
          consola.error(err)
          reject(err)
          return
        }

        if (!queryRes.rows[0]) {
          reject(new Error('Contact does not exist!'))
          return
        }

        resolve(queryRes.rows[0])
      }
    )
  })
}

export function getEvent (id: BigInt): Promise<MaevsiEvent> {
  return new Promise((resolve, reject) => {
    pool.query(
      'SELECT * FROM maevsi.event WHERE id = $1',
      [id],
      (err: typeof DatabaseError, queryRes: any) => {
        if (err) {
          reject(err)
          return
        }

        if (!queryRes.rows[0]) {
          reject(new Error('Event does not exist!'))
          return
        }

        resolve(queryRes.rows[0])
      }
    )
  })
}

export function getInvitation (id: BigInt): Promise<MaevsiInvitation> {
  return new Promise((resolve, reject) => {
    pool.query(
      'SELECT * FROM maevsi.invitation WHERE id = $1',
      [id],
      (err: typeof DatabaseError, queryRes: any) => {
        if (err) {
          reject(err)
          return
        }

        if (!queryRes.rows[0]) {
          reject(new Error('Invitation does not exist!'))
          return
        }

        resolve(queryRes.rows[0])
      }
    )
  })
}
