'use strict'

/*
  This file contains a few functions that were vendored from
  antora revision 46335b300490465bc9e4e194a31ae8e67f45f7c5
  These are licensed under Mozilla Public License Version 2.0 terms.
  The terms are available at https://gitlab.com/antora/antora/-/blob/main/LICENSE

  The `build` and `register` functions do not come with a license yet.
  Contact support@hercules-ci.com if you're interested in making it
  release-worthy and picking a license.
*/

const File = require('./file')
const { execSync, execFileSync } = require('child_process');
const ospath = require('path')
const fs = require('fs')
const { promises: fsp } = fs
const { pipeline, Writable } = require('stream')
const globStream = require('glob-stream')
const CONTENT_SRC_GLOB = '**/*[!~]'
const CONTENT_SRC_OPTS = { follow: true, nomount: true, nosort: true, nounique: true, strict: false }
const forEach = (write) => new Writable({ objectMode: true, write })
const posixify = require('path').sep === '\\' ? (p) => p.replace(/\\/g, '/') : undefined
const logger = require('@antora/logger')("generated-content")
const invariably = { true: () => true, false: () => false, void: () => undefined, emptyArray: () => [] }

function readFilesFromWorktree(origin) {
  const startPath = origin.startPath
  const cwd = ospath.join(origin.worktree, startPath, '.') // . shaves off trailing slash
  return fsp.stat(cwd).then(
    (startPathStat) => {
      if (!startPathStat.isDirectory()) throw new Error(`the start path '${startPath}' is not a directory`)
      return srcFs(cwd, origin)
    },
    () => {
      throw new Error(`the start path '${startPath}' does not exist`)
    }
  )
}

function symlinkAwareStat(path_) {
  return fsp.lstat(path_).then((lstat) => {
    if (!lstat.isSymbolicLink()) return lstat
    return fsp.stat(path_).catch((statErr) =>
      fsp
        .readlink(path_)
        .catch(invariably.void)
        .then((symlink) => {
          throw Object.assign(statErr, { symlink })
        })
    )
  })
}

function srcFs(cwd, origin) {
  return new Promise((resolve, reject, cache = Object.create(null), files = [], relpathStart = cwd.length + 1) =>
    pipeline(
      globStream(CONTENT_SRC_GLOB, Object.assign({ cache, cwd }, CONTENT_SRC_OPTS)),
      forEach(({ path: abspathPosix }, _, done) => {
        if ((cache[abspathPosix] || {}).constructor === Array) return done() // detects some directories
        const abspath = posixify ? ospath.normalize(abspathPosix) : abspathPosix
        const relpath = abspath.substr(relpathStart)
        symlinkAwareStat(abspath).then(
          (stat) => {
            if (stat.isDirectory()) return done() // detects directories that slipped through cache check
            fsp.readFile(abspath).then(
              (contents) => {
                files.push(new File({ path: posixify ? posixify(relpath) : relpath, contents, stat, src: { abspath } }))
                done()
              },
              (readErr) => {
                const logObject = { file: { abspath, origin } }
                readErr.code === 'ENOENT'
                  ? logger.warn(logObject, `ENOENT: file or directory disappeared, ${readErr.syscall} ${relpath}`)
                  : logger.error(logObject, readErr.message.replace(`'${abspath}'`, relpath))
                done()
              }
            )
          },
          (statErr) => {
            const logObject = { file: { abspath, origin } }
            if (statErr.symlink) {
              logger.error(
                logObject,
                (statErr.code === 'ELOOP' ? 'ELOOP: symbolic link cycle, ' : 'ENOENT: broken symbolic link, ') +
                `${relpath} -> ${statErr.symlink}`
              )
            } else if (statErr.code === 'ENOENT') {
              logger.warn(logObject, `ENOENT: file or directory disappeared, ${statErr.syscall} ${relpath}`)
            } else {
              logger.error(logObject, statErr.message.replace(`'${abspath}'`, relpath))
            }
            done()
          }
        )
      }),
      (err) => (err ? reject(err) : resolve(files))
    )
  )
}


async function build({ logger, aggregate, origin }) {

  var flakeref
  if (origin.worktree) {
    flakeref = "git+file://" + origin.worktree
  }
  else {
    flakeref = "git+file://" + origin.gitdir + "?ref=refs/remotes/origin/" + origin.refname + "&rev=" + origin.refhash

    // Nix doesn't support cloning from a shallow repo as of yet, so we take
    // care of that.
    execSync(`
        if test "$(git rev-parse --is-shallow-repository)" == true; then
          git fetch origin --unshallow
        fi
      `, {
        stdio: "inherit",
        cwd: origin.gitdir,
        shell: "sh"
      }
    )
  }

  var storePath;
  logger.info("Running nix for aggregate " + aggregate.name)
  try {
    const output =
      execFileSync(
        "nix",
        ["build",
          "--no-link", "--print-out-paths", "--show-trace",
          flakeref + "#generated-antora-files"
        ],
        { encoding: 'utf8',
          stdio: ['inherit', 'pipe', 'inherit']
        }
      ).toString();
    storePath = output.replace(/[\n\r]/g, '');
  } catch (err) {
    // logger.error(err)
    throw "Could not build #generated-antora-files for the aggregate `" + aggregate.name + "`. Internal flakeref: " + flakeref
  }
  logger.info("storePath: " + storePath)
  var generatedFiles = await readFilesFromWorktree({ worktree: storePath, startPath: "" })
  aggregate.files.push(...generatedFiles)
}

module.exports.register = function ({ /* config */ }) {
  const logger = this.getLogger('generated-content')
  this
    .on('contentAggregated', async ({ /* playbook, siteAsciiDocConfig, siteCatalog, */ contentAggregate }) => {
      for (let a in contentAggregate) {
        let aggregate = contentAggregate[a]
        for (let o in aggregate.origins) {
          let origin = aggregate.origins[o]
          if (origin.descriptor.nix == true) {
            await build({ logger, aggregate, origin })
          }
        }
      }
    })
}
