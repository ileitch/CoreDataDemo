# TTLogger

Standard logging for Thumbtack projects. Uses [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack) for the actual work.

## How To Use It

Add pod to your Podfile:

```
pod `TTLogger`
```

Configure the log level, the default is `LOG_LEVEL_ALL`.

```
#ifdef DEBUG
[TTLogger setLogLevel:LOG_LEVEL_INFO];
#else
[TTLogger setLogLevel:LOG_LEVEL_WARN];
#endif
```

Now instead of using `NSLog` you can use one of the `TTLog` macros:

```
TTLogError
TTLogWarn
TTLogInfo
TTLogDebug
TTLogVerbose
```
