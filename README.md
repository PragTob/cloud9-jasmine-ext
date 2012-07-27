Jasmine Test Panel for Cloud9
==================

The Jasmine Test Panel for Cloud9 is aimed at making testing with Jasmine and CoffeeScript easier in the [Cloud9](c9.io) easier. It provides a test panel from which tests can be executed.

Installation
------------
This extension currently only works with self-hosted copies of Cloud9. Third-party extensions are not supported on c9.io. As cloud9 is constantly evolving and changing APIs etc. we can not guarantee that the plug-in works with the current master of Cloud9. Therefore the safest way to use this plug-in is to clone the version of Cloud9 at [our fork](https://github.com/PragTob/cloud9), as this is the version we are developing the add-on with. You can refer to the README of this repository for installation instructions.

The most common way to install cloud9 would be (provided, that nodejs and npm are already installed):
    npm install -g sm
    git clone git://github.com/PragTob/cloud9.git
    cd cloud9
    sm install
    
Then you need to clone our plugin, which you can do by:
    git clone git://github.com/PragTob/cloud9-jasmine-ext.git cloud9/plugins-client/ext.jasmine

Open the `Tools -> Extension Manager` window, put the path to the extension in
    ext/jasmine/jasmine

Click add.

Please note that this plug-in only fully works in conjunction with our fork of the [livecoffee plug-in](https://github.com/PragTob/cloud9-livecoffee-ext), which is needed in order to access the full functionality.

Cheers,
Tobi²
