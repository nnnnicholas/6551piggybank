// for testing tokenuri outputs

var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};

// node_modules/.pnpm/is-docker@2.2.1/node_modules/is-docker/index.js
var require_is_docker = __commonJS({
  "node_modules/.pnpm/is-docker@2.2.1/node_modules/is-docker/index.js"(exports, module2) {
    "use strict";
    var fs2 = require("fs");
    var isDocker;
    function hasDockerEnv() {
      try {
        fs2.statSync("/.dockerenv");
        return true;
      } catch (_) {
        return false;
      }
    }
    function hasDockerCGroup() {
      try {
        return fs2.readFileSync("/proc/self/cgroup", "utf8").includes("docker");
      } catch (_) {
        return false;
      }
    }
    module2.exports = () => {
      if (isDocker === void 0) {
        isDocker = hasDockerEnv() || hasDockerCGroup();
      }
      return isDocker;
    };
  }
});

// node_modules/.pnpm/is-wsl@2.2.0/node_modules/is-wsl/index.js
var require_is_wsl = __commonJS({
  "node_modules/.pnpm/is-wsl@2.2.0/node_modules/is-wsl/index.js"(exports, module2) {
    "use strict";
    var os = require("os");
    var fs2 = require("fs");
    var isDocker = require_is_docker();
    var isWsl = () => {
      if (process.platform !== "linux") {
        return false;
      }
      if (os.release().toLowerCase().includes("microsoft")) {
        if (isDocker()) {
          return false;
        }
        return true;
      }
      try {
        return fs2.readFileSync("/proc/version", "utf8").toLowerCase().includes("microsoft") ? !isDocker() : false;
      } catch (_) {
        return false;
      }
    };
    if (process.env.__IS_WSL_TEST__) {
      module2.exports = isWsl;
    } else {
      module2.exports = isWsl();
    }
  }
});

// node_modules/.pnpm/define-lazy-prop@2.0.0/node_modules/define-lazy-prop/index.js
var require_define_lazy_prop = __commonJS({
  "node_modules/.pnpm/define-lazy-prop@2.0.0/node_modules/define-lazy-prop/index.js"(exports, module2) {
    "use strict";
    module2.exports = (object, propertyName, fn) => {
      const define = (value) => Object.defineProperty(object, propertyName, { value, enumerable: true, writable: true });
      Object.defineProperty(object, propertyName, {
        configurable: true,
        enumerable: true,
        get() {
          const result = fn();
          define(result);
          return result;
        },
        set(value) {
          define(value);
        }
      });
      return object;
    };
  }
});

