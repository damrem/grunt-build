module.exports = (grunt) ->
  
  path = require 'path'
  fs = require 'fs'

  initialize: ->
    if @data.list
      @outFiles = []

  completedFile: (args) ->
    if @data.list
      @outFiles.push args.file

  completedBuild: ->
    if @data.list
      outFiles = for file in @outFiles
        path.relative(@destination,file).replace(/\\/g, "\/")
      listFile = "#{@destination}/#{@data.list.fileName}"
      fs.writeFileSync listFile, "#{@data.list.set} = ['#{outFiles.join('\',\'')}']", "utf-8"
      grunt.log.debug 'Written list file: ' + listFile