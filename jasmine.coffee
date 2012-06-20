define (require, exports, module) ->
  ide = require 'core/ide'
  ext = require 'core/ext'
  menus = require 'ext/menus/menus'
  noderunner = require 'ext/noderunner/noderunner'
  commands = require 'ext/commands/commands'
  fs = require 'ext/filesystem/filesystem'
  panels = require 'ext/panels/panels'

  DIVIDER_POSITION = 2300
  MENU_ENTRY_POSITION = 2400
  PANEL_POSITION = 10000

  return ext.register 'ext/jasmine/jasmine',
    name: 'Jasmine'
    dev: 'Tobias Metzke, Tobias Pfeiffer'
    type: ext.GENERAL
    alone: yes # TODO: Access to livecoffee?
    commands:
      'jasmine': hint: 'Run your tests with jasmine!'
    hotitems : {}
    nodes: []
    hook: () ->
      _self = @
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
      
      panels.register this, 
        position : PANEL_POSITION,
        caption: "Jasmine",
        "class": "testing"

    jasmine: ->
      console.log "Jasmine starts to run"
      noderunner.run('node_modules/jasmine-node/lib/jasmine-node/cli.js', ['--coffee', '-m "(itemStorage|server)\."', 'spec/' ], false)
