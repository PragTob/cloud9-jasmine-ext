// Generated by CoffeeScript 1.3.3
(function() {

  define(function(require, exports, module) {
    var DIVIDER_POSITION, MENU_ENTRY_POSITION, PANEL_POSITION, PATH_TO_JASMINE, ParsedMessage, TEST_ERROR_MESSAGE, TEST_ERROR_STATUS, TEST_PASS_STATUS, TEST_RESET_MESSAGE, TEST_RESET_STATUS, commands, css, ext, filelist, fs, ide, markup, menus, noderunner, panels;
    ide = require('core/ide');
    ext = require('core/ext');
    menus = require('ext/menus/menus');
    noderunner = require('ext/noderunner/noderunner');
    commands = require('ext/commands/commands');
    fs = require('ext/filesystem/filesystem');
    panels = require('ext/panels/panels');
    markup = require('text!ext/jasmine/jasmine.xml');
    filelist = require('ext/filelist/filelist');
    css = require('text!ext/jasmine/jasmine.css');
    ParsedMessage = require('ext/jasmine/lib/parsedMessage').ParsedMessage;
    DIVIDER_POSITION = 2300;
    MENU_ENTRY_POSITION = 2400;
    PANEL_POSITION = 10000;
    PATH_TO_JASMINE = 'node_modules/jasmine-node/lib/jasmine-node/cli.js';
    TEST_PASS_STATUS = 1;
    TEST_ERROR_STATUS = 0;
    TEST_RESET_STATUS = -1;
    TEST_ERROR_MESSAGE = 'FAILED: ';
    TEST_RESET_MESSAGE = 'No Result';
    return module.exports = ext.register('ext/jasmine/jasmine', {
      name: 'Jasmine',
      dev: 'Tobias Metzke, Tobias Pfeiffer',
      type: ext.GENERAL,
      alone: true,
      commands: {
        'jasmine': {
          hint: 'Run your tests with jasmine!'
        }
      },
      hotitems: {},
      markup: markup,
      nodes: [],
      css: css,
      hook: function() {
        var _self;
        apf.importCssString(css);
        _self = this;
        this.markupInsertionPoint = colLeft;
        panels.register(this, {
          position: PANEL_POSITION,
          caption: "Jasmine",
          "class": "jasmine"
        });
        commands.addCommand({
          name: "jasmine",
          hint: "run your specs with jasmine",
          bindKey: {
            mac: "Command-J",
            win: "Ctrl-J"
          },
          exec: function() {
            return _self.jasmine();
          }
        });
        this.nodes.push(menus.addItemByPath("Edit/~", new apf.divider(), DIVIDER_POSITION));
        this.nodes.push(menus.addItemByPath("Edit/Jasmine", new apf.item({
          command: "jasmine"
        }), MENU_ENTRY_POSITION));
        this.hotitems['jasmine'] = [this.nodes[1]];
        this.projectName = this.getProjectName();
        return this.socketListenerRegistered = false;
      },
      init: function() {
        var _this = this;
        this.initButtons();
        this.panel = windowTestPanelJasmine;
        this.nodes.push(windowTestPanelJasmine, menuRunSettingsJasmine, stateTestRunJasmine);
        dataGridTestProjectJasmine.addEventListener('afterchoose', function() {
          var selection;
          selection = dataGridTestProjectJasmine.getSelection();
          if (_this.containsRepo(selection)) {
            selection = null;
          }
          return _this.run(selection);
        });
        ide.dispatchEvent("init.jasmine");
        this.setRepoName();
        this.initFilelist();
        return this.addFileSaveListener();
      },
      containsRepo: function(array) {
        if (array != null) {
          return array.some(function(node) {
            return node.tagName === 'repo';
          });
        } else {
          return true;
        }
      },
      initButtons: function() {
        return windowTestPanelJasmine.$ext.setAttribute("class", windowTestPanelJasmine.$ext.getAttribute("class") + " testpanel");
      },
      setRepoName: function() {
        this.projectName = this.getProjectName();
        return modelTestsJasmine.data.childNodes[1].setAttribute('name', this.projectName);
      },
      initFilelist: function() {
        var _this = this;
        return filelist.getFileList(false, function(data, state) {
          var sanitizedData, specs;
          if (state !== apf.SUCCESS) {
            return;
          }
          sanitizedData = data.replace(/^\./gm, "");
          sanitizedData = sanitizedData.replace(/^\/node_modules\/.*/gm, "");
          specs = sanitizedData.match(/^.*\.spec\.(js|coffee)$/gm);
          if (specs != null) {
            return _this.addFiles(specs, modelTestsJasmine.queryNode("repo[1]"));
          }
        });
      },
      addFiles: function(specs, parent) {
        var xmlFiles;
        xmlFiles = "";
        specs.each(function(spec) {
          return xmlFiles += "<file path='" + apf.escapeXML(ide.davPrefix + spec) + "' name='" + apf.escapeXML(spec.split("/").pop()) + "' type='jasmine' />";
        });
        return modelTestsJasmine.insert("<files>" + xmlFiles + "</files>", {
          insertPoint: parent
        });
      },
      addFileSaveListener: function() {
        var _this = this;
        return ide.addEventListener('afterfilesave', function(event) {
          var name;
          name = _this.getFileNameFrom(event.node);
          return _this.runJasmine([name]);
        });
      },
      getProjectName: function() {
        return document.title.slice(0, document.title.indexOf('-') - 1);
      },
      show: function() {
        if ((navbar.current != null) && (navbar.current !== this)) {
          navbar.current.disable();
        } else {
          return;
        }
        panels.initPanel(this);
        return this.enable();
      },
      enable: function() {
        return this.nodes.each(function(item) {
          if (item.enable) {
            return item.enable();
          }
        });
      },
      disable: function() {
        return this.nodes.each(function(item) {
          if (item.disable) {
            return item.disable();
          }
        });
      },
      destroy: function() {
        this.nodes.each(function(item) {
          return item.destroy(true, true);
        });
        this.nodes = [];
        return panels.unregister(this);
      },
      getFileNameFrom: function(node) {
        var fullFileName, name;
        fullFileName = node.getAttribute('name');
        return name = fullFileName.slice(0, fullFileName.indexOf('.'));
      },
      run: function(nodes) {
        if (this.containsRepo(nodes)) {
          return this.runJasmine();
        } else {
          return this.runSelectedNodes(nodes);
        }
      },
      runJasmine: function(fileNames) {
        var args;
        args = ['--coffee', '--verbose', 'spec/'];
        this.testFiles = this.filesToTest(fileNames);
        if ((fileNames != null) && fileNames.length > 0) {
          args.push('--match', this.matchString(fileNames));
        }
        return this.executeJasmineOnNodeRunner(args);
      },
      filesToTest: function(fileNames) {
        var fileNodes, node, testFiles, _i, _len;
        if (fileNames != null) {
          return fileNames;
        } else {
          fileNodes = this.findFileNodesFor();
          testFiles = [];
          for (_i = 0, _len = fileNodes.length; _i < _len; _i++) {
            node = fileNodes[_i];
            testFiles.push(this.getFileNameFrom(node));
          }
          return testFiles;
        }
      },
      matchString: function(fileNames) {
        var matchString;
        matchString = '(';
        fileNames.each(function(name) {
          return matchString += name + '|';
        });
        return matchString = matchString.slice(0, -1) + ')' + "\\.";
      },
      executeJasmineOnNodeRunner: function(args) {
        this.message = '';
        if (!this.socketListenerRegistered) {
          this.registerSocketListener();
        }
        return noderunner.run(PATH_TO_JASMINE, args, false);
      },
      runSelectedNodes: function(nodes) {
        var fileNames,
          _this = this;
        fileNames = [];
        nodes.each(function(node) {
          var name;
          name = _this.getFileNameFrom(node);
          return fileNames.push(name);
        });
        return this.runJasmine(fileNames);
      },
      registerSocketListener: function() {
        var _this = this;
        this.message = '';
        ide.addEventListener('socketMessage', function(event) {
          if (_this.panelInitialized()) {
            if (event.message.type === 'node-data') {
              _this.assembleMessage(event.message.data);
            }
            if (event.message.type === 'node-exit') {
              return _this.parseMessage();
            }
          }
        });
        return this.socketListenerRegistered = true;
      },
      assembleMessage: function(message) {
        return this.message += message;
      },
      panelInitialized: function() {
        return typeof dataGridTestProjectJasmine !== "undefined" && dataGridTestProjectJasmine !== null;
      },
      parseMessage: function() {
        var parsedMessage;
        this.resetTestStatus();
        parsedMessage = new ParsedMessage(this.message, this.projectName);
        console.log(parsedMessage);
        if (parsedMessage.isSyntaxError) {
          return this.handleSyntaxError();
        } else if (parsedMessage.isAllGreen) {
          return this.allSpecsPass();
        } else if (parsedMessage.isFailure) {
          return this.handleFailures(parsedMessage);
        } else {
          return console.log('Unknown message');
        }
      },
      handleSyntaxError: function() {
        return console.log('Syntax error during the execution of the tests');
      },
      allSpecsPass: function() {
        return this.specsPass(this.testFiles);
      },
      handleFailures: function(parsedMessage) {
        var _this = this;
        parsedMessage.specs.each(function(spec) {
          if (spec.passed === false) {
            return _this.specFails(spec);
          }
        });
        return this.testsPassExcept(parsedMessage.failedTests);
      },
      specFails: function(spec) {
        var failedNode, _i, _len, _ref, _results;
        _ref = this.findFileNodesFor([spec.specName]);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          failedNode = _ref[_i];
          _results.push(this.setTestFailed(failedNode, spec));
        }
        return _results;
      },
      setTestFailed: function(failedNode, spec) {
        var error;
        try {
          error = {};
          spec.children.each(function(block) {
            if (block.passed === false) {
              return error = block.error;
            }
          });
          apf.xmldb.setAttribute(failedNode, "errorFilePath", ide.davPrefix + error.filePath);
          apf.xmldb.setAttribute(failedNode, "errorLine", error.line);
          apf.xmldb.setAttribute(failedNode, "errorColumn", error.column);
          this.appendBlocksFor(failedNode, spec);
          return this.setTestStatus(failedNode, TEST_ERROR_STATUS, TEST_ERROR_MESSAGE + error.message);
        } catch (error) {
          return console.log("Caught bad error '" + error + "' and didn't enjoy it. Related to the damn helper specs.");
        }
      },
      setTestStatus: function(node, status, msg) {
        try {
          apf.xmldb.setAttribute(node, "status", status);
          return apf.xmldb.setAttribute(node, "status-message", msg || "");
        } catch (error) {
          return console.log("Caught bad error '" + error + "' and didn't enjoy it. Related to the damn helper specs.");
        }
      },
      testsPassExcept: function(failedTests) {
        var pass, passedTests, _i, _len, _ref;
        passedTests = [];
        _ref = this.testFiles;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pass = _ref[_i];
          if (!failedTests.contains(pass)) {
            passedTests.push(pass);
          }
        }
        return this.specsPass(passedTests);
      },
      specsPass: function(fileList) {
        var file, _i, _len, _ref, _results;
        _ref = this.findFileNodesFor(fileList);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          file = _ref[_i];
          _results.push(this.setTestStatus(file, TEST_PASS_STATUS));
        }
        return _results;
      },
      appendBlocksFor: function(node, spec) {
        var block, blockNode, ownerDocument, _i, _len, _ref;
        ownerDocument = node.ownerDocument;
        _ref = spec.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          block = _ref[_i];
          blockNode = ownerDocument.createElement("failed");
          blockNode.setAttribute("name", "" + block.type + ": " + block.message);
          if (block.passed) {
            this.setTestStatus(blockNode, TEST_PASS_STATUS);
          } else {
            this.setTestStatus(blockNode, TEST_ERROR_STATUS, TEST_ERROR_MESSAGE + block.error.message);
          }
          node.appendChild(blockNode);
        }
        return dataGridTestProjectJasmine.reload();
      },
      resetTestStatus: function() {
        var file, _i, _len, _ref;
        _ref = this.findFileNodesFor();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          file = _ref[_i];
          this.setTestStatus(file, TEST_RESET_STATUS, TEST_RESET_MESSAGE);
          this.removeBlocksFor(file);
        }
        return dataGridTestProjectJasmine.reload();
      },
      removeBlocksFor: function(node) {
        var _results;
        if (node.children != null) {
          _results = [];
          while (node.childNodes.length >= 1) {
            _results.push(node.removeChild(node.firstChild));
          }
          return _results;
        }
      },
      findFileNodesFor: function(testFiles) {
        var file, files, model, _i, _len;
        model = dataGridTestProjectJasmine.$model;
        files = [];
        if (testFiles != null) {
          for (_i = 0, _len = testFiles.length; _i < _len; _i++) {
            file = testFiles[_i];
            file = file.charAt(0).toLowerCase() + file.substring(1);
            files.push(model.queryNode("//node()[@name='" + file + ".spec.coffee']"));
          }
        } else {
          files = model.queryNode("repo[@name='" + this.projectName + "']").children;
        }
        return files;
      },
      goToCoffee: function(node) {
        var error;
        error = {
          filePath: node.getAttribute('errorFilePath'),
          line: node.getAttribute('errorLine'),
          column: node.getAttribute('errorColumn')
        };
        ide.dispatchEvent('openfile', {
          doc: ide.createDocument(require("ext/filesystem/filesystem").createFileNodeFromPath(error.filePath))
        });
        return ide.dispatchEvent('livecoffee_show_file', {
          line: error.line
        });
      },
      jasmine: function() {
        return this.runJasmine();
      }
    });
  });

}).call(this);
