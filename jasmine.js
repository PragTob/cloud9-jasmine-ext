// Generated by CoffeeScript 1.3.3
(function() {

  define(function(require, exports, module) {
    var DIVIDER_POSITION, MENU_ENTRY_POSITION, PANEL_POSITION, PATH_TO_JASMINE, TEST_ERROR_MESSAGE, TEST_ERROR_STATUS, TEST_PASS_STATUS, TEST_RESET_MESSAGE, TEST_RESET_STATUS, commands, css, ext, filelist, fs, ide, markup, menus, noderunner, panels;
    ide = require('core/ide');
    ext = require('core/ext');
    menus = require('ext/menus/menus');
    noderunner = require('ext/noderunner/noderunner');
    commands = require('ext/commands/commands');
    fs = require('ext/filesystem/filesystem');
    panels = require('ext/panels/panels');
    markup = require('text!ext/jasmine/jasmine.xml');
    filelist = require('ext/filelist/filelist');
    css = require("text!ext/jasmine/jasmine.css");
    DIVIDER_POSITION = 2300;
    MENU_ENTRY_POSITION = 2400;
    PANEL_POSITION = 10000;
    PATH_TO_JASMINE = 'node_modules/jasmine-node/lib/jasmine-node/cli.js';
    TEST_PASS_STATUS = 1;
    TEST_ERROR_STATUS = 0;
    TEST_RESET_STATUS = -1;
    TEST_ERROR_MESSAGE = 'FAILED';
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
        var _self,
          _this = this;
        this.initButtons();
        this.panel = windowTestPanelJasmine;
        this.nodes.push(windowTestPanelJasmine, menuRunSettingsJasmine, stateTestRunJasmine);
        _self = this;
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
        return this.afterFileSave();
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
        buttonTestRunJasmine.$ext.setAttribute("class", "light-dropdown");
        buttonTestStopJasmine.$ext.setAttribute("class", buttonTestStopJasmine.$ext.getAttribute("class") + " buttonTestStopJasmine");
        return windowTestPanelJasmine.$ext.setAttribute("class", windowTestPanelJasmine.$ext.getAttribute("class") + " testpanelJasmine");
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
          return _this.addFiles(specs, modelTestsJasmine.queryNode("repo[1]"));
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
      afterFileSave: function() {
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
        var args, fileNodes, matchString, node, _i, _len;
        if (fileNames != null) {
          this.testFiles = fileNames;
        } else {
          fileNodes = this.findFileNodesFor();
          this.testFiles = [];
          for (_i = 0, _len = fileNodes.length; _i < _len; _i++) {
            node = fileNodes[_i];
            this.testFiles.push(this.getFileNameFrom(node));
          }
        }
        args = ['--coffee', '--verbose', 'spec/'];
        if ((fileNames != null) && fileNames.length > 0) {
          matchString = '(';
          fileNames.each(function(name) {
            return matchString += name + '|';
          });
          matchString = matchString.slice(0, -1) + ')' + "\\.";
          args.push('--match', matchString);
        }
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
        var failureMessages;
        console.log(this.message);
        failureMessages = this.message.match(/Failures:\s([\s\S]*)\n+Finished/m);
        if (failureMessages != null) {
          this.resetTestStatus();
          return this.handleFailures(failureMessages);
        } else {
          return this.allSpecsPass();
        }
      },
      handleFailures: function(failureMessages) {
        var failedTests, failures,
          _this = this;
        failedTests = [];
        failures = failureMessages[1].split("\n\n");
        failures.each(function(failure) {
          var failedTestFile;
          failedTestFile = _this.parseFailure(failure);
          _this.specFails(failedTestFile);
          return failedTests.push(failedTestFile);
        });
        return this.testsPassedExcept(failedTests);
      },
      testsPassedExcept: function(failedTests) {
        var pass, passedTests, _i, _len, _ref;
        passedTests = [];
        _ref = this.testFiles;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pass = _ref[_i];
          if (!failedTests.contains(pass)) {
            passedTests.push(pass);
          }
        }
        console.log('failed tests');
        console.log(failedTests);
        console.log('passed tests');
        console.log(passedTests);
        return this.specsPass(passedTests);
      },
      parseFailure: function(failure) {
        var errorLine, matches, message, stacktrace;
        matches = failure.match(/Message:\s([\s\S]+?)Stacktrace:[\s\S]*?(at[\s\S]*)/m);
        message = matches[1];
        stacktrace = matches[2];
        errorLine = this.parseStackTrace(stacktrace);
        return errorLine.slice(errorLine.lastIndexOf('/') + 1, errorLine.indexOf('.'));
      },
      parseStackTrace: function(stacktrace) {
        var error, traces,
          _this = this;
        traces = stacktrace.split("\n");
        error = '';
        traces.each(function(trace) {
          if ((trace.indexOf('node_modules') === -1) && (trace.indexOf(_this.projectName) >= 0)) {
            error = trace.match(new RegExp(_this.projectName + '(.+)'))[1];
            error = error.slice(0, -1);
            return error;
          }
        });
        return error;
      },
      specFails: function(failedTest) {
        var failed, _i, _len, _ref, _results;
        _ref = this.findFileNodesFor([failedTest]);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          failed = _ref[_i];
          _results.push(this.setTestStatus(failed, TEST_ERROR_STATUS, TEST_ERROR_MESSAGE));
        }
        return _results;
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
      allSpecsPass: function() {
        this.resetTestStatus();
        return this.specsPass(this.testFiles);
      },
      resetTestStatus: function() {
        var file, _i, _len, _ref, _results;
        _ref = this.findFileNodesFor();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          file = _ref[_i];
          _results.push(this.setTestStatus(file, TEST_RESET_STATUS, TEST_RESET_MESSAGE));
        }
        return _results;
      },
      findFileNodesFor: function(testFiles) {
        var file, files, model, _i, _len;
        model = dataGridTestProjectJasmine.$model;
        files = [];
        if (testFiles != null) {
          for (_i = 0, _len = testFiles.length; _i < _len; _i++) {
            file = testFiles[_i];
            files.push(model.queryNode("//node()[@name='" + file + ".spec.coffee']"));
          }
        } else {
          files = model.queryNode("repo[@name='" + this.projectName + "']").children;
        }
        return files;
      },
      setTestStatus: function(node, status, msg) {
        apf.xmldb.setAttribute(node, "status", status);
        return apf.xmldb.setAttribute(node, "status-message", msg || "");
      },
      jasmine: function() {
        return this.runJasmine();
      }
    });
  });

}).call(this);