// node_modules/.pnpm/open@8.4.0/node_modules/open/index.js
var require_open = __commonJS({
  "node_modules/.pnpm/open@8.4.0/node_modules/open/index.js"(exports, module2) {
    var path = require("path");
    var childProcess = require("child_process");
    var { promises: fs2, constants: fsConstants } = require("fs");
    var isWsl = require_is_wsl();
    var isDocker = require_is_docker();
    var defineLazyProperty = require_define_lazy_prop();
    var localXdgOpenPath = path.join(__dirname, "xdg-open");
    var { platform, arch } = process;
    var getWslDrivesMountPoint = (() => {
      const defaultMountPoint = "/mnt/";
      let mountPoint;
      return async function() {
        if (mountPoint) {
          return mountPoint;
        }
        const configFilePath = "/etc/wsl.conf";
        let isConfigFileExists = false;
        try {
          await fs2.access(configFilePath, fsConstants.F_OK);
          isConfigFileExists = true;
        } catch {
        }
        if (!isConfigFileExists) {
          return defaultMountPoint;
        }
        const configContent = await fs2.readFile(configFilePath, { encoding: "utf8" });
        const configMountPoint = /(?<!#.*)root\s*=\s*(?<mountPoint>.*)/g.exec(configContent);
        if (!configMountPoint) {
          return defaultMountPoint;
        }
        mountPoint = configMountPoint.groups.mountPoint.trim();
        mountPoint = mountPoint.endsWith("/") ? mountPoint : `${mountPoint}/`;
        return mountPoint;
      };
    })();
    var pTryEach = async (array, mapper) => {
      let latestError;
      for (const item of array) {
        try {
          return await mapper(item);
        } catch (error) {
          latestError = error;
        }
      }
      throw latestError;
    };
    var baseOpen = async (options) => {
      options = {
        wait: false,
        background: false,
        newInstance: false,
        allowNonzeroExitCode: false,
        ...options
      };
      if (Array.isArray(options.app)) {
        return pTryEach(options.app, (singleApp) => baseOpen({
          ...options,
          app: singleApp
        }));
      }
      let { name: app, arguments: appArguments = [] } = options.app || {};
      appArguments = [...appArguments];
      if (Array.isArray(app)) {
        return pTryEach(app, (appName) => baseOpen({
          ...options,
          app: {
            name: appName,
            arguments: appArguments
          }
        }));
      }
      let command;
      const cliArguments = [];
      const childProcessOptions = {};
      if (platform === "darwin") {
        command = "open";
        if (options.wait) {
          cliArguments.push("--wait-apps");
        }
        if (options.background) {
          cliArguments.push("--background");
        }
        if (options.newInstance) {
          cliArguments.push("--new");
        }
        if (app) {
          cliArguments.push("-a", app);
        }
      } else if (platform === "win32" || isWsl && !isDocker()) {
        const mountPoint = await getWslDrivesMountPoint();
        command = isWsl ? `${mountPoint}c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe` : `${process.env.SYSTEMROOT}\\System32\\WindowsPowerShell\\v1.0\\powershell`;
        cliArguments.push(
          "-NoProfile",
          "-NonInteractive",
          "\u2013ExecutionPolicy",
          "Bypass",
          "-EncodedCommand"
        );
        if (!isWsl) {
          childProcessOptions.windowsVerbatimArguments = true;
        }
        const encodedArguments = ["Start"];
        if (options.wait) {
          encodedArguments.push("-Wait");
        }
        if (app) {
          encodedArguments.push(`"\`"${app}\`""`, "-ArgumentList");
          if (options.target) {
            appArguments.unshift(options.target);
          }
        } else if (options.target) {
          encodedArguments.push(`"${options.target}"`);
        }
        if (appArguments.length > 0) {
          appArguments = appArguments.map((arg) => `"\`"${arg}\`""`);
          encodedArguments.push(appArguments.join(","));
        }
        options.target = Buffer.from(encodedArguments.join(" "), "utf16le").toString("base64");
      } else {
        if (app) {
          command = app;
        } else {
          const isBundled = !__dirname || __dirname === "/";
          let exeLocalXdgOpen = false;
          try {
            await fs2.access(localXdgOpenPath, fsConstants.X_OK);
            exeLocalXdgOpen = true;
          } catch {
          }
          const useSystemXdgOpen = process.versions.electron || platform === "android" || isBundled || !exeLocalXdgOpen;
          command = useSystemXdgOpen ? "xdg-open" : localXdgOpenPath;
        }
        if (appArguments.length > 0) {
          cliArguments.push(...appArguments);
        }
        if (!options.wait) {
          childProcessOptions.stdio = "ignore";
          childProcessOptions.detached = true;
        }
      }
      if (options.target) {
        cliArguments.push(options.target);
      }
      if (platform === "darwin" && appArguments.length > 0) {
        cliArguments.push("--args", ...appArguments);
      }
      const subprocess = childProcess.spawn(command, cliArguments, childProcessOptions);
      if (options.wait) {
        return new Promise((resolve, reject) => {
          subprocess.once("error", reject);
          subprocess.once("close", (exitCode) => {
            if (options.allowNonzeroExitCode && exitCode > 0) {
              reject(new Error(`Exited with code ${exitCode}`));
              return;
            }
            resolve(subprocess);
          });
        });
      }
      subprocess.unref();
      return subprocess;
    };
    var open2 = (target, options) => {
      if (typeof target !== "string") {
        throw new TypeError("Expected a `target`");
      }
      return baseOpen({
        ...options,
        target
      });
    };
    var openApp = (name, options) => {
      if (typeof name !== "string") {
        throw new TypeError("Expected a `name`");
      }
      const { arguments: appArguments = [] } = options || {};
      if (appArguments !== void 0 && appArguments !== null && !Array.isArray(appArguments)) {
        throw new TypeError("Expected `appArguments` as Array type");
      }
      return baseOpen({
        ...options,
        app: {
          name,
          arguments: appArguments
        }
      });
    };
    function detectArchBinary(binary) {
      if (typeof binary === "string" || Array.isArray(binary)) {
        return binary;
      }
      const { [arch]: archBinary } = binary;
      if (!archBinary) {
        throw new Error(`${arch} is not supported`);
      }
      return archBinary;
    }
    function detectPlatformBinary({ [platform]: platformBinary }, { wsl }) {
      if (wsl && isWsl) {
        return detectArchBinary(wsl);
      }
      if (!platformBinary) {
        throw new Error(`${platform} is not supported`);
      }
      return detectArchBinary(platformBinary);
    }
    var apps = {};
    defineLazyProperty(apps, "chrome", () => detectPlatformBinary({
      darwin: "google chrome",
      win32: "chrome",
      linux: ["google-chrome", "google-chrome-stable", "chromium"]
    }, {
      wsl: {
        ia32: "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe",
        x64: ["/mnt/c/Program Files/Google/Chrome/Application/chrome.exe", "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"]
      }
    }));
    defineLazyProperty(apps, "firefox", () => detectPlatformBinary({
      darwin: "firefox",
      win32: "C:\\Program Files\\Mozilla Firefox\\firefox.exe",
      linux: "firefox"
    }, {
      wsl: "/mnt/c/Program Files/Mozilla Firefox/firefox.exe"
    }));
    defineLazyProperty(apps, "edge", () => detectPlatformBinary({
      darwin: "microsoft edge",
      win32: "msedge",
      linux: ["microsoft-edge", "microsoft-edge-dev"]
    }, {
      wsl: "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
    }));
    open2.apps = apps;
    open2.openApp = openApp;
    module2.exports = open2;
  }
});

// me.js
var fs = require("fs");
var open = require_open();
var dataURI = process.argv[process.argv.length - 1];
console.log(dataURI);
var data = dataURI.split(",")[1];
var byteString = Buffer.from(data, "base64");
var json = JSON.parse(byteString.toString("utf8"));
var image = json.image;
var imageData = image.split(",")[1];
var imageBuffer = Buffer.from(imageData, "base64");
fs.writeFileSync("./src/onchain.svg", imageBuffer);
open("./src/onchain.svg");