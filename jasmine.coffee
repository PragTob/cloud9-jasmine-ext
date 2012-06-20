define (require, exports, module) ->
  ide = require 'core/ide'
  ext = require 'core/ext'
  menus = require 'ext/menus/menus'
  noderunner = require 'ext/noderunner/noderunner'
  commands = require 'ext/commands/commands'
  fs = require 'ext/filesystem/filesystem'
  panels = require 'ext/panels/panels'
  markup = require 'text!ext/jasmine/jasmine.xml'
  filelist = require 'ext/filelist/filelist'

  DIVIDER_POSITION = 2300
  MENU_ENTRY_POSITION = 2400
  PANEL_POSITION = 10000

  module.exports = ext.register 'ext/jasmine/jasmine',
    name: 'Jasmine'
    dev: 'Tobias Metzke, Tobias Pfeiffer'
    type: ext.GENERAL
    alone: yes # TODO: Access to livecoffee?
    commands:
      'jasmine': hint: 'Run your tests with jasmine!'
    hotitems : {}
    markup: markup
    nodes: []
    hook: () ->
      _self = @
      
      @markupInsertionPoint = colLeft
      panels.register this, 
        position : PANEL_POSITION,
        caption: "Jasmine",
        "class": "testing"
      
      commands.addCommand(
        name: "jasmine"
        hint: "run your specs with jasmine"
        bindKey:
          mac: "Command-J"
          win: "Ctrl-J"
        exec: -> _self.jasmine()
      )
      @nodes.push menus.addItemByPath("Edit/~", new apf.divider(), DIVIDER_POSITION)
      @nodes.push menus.addItemByPath("Edit/Jasmine", new apf.item({command: "jasmine"}), MENU_ENTRY_POSITION)

      @hotitems['jasmine'] = [@nodes[1]]
      
    init: ->
      btnTestRun.$ext.setAttribute("class", "light-dropdown")
      btnTestStop.$ext.setAttribute("class", btnTestStop.$ext.getAttribute("class") + " btnTestStop")
      winTestPanel.$ext.setAttribute("class", winTestPanel.$ext.getAttribute("class") + " testpanel")

      _self = @
      
      @panel = winTestPanel
      @nodes.push(winTestPanel, mnuRunSettings, stTestRun)
      
      ide.dispatchEvent "init.jasmine"
      console.log "after init.jasmine"
      @initFilelist()
      
    initFilelist: ->
      console.log "initFilelist"
      filelist.getFileList false, (data, state) =>
        return if (state != apf.SUCCESS)
        sanitizedData = data.replace(/^\./gm, "")
        sanitizedData = sanitizedData.replace(/^\/node_modules\/.*/gm, "")
        specs = sanitizedData.match(/^.*\.spec\.(js|coffee)$/gm)
        @addFiles(specs, mdlTests.queryNode("repo[1]"))
    
    addFiles: (specs, parent) -> 
      console.log "addFiles"
      xmlFiles = ""
      specs.each (spec) ->
        xmlFiles += "<file path='" +
              apf.escapeXML(ide.davPrefix + spec) +
              "' name='" + apf.escapeXML(spec.split("/").pop()) + 
              "' type='jasmine' />"
      
      console.log "xmlFiles"        
      console.log xmlFiles
      mdlTests.insert "<files>" + xmlFiles + "</files>", {insertPoint : parent}
      
    show: ->
      if (navbar.current?) && (navbar.current != this)
        navbar.current.disable()
      else
        return
      
      panels.initPanel(@)
      @enable()
      
    enable: ->
      @nodes.each (item) ->
        item.enable() if item.enable
        
    disable: ->
      @nodes.each (item) ->
        item.disable() if item.disable
        
    destroy: ->
      # stop
      
      @nodes.each (item) -> item.destroy true, true
      @nodes = []
      
      panels.unregister(@)
      
    run: (nodes) ->
      console.log "noddeesss"
      console.log nodes
      fileNames = "("
      nodes.each (node) ->
        name = node.getAttribute('name')
        name = name[0...name.indexOf('.')]
        fileNames += name + '|'
      
      fileNames = fileNames[0...-1] + ')'
      noderunner.run('node_modules/jasmine-node/lib/jasmine-node/cli.js', ['--coffee', '-m', "#{fileNames}\\.", 'spec/' ], false)
      
        
        

    jasmine: ->
      console.log "Jasmine starts to run"
      noderunner.run('node_modules/jasmine-node/lib/jasmine-node/cli.js', ['--coffee', '-m', "(itemStorage|server)\\.", 'spec/' ], false)
