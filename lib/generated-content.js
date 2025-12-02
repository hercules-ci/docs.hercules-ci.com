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

// Simple recursive directory walker for reading files from Nix store paths
async function walkDir(dir, fileList = []) {
  const entries = await fsp.readdir(dir, { withFileTypes: true })
  for (const entry of entries) {
    const fullPath = ospath.join(dir, entry.name)
    if (entry.isDirectory()) {
      await walkDir(fullPath, fileList)
    } else if (entry.isFile() && !entry.name.endsWith('~')) {
      fileList.push(fullPath)
    }
  }
  return fileList
}

async function srcFs(cwd, origin) {
  const logger = require('@antora/logger')("generated-content-srcfs")

  try {
    const filePaths = await walkDir(cwd)
    const files = []
    const relpathStart = cwd.length + 1

    for (const abspath of filePaths) {
      try {
        const stat = await fsp.stat(abspath)
        const contents = await fsp.readFile(abspath)
        const relpath = abspath.substr(relpathStart)
        files.push(new File({
          path: posixify ? posixify(relpath) : relpath,
          contents,
          stat,
          src: { abspath }
        }))
      } catch (err) {
        logger.warn("Failed to read file " + abspath + ": " + err.message)
      }
    }

    return files
  } catch (err) {
    logger.error("srcFs error: " + err.message)
    throw err
  }
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
  logger.info("Generated " + generatedFiles.length + " files from Nix build")
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
