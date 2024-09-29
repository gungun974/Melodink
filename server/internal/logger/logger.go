package logger

import (
	"fmt"
	"path"
	"runtime"
	"strings"

	log "github.com/sirupsen/logrus"
)

type customFormatter struct{}

var projectSourceFolder = ""

func (f *customFormatter) Format(entry *log.Entry) ([]byte, error) {
	levelColor := "\x1b[0m" // Reset
	levelText := strings.ToUpper(entry.Level.String())

	switch entry.Level {
	case log.TraceLevel:
		levelColor = "\x1b[37m"
	case log.DebugLevel:
		levelColor = "\x1b[32m"
	case log.InfoLevel:
		levelColor = "\x1b[34m"
	case log.WarnLevel:
		levelColor = "\x1b[33m"
	case log.ErrorLevel:
		levelColor = "\x1b[31m"
	case log.FatalLevel:
		levelColor = "\x1b[91m"
	case log.PanicLevel:
		levelColor = "\x1b[91m"
	}

	loggerName, ok := entry.Data["logger"]
	if !ok {
		loggerName = "unknown"
	}

	return []byte(fmt.Sprintf(
		"%s %-20s %-40s %-24s %s\n",
		entry.Time.Format("2006-01-02 15:04:05.000"),
		fmt.Sprintf("%s\x1b[1m%s\x1b[0m", levelColor, levelText),
		fmt.Sprintf(
			"%s:%d",
			strings.TrimPrefix(entry.Caller.File, projectSourceFolder),
			entry.Caller.Line,
		),
		fmt.Sprintf("\x1b[1m%s\x1b[0m", loggerName),
		entry.Message,
	)), nil
}

func init() {
	log.SetFormatter(&customFormatter{})
	log.SetLevel(log.InfoLevel)
	log.SetReportCaller(true)

	_, file, _, ok := runtime.Caller(0)
	if ok {
		projectSourceFolder = path.Dir(path.Dir(path.Dir(file)))
	}
}

var MainLogger = log.WithField("logger", "MainLogger")

var DatabaseLogger = log.WithField("logger", "DatabaseLogger")

var ScannerLogger = log.WithField("logger", "ScannerLogger")

var HTTPLogger = log.WithField("logger", "HTTPLogger")
