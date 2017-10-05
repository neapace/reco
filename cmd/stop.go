package cmd

import (
	"fmt"
	"reflect"
	"strings"

	"github.com/ReconfigureIO/reco"
	"github.com/ReconfigureIO/reco/logger"
	"github.com/spf13/cobra"
)

var stopPreRun = func(cmd *cobra.Command, args []string) {
	if len(args) == 0 {
		exitWithError("id required")
	}
}

func genStopSubcommand(name string) *cobra.Command {
	return &cobra.Command{
		Use:     "stop id",
		Aliases: []string{"s", "stp", "stops"},
		Short:   fmt.Sprintf("Stop a %s", name),
		Long:    fmt.Sprintf("Stop a %s previously started with 'reco %s run'", name, name),
		PreRun:  stopPreRun,
		Run: func(cmd *cobra.Command, args []string) {
			l := reflect.ValueOf(tool).MethodByName(strings.Title(name)).Call(nil)[0].Interface()
			if err := l.(reco.Job).Stop(args[0]); err != nil {
				exitWithError(err)
			}
			logger.Std.Printf("%s stopped successfully", name)
		},
	}
}
